# Ritual AI Bounty Judge homework rules

## Goal

The homework turns the workshop bounty judge into a fairer system:

- Participants should not see each other's answers during the submission phase.
- The required track should use a `commit-reveal` flow.
- Only valid revealed answers should be eligible for AI judging.
- AI should judge submissions in one batch, while a human still calls `finalizeWinner`.

## Core required flow

The required track must implement this flow:

1. The bounty owner creates a bounty with:
   - a reward
   - a submission deadline
   - a reveal deadline
2. During the submission phase, each participant submits only a `commitment hash`.
3. After the submission deadline, the participant reveals `answer + salt`.
4. The contract verifies:

```solidity
keccak256(abi.encodePacked(answer, salt, msg.sender, bountyId))
```

5. Only valid revealed answers are eligible for AI judging.
6. After the reveal deadline, the owner calls `judgeAll(...)`.
7. After judging is complete, the owner calls `finalizeWinner(...)`.
8. Only one winner receives the reward.

Notes:

- The required track is a smart contract solution that should work on any EVM chain.
- The minimum privacy goal for the required track is to hide answers during the submission phase.
- Keeping answers hidden until after judging belongs to the advanced track.

## The problem the homework is solving

The workshop version had a clear fairness issue:

- User A submitted an answer early.
- That answer became public immediately.
- User B could read it, reuse the idea, improve it, and submit a stronger version.

The new flow needs to fix that.

## Required Solidity functions

```solidity
submitCommitment(uint256 bountyId, bytes32 commitment)
revealAnswer(uint256 bountyId, string calldata answer, bytes32 salt)
judgeAll(uint256 bountyId, bytes calldata llmInput)
finalizeWinner(uint256 bountyId, uint256 winnerIndex)
```

## Important contract rules

- Commitments can be submitted only before `submissionDeadline`.
- Answers can be revealed only after `submissionDeadline` and before `revealDeadline`.
- Each participant can submit only one commitment per bounty.
- A reveal is valid only if the hash matches the original commitment.
- Unrevealed submissions are not eligible for judging.
- The owner can judge only after `revealDeadline`.
- The owner can finalize only after judging is complete.
- AI should not pay out automatically. The owner still finalizes the winner.

## What reveal means in the required track

The required track does not reveal answers automatically.

- The contract stores only the `commitment`, not the plaintext answer.
- A participant must explicitly call `revealAnswer(...)`.
- If a participant never reveals, that submission is not eligible for judging.

## When answers become public

There are two different tracks here.

### Required track

- Answers stay hidden during the submission phase.
- Answers become public when participants reveal them during the reveal phase.
- Judging happens only after the reveal deadline.

### Advanced track

- Plaintext answers can stay hidden until after AI judging is complete.
- This can be presented as a design note even if it is not fully implemented.

## Required deliverables

The submission should include at least:

- an updated Solidity contract
- a README that explains the new bounty lifecycle
- a test or test plan for valid and invalid reveal cases
- an architecture note comparing:
  - commit-reveal
  - Ritual-native hidden submissions
- a 5 to 8 sentence reflection answering:
  - "What should be public, what should stay hidden, and what should be decided by AI versus by a human in a bounty system?"

## Evaluation criteria

- Commit-reveal correctness: 30%
- Smart contract safety: 20%
- Ritual understanding: 20%
- Code clarity: 15%
- Testing / explanation: 15%

To score well, the work should prioritize:

- correct deadline and eligibility logic
- safe payout handling
- a clear explanation of why AI judging is batched
- readable code
- reasonable tests or a clear test plan

## What the advanced track should explain

If the advanced track is attempted, it should explain:

- where plaintext answers exist
- what stays on-chain and what stays off-chain
- how the LLM receives all submissions in one batch
- how the final reveal happens
- how the contract verifies or commits to the final revealed bundle

It does not have to be fully implemented if that becomes too complex, but the note should still be coherent.

## Important assignment constraints

- Do not call the LLM once per submission inside a loop.
- Judge all submissions together in one batch request.
- Do not reveal answers during the submission phase.
- Do not let AI automatically pay the winner unless the result parsing and validation are explained clearly.
- Keep the required track simple.

## Recommended commitment formula

```solidity
bytes32 commitment = keccak256(
    abi.encodePacked(answer, salt, msg.sender, bountyId)
);
```

Why include `msg.sender` and `bountyId`:

- to stop another participant from copying a commitment
- to stop the same commitment from being reused across bounties

## Current repo and important files

Root repo:

- [README.md](F:\Ritual Academy\ritual-chain-workshop\README.md)
- [rule.md](F:\Ritual Academy\ritual-chain-workshop\rule.md)

Smart contract:

