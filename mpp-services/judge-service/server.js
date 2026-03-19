import cors from "cors";
import crypto from "node:crypto";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import dotenv from "dotenv";
import express from "express";
import { Mppx, tempo } from "mppx/express";

const execFileAsync = promisify(execFile);

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const PORT = Number(process.env.PORT || 4102);
const HOST = process.env.HOST || "0.0.0.0";
const JUDGE_CHARGE = process.env.JUDGE_CHARGE || "0.02";
const MPP_SECRET_KEY = process.env.MPP_SECRET_KEY || "dev_mpp_secret_change_me";
const MPP_USE_TESTNET = String(process.env.MPP_USE_TESTNET || "false").toLowerCase() === "true";
const MPP_RECIPIENT = process.env.MPP_RECIPIENT || "";
const IS_PROD = process.env.NODE_ENV === "production";

if (IS_PROD && MPP_SECRET_KEY === "dev_mpp_secret_change_me") {
  throw new Error("Set MPP_SECRET_KEY in production (never use the dev default).");
}
const MPP_CURRENCY =
  process.env.MPP_CURRENCY || "0x20c000000000000000000000b9537d11c60e8b50";
const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY || "";
const ANTHROPIC_MODEL = process.env.ANTHROPIC_MODEL || "claude-3-5-haiku-latest";
const ANTHROPIC_MAX_TOKENS = Number(process.env.ANTHROPIC_MAX_TOKENS || 250);

const JUDGE_PRIVATE_KEY = process.env.JUDGE_PRIVATE_KEY || "";
const ESCROW_ADDRESS = process.env.ESCROW_ADDRESS || "";
const TEMPO_RPC_URL = process.env.TEMPO_RPC_URL || "https://rpc.tempo.xyz";
const CAST_BIN = process.env.CAST_BIN || "/Users/adam/.foundry/bin/cast";
const AUTO_SETTLE = !!(JUDGE_PRIVATE_KEY && ESCROW_ADDRESS);

if (!MPP_RECIPIENT) {
  throw new Error("Missing MPP_RECIPIENT in .env (address that receives MPP payments).");
}

const mppx = Mppx.create({
  secretKey: MPP_SECRET_KEY,
  methods: [tempo({ testnet: MPP_USE_TESTNET, recipient: MPP_RECIPIENT, currency: MPP_CURRENCY })],
});

async function settleOnChain(taskId, approve, resolutionMemo) {
  if (!AUTO_SETTLE) return null;

  try {
    const sig = "resolveTask(uint256,bool,string)";
    const args = [
      CAST_BIN, "send", ESCROW_ADDRESS, sig,
      String(taskId), String(approve), resolutionMemo,
      "--rpc-url", TEMPO_RPC_URL,
      "--private-key", JUDGE_PRIVATE_KEY,
      "--tempo.fee-token", MPP_CURRENCY,
    ];
    const { stdout } = await execFileAsync(args[0], args.slice(1), { timeout: 60_000 });
    const hashMatch = stdout.match(/transactionHash\s+(0x[0-9a-fA-F]+)/);
    const statusMatch = stdout.match(/status\s+(true|false|0x[01])/);
    const txHash = hashMatch ? hashMatch[1] : null;
    const ok = statusMatch ? (statusMatch[1] === "true" || statusMatch[1] === "0x1") : false;
    return { txHash, status: ok ? "confirmed" : "reverted" };
  } catch (err) {
    return { txHash: null, status: "failed", error: String(err.message || err).slice(0, 200) };
  }
}

app.get("/health", (_req, res) => {
  res.json({
    ok: true,
    service: "judge-service",
    charge: JUDGE_CHARGE,
    autoSettle: AUTO_SETTLE ? "enabled" : "disabled",
  });
});

async function handleEvaluate(req, res) {
  const { taskId, workRef, rubric, notes } = req.body ?? {};

  if (!taskId || !workRef) {
    return res.status(400).json({
      ok: false,
      error: "taskId and workRef are required",
    });
  }

  const evaluation = await evaluateSubmission({
    workRef: String(workRef),
    rubric: rubric || "default-rubric",
    notes: notes || "",
  });

  const settlement = await settleOnChain(taskId, evaluation.approve, evaluation.resolutionMemo);

  const receiptId = `judge-${crypto.randomUUID()}`;
  return res.json({
    ok: true,
    receiptId,
    taskId: String(taskId),
    approve: evaluation.approve,
    resolutionMemo: evaluation.resolutionMemo,
    judgeReasoning: evaluation.reasoning,
    judgeProvider: evaluation.provider,
    rubric: rubric || "default-rubric",
    notes: notes || "",
    evaluatedAt: new Date().toISOString(),
    settlement: settlement || { status: "disabled" },
  });
}

