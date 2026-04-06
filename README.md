# ETH 복권 게임

5명이 0.001 ETH씩 베팅하면 자동 추첨, 당첨자가 90%를 가져가는 온체인 복권 게임입니다.

```
참가자 5명 x 0.001 ETH = 총 0.005 ETH
  → 당첨자: 0.0045 ETH (90%)
  → 수수료: 0.0005 ETH (10%, 컨트랙트 보관)
```

- 네트워크: Ethereum Sepolia 테스트넷
- 컨트랙트: `0xcB3A21CDF1D2D25C196e096b517Cc0aD3F2018A0`
- 웹 UI: https://stevekim0417.github.io/eth-lottery/

---

## 시작하기

### 1. MetaMask 설치

Chrome 웹스토어에서 MetaMask 확장 프로그램을 설치합니다.

### 2. Sepolia 테스트넷 선택

MetaMask 상단 네트워크 드롭다운에서 Sepolia를 선택합니다.
테스트 네트워크가 보이지 않으면 "Show test networks"를 활성화하세요.

### 3. 테스트 ETH 받기

아래 Faucet 사이트에서 Sepolia ETH를 무료로 받을 수 있습니다.

| Faucet | 필요 계정 |
|--------|----------|
| Google Cloud Faucet | Google |
| Alchemy Sepolia Faucet | Alchemy |
| Infura Sepolia Faucet | Infura |

MetaMask에서 지갑 주소를 복사해서 Faucet에 붙여넣으면 1~2분 내에 테스트 ETH가 도착합니다.

### 4. 게임 접속

https://stevekim0417.github.io/eth-lottery/ 에 접속하여 "지갑 연결"을 클릭하면 바로 참가할 수 있습니다.

---

## 게임 규칙

```
1. "베팅하기 0.001 ETH" 버튼을 클릭하여 참가
2. 같은 지갑으로 같은 라운드에 중복 참가 불가
3. 5명이 모이면 자동으로 추첨 실행
4. 당첨자에게 0.0045 ETH 즉시 송금
5. 다음 라운드가 자동으로 시작됨
```

---

## 기술 스택

| 구분 | 기술 |
|------|------|
| 블록체인 | Ethereum Sepolia 테스트넷 |
| 스마트컨트랙트 | Solidity ^0.8.0 |
| 프론트엔드 | HTML + CSS + JavaScript (단일 파일) |
| Web3 연결 | ethers.js v6 (CDN) |
| 지갑 | MetaMask |
| 호스팅 | GitHub Pages |

---

## 스마트컨트랙트 상세 설명

> Solidity를 처음 접하는 분들을 위한 `EthLottery.sol` 코드 해설입니다.
> 위에서 아래로 순서대로 읽으면 전체 흐름을 이해할 수 있습니다.

### 파일 헤더

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
```

| 코드 | 설명 |
|------|------|
| `SPDX-License-Identifier` | 오픈소스 라이선스 선언. MIT는 자유롭게 사용 가능한 라이선스 |
| `pragma solidity ^0.8.0` | 사용할 Solidity 컴파일러 버전. `^0.8.0`은 0.8.0 이상 0.9.0 미만을 의미 |

### 상수 (constant)

```solidity
uint256 public constant ENTRY_FEE      = 0.001 ether;
uint256 public constant MAX_PLAYERS    = 5;
uint256 public constant WINNER_PERCENT = 90;
```

`constant`로 선언하면 블록체인 저장소(storage)를 사용하지 않아 가스비가 절감됩니다.
컴파일 시점에 바이트코드에 값이 직접 삽입되기 때문입니다.

- `uint256`: 부호 없는 256비트 정수 (Solidity의 기본 숫자 타입)
- `public`: 자동으로 getter 함수가 생성되어 외부에서 조회 가능
- `ether`: Solidity 내장 단위. `0.001 ether`는 `1000000000000000 wei`와 동일

### 상태 변수 (State Variables)

```solidity
address public owner;                          // 컨트랙트 배포자(관리자) 주소
uint256 public roundNumber;                    // 현재 라운드 번호
uint256 public accumulatedFees;                // 누적 수수료

