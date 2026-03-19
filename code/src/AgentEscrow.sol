// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITIP20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract AgentEscrow {
    enum TaskStatus {
        None,
        Created,
        Accepted,
        Submitted,
        ResolvedPaid,
        ResolvedRefunded,
        TimedOut,
        Cancelled
    }

    struct Task {
        address requester;
        address worker;
        address judge;
        address token;
        uint256 bountyAmount;
        bytes32 metadataHash;
        /// @notice Seconds the judge has to resolve after `submittedAt`. If 0, on-chain timeout is disabled.
        uint256 judgeReviewPeriod;
        string workRef;
        string resolutionMemo;
        uint256 createdAt;
        uint256 submittedAt;
        uint256 resolvedAt;
        TaskStatus status;
    }

    error InvalidAddress();
    error InvalidAmount();
    error Unauthorized();
    error InvalidStatus();
    error EmptyWorkRef();
    error TokenTransferFailed();
    error ReentrancyGuard();
    error TimeoutDisabled();
    error TimeoutNotReached();

    event TaskCreated(
        uint256 indexed taskId,
        address indexed requester,
        address indexed worker,
        address judge,
        address token,
        uint256 bountyAmount,
        bytes32 metadataHash,
        uint256 judgeReviewPeriod
    );
    event TaskCancelled(uint256 indexed taskId, address indexed requester, uint256 bountyAmount);
    event TaskTimedOut(uint256 indexed taskId, address indexed requester, uint256 bountyAmount);
    event TaskAccepted(uint256 indexed taskId, address indexed worker);
    event WorkSubmitted(uint256 indexed taskId, address indexed worker, string workRef);
    event TaskResolved(
        uint256 indexed taskId, address indexed judge, bool approved, address payoutRecipient, string resolutionMemo
    );

    uint256 public nextTaskId;
    mapping(uint256 => Task) public tasks;

    bool private locked;

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() internal {
        if (locked) revert ReentrancyGuard();
        locked = true;
    }

    function _nonReentrantAfter() internal {
        locked = false;
    }

    function createTask(
        address worker,
        address judge,
        address token,
        uint256 bountyAmount,
        bytes32 metadataHash,
        uint256 judgeReviewPeriod
    ) external returns (uint256 taskId) {
        if (worker == address(0) || judge == address(0) || token == address(0)) revert InvalidAddress();
        if (bountyAmount == 0) revert InvalidAmount();
        if (worker == msg.sender || judge == msg.sender || worker == judge) revert InvalidAddress();

        taskId = ++nextTaskId;
        tasks[taskId] = Task({
            requester: msg.sender,
            worker: worker,
            judge: judge,
            token: token,
            bountyAmount: bountyAmount,
            metadataHash: metadataHash,
            judgeReviewPeriod: judgeReviewPeriod,
            workRef: "",
            resolutionMemo: "",
            createdAt: block.timestamp,
            submittedAt: 0,
            resolvedAt: 0,
            status: TaskStatus.Created
        });

        if (!ITIP20(token).transferFrom(msg.sender, address(this), bountyAmount)) revert TokenTransferFailed();

        emit TaskCreated(taskId, msg.sender, worker, judge, token, bountyAmount, metadataHash, judgeReviewPeriod);
    }

    /// @notice Requester cancels before the worker accepts — bounty refunded immediately.
    function cancelTask(uint256 taskId) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.status != TaskStatus.Created) revert InvalidStatus();
        if (msg.sender != task.requester) revert Unauthorized();

        task.status = TaskStatus.Cancelled;
        task.resolvedAt = block.timestamp;

        if (!ITIP20(task.token).transfer(task.requester, task.bountyAmount)) revert TokenTransferFailed();

        emit TaskCancelled(taskId, task.requester, task.bountyAmount);
    }

    function acceptTask(uint256 taskId) external {
        Task storage task = tasks[taskId];
        if (task.status != TaskStatus.Created) revert InvalidStatus();
        if (msg.sender != task.worker) revert Unauthorized();

        task.status = TaskStatus.Accepted;
        emit TaskAccepted(taskId, msg.sender);
    }

    function submitWork(uint256 taskId, string calldata workRef) external {
        Task storage task = tasks[taskId];
        if (task.status != TaskStatus.Accepted) revert InvalidStatus();
        if (msg.sender != task.worker) revert Unauthorized();
        if (bytes(workRef).length == 0) revert EmptyWorkRef();

        task.workRef = workRef;
        task.submittedAt = block.timestamp;
        task.status = TaskStatus.Submitted;

        emit WorkSubmitted(taskId, msg.sender, workRef);
    }

    function resolveTask(uint256 taskId, bool approve, string calldata resolutionMemo) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.status != TaskStatus.Submitted) revert InvalidStatus();
        if (msg.sender != task.judge) revert Unauthorized();

        task.resolvedAt = block.timestamp;
        task.resolutionMemo = resolutionMemo;

        address payoutRecipient = approve ? task.worker : task.requester;
        task.status = approve ? TaskStatus.ResolvedPaid : TaskStatus.ResolvedRefunded;

        if (!ITIP20(task.token).transfer(payoutRecipient, task.bountyAmount)) revert TokenTransferFailed();

        emit TaskResolved(taskId, msg.sender, approve, payoutRecipient, resolutionMemo);
    }

    /// @notice If the judge does not resolve before `submittedAt + judgeReviewPeriod`, the requester can reclaim the bounty.
    /// @dev When `judgeReviewPeriod` is 0 (set at task creation), this path is disabled.
    function claimJudgeTimeout(uint256 taskId) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.status != TaskStatus.Submitted) revert InvalidStatus();
        if (task.judgeReviewPeriod == 0) revert TimeoutDisabled();
        if (msg.sender != task.requester) revert Unauthorized();
        if (block.timestamp < task.submittedAt + task.judgeReviewPeriod) revert TimeoutNotReached();

        task.resolvedAt = block.timestamp;
        task.resolutionMemo = "judge timeout";
        task.status = TaskStatus.TimedOut;

        if (!ITIP20(task.token).transfer(task.requester, task.bountyAmount)) revert TokenTransferFailed();

        emit TaskTimedOut(taskId, task.requester, task.bountyAmount);
    }

    function getTaskStatus(uint256 taskId) external view returns (TaskStatus) {
        return tasks[taskId].status;
    }

    function getTask(uint256 taskId) external view returns (Task memory) {
        return tasks[taskId];
    }
}

