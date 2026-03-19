// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AgentEscrow} from "../src/AgentEscrow.sol";

contract MockTIP20 {
    string public constant NAME = "Mock USD";
    string public constant SYMBOL = "mUSD";
    uint8 public constant DECIMALS = 6;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed < amount) revert("allowance");
        allowance[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        uint256 bal = balanceOf[from];
        if (bal < amount) revert("balance");
        balanceOf[from] = bal - amount;
        balanceOf[to] += amount;
    }
}

contract AgentEscrowTest is Test {
    AgentEscrow internal escrow;
    MockTIP20 internal token;

    uint256 internal requesterPk = 0xA11CE;
    uint256 internal workerPk = 0xB0B;
    uint256 internal judgePk = 0xC0DE;
    uint256 internal outsiderPk = 0xD00D;

    address internal requester;
    address internal worker;
    address internal judge;
    address internal outsider;

    uint256 internal constant BOUNTY = 500_000_000; // 500 USDC-like with 6 decimals
    bytes32 internal constant META = keccak256("task:write-unit-tests");
    uint256 internal constant REVIEW_WINDOW = 3 days;

    function setUp() public {
        requester = vm.addr(requesterPk);
        worker = vm.addr(workerPk);
        judge = vm.addr(judgePk);
        outsider = vm.addr(outsiderPk);

        token = new MockTIP20();
        escrow = new AgentEscrow();

        token.mint(requester, 1_000_000_000);

        vm.prank(requester);
        token.approve(address(escrow), type(uint256).max);
    }

    function test_HappyPath_PaysWorker() public {
        vm.prank(requester);
        uint256 taskId = escrow.createTask(worker, judge, address(token), BOUNTY, META, REVIEW_WINDOW);

        assertEq(token.balanceOf(address(escrow)), BOUNTY);
        assertEq(uint256(escrow.getTaskStatus(taskId)), uint256(AgentEscrow.TaskStatus.Created));

        vm.prank(worker);
        escrow.acceptTask(taskId);
        assertEq(uint256(escrow.getTaskStatus(taskId)), uint256(AgentEscrow.TaskStatus.Accepted));

        vm.prank(worker);
        escrow.submitWork(taskId, "ipfs://QmWorkerOutput123");
        assertEq(uint256(escrow.getTaskStatus(taskId)), uint256(AgentEscrow.TaskStatus.Submitted));

        uint256 workerBefore = token.balanceOf(worker);
        vm.prank(judge);
        escrow.resolveTask(taskId, true, "meets acceptance criteria");

        assertEq(uint256(escrow.getTaskStatus(taskId)), uint256(AgentEscrow.TaskStatus.ResolvedPaid));
        assertEq(token.balanceOf(worker), workerBefore + BOUNTY);
        assertEq(token.balanceOf(address(escrow)), 0);
    }

    function test_RejectPath_RefundsRequester() public {
        vm.prank(requester);
        uint256 taskId = escrow.createTask(worker, judge, address(token), BOUNTY, META, REVIEW_WINDOW);

        vm.prank(worker);
        escrow.acceptTask(taskId);

        vm.prank(worker);
        escrow.submitWork(taskId, "ipfs://QmBadOutput");

        uint256 requesterBefore = token.balanceOf(requester);
        vm.prank(judge);
        escrow.resolveTask(taskId, false, "output failed requirements");

        assertEq(uint256(escrow.getTaskStatus(taskId)), uint256(AgentEscrow.TaskStatus.ResolvedRefunded));
        assertEq(token.balanceOf(requester), requesterBefore + BOUNTY);
        assertEq(token.balanceOf(address(escrow)), 0);
    }

    function test_RevertIf_UnauthorizedActorCallsRoleFunction() public {
        vm.prank(requester);
        uint256 taskId = escrow.createTask(worker, judge, address(token), BOUNTY, META, REVIEW_WINDOW);

        vm.prank(outsider);
        vm.expectRevert(AgentEscrow.Unauthorized.selector);
        escrow.acceptTask(taskId);
    }

    function test_RevertIf_JudgeResolvesBeforeSubmit() public {
        vm.prank(requester);
        uint256 taskId = escrow.createTask(worker, judge, address(token), BOUNTY, META, REVIEW_WINDOW);

        vm.prank(worker);
        escrow.acceptTask(taskId);

        vm.prank(judge);
        vm.expectRevert(AgentEscrow.InvalidStatus.selector);
        escrow.resolveTask(taskId, true, "too early");
    }

    function test_TimeoutPath_RefundsRequesterWhenJudgeInactive() public {
        vm.prank(requester);
        uint256 taskId = escrow.createTask(worker, judge, address(token), BOUNTY, META, REVIEW_WINDOW);

        vm.prank(worker);
        escrow.acceptTask(taskId);

        vm.prank(worker);
        escrow.submitWork(taskId, "ipfs://QmPendingJudge");

        uint256 requesterBefore = token.balanceOf(requester);
        vm.warp(block.timestamp + REVIEW_WINDOW);

        vm.prank(requester);
        escrow.claimJudgeTimeout(taskId);

        assertEq(uint256(escrow.getTaskStatus(taskId)), uint256(AgentEscrow.TaskStatus.TimedOut));
        assertEq(token.balanceOf(requester), requesterBefore + BOUNTY);
        assertEq(token.balanceOf(address(escrow)), 0);
    }

    function test_RevertIf_ClaimTimeoutTooEarly() public {
        vm.prank(requester);
        uint256 taskId = escrow.createTask(worker, judge, address(token), BOUNTY, META, REVIEW_WINDOW);

        vm.prank(worker);
        escrow.acceptTask(taskId);
        vm.prank(worker);
        escrow.submitWork(taskId, "ipfs://QmX");

        vm.prank(requester);
        vm.expectRevert(AgentEscrow.TimeoutNotReached.selector);
        escrow.claimJudgeTimeout(taskId);
    }

    function test_RevertIf_NonRequesterClaimsTimeout() public {
        vm.prank(requester);
        uint256 taskId = escrow.createTask(worker, judge, address(token), BOUNTY, META, REVIEW_WINDOW);

        vm.prank(worker);
        escrow.acceptTask(taskId);
        vm.prank(worker);
        escrow.submitWork(taskId, "ipfs://QmX");

        vm.warp(block.timestamp + REVIEW_WINDOW);

        vm.prank(worker);
        vm.expectRevert(AgentEscrow.Unauthorized.selector);
        escrow.claimJudgeTimeout(taskId);
    }

    function test_RevertIf_TimeoutDisabledWhenReviewWindowZero() public {
        vm.prank(requester);
        uint256 taskId = escrow.createTask(worker, judge, address(token), BOUNTY, META, 0);

        vm.prank(worker);
        escrow.acceptTask(taskId);
        vm.prank(worker);
        escrow.submitWork(taskId, "ipfs://QmX");

        vm.warp(block.timestamp + 30 days);

        vm.prank(requester);
        vm.expectRevert(AgentEscrow.TimeoutDisabled.selector);
        escrow.claimJudgeTimeout(taskId);
    }

    function test_JudgeCanStillResolveBeforeTimeout() public {
        vm.prank(requester);
        uint256 taskId = escrow.createTask(worker, judge, address(token), BOUNTY, META, REVIEW_WINDOW);

        vm.prank(worker);
        escrow.acceptTask(taskId);
        vm.prank(worker);
        escrow.submitWork(taskId, "ipfs://QmGood");

        vm.warp(block.timestamp + REVIEW_WINDOW - 1);

        uint256 workerBefore = token.balanceOf(worker);
        vm.prank(judge);
        escrow.resolveTask(taskId, true, "on time");

        assertEq(uint256(escrow.getTaskStatus(taskId)), uint256(AgentEscrow.TaskStatus.ResolvedPaid));
        assertEq(token.balanceOf(worker), workerBefore + BOUNTY);
    }

    function test_CancelPath_RefundsRequesterBeforeAccept() public {
        vm.prank(requester);
        uint256 taskId = escrow.createTask(worker, judge, address(token), BOUNTY, META, REVIEW_WINDOW);

        uint256 requesterBefore = token.balanceOf(requester);
        vm.prank(requester);
        escrow.cancelTask(taskId);

        assertEq(uint256(escrow.getTaskStatus(taskId)), uint256(AgentEscrow.TaskStatus.Cancelled));
        assertEq(token.balanceOf(requester), requesterBefore + BOUNTY);
        assertEq(token.balanceOf(address(escrow)), 0);
    }

    function test_RevertIf_CancelAfterAccept() public {
        vm.prank(requester);
        uint256 taskId = escrow.createTask(worker, judge, address(token), BOUNTY, META, REVIEW_WINDOW);

        vm.prank(worker);
        escrow.acceptTask(taskId);

        vm.prank(requester);
        vm.expectRevert(AgentEscrow.InvalidStatus.selector);
        escrow.cancelTask(taskId);
    }

    function test_RevertIf_NonRequesterCancels() public {
        vm.prank(requester);
        uint256 taskId = escrow.createTask(worker, judge, address(token), BOUNTY, META, REVIEW_WINDOW);

        vm.prank(worker);
        vm.expectRevert(AgentEscrow.Unauthorized.selector);
        escrow.cancelTask(taskId);
    }

    function test_GetTaskReturnsFullData() public {
        vm.prank(requester);
        uint256 taskId = escrow.createTask(worker, judge, address(token), BOUNTY, META, REVIEW_WINDOW);

        AgentEscrow.Task memory t = escrow.getTask(taskId);

        assertEq(t.requester, requester);
        assertEq(t.worker, worker);
        assertEq(t.judge, judge);
        assertEq(t.token, address(token));
        assertEq(t.bountyAmount, BOUNTY);
        assertEq(t.metadataHash, META);
        assertEq(t.judgeReviewPeriod, REVIEW_WINDOW);
        assertGt(t.createdAt, 0);
        assertEq(uint256(t.status), uint256(AgentEscrow.TaskStatus.Created));
    }
}