address payable[] private players;             // 현재 라운드 참가자 배열
mapping(address => bool) private playerEntered; // 참가 여부 매핑
```

상태 변수는 블록체인에 **영구 저장**됩니다. 함수가 끝나도 값이 사라지지 않습니다.

| 타입 | 설명 |
|------|------|
| `address` | 20바이트 이더리움 주소 (지갑 또는 컨트랙트) |
| `address payable` | ETH를 받을 수 있는 주소. 일반 `address`에는 ETH 전송 불가 |
| `address payable[]` | payable 주소의 동적 배열 |
| `mapping(A => B)` | A를 키, B를 값으로 갖는 해시맵. `playerEntered[0x1234]`처럼 접근 |
| `public` | 외부에서 읽기 가능 (자동 getter 생성) |
| `private` | 컨트랙트 내부에서만 접근 가능 (외부 호출 불가) |

> **주의**: `private`은 "코드에서 접근 불가"일 뿐, 블록체인에 데이터는 공개됩니다.
> 블록 탐색기에서 storage slot을 직접 읽으면 값을 볼 수 있습니다.

### 이벤트 (Event)

```solidity
event PlayerEntered(
    address indexed player,
    uint256 indexed roundNumber,
    uint256 playerCount
);
```

이벤트는 블록체인의 **로그(Log)**에 기록됩니다. 상태 변수보다 가스비가 훨씬 저렴합니다.

- 컨트랙트 안에서는 `emit PlayerEntered(...)` 로 발생시킴
- 웹에서는 `contract.on("PlayerEntered", callback)` 으로 실시간 감지
- `indexed` 키워드가 붙은 파라미터는 필터링 검색 가능 (최대 3개)

```
이벤트 흐름:

  컨트랙트                  블록체인 로그               웹 UI
  emit 실행  ────────▶  트랜잭션 로그에 기록  ────────▶  실시간 감지
                       (영구 저장, 저렴)              (contract.on)
```

### 제어자 (Modifier)

```solidity
modifier onlyOwner() {
    require(msg.sender == owner, "Only owner");
    _;
}
```

modifier는 함수 실행 **전에 조건을 검사**하는 재사용 가능한 코드입니다.

- `msg.sender`: 이 함수를 호출한 지갑 주소 (Solidity 전역 변수)
- `require(조건, "에러메시지")`: 조건이 false이면 트랜잭션을 revert(취소)
- `_;`: "여기에 원래 함수 본문을 실행하라"는 뜻

```solidity
// 아래처럼 함수에 붙여서 사용
function withdrawFees() external onlyOwner { ... }

// 위 코드는 실질적으로 이렇게 동작:
function withdrawFees() external {
    require(msg.sender == owner, "Only owner");  // modifier 부분
    ...                                           // 원래 함수 본문 (_; 위치)
}
```

### 생성자 (Constructor)

```solidity
constructor() {
    owner = msg.sender;
    roundNumber = 1;
}
```

`constructor()`는 컨트랙트가 블록체인에 **배포될 때 딱 한 번**만 실행됩니다.
배포 이후에는 다시 호출할 수 없습니다.

- `msg.sender`가 배포 트랜잭션을 보낸 주소이므로, 배포자가 자동으로 `owner`가 됩니다

### 핵심 함수: enter()

```solidity
function enter() external payable {
    require(msg.value == ENTRY_FEE, "Must send exactly 0.001 ETH");
    require(!playerEntered[msg.sender], "Already entered this round");
    require(players.length < MAX_PLAYERS, "Round is full");

    players.push(payable(msg.sender));
    playerEntered[msg.sender] = true;

    emit PlayerEntered(msg.sender, roundNumber, players.length);

    if (players.length == MAX_PLAYERS) {
        _pickWinner();
    }
}
```

이 함수가 게임의 핵심입니다. 한 줄씩 해설합니다.

**함수 선언부:**

| 키워드 | 의미 |
|--------|------|
| `external` | 외부에서만 호출 가능 (컨트랙트 내부 호출 불가). `public`보다 가스비 절약 |
| `payable` | 이 함수를 호출할 때 ETH를 함께 보낼 수 있음. 없으면 ETH 수신 불가 |

**3단계 검증 (require):**

```
require #1: msg.value == ENTRY_FEE
  → 보낸 ETH가 정확히 0.001인지 확인
  → msg.value는 트랜잭션에 포함된 ETH 금액 (wei 단위)

require #2: !playerEntered[msg.sender]
  → 이 지갑이 현재 라운드에 이미 참가했는지 확인
  → mapping에서 조회: true면 참가한 상태 → !true = false → revert

require #3: players.length < MAX_PLAYERS
  → 참가자가 5명 미만인지 확인
  → 5명 이상이면 참가 거부
