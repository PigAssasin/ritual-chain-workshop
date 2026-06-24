# Ritual AI Bounty Judge Homework Rules

## Muc tieu cua bai tap

Can hoan thien bai workshop thanh mot he thong bounty judge cong bang hon:

- Khong de nguoi choi nhin thay dap an cua nhau trong giai doan nop bai.
- Dung flow `commit-reveal` cho phan bat buoc.
- Chi cac bai `revealed` hop le moi duoc dua vao AI judging.
- AI chi danh gia theo lo batch, con con nguoi van la nguoi `finalizeWinner`.

## Yeu cau bat buoc phai nho

Phan required track phai implement flow nay:

1. Bounty owner tao bounty voi:
   - reward
   - submission deadline
   - reveal deadline
2. Trong submission phase, participant chi gui `commitment hash`.
3. Sau submission deadline, participant tu `reveal` bang `answer + salt`.
4. Contract verify:

```solidity
keccak256(abi.encodePacked(answer, salt, msg.sender, bountyId))
```

5. Chi bai reveal hop le moi duoc AI judge.
6. Sau reveal deadline, owner goi `judgeAll(...)`.
7. Sau khi judge xong, owner goi `finalizeWinner(...)`.
8. Chi 1 winner nhan reward.

Ghi chu:

- Required track la huong giai quyet bang smart contract, dung duoc tren bat ky EVM chain nao.
- Muc tieu toi thieu cua required track la giu hidden trong submission phase.
- Viec giu hidden cho den sau khi judging xong thuoc advanced-track thinking.

## Dieu de bai muon giai quyet

Workshop cu bi loi:

- User A nop dap an som.
- Dap an hien cong khai ngay.
- User B vao doc, copy y tuong, sua tot hon, roi nop.

Flow moi phai giai quyet dung van de nay.

## Cac ham bat buoc nen co

```solidity
submitCommitment(uint256 bountyId, bytes32 commitment)
revealAnswer(uint256 bountyId, string calldata answer, bytes32 salt)
judgeAll(uint256 bountyId, bytes calldata llmInput)
finalizeWinner(uint256 bountyId, uint256 winnerIndex)
```

## Luat nghiep vu quan trong

- Chi duoc submit commitment truoc `submissionDeadline`.
- Chi duoc reveal sau `submissionDeadline` va truoc `revealDeadline`.
- Moi participant chi duoc 1 commitment cho moi bounty.
- Reveal chi hop le khi hash khop commitment cu.
- Bai khong reveal thi khong duoc dem di judge.
- Owner chi duoc judge sau `revealDeadline`.
- Owner chi duoc finalize sau khi judging hoan tat.
- AI khong tu dong tra thuong. Owner van phai finalize.

## Cach hieu dung ve reveal

Required track khong tu dong mo dap an.

- Contract chi luu `commitment`, khong the tu suy nguoc ra answer.
- Participant phai tu goi `revealAnswer(...)`.
- Neu khong reveal, bai do xem nhu khong hop le de cham.

## Cong khai dap an khi nao

Can phan biet 2 track:

### Required track

- Dap an bi an trong submission phase.
- Dap an tro nen cong khai khi participant tu reveal trong reveal phase.
- Sau reveal deadline moi judge.

### Advanced track

- Co the thiet ke de plaintext answers tiep tuc duoc an cho den sau khi AI judging xong.
- Phan nay co the chi can viet design note, khong nhat thiet build full.

## Deliverables can co trong bai nop

Phai co it nhat:

- Updated Solidity contract.
- README giai thich bounty lifecycle moi.
- Test hoac test plan cho valid va invalid reveal cases.
- Architecture note so sanh:
  - commit-reveal
  - Ritual-native hidden submissions
- Reflection answer 5-8 cau:
  - "What should be public, what should stay hidden, and what should be decided by AI versus by a human in a bounty system?"

## Tieu chi cham diem

- Commit-reveal correctness: 30%
- Smart contract safety: 20%
- Ritual understanding: 20%
- Code clarity: 15%
- Testing / explanation: 15%

Muon diem on thi phai uu tien:

- dung flow deadline va eligibility
- an toan payout
- co giai thich ro vi sao AI duoc dung theo batch
- code de doc
- co test hoac test plan hop ly

## Advanced track can noi gi

Neu lam phan nang cao, phai giai thich ro:

- Plaintext answers ton tai o dau.
- Cai gi luu on-chain, cai gi luu off-chain.
- LLM nhan tat ca submissions theo batch the nao.
- Final reveal xay ra ra sao.
- Contract verify hoac commit bundle ket qua cuoi the nao.

Khong can nhat thiet implement full neu qua phuc tap, nhung note phai hop ly.

## Rang buoc quan trong tu de bai

