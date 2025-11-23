// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {Vault} from "../src/Vault.sol";

import {
    RegistryModuleOwnerCustom
} from "@chainlink/contracts-ccip/contracts/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "@chainlink/contracts-ccip/contracts/tokenAdminRegistry/TokenAdminRegistry.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {IERC20} from "@openzeppelin/contracts@4.8.3/token/ERC20/IERC20.sol";

import {Script} from "forge-std/Script.sol";

abstract contract CodeConstants {
    // RBT name and symbol
    string public constant RBT_NAME = "Rebase Token";
    string public constant RBT_SYMBOL = "RBT";
    uint256 public constant INITIAL_INTEREST_RATE = 5e10;
    // RBT Token Pool Info
    uint8 public constant DECIMAL_PRECISION = 18;
    // mainnet chain id and info
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    // sepolia chain id and info
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11_155_111;
    // local chain id and info
    uint256 public constant LOCAL_CHAIN_ID = 31_337;
}

contract DeployRBT is Script, CodeConstants {
    address account;

    function run() external returns (RebaseToken rbt, Vault vault) {
        if (block.chainid == LOCAL_CHAIN_ID) {
            account = DEFAULT_SENDER;
        } else {
            account = vm.envAddress("DEFAULT_KEY_ADDRESS");
        }
        vm.startBroadcast(account);
        rbt = new RebaseToken(RBT_NAME, RBT_SYMBOL, INITIAL_INTEREST_RATE);
        vault = new Vault(rbt);
        rbt.grantMintAndBurnRole(address(vault));
        vm.stopBroadcast();
    }
}

contract DeployRBTv2 is Script, CodeConstants {
    RebaseToken rbt;
    address[] allowList; // blank address array for allowlist == anyone can use the bridge

    function run()
        external
        returns (RebaseToken rbt, RebaseTokenPool rbtPool, CCIPLocalSimulatorFork ccipLocalSimulatorFork)
    {
        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        Register.NetworkDetails memory networkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);

        vm.startBroadcast(_getAccount());
        rbt = new RebaseToken(RBT_NAME, RBT_SYMBOL, INITIAL_INTEREST_RATE);
        rbtPool = new RebaseTokenPool(
            IERC20(address(rbt)),
            DECIMAL_PRECISION,
            allowList,
            networkDetails.rmnProxyAddress,
            networkDetails.routerAddress
        );
        rbt.grantMintAndBurnRole(address(rbtPool));
        RegistryModuleOwnerCustom(networkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(address(rbt));
        TokenAdminRegistry(networkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(rbt));
        TokenAdminRegistry(networkDetails.tokenAdminRegistryAddress).setPool(address(rbt), address(rbtPool));
        vm.stopBroadcast();
    }

    function deployVault() external returns (Vault vault) {
        vm.startBroadcast(_getAccount());
        vault = new Vault(rbt);
        rbt.grantMintAndBurnRole(address(vault));
        vm.stopBroadcast();
    }

    function _getAccount() internal returns (address) {
        if (block.chainid == LOCAL_CHAIN_ID) {
            return DEFAULT_SENDER;
        } else {
            return vm.envAddress("DEFAULT_KEY_ADDRESS");
        }
    }
}