```

3개의 `require` 중 하나라도 실패하면 트랜잭션 전체가 취소(revert)되고,
보낸 ETH도 돌아오며, 가스비만 소비됩니다.

**상태 변경 + 이벤트:**

```
players.push(...)          → 참가자 배열에 추가
playerEntered[...] = true  → 중복 참가 방지용 플래그 설정
emit PlayerEntered(...)    → 이벤트 발생 (웹 UI가 감지)
```

**자동 추첨 트리거:**

```
if (players.length == MAX_PLAYERS)  → 5명이 되면
    _pickWinner();                  → 추첨 함수 자동 호출
```

5번째 참가자의 트랜잭션 안에서 `enter()` + `_pickWinner()`가 모두 실행됩니다.

### 핵심 함수: _pickWinner()

```solidity
function _pickWinner() private { ... }
```

`private`: 컨트랙트 내부에서만 호출 가능. 외부에서 직접 호출 불가능합니다.
함수명 앞의 `_`는 내부 함수라는 관례적 표시입니다.

**난수 생성:**

```solidity
uint256 randomIndex = uint256(
    keccak256(
        abi.encodePacked(
            block.prevrandao,
            block.timestamp,
            players,
            roundNumber
        )
    )
) % MAX_PLAYERS;
```

안쪽부터 바깥으로 읽으면 이해하기 쉽습니다:

```
① abi.encodePacked(...)    → 여러 값을 하나의 바이트 배열로 결합
② keccak256(...)           → 256비트 해시값 생성 (SHA-3 계열)
③ uint256(...)             → 해시를 숫자로 변환
④ % MAX_PLAYERS            → 5로 나눈 나머지 (결과: 0~4)
```

입력값들:

| 입력 | 역할 |
|------|------|
| `block.prevrandao` | 이전 블록의 난수값 (PoS 밸리데이터가 제공) |
| `block.timestamp` | 현재 블록의 타임스탬프 |
| `players` | 참가자 주소 배열 (참가 순서에 따라 변화) |
| `roundNumber` | 라운드 번호 (같은 참가자 조합이라도 라운드마다 다른 결과) |

> **교육 포인트**: 이 방식은 밸리데이터가 `prevrandao` 값을 미리 알 수 있어
> 이론적으로 조작 가능합니다. 실제 서비스에서는 Chainlink VRF(검증 가능한 난수)를 사용합니다.

**상금 계산:**

```solidity
uint256 totalPot = ENTRY_FEE * MAX_PLAYERS;          // 0.005 ETH
uint256 prize    = (totalPot * WINNER_PERCENT) / 100; // 0.0045 ETH
uint256 fee      = totalPot - prize;                  // 0.0005 ETH
```

Solidity에는 소수점이 없으므로, `90 / 100`이 아니라 `* 90 / 100` 순서로 계산합니다.
`fee`를 `totalPot * 10 / 100` 대신 `totalPot - prize`로 구하면 반올림 오차로 인한 잔액 불일치를 방지할 수 있습니다.

**CEI 패턴 (Checks-Effects-Interactions):**

이 함수에서 가장 중요한 보안 패턴입니다.

```solidity
// ─── Effects (상태 변경) ───
accumulatedFees += fee;

for (uint256 i = 0; i < MAX_PLAYERS; i++) {
    playerEntered[players[i]] = false;      // 매핑 초기화
}
delete players;                              // 배열 초기화
roundNumber++;                               // 다음 라운드

emit WinnerSelected(winner, prize, completedRound);

// ─── Interactions (외부 호출) ───
(bool success, ) = winner.call{value: prize}("");
require(success, "Prize transfer failed");
```

```
실행 순서 (반드시 이 순서를 지켜야 함):

  ① Checks       → require로 조건 검증 (enter에서 이미 완료)
  ② Effects       → 상태 변수 변경 (mapping 초기화, 배열 삭제, 라운드 증가)
  ③ Interactions  → 외부 주소에 ETH 전송
```

왜 이 순서가 중요한가:

```
만약 Effects와 Interactions 순서가 반대라면:

  1. winner에게 ETH 전송 (Interactions 먼저)
  2. winner가 악의적 컨트랙트라면?
  3. ETH 수신 시 receive() 함수가 자동 실행됨
  4. receive() 안에서 다시 enter()를 호출!
  5. 아직 상태가 초기화되지 않았으므로 → 재진입 성공 → 자금 탈취

  CEI 패턴을 지키면:
  1. 먼저 상태 초기화 (playerEntered = false, delete players)
  2. 그 다음 ETH 전송
  3. 재진입하더라도 이미 상태가 리셋되어 있으므로 → 새 라운드로 진입할 뿐