- [hardhat/contracts/AIJudge.sol](F:\Ritual Academy\ritual-chain-workshop\hardhat\contracts\AIJudge.sol)
- [hardhat/ignition/modules/AIJudge.ts](F:\Ritual Academy\ritual-chain-workshop\hardhat\ignition\modules\AIJudge.ts)
- [hardhat/hardhat.config.ts](F:\Ritual Academy\ritual-chain-workshop\hardhat\hardhat.config.ts)
- [hardhat/package.json](F:\Ritual Academy\ritual-chain-workshop\hardhat\package.json)

The current frontend is still oriented around the public-answer workflow, so it may need updates later:

- [web/src/components/SubmitAnswer.tsx](F:\Ritual Academy\ritual-chain-workshop\web\src\components\SubmitAnswer.tsx)
- [web/src/components/SubmissionsList.tsx](F:\Ritual Academy\ritual-chain-workshop\web\src\components\SubmissionsList.tsx)
- [web/src/components/JudgeAll.tsx](F:\Ritual Academy\ritual-chain-workshop\web\src\components\JudgeAll.tsx)
- [web/src/components/FinalizeWinner.tsx](F:\Ritual Academy\ritual-chain-workshop\web\src\components\FinalizeWinner.tsx)
- [web/src/components/CreateBountyForm.tsx](F:\Ritual Academy\ritual-chain-workshop\web\src\components\CreateBountyForm.tsx)
- [web/src/components/BountyView.tsx](F:\Ritual Academy\ritual-chain-workshop\web\src\components\BountyView.tsx)
- [web/src/components/BountyDetail.tsx](F:\Ritual Academy\ritual-chain-workshop\web\src\components\BountyDetail.tsx)
- [web/src/hooks/useBounty.ts](F:\Ritual Academy\ritual-chain-workshop\web\src\hooks\useBounty.ts)
- [web/src/lib/bounty.ts](F:\Ritual Academy\ritual-chain-workshop\web\src\lib\bounty.ts)
- [web/src/lib/ritualLlm.ts](F:\Ritual Academy\ritual-chain-workshop\web\src\lib\ritualLlm.ts)
- [web/src/abi/AIJudge.ts](F:\Ritual Academy\ritual-chain-workshop\web\src\abi\AIJudge.ts)

## Current code status

The required-track contract has already been moved to a commit-reveal flow:

- `createBounty(title, rubric, submissionDeadline, revealDeadline)`
- `submitCommitment(bountyId, commitment)`
- `revealAnswer(bountyId, answer, salt)`
- `judgeAll(bountyId, llmInput)`
- `finalizeWinner(bountyId, winnerIndex)`

In the required track, `judgeAll(...)` records a batch judging artifact on-chain in an EVM-generic way instead of depending on a Ritual-only precompile.

## Implementation order that made sense

When implementing the homework, this order was the most practical:

1. Update the `Bounty` struct to include:
   - a submission deadline
   - a reveal deadline
   - commitment storage
   - revealed submission storage
2. Replace `submitAnswer` with `submitCommitment`.
3. Add `revealAnswer`.
4. Enforce the correct phase for each action.
5. Build the `judgeAll` batch artifact only from valid revealed submissions.
6. Validate `winnerIndex` against the judged submission list.
7. Update the ABI and frontend later if a UI demo is needed.

## Tests worth covering

At minimum, the tests should cover:

- valid commitment submission before the deadline
- submission after the deadline reverting
- valid reveal with the correct answer and salt
- invalid reveal with the wrong answer or salt reverting
- reveal before submission deadline reverting
- reveal after reveal deadline reverting
- unrevealed submissions being excluded from judging
- judging before the reveal deadline reverting
- finalizing before judging reverting
- only one winner receiving the reward

## What to prepare for the submission form

For the "Proof of Building - Step 1" form, prepare:

- GitHub Fork URL
  - the fork containing the homework code
- Deployed Contract Address
  - the deployed contract address
- Deploy Transaction Hash
  - the deployment transaction hash
- A step you struggled with
  - a short honest description of a real difficulty
  - for example:
    - phase logic between submit, reveal, and judge
    - commitment hashing
    - judging only revealed submissions
    - using one batch LLM request instead of one call per answer

## Reflection guidance

The reflection should focus on system design, not just code:

- what should be public
- what should stay hidden
- what AI should decide
- what a human should keep control over

A safe answer usually looks like this:

- rubric, deadlines, reward, and winner should be public
- answers should stay hidden during the submission phase
- AI should help with scoring, ranking, and summary reasoning
- the human owner should finalize the payout

## Working rules for future changes

Before any major edit, check all of these:

1. Does this change still follow the commit-reveal flow?
2. Does it leak plaintext answers too early?
3. Does it keep judging in one batch request?
4. Does it keep the owner responsible for the final payout decision?
5. Does it require updates to the README, tests, architecture note, ABI, or frontend?

## Source material

- Homework PDF:
  - `F:\Ritual Academy\Ritual_AI_Bounty_Judge_Homework.pdf`
- Workshop repo:
  - `F:\Ritual Academy\ritual-chain-workshop`

If the code and the assignment ever conflict, the assignment should win.
