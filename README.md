# Privacy-Preserving AI Bounty Judge

This repo takes the Ritual workshop bounty judge and fixes the main fairness problem from the original version. Instead of posting answers in public right away, participants now commit first and reveal later.

## What changed from the workshop baseline

The workshop contract used `submitAnswer(bountyId, answer)`, so every answer became public as soon as it was submitted. That meant later participants could read earlier entries, borrow ideas, and submit a better version before the deadline.

This homework version switches the bounty to a two-phase flow:

1. During the submission phase, participants submit only a `commitment` hash.
2. During the reveal phase, they reveal their plaintext answer and salt.
3. The contract checks the reveal against the original commitment.
4. Only valid revealed answers are eligible for AI judging.
5. After the reveal deadline, the bounty owner calls `judgeAll(...)` with one batch judging artifact.
6. The owner still chooses the final winner with `finalizeWinner(...)`.

## Contract lifecycle

### 1. Create bounty

The owner creates a bounty with:

- a title
- a rubric
- a reward
- a `submissionDeadline`
- a `revealDeadline`

The reward stays in the contract until the winner is finalized.

### 2. Submit commitment

Each participant computes:

```solidity
keccak256(abi.encodePacked(answer, salt, msg.sender, bountyId))
```

and sends only that hash with:

```solidity
submitCommitment(uint256 bountyId, bytes32 commitment)
```

At this point, the real answer is still hidden.

### 3. Reveal answer

After the submission deadline and before the reveal deadline, the participant reveals:

```solidity
revealAnswer(uint256 bountyId, string calldata answer, bytes32 salt)
```

The contract recomputes the hash and compares it to the stored commitment. If they match, the answer becomes a valid revealed submission for that bounty.

### 4. Judge all revealed answers

After the reveal deadline, the bounty owner calls:

```solidity
judgeAll(uint256 bountyId, bytes calldata llmInput)
```

In the required track, `llmInput` is treated as a batch judging artifact built from all revealed submissions together. On Ritual, that artifact can come from one Ritual AI judging run. On another EVM chain, it can be an encoded prompt/result pair or a reference to the batch judging record. The contract stores that artifact and marks the bounty as judged without depending on a Ritual-only precompile.

### 5. Finalize winner

After judging is complete, the bounty owner calls:

```solidity
finalizeWinner(uint256 bountyId, uint256 winnerIndex)
```

The reward is paid to exactly one revealed submission. The owner still makes the final payout decision.

## Files that matter for the homework

- `hardhat/contracts/AIJudge.sol`
- `hardhat/test/AIJudge.t.sol`
- `ARCHITECTURE.md`
- `rule.md`
- `plan.md`

## Tests

The Solidity tests cover the reveal flow and the main edge cases:

- valid commitment submission
- submission after the deadline
- one commitment per participant
- valid reveal
- invalid reveal
- reveal before and after the allowed window
- unrevealed submissions excluded from judging
- non-owner judging and finalization rejected
- judging with no revealed submissions rejected
- judging before the reveal deadline
- empty judging artifact rejected
- finalization before judging
- invalid winner index rejected
- successful payout to the chosen revealed winner

## How to run

From `hardhat/`:

```bash
pnpm install
pnpm hardhat build
pnpm hardhat test solidity
```

If your local Hardhat compiler cache is locked, or if you want to point Hardhat at a local `0.8.24` binary, you can set:

```bash
HARDHAT_SOLC_PATH=<path-to-solc-0.8.24-binary>
```

before running the commands above.

## How to deploy

From `hardhat/`, set a funded deployer key:

```bash
DEPLOYER_PRIVATE_KEY=0x...
```

Then deploy with your target EVM network. Example for Ritual:

```bash
pnpm hardhat ignition deploy --network ritual ignition/modules/AIJudge.ts
```

After deployment, record:

- the deployed contract address
- the deployment transaction hash

You will need those two values for the submission form.

## Notes

- This implementation stays close to the assignment and does not include the full advanced encrypted-submission flow.
- The required-track contract is EVM-generic and does not rely on Ritual-only precompiles.
- The advanced Ritual-native path is described separately in `ARCHITECTURE.md`.
- The main deliverables here are the contract, tests, and design notes. The workshop frontend can be updated later if needed.
