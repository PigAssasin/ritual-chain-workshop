# Privacy-Preserving AI Bounty Judge

This repository updates the Ritual workshop bounty judge from a public-answer submission flow to a required homework-compliant `commit-reveal` flow.

## What changed from the workshop baseline

The original workshop contract accepted `submitAnswer(bountyId, answer)`, which made each answer public as soon as it was submitted. That let later participants read earlier answers and improve on them before the deadline.

This homework version replaces that weakness with a two-phase flow:

1. During the submission phase, participants submit only a `commitment` hash.
2. During the reveal phase, they reveal their plaintext answer and salt.
3. The contract verifies the reveal against the original commitment.
4. Only valid revealed answers are eligible for AI judging.
5. After the reveal deadline, the bounty owner calls `judgeAll(...)`.
6. The owner still chooses the final winner with `finalizeWinner(...)`.

## Contract lifecycle

### 1. Create bounty

The owner creates a bounty with:

- a title
- a rubric
- a reward
- a `submissionDeadline`
- a `revealDeadline`

The reward is locked in the contract at creation time.

### 2. Submit commitment

Each participant computes:

```solidity
keccak256(abi.encodePacked(answer, salt, msg.sender, bountyId))
```

and sends only that hash with:

```solidity
submitCommitment(uint256 bountyId, bytes32 commitment)
```

At this stage, the plaintext answer is still hidden.

### 3. Reveal answer

After the submission deadline and before the reveal deadline, the participant reveals:

```solidity
revealAnswer(uint256 bountyId, string calldata answer, bytes32 salt)
```

The contract recomputes the hash and checks that it matches the original commitment. If it matches, the answer becomes a valid revealed submission for that bounty.

### 4. Judge all revealed answers

After the reveal deadline, the bounty owner calls:

```solidity
judgeAll(uint256 bountyId, bytes calldata llmInput)
```

This preserves the Ritual workshop pattern of sending a single batch LLM request through the Ritual LLM precompile. The AI review is advisory only.

### 5. Finalize winner

After judging is complete, the bounty owner calls:

```solidity
finalizeWinner(uint256 bountyId, uint256 winnerIndex)
```

The reward is paid to exactly one revealed submission. The owner remains the human in the loop for the final payout decision.

## Files that matter for the homework

- `hardhat/contracts/AIJudge.sol`
- `hardhat/contracts/utils/PrecompileConsumer.sol`
- `hardhat/test/AIJudge.t.sol`
- `ARCHITECTURE.md`
- `rule.md`
- `plan.md`

## Tests

The Solidity test suite covers the required reveal-focused cases:

- valid commitment submission
- submission after the deadline
- one commitment per participant
- valid reveal
- invalid reveal
- reveal before and after the allowed window
- unrevealed submissions excluded from judging
- judging before the reveal deadline
- finalization before judging
- successful payout to the chosen revealed winner

## How to run

From `hardhat/`:

```bash
pnpm install
pnpm hardhat build
pnpm hardhat test solidity
```

If your local Hardhat compiler cache is locked or you want to force the local
0.8.24 compiler binary, you can optionally set:

```bash
HARDHAT_SOLC_PATH=<path-to-solc-0.8.24-binary>
```

before running the commands above.

## How to deploy

From `hardhat/`, set a funded Ritual deployer key:

```bash
DEPLOYER_PRIVATE_KEY=0x...
```

Then deploy with:

```bash
pnpm hardhat ignition deploy --network ritual ignition/modules/AIJudge.ts
```

After deployment, record:

- the deployed contract address
- the deployment transaction hash

Those two values are required for the submission form.

## Notes

- This implementation stays close to the assignment scope and does not add the full advanced encrypted-submission flow.
- The Ritual-specific judging flow is preserved as a single batch LLM request.
- The current deliverable focus is the contract, tests, and design notes. The workshop frontend can be updated later if needed to match the new ABI.