```

**ETH 전송 방식:**

```solidity
(bool success, ) = winner.call{value: prize}("");
require(success, "Prize transfer failed");
```

| 전송 방식 | 가스 제한 | 권장 여부 |
|-----------|----------|----------|
| `transfer()` | 2300 고정 | 비권장 (EIP-1884 이후 가스 부족 가능) |
| `send()` | 2300 고정 | 비권장 |
| `call{value:}("")` | 무제한 | 권장 (CEI 패턴 필수) |

`call`의 반환값 `(bool success, bytes memory data)`에서 `success`만 사용하고
`data`는 `_`로 무시합니다.

### 조회 함수 (View Functions)

```solidity
function getPlayerCount() external view returns (uint256) {
    return players.length;
}
```

| 키워드 | 의미 |
|--------|------|
| `view` | 상태를 읽기만 하고 변경하지 않는 함수 |
| `returns (uint256)` | 반환 타입 선언 |

`view` 함수는 가스비가 들지 않습니다 (외부에서 호출 시).
블록체인에 트랜잭션을 보내지 않고, 노드에서 로컬로 실행하기 때문입니다.

### 관리자 함수: withdrawFees()

```solidity
function withdrawFees() external onlyOwner {
    uint256 amount = accumulatedFees;
    require(amount > 0, "No fees to withdraw");

    accumulatedFees = 0;
    emit FeesWithdrawn(owner, amount);

    (bool success, ) = payable(owner).call{value: amount}("");
    require(success, "Withdrawal failed");
}
```

관리자가 누적된 수수료(10%)만 출금할 수 있습니다.
`accumulatedFees`만 출금하므로 참가자의 베팅 금액에는 절대 접근할 수 없습니다.

```
컨트랙트 잔액 = 현재 라운드 참가비 + 누적 수수료
                ^^^^^^^^^^^^^^^^^^^^   ^^^^^^^^^^^
                  출금 불가 (보호)     이것만 출금 가능
```

---

## 스마트컨트랙트 함수 요약

### 쓰기 함수 (트랜잭션 필요, 가스비 발생)

| 함수 | 접근 | 설명 |
|------|------|------|
| `enter()` | 누구나 | 0.001 ETH와 함께 호출하여 참가. 5명 시 자동 추첨 |
| `withdrawFees()` | 관리자만 | 누적 수수료 출금 |

### 읽기 함수 (가스비 무료)

| 함수 | 반환 | 설명 |
|------|------|------|
| `getPlayerCount()` | uint256 | 현재 참가자 수 (0~5) |
| `getPlayers()` | address[] | 참가자 주소 목록 |
| `getJackpot()` | uint256 | 현재 잭팟 (참가자수 x 0.001 ETH) |
| `isPlayerEntered(addr)` | bool | 해당 주소의 참가 여부 |
| `getAccumulatedFees()` | uint256 | 누적 수수료 잔액 |
| `getRoundNumber()` | uint256 | 현재 라운드 번호 |
| `owner()` | address | 관리자 주소 |

### 이벤트

| 이벤트 | 발생 시점 | 웹 UI 반응 |
|--------|----------|-----------|
| `PlayerEntered` | 참가자 베팅 성공 | 슬롯 업데이트 + 토스트 알림 |
| `WinnerSelected` | 당첨자 선정 | 당첨 모달 팝업 |
| `FeesWithdrawn` | 수수료 출금 | 관리자 패널 갱신 |

---

## 웹 UI 코드 구조

단일 HTML 파일(`index.html`) 안에 CSS와 JavaScript가 모두 포함되어 있습니다.

### 전체 아키텍처

```
index.html
├── <style>    CSS (테마 변수 + 컴포넌트 스타일)
├── <body>     HTML (UI 레이아웃)
└── <script>   JavaScript (Web3 로직 + UI 제어)
```

### CSS: 변수 기반 테마

```css
:root {
    --bg:    #0d1117;     /* 배경색 */
    --gold:  #f0b90b;     /* 강조색 (잭팟, 당첨) */
    --green: #3fb950;     /* 성공 (참가 완료) */
    --red:   #f85149;     /* 에러/경고 */
    --blue:  #58a6ff;     /* 액션 (연결 버튼) */
}
```

색상을 CSS 변수로 선언하여 전체 파일에서 `var(--gold)` 형태로 재사용합니다.
테마를 바꾸려면 `:root`의 변수 값만 변경하면 됩니다.

### HTML: 섹션 기반 레이아웃

```
<div id="app">
├── <header>            헤더 (제목 + 지갑 연결 버튼)
├── #setupWarning       컨트랙트 미설정 경고
├── #noMetaMask         MetaMask 미설치 안내
├── #gameSection        게임 영역 (라운드, 슬롯, 베팅 버튼)
├── #historySection     당첨 히스토리
└── #adminSection       관리자 패널 (owner만 표시)

