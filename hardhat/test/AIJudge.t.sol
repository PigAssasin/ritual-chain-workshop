// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AIJudge} from "../contracts/AIJudge.sol";

contract AIJudgeTest is Test {
    AIJudge internal judge;

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    uint256 internal constant REWARD = 1 ether;
    uint256 internal constant START_TIME = 1_000_000;

    function setUp() public {
        judge = new AIJudge();

        vm.deal(owner, 10 ether);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);

        vm.warp(START_TIME);
    }

    function test_SubmitCommitmentBeforeSubmissionDeadlineSucceeds() public {
        uint256 bountyId = _createBounty();
        bytes32 commitment = _commitment("answer", bytes32("salt"), alice, bountyId);

        vm.prank(alice);
        judge.submitCommitment(bountyId, commitment);

        AIJudge.BountyView memory bounty = judge.getBounty(bountyId);
        assertEq(bounty.commitmentCount, 1);
    }

    function test_SubmitCommitmentAfterSubmissionDeadlineReverts() public {
        uint256 bountyId = _createBounty();
        bytes32 commitment = _commitment("answer", bytes32("salt"), alice, bountyId);

        vm.warp(_submissionDeadline() + 1);

        vm.prank(alice);
        vm.expectRevert("submission closed");
        judge.submitCommitment(bountyId, commitment);
    }

    function test_ParticipantCannotSubmitTwoCommitments() public {
        uint256 bountyId = _createBounty();
        bytes32 firstCommitment = _commitment(
            "answer-one",
            bytes32("salt-1"),
            alice,
            bountyId
        );
        bytes32 secondCommitment = _commitment(
            "answer-two",
            bytes32("salt-2"),
            alice,
            bountyId
        );

        vm.startPrank(alice);
        judge.submitCommitment(bountyId, firstCommitment);
        vm.expectRevert("commitment exists");
        judge.submitCommitment(bountyId, secondCommitment);
        vm.stopPrank();
    }

    function test_RevealDuringRevealWindowSucceeds() public {
        uint256 bountyId = _createBounty();
        string memory answer = "Ritual enables AI calls in smart contracts.";
        bytes32 salt = bytes32("valid-salt");

        vm.prank(alice);
        judge.submitCommitment(bountyId, _commitment(answer, salt, alice, bountyId));

        vm.warp(_submissionDeadline());

        vm.prank(alice);
        judge.revealAnswer(bountyId, answer, salt);

        (
            address submitterAnswer,
            string memory revealedAnswer
        ) = judge.getSubmission(bountyId, 0);

        assertEq(submitterAnswer, alice);
        assertEq(revealedAnswer, answer);
    }

    function test_RevealWithWrongSaltReverts() public {
        uint256 bountyId = _createBounty();
        string memory answer = "Ritual answer";
        bytes32 salt = bytes32("right-salt");

        vm.prank(alice);
        judge.submitCommitment(bountyId, _commitment(answer, salt, alice, bountyId));

        vm.warp(_submissionDeadline());

        vm.prank(alice);
        vm.expectRevert("invalid reveal");
        judge.revealAnswer(bountyId, answer, bytes32("wrong-salt"));
    }

    function test_RevealFromDifferentSenderReverts() public {
        uint256 bountyId = _createBounty();
        string memory answer = "Ritual answer";
        bytes32 salt = bytes32("right-salt");

        vm.prank(alice);
        judge.submitCommitment(bountyId, _commitment(answer, salt, alice, bountyId));

        vm.warp(_submissionDeadline());

        vm.prank(bob);
        vm.expectRevert("no commitment");
        judge.revealAnswer(bountyId, answer, salt);
    }

    function test_ParticipantCannotRevealTwice() public {
        uint256 bountyId = _createBounty();
        string memory answer = "Ritual answer";
        bytes32 salt = bytes32("right-salt");

        vm.prank(alice);
        judge.submitCommitment(bountyId, _commitment(answer, salt, alice, bountyId));

        vm.warp(_submissionDeadline());

        vm.startPrank(alice);
        judge.revealAnswer(bountyId, answer, salt);
        vm.expectRevert("already revealed");
        judge.revealAnswer(bountyId, answer, salt);
        vm.stopPrank();
    }

    function test_RevealBeforeSubmissionDeadlineReverts() public {
        uint256 bountyId = _createBounty();
        string memory answer = "Ritual answer";
        bytes32 salt = bytes32("salt");

        vm.prank(alice);
        judge.submitCommitment(bountyId, _commitment(answer, salt, alice, bountyId));

        vm.prank(alice);
        vm.expectRevert("reveal not started");
        judge.revealAnswer(bountyId, answer, salt);
    }

    function test_RevealAfterRevealDeadlineReverts() public {
        uint256 bountyId = _createBounty();
        string memory answer = "Ritual answer";
        bytes32 salt = bytes32("salt");

        vm.prank(alice);
        judge.submitCommitment(bountyId, _commitment(answer, salt, alice, bountyId));

        vm.warp(_revealDeadline());

        vm.prank(alice);
        vm.expectRevert("reveal closed");
        judge.revealAnswer(bountyId, answer, salt);
    }

    function test_UnrevealedSubmissionsAreExcludedFromJudging() public {
        uint256 bountyId = _createBounty();
        string memory aliceAnswer = "Alice answer";
        bytes32 aliceSalt = bytes32("alice-salt");
        string memory bobAnswer = "Bob answer";
        bytes32 bobSalt = bytes32("bob-salt");

        vm.prank(alice);
        judge.submitCommitment(
            bountyId,
            _commitment(aliceAnswer, aliceSalt, alice, bountyId)
        );

        vm.prank(bob);
        judge.submitCommitment(
            bountyId,
            _commitment(bobAnswer, bobSalt, bob, bountyId)
        );

        vm.warp(_submissionDeadline());

        vm.prank(alice);
        judge.revealAnswer(bountyId, aliceAnswer, aliceSalt);

        vm.warp(_revealDeadline());

        vm.prank(owner);
        judge.judgeAll(bountyId, bytes("batch-review"));

        AIJudge.BountyView memory bounty = judge.getBounty(bountyId);
        assertTrue(bounty.judged);
        assertEq(bounty.revealedSubmissionCount, 1);
        assertEq(bounty.aiReview, bytes("batch-review"));

        vm.expectRevert("invalid index");
        judge.getSubmission(bountyId, 1);
    }

    function test_JudgeBeforeRevealDeadlineReverts() public {
        uint256 bountyId = _createBounty();
        string memory answer = "Alice answer";
        bytes32 salt = bytes32("alice-salt");

        vm.prank(alice);
        judge.submitCommitment(bountyId, _commitment(answer, salt, alice, bountyId));

        vm.warp(_submissionDeadline());

        vm.prank(alice);
        judge.revealAnswer(bountyId, answer, salt);

        vm.prank(owner);
        vm.expectRevert("reveal ongoing");
        judge.judgeAll(bountyId, bytes("batch-review"));
    }

    function test_NonOwnerCannotJudge() public {
        uint256 bountyId = _createBounty();
        string memory answer = "Alice answer";
        bytes32 salt = bytes32("alice-salt");

        vm.prank(alice);
        judge.submitCommitment(bountyId, _commitment(answer, salt, alice, bountyId));

        vm.warp(_submissionDeadline());

        vm.prank(alice);
        judge.revealAnswer(bountyId, answer, salt);

        vm.warp(_revealDeadline());

        vm.prank(alice);
        vm.expectRevert("not bounty owner");
        judge.judgeAll(bountyId, bytes("batch-review"));
    }

    function test_JudgeWithoutRevealedSubmissionsReverts() public {
        uint256 bountyId = _createBounty();

        vm.warp(_revealDeadline());

        vm.prank(owner);
        vm.expectRevert("no revealed submissions");
        judge.judgeAll(bountyId, bytes("batch-review"));
    }

    function test_FinalizeBeforeJudgingReverts() public {
        uint256 bountyId = _createBounty();

        vm.prank(owner);
        vm.expectRevert("not judged yet");
        judge.finalizeWinner(bountyId, 0);
    }

    function test_NonOwnerCannotFinalize() public {
        uint256 bountyId = _createBounty();
        string memory answer = "Winning answer";
        bytes32 salt = bytes32("winner-salt");

        vm.prank(alice);
        judge.submitCommitment(bountyId, _commitment(answer, salt, alice, bountyId));

        vm.warp(_submissionDeadline());

        vm.prank(alice);
        judge.revealAnswer(bountyId, answer, salt);

        vm.warp(_revealDeadline());

        vm.prank(owner);
        judge.judgeAll(bountyId, bytes("batch-review"));

        vm.prank(alice);
        vm.expectRevert("not bounty owner");
        judge.finalizeWinner(bountyId, 0);
    }

    function test_FinalizeWithInvalidWinnerIndexReverts() public {
        uint256 bountyId = _createBounty();
        string memory answer = "Winning answer";
        bytes32 salt = bytes32("winner-salt");

        vm.prank(alice);
        judge.submitCommitment(bountyId, _commitment(answer, salt, alice, bountyId));

        vm.warp(_submissionDeadline());

        vm.prank(alice);
        judge.revealAnswer(bountyId, answer, salt);

        vm.warp(_revealDeadline());

        vm.prank(owner);
        judge.judgeAll(bountyId, bytes("batch-review"));

        vm.prank(owner);
        vm.expectRevert("invalid winner index");
        judge.finalizeWinner(bountyId, 1);
    }

    function test_FinalizePaysChosenRevealedWinner() public {
        uint256 bountyId = _createBounty();
        string memory answer = "Winning answer";
        bytes32 salt = bytes32("winner-salt");

        vm.prank(alice);
        judge.submitCommitment(bountyId, _commitment(answer, salt, alice, bountyId));

        vm.warp(_submissionDeadline());

        vm.prank(alice);
        judge.revealAnswer(bountyId, answer, salt);

        vm.warp(_revealDeadline());

        vm.prank(owner);
        judge.judgeAll(bountyId, bytes("batch-review"));

        uint256 aliceBalanceBefore = alice.balance;

        vm.prank(owner);
        judge.finalizeWinner(bountyId, 0);

        assertEq(alice.balance, aliceBalanceBefore + REWARD);
    }

    function _createBounty() internal returns (uint256 bountyId) {
        vm.prank(owner);
        bountyId = judge.createBounty{value: REWARD}(
            "Best Ritual explanation",
            "Score for correctness and clarity.",
            _submissionDeadline(),
            _revealDeadline()
        );
    }

    function _submissionDeadline() internal pure returns (uint256) {
        return START_TIME + 100;
    }

    function _revealDeadline() internal pure returns (uint256) {
        return START_TIME + 200;
    }

    function test_JudgeAllWithoutBatchArtifactReverts() public {
        uint256 bountyId = _createBounty();
        string memory answer = "Alice answer";
        bytes32 salt = bytes32("alice-salt");

        vm.prank(alice);
        judge.submitCommitment(bountyId, _commitment(answer, salt, alice, bountyId));

        vm.warp(_submissionDeadline());

        vm.prank(alice);
        judge.revealAnswer(bountyId, answer, salt);

        vm.warp(_revealDeadline());

        vm.prank(owner);
        vm.expectRevert("llm input required");
        judge.judgeAll(bountyId, bytes(""));
    }

    function _commitment(
        string memory answer,
        bytes32 salt,
        address submitter,
        uint256 bountyId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(answer, salt, submitter, bountyId));
    }
}
