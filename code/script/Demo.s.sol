// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {AgentEscrow} from "../src/AgentEscrow.sol";

interface ITIP20Approve {
    function approve(address spender, uint256 value) external returns (bool);
}

contract DemoScript is Script {
    function run() external {
        uint256 step = vm.envUint("STEP");
        address escrowAddr = vm.envAddress("ESCROW_ADDRESS");
        AgentEscrow escrow = AgentEscrow(escrowAddr);

        if (step == 1) {
            _createTask(escrow);
            return;
        }
        if (step == 2) {
            _acceptTask(escrow);
            return;
        }
        if (step == 3) {
            _submitWork(escrow);
            return;
        }
        if (step == 4) {
            _resolve(escrow);
            return;
        }
        if (step == 5) {
            _claimJudgeTimeout(escrow);
            return;
        }

        revert("STEP must be 1..5");
    }

    function _createTask(AgentEscrow escrow) internal {
        uint256 requesterPk = vm.envUint("REQUESTER_PRIVATE_KEY");
        address worker = vm.envAddress("WORKER_ADDRESS");
        address judge = vm.envAddress("JUDGE_ADDRESS");
        address token = vm.envAddress("TIP20_STABLECOIN_ADDRESS");
        uint256 amount = vm.envUint("TASK_BOUNTY_AMOUNT");
        bytes32 metadataHash = vm.envBytes32("TASK_METADATA_HASH");
        uint256 judgeReviewPeriod = vm.envUint("JUDGE_REVIEW_PERIOD_SECONDS");

        vm.startBroadcast(requesterPk);
        ITIP20Approve(token).approve(address(escrow), amount);
        uint256 taskId = escrow.createTask(worker, judge, token, amount, metadataHash, judgeReviewPeriod);
        vm.stopBroadcast();

        console2.log("Created task id:", taskId);
    }

    function _acceptTask(AgentEscrow escrow) internal {
        uint256 workerPk = vm.envUint("WORKER_PRIVATE_KEY");
        uint256 taskId = vm.envUint("TASK_ID");

        vm.startBroadcast(workerPk);
        escrow.acceptTask(taskId);
        vm.stopBroadcast();

        console2.log("Accepted task id:", taskId);
    }

    function _submitWork(AgentEscrow escrow) internal {
        uint256 workerPk = vm.envUint("WORKER_PRIVATE_KEY");
        uint256 taskId = vm.envUint("TASK_ID");
        string memory workRef = vm.envString("WORK_REF");

        vm.startBroadcast(workerPk);
        escrow.submitWork(taskId, workRef);
        vm.stopBroadcast();

        console2.log("Submitted work for task id:", taskId);
    }

    function _resolve(AgentEscrow escrow) internal {
        uint256 judgePk = vm.envUint("JUDGE_PRIVATE_KEY");
        uint256 taskId = vm.envUint("TASK_ID");
        bool approve = vm.envBool("APPROVE");
        string memory memo = vm.envString("RESOLUTION_MEMO");

        vm.startBroadcast(judgePk);
        escrow.resolveTask(taskId, approve, memo);
        vm.stopBroadcast();

        console2.log("Resolved task id:", taskId);
        console2.log("approve:", approve);
    }

    function _claimJudgeTimeout(AgentEscrow escrow) internal {
        uint256 requesterPk = vm.envUint("REQUESTER_PRIVATE_KEY");
        uint256 taskId = vm.envUint("TASK_ID");

        vm.startBroadcast(requesterPk);
        escrow.claimJudgeTimeout(taskId);
        vm.stopBroadcast();

        console2.log("Claimed judge timeout for task id:", taskId);
    }
}

