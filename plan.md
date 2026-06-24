# Implementation Plan - Privacy-Preserving AI Bounty Judge

This file is the working plan for the homework. Read `rule.md` first, then use this file as the execution checklist.

## Goal

Implement the required `commit-reveal` bounty flow in the existing workshop repo without adding unnecessary features.

## Scope lock

In scope:

- Update the Solidity contract to the required `commit-reveal` flow.
- Add tests for reveal validity and deadline rules.
- Update submission docs to satisfy the assignment deliverables.
- Keep batch AI judging and human finalization.

Out of scope for the first pass:

- Full advanced encrypted-submission implementation.
- Frontend redesign or extra UX features.
- Off-chain services beyond short documentation notes.

## Live session takeaways

The X live session confirms the workshop baseline and how much of it we should preserve:

- The current repo was built around the old public-answer flow:
  - `createBounty`
  - `submitAnswer`
  - `judgeAll`
  - `finalizeWinner`
- The homework is specifically about evolving that baseline into `commit-reveal`, not inventing a brand-new product.
- Ritual-specific logic is mainly in the contract side, not the frontend side.
- `judgeAll` should keep using one batch judging flow, not one call per submission.
- The owner should remain the human in the loop for final payout selection.
- The repo started with Ritual-specific judging pieces, but the required track still needs to satisfy the wording `works on any EVM chain`.

## Checkpoint 0 - Baseline and source of truth

- [x] Read the assignment PDF.
- [x] Create `rule.md` with the important constraints and repo map.
- [x] Read the X live session transcript for the original workshop context.
- [x] Restore repo baseline after accidental contract deletion.
- [x] Re-read `rule.md` before each major edit block.

Exit criteria:

- We are aligned on the exact assignment requirements.
- No accidental unrelated repo changes are left behind.

## Checkpoint 1 - Contract design before editing

Files:

- `hardhat/contracts/AIJudge.sol`

Design decisions to lock before coding:

- [x] `createBounty` must take both `submissionDeadline` and `revealDeadline`.
- [x] `submitAnswer` will be replaced by `submitCommitment`.
- [x] `revealAnswer` will store plaintext only after the reveal phase opens.
- [x] Only revealed submissions will count toward judging.
- [x] `judgeAll` must be callable only by the bounty owner after `revealDeadline`.
- [x] `finalizeWinner` must pay exactly one winner from the revealed-and-judged set.
- [x] Keep the implementation simple and readable, with no advanced-track features mixed into the required path.
- [x] Keep only the workshop pieces that still fit the homework wording:
  - one batch judging step
  - human-in-the-loop finalization
  - no advanced encrypted-submission logic in the required track

Suggested storage shape:

- `Bounty` stores:
  - owner
  - title
  - rubric
  - reward
  - submissionDeadline
  - revealDeadline
  - judged
  - finalized
  - aiReview
  - winnerIndex
  - revealed submissions array
  - commitment count
  - per-user commitment records

Exit criteria:

- The data model directly maps to the assignment rules.
- There is no public-answer path left in the contract design.

## Checkpoint 2 - Tests first

Files:

- `hardhat/test/AIJudge.t.sol` or `hardhat/contracts/AIJudge.t.sol`

Tests to write before or alongside the contract change:

- [x] submit commitment before submission deadline succeeds
- [x] submit commitment after submission deadline reverts
- [x] a participant cannot submit two commitments for one bounty
- [x] reveal during the valid reveal window succeeds for the correct answer and salt
- [x] reveal with wrong answer or wrong salt reverts
- [x] reveal before submission deadline reverts
- [x] reveal after reveal deadline reverts
- [x] unrevealed submissions are excluded from judging
- [x] judge before reveal deadline reverts
- [x] finalize before judging reverts
- [x] finalize pays the chosen revealed winner

Testing notes:

- Use Solidity unit tests first because the behavior is contract-centric.
- Treat `judgeAll` as the required-track batch judging checkpoint and test the stored artifact directly.
- Keep tests narrow and explicit rather than building a large fixture system.

Exit criteria:

- The tests clearly describe the required assignment behavior.
- At least valid and invalid reveal cases are covered, as required by the PDF.

## Checkpoint 3 - Contract implementation

Files:

- `hardhat/contracts/AIJudge.sol`

Implementation checklist:

- [x] Replace the single `deadline` flow with `submissionDeadline` + `revealDeadline`
- [x] Add `submitCommitment(uint256 bountyId, bytes32 commitment)`
- [x] Add `revealAnswer(uint256 bountyId, string calldata answer, bytes32 salt)`
- [x] Enforce one commitment per participant per bounty
- [x] Verify `keccak256(abi.encodePacked(answer, salt, msg.sender, bountyId))`
- [x] Store only revealed answers in the judged submission list
- [x] Restrict `judgeAll` to owner and post-reveal deadline
- [x] Restrict `finalizeWinner` to the judged state
- [x] Validate `winnerIndex` against the revealed submission count
- [x] Preserve batch judging via one `llmInput` request
- [x] Keep `judgeAll` EVM-generic with no Ritual-only dependency
- [x] Keep payout logic safe with checks-effects-interactions ordering

Exit criteria:

- The contract matches the required function list from the assignment.
- No rule in `rule.md` is violated.

## Checkpoint 4 - Documentation deliverables

Files:

- `README.md`
- `ARCHITECTURE.md` or similar note file

README must include:

- [x] what changed from the workshop baseline
- [x] the bounty lifecycle in plain language
- [x] how commitment and reveal work
- [x] how `judgeAll` and `finalizeWinner` fit the flow
- [x] a short note that this homework starts from the original workshop's public-answer version and replaces that weakness with commit-reveal
- [x] how to run tests

Architecture note must include:

- [x] commit-reveal summary
- [x] Ritual-native hidden submissions comparison
- [x] where plaintext would exist in the advanced design
- [x] what belongs on-chain vs off-chain
- [x] how batch judging works

Reflection deliverable:

- [x] include a 5-8 sentence answer about what should be public, hidden, AI-decided, and human-decided

Exit criteria:

- The repo contains all submission artifacts requested by the homework PDF.

## Checkpoint 5 - Verification

Verification commands to run:

- [x] install Hardhat dependencies if needed
- [x] run contract build/compile
- [x] run the relevant Solidity tests
- [x] inspect git diff for unrelated edits

Verification notes:

- Do not claim completion unless the contract compiles and the new tests pass.
- If deployment is not performed yet, state that clearly rather than pretending it is done.

Exit criteria:

- The changed contract is tested and reviewable.
- The repo is ready for the next step: deployment and form submission.

## Checkpoint 6 - Submission follow-up

This is only after the code and docs are done:

- [ ] deploy the contract
- [ ] record deployed contract address
- [ ] record deployment transaction hash
- [ ] push code to GitHub fork
- [ ] fill the Proof of Building form

Form fields to prepare:

- GitHub Fork URL
- Deployed Contract Address
- Deploy Transaction Hash
- A short honest note about one struggle during the implementation

## Execution order

1. Finish contract design.
2. Write the tests.
3. Implement the contract changes.
4. Update README and architecture note.
5. Run verification.
6. Deploy and fill the form.

## Anti-drift rules

Before any new edit, confirm all of these:

- [ ] This change is required by the assignment or supports a required deliverable.
- [ ] This change does not introduce advanced-track complexity into the required track.
- [ ] This change does not expose plaintext answers during the submission phase.
- [ ] This change keeps AI judging batched, not one call per answer.
- [ ] This change keeps the owner responsible for final payout selection.