<div id="winnerModal">  당첨 모달 (오버레이)
<div id="toastContainer"> 토스트 알림 (우상단)
```

### JavaScript: 이벤트 드리븐 구조

```
(function() {               ← IIFE: 전역 스코프 오염 방지
│
├── 설정
│   ├── CONTRACT_ADDRESS     컨트랙트 주소
│   ├── ABI[]                컨트랙트 인터페이스
│   └── SEPOLIA_CHAIN_ID     네트워크 ID
│
├── 지갑 연결
│   ├── connectWallet()      MetaMask 연결
│   ├── ensureSepolia()      네트워크 자동 전환
│   └── handleAccountsChanged()  계정 변경 대응
│
├── 컨트랙트 상호작용
│   ├── loadState()          상태 조회 (6개 함수 병렬 호출)
│   ├── enterLottery()       베팅 트랜잭션
│   ├── withdrawFees()       수수료 출금
│   └── loadHistory()        이벤트 로그에서 히스토리 로드
│
├── 실시간 이벤트
│   └── setupEventListeners()
│       ├── PlayerEntered → 슬롯 갱신
│       ├── WinnerSelected → 당첨 모달
│       └── FeesWithdrawn → 관리자 패널 갱신
│
├── UI 렌더링
│   ├── renderSlots()        5개 참가자 슬롯
│   ├── updateBetButton()    버튼 상태 전환
│   ├── showWinnerModal()    당첨 모달
│   └── showToast()          토스트 알림
│
└── 에러 처리
    └── handleTxError()      revert 메시지 → 한글 변환
})();
```

### 데이터 흐름

```
사용자               MetaMask            ethers.js           블록체인
  │                    │                    │                   │
  │  "베팅하기" 클릭    │                    │                   │
  │───────────────────▶│                    │                   │
  │                    │  트랜잭션 승인 팝업  │                   │
  │                    │◀──────────────────│                   │
  │   확인 클릭         │                    │                   │
  │───────────────────▶│  서명된 트랜잭션     │                   │
  │                    │──────────────────▶│  enter() 호출      │
  │                    │                    │─────────────────▶│
  │                    │                    │                   │
  │                    │                    │   이벤트 발생       │
  │                    │                    │◀─────────────────│
  │                    │                    │                   │
  │  UI 자동 갱신       │                    │                   │
  │◀──────────────────│◀──────────────────│  contract.on()    │
```

---

## Solidity 핵심 개념 정리

이 프로젝트에서 다루는 Solidity 핵심 개념 8가지입니다.

| # | 개념 | 코드에서의 역할 |
|---|------|---------------|
| 1 | `payable` | `enter()` 함수가 ETH를 받을 수 있게 함 |
| 2 | `msg.value` | 사용자가 보낸 ETH 금액을 검증 |
| 3 | `msg.sender` | 호출자 주소로 중복 참가 방지 |
| 4 | `mapping` | `playerEntered[주소] = true/false`로 참가 여부 저장 |
| 5 | `call{value:}` | 당첨금을 당첨자에게 전송 |
| 6 | `event` + `emit` | 웹 UI에서 실시간으로 상태 변화 감지 |
| 7 | `modifier` | `onlyOwner`로 관리자 권한 제어 |
| 8 | 난수의 한계 | `prevrandao`는 조작 가능 → 프로덕션에서는 Chainlink VRF 필요 |

---

## 로컬 개발

```bash
# 서버 시작
./start.sh

# 서버 중지
./stop.sh
```

`http://localhost:8080/index.html`에서 접속 가능합니다.
`file://` 프로토콜로 열면 MetaMask가 동작하지 않으므로 반드시 HTTP 서버를 사용하세요.
