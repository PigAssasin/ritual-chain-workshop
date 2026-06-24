# Architecture Note

## Commit-reveal required track

The required track uses a straightforward commit-reveal pattern that works on any EVM chain:

1. A participant computes a commitment from:
   - `answer`
   - `salt`
   - `msg.sender`
   - `bountyId`
2. The participant submits only the commitment during the submission phase.
3. After the submission deadline, the participant reveals `answer + salt`.
4. The contract verifies the reveal and stores only valid revealed answers as judgeable submissions.
5. After the reveal deadline, the owner submits one batch judging artifact through `judgeAll(...)`.
6. The owner finalizes exactly one winner.

This fixes the fairness problem from the workshop version because answers stay hidden while submissions are still open. It does not keep answers hidden until judging is over. That stronger privacy model belongs to the advanced track.

## Why this is enough for the required track

The required track only asks for two things: answers should stay hidden during submission, and only valid revealed answers should be eligible for judging. A standard commit-reveal contract covers both. To stay close to the wording of the assignment, the required-track contract avoids Ritual-only precompiles and treats `judgeAll(...)` as the point where one batch judging artifact is recorded on-chain.

## What `judgeAll(...)` means in the required track

In this implementation, `judgeAll(uint256 bountyId, bytes calldata llmInput)` does not run inference on-chain. Instead:

- the owner or app gathers all revealed answers
- one Ritual AI batch judging run is prepared from those answers together when using the Ritual workflow
- the resulting batch artifact is passed into `judgeAll(...)`
- the contract stores that artifact and marks the bounty as judged

That keeps the contract portable across EVM chains while still following the rule that submissions are judged in one batch instead of one at a time.

## Ritual-native hidden submissions comparison

The advanced track goes further than commit-reveal:

- participants would encrypt their answers for a Ritual TEE executor
- the contract would store ciphertext or an off-chain ciphertext reference
- plaintext answers would stay hidden from the public chain before judging
- the TEE would decrypt all submissions privately during `judgeAll`
- the LLM would receive the submissions together in one batch
- after judging, the system would publish a revealed bundle and store a hash or reference on-chain

## Where plaintext exists in the advanced design

In a Ritual-native encrypted-submission design, plaintext answers should exist only in these places:

- on the participant side before encryption
- inside the TEE executor during private decryption and judging
- in the final revealed bundle after judging, if the system chooses to publish all answers

Plaintext answers should not appear on-chain before judging.

## What is on-chain vs off-chain in the advanced design

On-chain:

- bounty metadata
- reward and deadlines
- encrypted submission references or ciphertext hashes
- judging result metadata
- final revealed bundle hash and reference

Off-chain:

- encrypted submission payloads, if large
- the final revealed answers bundle
- optional storage references such as IPFS or another content-addressed store

## How batch judging works

Both the required track and the advanced design should keep one important Ritual rule: judge all submissions together in one AI request, not one call per answer. In the required track, the owner or frontend builds the batch judging artifact from the revealed submissions and passes it into `judgeAll(...)`. In the advanced design, the TEE would privately assemble the decrypted submissions into one batch prompt before sending them to the LLM.

## Reflection

The bounty title, rubric, reward, deadlines, and final winner should be public because they define the rules and the payout. Individual answers should stay hidden during the submission phase so participants cannot copy each other before the contest closes. AI should help with ranking, scoring, and explaining which submission matches the rubric best, because that is the repetitive comparison work. A human should still finalize the winner and payout, because AI output can be wrong or poorly reasoned. In the advanced version, encrypted inputs plus a revealed bundle hash are a reasonable balance between privacy and auditability. In every version, the rules should be public, the work should stay private until the right phase, and the final payout decision should remain accountable to a human.
