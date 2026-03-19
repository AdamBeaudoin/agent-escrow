// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {AgentEscrow} from "../src/AgentEscrow.sol";

contract DeployScript is Script {
    function run() external returns (AgentEscrow escrow) {
        uint256 deployerPk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        escrow = new AgentEscrow();
        vm.stopBroadcast();

        console2.log("AgentEscrow deployed");
        console2.log("deployer:", deployer);
        console2.log("contract:", address(escrow));
    }
}

