include .env
export

# Prefer the Tempo-patched Foundry; fall back to whatever is in PATH.
FORGE := $(shell command -v /Users/adam/.foundry/bin/forge 2>/dev/null || command -v forge)
CAST  := $(shell command -v /Users/adam/.foundry/bin/cast  2>/dev/null || command -v cast)

.PHONY: build test clean fmt snapshot deploy-mainnet deploy-mainnet-verify demo-step1 demo-step2 demo-step3 demo-step4 demo-step5

build:
	$(FORGE) build

test:
	$(FORGE) test -vvv

snapshot:
	$(FORGE) snapshot

fmt:
	$(FORGE) fmt

clean:
	$(FORGE) clean

deploy-mainnet:
	@if [ -z "$$TEMPO_RPC_URL" ] || [ -z "$$DEPLOYER_PRIVATE_KEY" ]; then \
		echo "Set TEMPO_RPC_URL and DEPLOYER_PRIVATE_KEY first"; \
		exit 1; \
	fi
	$(FORGE) create src/AgentEscrow.sol:AgentEscrow \
		--rpc-url $$TEMPO_RPC_URL \
		--private-key $$DEPLOYER_PRIVATE_KEY \
		--tempo.fee-token $$TIP20_STABLECOIN_ADDRESS

deploy-mainnet-verify:
	@if [ -z "$$TEMPO_RPC_URL" ] || [ -z "$$DEPLOYER_PRIVATE_KEY" ] || [ -z "$$VERIFIER_URL" ]; then \
		echo "Set TEMPO_RPC_URL, DEPLOYER_PRIVATE_KEY, and VERIFIER_URL first"; \
		exit 1; \
	fi
	$(FORGE) create src/AgentEscrow.sol:AgentEscrow \
		--rpc-url $$TEMPO_RPC_URL \
		--private-key $$DEPLOYER_PRIVATE_KEY \
		--tempo.fee-token $$TIP20_STABLECOIN_ADDRESS \
		--verify \
		--verifier-url $$VERIFIER_URL

demo-step1:
	@if [ -z "$$TEMPO_RPC_URL" ] || [ -z "$$ESCROW_ADDRESS" ]; then \
		echo "Set TEMPO_RPC_URL and ESCROW_ADDRESS first"; \
		exit 1; \
	fi
	STEP=1 $(FORGE) script script/Demo.s.sol:DemoScript \
		--broadcast --slow -vvv \
		--rpc-url $$TEMPO_RPC_URL \
		--tempo.fee-token $$TIP20_STABLECOIN_ADDRESS

demo-step2:
	@if [ -z "$$TEMPO_RPC_URL" ] || [ -z "$$ESCROW_ADDRESS" ] || [ -z "$$TASK_ID" ]; then \
		echo "Set TEMPO_RPC_URL, ESCROW_ADDRESS, and TASK_ID first"; \
		exit 1; \
	fi
	STEP=2 $(FORGE) script script/Demo.s.sol:DemoScript \
		--broadcast --slow -vvv \
		--rpc-url $$TEMPO_RPC_URL \
		--tempo.fee-token $$TIP20_STABLECOIN_ADDRESS

demo-step3:
	@if [ -z "$$TEMPO_RPC_URL" ] || [ -z "$$ESCROW_ADDRESS" ] || [ -z "$$TASK_ID" ]; then \
		echo "Set TEMPO_RPC_URL, ESCROW_ADDRESS, and TASK_ID first"; \
		exit 1; \
	fi
	STEP=3 $(FORGE) script script/Demo.s.sol:DemoScript \
		--broadcast --slow -vvv \
		--rpc-url $$TEMPO_RPC_URL \
		--tempo.fee-token $$TIP20_STABLECOIN_ADDRESS

demo-step4:
	@if [ -z "$$TEMPO_RPC_URL" ] || [ -z "$$ESCROW_ADDRESS" ] || [ -z "$$TASK_ID" ]; then \
		echo "Set TEMPO_RPC_URL, ESCROW_ADDRESS, and TASK_ID first"; \
		exit 1; \
	fi
	STEP=4 $(FORGE) script script/Demo.s.sol:DemoScript \
		--broadcast --slow -vvv \
		--rpc-url $$TEMPO_RPC_URL \
		--tempo.fee-token $$TIP20_STABLECOIN_ADDRESS

demo-step5:
	@if [ -z "$$TEMPO_RPC_URL" ] || [ -z "$$ESCROW_ADDRESS" ] || [ -z "$$TASK_ID" ]; then \
		echo "Set TEMPO_RPC_URL, ESCROW_ADDRESS, and TASK_ID first"; \
		exit 1; \
	fi
	STEP=5 $(FORGE) script script/Demo.s.sol:DemoScript \
		--broadcast --slow -vvv \
		--rpc-url $$TEMPO_RPC_URL \
		--tempo.fee-token $$TIP20_STABLECOIN_ADDRESS
