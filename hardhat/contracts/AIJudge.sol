// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PrecompileConsumer} from "./utils/PrecompileConsumer.sol";

contract AIJudge is PrecompileConsumer {
    uint256 public constant MAX_SUBMISSIONS = 10;
    uint256 public constant MAX_ANSWER_LENGTH = 2_000;
    uint256 public constant NO_WINNER = type(uint256).max;

    uint256 public nextBountyId = 1;

    struct Submission {
        address submitter;
        string answer;
    }

    struct CommitmentRecord {
        bytes32 commitment;
        bool revealed;
    }

    struct Bounty {
        address owner;
        string title;
        string rubric;
        uint256 reward;
        uint256 submissionDeadline;
        uint256 revealDeadline;
        bool judged;
        bool finalized;
        bytes aiReview;
        uint256 winnerIndex;
        uint256 commitmentCount;
        Submission[] revealedSubmissions;
        mapping(address => CommitmentRecord) commitments;
    }

    struct BountyView {
        address owner;
        string title;
        string rubric;
        uint256 reward;
        uint256 submissionDeadline;
        uint256 revealDeadline;
        bool judged;
        bool finalized;
        uint256 commitmentCount;
        uint256 revealedSubmissionCount;
        uint256 winnerIndex;
        bytes aiReview;
    }

    struct ConvoHistory {
        string storageType;
        string path;
        string secretsName;
    }

    mapping(uint256 => Bounty) private bounties;

    event BountyCreated(
        uint256 indexed bountyId,
        address indexed owner,
        string title,
        uint256 reward,
        uint256 submissionDeadline,
        uint256 revealDeadline
    );

    event CommitmentSubmitted(
        uint256 indexed bountyId,
        address indexed submitter,
        bytes32 commitment
    );

    event AnswerRevealed(
        uint256 indexed bountyId,
        uint256 indexed submissionIndex,
        address indexed submitter
    );

    event AllAnswersJudged(uint256 indexed bountyId, bytes aiReview);

    event WinnerFinalized(
        uint256 indexed bountyId,
        uint256 indexed winnerIndex,
        address indexed winner,
        uint256 reward
    );

    modifier bountyExists(uint256 bountyId) {
        require(bounties[bountyId].owner != address(0), "bounty not found");
        _;
    }

    modifier onlyOwner(uint256 bountyId) {
        require(msg.sender == bounties[bountyId].owner, "not bounty owner");
        _;
    }

    modifier onlySubmissionPhase(uint256 bountyId) {
        require(
            block.timestamp < bounties[bountyId].submissionDeadline,
            "submission closed"
        );
        _;
    }

    modifier onlyRevealPhase(uint256 bountyId) {
        Bounty storage bounty = bounties[bountyId];
        require(
            block.timestamp >= bounty.submissionDeadline,
            "reveal not started"
        );
        require(block.timestamp < bounty.revealDeadline, "reveal closed");
        _;
    }

    modifier onlyAfterRevealDeadline(uint256 bountyId) {
        require(
            block.timestamp >= bounties[bountyId].revealDeadline,
            "reveal ongoing"
        );
        _;
    }

    function createBounty(
        string calldata title,
        string calldata rubric,
        uint256 submissionDeadline,
        uint256 revealDeadline
    ) external payable returns (uint256 bountyId) {
        require(msg.value > 0, "reward required");
        require(
            submissionDeadline > block.timestamp,
            "submission deadline invalid"
        );
        require(
            revealDeadline > submissionDeadline,
            "reveal deadline invalid"
        );

        bountyId = nextBountyId++;

        Bounty storage bounty = bounties[bountyId];
        bounty.owner = msg.sender;
        bounty.title = title;
        bounty.rubric = rubric;
        bounty.reward = msg.value;
        bounty.submissionDeadline = submissionDeadline;
        bounty.revealDeadline = revealDeadline;
        bounty.winnerIndex = NO_WINNER;

        emit BountyCreated(
            bountyId,
            msg.sender,
            title,
            msg.value,
            submissionDeadline,
            revealDeadline
        );
    }

    function submitCommitment(
        uint256 bountyId,
        bytes32 commitment
    )
        external
        bountyExists(bountyId)
        onlySubmissionPhase(bountyId)
    {
        Bounty storage bounty = bounties[bountyId];
        CommitmentRecord storage record = bounty.commitments[msg.sender];

        require(!bounty.judged, "already judged");
        require(!bounty.finalized, "already finalized");
        require(commitment != bytes32(0), "commitment required");
        require(record.commitment == bytes32(0), "commitment exists");
        require(
            bounty.commitmentCount < MAX_SUBMISSIONS,
            "too many submissions"
        );

        record.commitment = commitment;
        bounty.commitmentCount += 1;

        emit CommitmentSubmitted(bountyId, msg.sender, commitment);
    }

    function revealAnswer(
        uint256 bountyId,
        string calldata answer,
        bytes32 salt
    )
        external
        bountyExists(bountyId)
        onlyRevealPhase(bountyId)
    {
        Bounty storage bounty = bounties[bountyId];
        CommitmentRecord storage record = bounty.commitments[msg.sender];

        require(!bounty.judged, "already judged");
        require(!bounty.finalized, "already finalized");
        require(record.commitment != bytes32(0), "no commitment");
        require(!record.revealed, "already revealed");
        require(bytes(answer).length <= MAX_ANSWER_LENGTH, "answer too long");

        bytes32 expectedCommitment = keccak256(
            abi.encodePacked(answer, salt, msg.sender, bountyId)
        );
        require(expectedCommitment == record.commitment, "invalid reveal");

        record.revealed = true;
        bounty.revealedSubmissions.push(
            Submission({submitter: msg.sender, answer: answer})
        );

        emit AnswerRevealed(
            bountyId,
            bounty.revealedSubmissions.length - 1,
            msg.sender
        );
    }

    function judgeAll(
        uint256 bountyId,
        bytes calldata llmInput
    )
        external
        bountyExists(bountyId)
        onlyOwner(bountyId)
        onlyAfterRevealDeadline(bountyId)
    {
        Bounty storage bounty = bounties[bountyId];

        require(!bounty.judged, "already judged");
        require(!bounty.finalized, "already finalized");
        require(
            bounty.revealedSubmissions.length > 0,
            "no revealed submissions"
        );

        bytes memory output = _executePrecompile(
            LLM_INFERENCE_PRECOMPILE,
            llmInput
        );

        (
            bool hasError,
            bytes memory completionData,
            ,
            string memory errorMessage,

        ) = abi.decode(output, (bool, bytes, bytes, string, ConvoHistory));

        require(!hasError, errorMessage);

        bounty.judged = true;
        bounty.aiReview = completionData;

        emit AllAnswersJudged(bountyId, completionData);
    }

    function finalizeWinner(
        uint256 bountyId,
        uint256 winnerIndex
    ) external bountyExists(bountyId) onlyOwner(bountyId) {
        Bounty storage bounty = bounties[bountyId];

        require(bounty.judged, "not judged yet");
        require(!bounty.finalized, "already finalized");
        require(
            winnerIndex < bounty.revealedSubmissions.length,
            "invalid winner index"
        );

        bounty.finalized = true;
        bounty.winnerIndex = winnerIndex;

        address winner = bounty.revealedSubmissions[winnerIndex].submitter;
        uint256 reward = bounty.reward;
        bounty.reward = 0;

        (bool ok, ) = payable(winner).call{value: reward}("");
        require(ok, "payment failed");

        emit WinnerFinalized(bountyId, winnerIndex, winner, reward);
    }

    function getBounty(
        uint256 bountyId
    )
        external
        view
        bountyExists(bountyId)
        returns (BountyView memory bountyView)
    {
        Bounty storage bounty = bounties[bountyId];

        bountyView = BountyView({
            owner: bounty.owner,
            title: bounty.title,
            rubric: bounty.rubric,
            reward: bounty.reward,
            submissionDeadline: bounty.submissionDeadline,
            revealDeadline: bounty.revealDeadline,
            judged: bounty.judged,
            finalized: bounty.finalized,
            commitmentCount: bounty.commitmentCount,
            revealedSubmissionCount: bounty.revealedSubmissions.length,
            winnerIndex: bounty.winnerIndex,
            aiReview: bounty.aiReview
        });
    }

    function getSubmission(
        uint256 bountyId,
        uint256 index
    )
        external
        view
        bountyExists(bountyId)
        returns (address submitter, string memory answer)
    {
        Bounty storage bounty = bounties[bountyId];
        require(index < bounty.revealedSubmissions.length, "invalid index");

        Submission storage submission = bounty.revealedSubmissions[index];
        return (submission.submitter, submission.answer);
    }
}
