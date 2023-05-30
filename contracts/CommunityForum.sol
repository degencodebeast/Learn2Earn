// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CommunityForum {
    struct ForumThread {
        uint256 id;
        uint256 closingTime;
        mapping(address => uint256) upvotes;
        mapping(uint256 => Answer) answers;
        uint256 answerCount;
    }

    struct Answer {
        address student;
        uint256 upvoteCount;
    }

    mapping(uint256 => ForumThread) public forumThreads;
    uint256 public totalThreads;
    uint256 public maxReward;
    IERC20 public learn;

    event ThreadCreated(uint256 indexed id, uint256 closingTime);
    event AnswerSubmitted(
        uint256 indexed threadId,
        uint256 indexed answerId,
        address indexed student
    );
    event Upvote(
        uint256 indexed threadId,
        uint256 indexed answerId,
        address indexed student,
        uint256 upvoteCount
    );
    event RewardsDistributed(uint256 indexed threadId);

    constructor(IERC20 _token, uint256 _maxReward) {
        learn = _token;
        totalThreads = 0;
        maxReward = _maxReward;
    }

    function createThread() external {
        totalThreads++;
        ForumThread storage thread = forumThreads[totalThreads];
        thread.id = totalThreads;
        thread.closingTime = block.timestamp + 7 days;

        emit ThreadCreated(totalThreads, thread.closingTime);
    }

    function submitAnswer(uint256 _threadId) external {
        require(_threadId <= totalThreads, "Invalid thread ID");
        ForumThread storage thread = forumThreads[_threadId];
        require(
            block.timestamp <= thread.closingTime,
            "Forum thread is closed"
        );

        uint256 answerId = ++thread.answerCount;
        Answer storage answer = thread.answers[answerId];
        answer.student = msg.sender;

        emit AnswerSubmitted(_threadId, answerId, msg.sender);
    }

    function upvoteAnswer(uint256 _threadId, uint256 _answerId) external {
        require(_threadId <= totalThreads, "Invalid thread ID");
        ForumThread storage thread = forumThreads[_threadId];
        require(_answerId <= thread.answerCount, "Invalid answer ID");
        Answer storage answer = thread.answers[_answerId];
        require(
            block.timestamp <= thread.closingTime,
            "Forum thread is closed"
        );

        answer.upvoteCount++;
        thread.upvotes[msg.sender]++;

        emit Upvote(_threadId, _answerId, msg.sender, answer.upvoteCount);
    }

    function distributeRewards(uint256 _threadId) external {
        // automatically with chainlink automation
        require(_threadId <= totalThreads, "Invalid thread ID");
        ForumThread storage thread = forumThreads[_threadId];
        require(
            block.timestamp > thread.closingTime,
            "Forum thread is still open"
        );

        uint256 totalUpvotes = getTotalUpvotes(thread);
        require(totalUpvotes > 0, "No upvoted answers");

        for (uint256 i = 1; i <= thread.answerCount; i++) {
            Answer storage answer = thread.answers[i];
            if (answer.upvoteCount > 0) {
                uint256 reward = (answer.upvoteCount * maxReward) /
                    totalUpvotes;
                learn.transfer(answer.student, reward);
            }
        }

        emit RewardsDistributed(_threadId);
    }

    function getTotalUpvotes(
        ForumThread storage _thread
    ) internal view returns (uint256) {
        uint256 totalUpvotes = 0;
        for (uint256 i = 1; i <= _thread.answerCount; i++) {
            totalUpvotes += _thread.answers[i].upvoteCount;
        }
        return totalUpvotes;
    }
}
