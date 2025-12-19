-include .env

.PHONY: all test clean deploy fund help install snapshot coverageReport format anvil configureSourcePool configureDestinationPool depositToVaultAndMintRbt bridgeTokensFromSource

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.4.0 && forge install foundry-rs/forge-std@v1.11.0 && forge install openzeppelin/openzeppelin-contracts@v5.5.0 && forge install smartcontractkit/chainlink-local@v0.2.7-beta && npm install @chainlink/contracts-ccip@1.6.3

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

# Create test coverage report and save to .txt file
coverageReport :; forge coverage --report debug > coverage.txt

# Generate Gas Snapshot
snapshot :; forge snapshot

# Generate table showing gas cost for each function
gasReport :; forge test --gas-report

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network eth MAINNET,$(ARGS)),--network eth MAINNET)
	NETWORK_ARGS := --rpc-url $(ETH_MAINNET_RPC_URL) --account defaultKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network eth sepolia,$(ARGS)),--network eth sepolia)
	NETWORK_ARGS := --rpc-url $(ETH_SEPOLIA_RPC_URL) --account defaultKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network arb MAINNET,$(ARGS)),--network arb MAINNET)
	NETWORK_ARGS := --rpc-url $(ARB_MAINNET_RPC_URL) --account defaultKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network arb sepolia,$(ARGS)),--network arb sepolia)
	NETWORK_ARGS := --rpc-url $(ARB_SEPOLIA_RPC_URL) --account defaultKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

# during anvil deployment grantMintAndBurnRole for vault contract is failing, not sure why but acts like it is being called from someone who is not the owner even though it is within the same broadcast. Need to investigate further
deploy:
	@read -p "Deploy Vault contract also? (y/n): " RESPONSE; \
	DEPLOY_FLAG=$$([ "$$RESPONSE" = "y" ] && echo "true" || echo "false"); \
	forge script script/DeployRBT.s.sol:DeployRBT --sig "run(bool)" $$DEPLOY_FLAG $(NETWORK_ARGS)

configureSourcePool:
	forge script script/Interactions.s.sol:ConfigurePool --sig "run(address, uint64, address, address)" 0x7099bF52dBF2f9BDa10a5C7AAae3050886271a4d 3478487238524512106 0xE24BcCBFC48878ea59146E98cfef871d920891Fd 0x3303128056E8B7459C403277AC88468992058941 $(NETWORK_ARGS)

configureDestinationPool:
	forge script script/Interactions.s.sol:ConfigurePool --sig "run(address, uint64, address, address)" 0xE24BcCBFC48878ea59146E98cfef871d920891Fd 16015286601757825753 0x7099bF52dBF2f9BDa10a5C7AAae3050886271a4d 0x98f2e36a043D6828F856a7008Aa5502c10974e51 $(NETWORK_ARGS)

depositToVaultAndMintRbt:
	forge script script/Interactions.s.sol:DepositAndMintRbt --sig "run(address payable, uint256)" 0x12639d86f599921c1b54d502834a55b25AEC5D5e 1000000000000000 $(NETWORK_ARGS)

bridgeTokensFromSource:
	forge script script/Interactions.s.sol:BridgeTokens --sig "run(address, address, uint256, uint64, address, address, uint256)" 0x7Db545F2803A8Fe741522Dec7274Fa4142a337FA 0x98f2e36a043D6828F856a7008Aa5502c10974e51 1000000000000000 3478487238524512106 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59 0x779877A7B0D9E8603169DdbD7836e478b4624789 0 $(NETWORK_ARGS)

# depositToVaultAndMintRbt:
# 	forge cast send --value .001ether --account defaultKey 0x12639d86f599921c1b54d502834a55b25AEC5D5e "deposit()" --rpc-url $(ETH_SEPOLIA_RPC_URL) --broadcast