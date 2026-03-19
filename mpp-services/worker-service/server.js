import cors from "cors";
import crypto from "node:crypto";
import dotenv from "dotenv";
import express from "express";
import { Mppx, tempo } from "mppx/express";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const PORT = Number(process.env.PORT || 4101);
const HOST = process.env.HOST || "0.0.0.0";
const WORKER_CHARGE = process.env.WORKER_CHARGE || "0.01";
const MPP_SECRET_KEY = process.env.MPP_SECRET_KEY || "dev_mpp_secret_change_me";
const MPP_USE_TESTNET = String(process.env.MPP_USE_TESTNET || "false").toLowerCase() === "true";
const MPP_RECIPIENT = process.env.MPP_RECIPIENT || "";
const IS_PROD = process.env.NODE_ENV === "production";

if (IS_PROD && MPP_SECRET_KEY === "dev_mpp_secret_change_me") {
  throw new Error("Set MPP_SECRET_KEY in production (never use the dev default).");
}
const MPP_CURRENCY =
  process.env.MPP_CURRENCY || "0x20c000000000000000000000b9537d11c60e8b50";

if (!MPP_RECIPIENT) {
  throw new Error("Missing MPP_RECIPIENT in .env (address that receives MPP payments).");
}

const mppx = Mppx.create({
  secretKey: MPP_SECRET_KEY,
  methods: [tempo({ testnet: MPP_USE_TESTNET, recipient: MPP_RECIPIENT, currency: MPP_CURRENCY })],
});

app.get("/health", (_req, res) => {
  res.json({
    ok: true,
    service: "worker-service",
    charge: WORKER_CHARGE,
  });
});

// Requester pays via MPP before worker submission is accepted.
app.post("/work/submit", mppx.charge({ amount: WORKER_CHARGE }), (req, res) => {
  const { taskId, requesterAddress, artifactUrl, summary } = req.body ?? {};

  if (!taskId || !artifactUrl) {
    return res.status(400).json({
      ok: false,
      error: "taskId and artifactUrl are required",
    });
  }

  const payload = {
    taskId: String(taskId),
    requesterAddress: requesterAddress || null,
    artifactUrl: String(artifactUrl),
    summary: summary || "",
    submittedAt: new Date().toISOString(),
  };

  const workRef = `ipfs://mock-${crypto.randomUUID()}`;
  const metadataHash = `0x${crypto
    .createHash("sha256")
    .update(JSON.stringify(payload))
    .digest("hex")}`;

  return res.json({
    ok: true,
    message: "MPP payment accepted. Worker payload recorded.",
    workRef,
    metadataHash,
    payload,
  });
});

app.listen(PORT, HOST, () => {
  console.log(`worker-service listening on http://${HOST}:${PORT}`);
  console.log(`MPP charge amount: ${WORKER_CHARGE}`);
  console.log(`MPP network mode: ${MPP_USE_TESTNET ? "testnet" : "mainnet"}`);
  console.log(`MPP recipient: ${MPP_RECIPIENT}`);
  console.log(`MPP currency: ${MPP_CURRENCY}`);
  if (!process.env.MPP_SECRET_KEY) {
    console.warn("WARN: using fallback MPP secret key; set MPP_SECRET_KEY in .env for stable receipts.");
  }
});