- Khong goi 1 LLM call cho tung submission trong vong lap.
- Phai batch judge tat ca submission trong 1 request.
- Khong reveal answer trong submission phase.
- Khong de AI tu dong payout neu khong co giai thich ro cach parse va validate ket qua.
- Keep required track simple.

## Cong thuc commitment nen dung

```solidity
bytes32 commitment = keccak256(
    abi.encodePacked(answer, salt, msg.sender, bountyId)
);
```

Ly do them `msg.sender` va `bountyId`:

- tranh nguoi khac copy commitment
- tranh tai su dung commitment giua cac bounty

## Repo hien tai va cac file quan trong

Root repo:

- [README.md](F:\Ritual Academy\ritual-chain-workshop\README.md)
- [rule.md](F:\Ritual Academy\ritual-chain-workshop\rule.md)

Smart contract:

- [hardhat/contracts/AIJudge.sol](F:\Ritual Academy\ritual-chain-workshop\hardhat\contracts\AIJudge.sol)
- [hardhat/contracts/utils/PrecompileConsumer.sol](F:\Ritual Academy\ritual-chain-workshop\hardhat\contracts\utils\PrecompileConsumer.sol)
- [hardhat/ignition/modules/AIJudge.ts](F:\Ritual Academy\ritual-chain-workshop\hardhat\ignition\modules\AIJudge.ts)
- [hardhat/hardhat.config.ts](F:\Ritual Academy\ritual-chain-workshop\hardhat\hardhat.config.ts)
- [hardhat/package.json](F:\Ritual Academy\ritual-chain-workshop\hardhat\package.json)

Frontend hien tai dang public-answer oriented, co kha nang can sua:

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

## Tinh trang code hien tai truoc khi sua

Contract hien tai dang theo flow cu:

- `createBounty(title, rubric, deadline)`
- `submitAnswer(bountyId, answer)`
- `judgeAll(bountyId, llmInput)`
- `finalizeWinner(bountyId, winnerIndex)`
- `getSubmission(...)` hien dang tra ve plaintext answer

Nghia la contract hien tai chua dung commit-reveal.

## Huong sua hop ly

Khi bat dau implement, uu tien suy nghi theo thu tu nay:

1. Sua struct `Bounty` de co:
   - submission deadline
   - reveal deadline
   - commitment storage
   - revealed submissions storage
2. Thay `submitAnswer` bang `submitCommitment`.
3. Them `revealAnswer`.
4. Gioi han dung phase cho tung action.
5. Chi gom cac bai reveal hop le khi build input cho `judgeAll`.
6. Validate `winnerIndex` dua tren danh sach da duoc judge.
7. Cap nhat ABI + frontend neu muon demo giao dien.

## Cac test nen co

It nhat phai cover:

- submit commitment hop le truoc deadline
- submit commitment sau deadline bi revert
- reveal dung answer + salt thi pass
- reveal sai answer hoac sai salt thi revert
- reveal truoc submission deadline bi revert
- reveal sau reveal deadline bi revert
- bai khong reveal khong duoc tinh vao judge
- judge truoc reveal deadline bi revert
- finalize truoc khi judge xong bi revert
- chi 1 winner nhan thuong

## Noi dung de dien form submission

Khi nop form "Proof of Building - Step 1", can chuan bi:

- GitHub Fork URL:
  - link repo fork cua ban co chua code bai lam
- Deployed Contract Address:
  - dia chi contract sau khi deploy
- Deploy Transaction Hash:
  - tx hash cua lan deploy
- A step you struggled with:
  - mo ta ngan kho khan that su gap phai
  - vi du:
    - phase logic giua submit/reveal/judge
    - commitment hashing
    - chi judge cac bai da reveal
    - batch LLM request thay vi mot call moi bai

## Reflection can nho de tra loi

Reflection khong phai noi ve code thuan tuy, ma ve thiet ke he thong:

- Cai gi nen public
- Cai gi nen hidden
- Cai gi de AI quyet
- Cai gi con nguoi phai giu quyen quyet dinh

Huong an toan:

- rubric, deadlines, reward, winner nen public
- dap an nen hidden trong submission phase
- AI nen danh gia, ranking, tom tat
- human owner nen finalize payout

## Cach lam viec tu nay ve sau

Truoc moi thay doi lon, doc lai file nay va tu check:

1. Sua nay co vi pham commit-reveal flow khong?
2. Co lam lo plaintext answer qua som khong?
3. Co batch judging dung 1 request khong?
4. Co giu owner la nguoi finalize cuoi cung khong?
5. Co can cap nhat README, tests, architecture note, ABI, frontend khong?

## Nguon thong tin da co

- PDF bai tap:
  - `F:\Ritual Academy\Ritual_AI_Bounty_Judge_Homework.pdf`
- Repo workshop:
  - `F:\Ritual Academy\ritual-chain-workshop`

Neu co mau thuan giua code hien tai va de bai, uu tien de bai.