app.post("/judge/evaluate", mppx.charge({ amount: JUDGE_CHARGE }), handleEvaluate);

app.post("/judge/evaluate-test", (req, res, next) => {
  if (IS_PROD) return res.status(403).json({ ok: false, error: "test endpoint disabled in production" });
  next();
}, handleEvaluate);

async function evaluateSubmission({ workRef, rubric, notes }) {
  const fallback = heuristicJudge(workRef);
  if (!ANTHROPIC_API_KEY) {
    return {
      ...fallback,
      provider: "fallback-heuristic",
      reasoning: "No ANTHROPIC_API_KEY configured; used heuristic evaluation.",
    };
  }

  try {
    const systemPrompt =
      "You are a strict neutral judge for hackathon task submissions. " +
      "Return JSON only with fields: approve(boolean), resolutionMemo(string), reasoning(string). " +
      "Keep memo short and specific.";

    const userPrompt = JSON.stringify(
      {
        rubric,
        notes,
        submission: { workRef },
        instructions: "Assess whether this submission likely satisfies requested work quality.",
      },
      null,
      2
    );

    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "anthropic-version": "2023-06-01",
        "x-api-key": ANTHROPIC_API_KEY,
      },
      body: JSON.stringify({
        model: ANTHROPIC_MODEL,
        max_tokens: ANTHROPIC_MAX_TOKENS,
        temperature: 0,
        system: systemPrompt,
        messages: [{ role: "user", content: userPrompt }],
      }),
    });

    if (!response.ok) {
      const errBody = await response.text().catch(() => "");
      console.error(`Anthropic API error ${response.status}:`, errBody);
      throw new Error(`anthropic_status_${response.status}: ${errBody.slice(0, 120)}`);
    }

    const json = await response.json();
    const text = Array.isArray(json.content)
      ? json.content.find((item) => item.type === "text")?.text || ""
      : "";

    const parsed = parseJsonBlock(text);
    if (typeof parsed.approve !== "boolean") throw new Error("invalid_judge_json");

    return {
      approve: parsed.approve,
      resolutionMemo: String(parsed.resolutionMemo || (parsed.approve ? "accepted" : "rejected")).slice(0, 160),
      reasoning: String(parsed.reasoning || "LLM evaluation completed").slice(0, 400),
      provider: "anthropic",
    };
  } catch (error) {
    return {
      ...fallback,
      provider: "fallback-heuristic",
      reasoning: `LLM unavailable (${String(error)}); used heuristic evaluation.`,
    };
  }
}

function heuristicJudge(workRef) {
  const normalized = String(workRef).toLowerCase();
  const rejectSignal =
    normalized.includes("bad") || normalized.includes("fail") || normalized.includes("incomplete");
  const approve = !rejectSignal;
  return {
    approve,
    resolutionMemo: approve ? "accepted by judge service" : "rejected by judge service",
  };
}

function parseJsonBlock(value) {
  const trimmed = String(value || "").trim();
  const start = trimmed.indexOf("{");
  const end = trimmed.lastIndexOf("}");
  if (start < 0 || end <= start) throw new Error("json_not_found");
  return JSON.parse(trimmed.slice(start, end + 1));
}

app.listen(PORT, HOST, () => {
  console.log(`judge-service listening on http://${HOST}:${PORT}`);
  console.log(`MPP charge amount: ${JUDGE_CHARGE}`);
  console.log(
    `judge model mode: ${
      ANTHROPIC_API_KEY ? `${ANTHROPIC_MODEL} (API enabled)` : "fallback heuristic (no API key)"
    }`
  );
  console.log(`auto-settle: ${AUTO_SETTLE ? `enabled → ${ESCROW_ADDRESS}` : "disabled (set JUDGE_PRIVATE_KEY + ESCROW_ADDRESS to enable)"}`);
  console.log(`MPP network mode: ${MPP_USE_TESTNET ? "testnet" : "mainnet"}`);
  console.log(`MPP recipient: ${MPP_RECIPIENT}`);
  console.log(`MPP currency: ${MPP_CURRENCY}`);
  if (!process.env.MPP_SECRET_KEY) {
    console.warn("WARN: using fallback MPP secret key; set MPP_SECRET_KEY in .env for stable receipts.");
  }
});
