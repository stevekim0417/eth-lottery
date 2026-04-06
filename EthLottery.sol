// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ETH Lottery - 5인 베팅 복권 게임
/// @notice 5명이 0.001 ETH씩 베팅, 당첨자 90% 수령, 10% 컨트랙트 수수료
/// @dev 난수는 prevrandao 기반 — 프로덕션에서는 Chainlink VRF 사용 권장
contract EthLottery {

    // ──────────────────────────────────────
    // 상수
    // ──────────────────────────────────────
    uint256 public constant ENTRY_FEE   = 0.001 ether;
    uint256 public constant MAX_PLAYERS = 5;
    uint256 public constant WINNER_PERCENT = 90;

    // ──────────────────────────────────────
    // 상태 변수
    // ──────────────────────────────────────
    address public owner;
    uint256 public roundNumber;
    uint256 public accumulatedFees;

    address payable[] private players;
    mapping(address => bool) private playerEntered;

    // ──────────────────────────────────────
    // 이벤트
    // ──────────────────────────────────────
    /// @notice 참가자가 베팅에 성공했을 때 발생
    event PlayerEntered(
        address indexed player,
        uint256 indexed roundNumber,
        uint256 playerCount
    );

    /// @notice 당첨자가 선정되었을 때 발생
    event WinnerSelected(
        address indexed winner,
        uint256 prize,
        uint256 indexed roundNumber
    );

    /// @notice 관리자가 수수료를 출금했을 때 발생
    event FeesWithdrawn(
        address indexed to,
        uint256 amount
    );

    // ──────────────────────────────────────
    // 제어자 (modifier)
    // ──────────────────────────────────────
    /// @dev 관리자(배포자)만 호출 가능
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // ──────────────────────────────────────
    // 생성자
    // ──────────────────────────────────────
    constructor() {
        owner = msg.sender;
        roundNumber = 1;
    }

    // ──────────────────────────────────────
    // 핵심 함수
    // ──────────────────────────────────────

    /// @notice 복권 참가 (0.001 ETH 필요)
    /// @dev 5번째 참가자 트랜잭션에서 자동 추첨 실행
    function enter() external payable {
        require(msg.value == ENTRY_FEE, "Must send exactly 0.001 ETH");
        require(!playerEntered[msg.sender], "Already entered this round");
        require(players.length < MAX_PLAYERS, "Round is full");

        players.push(payable(msg.sender));
        playerEntered[msg.sender] = true;

        emit PlayerEntered(msg.sender, roundNumber, players.length);

        // 5명 모이면 자동 추첨
        if (players.length == MAX_PLAYERS) {
            _pickWinner();
        }
    }

    /// @dev 당첨자 선정 및 상금 송금
    ///      ⚠️ prevrandao는 밸리데이터가 이론상 조작 가능
    ///      프로덕션에서는 반드시 Chainlink VRF 등 외부 오라클 사용
    function _pickWinner() private {
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

        address payable winner = players[randomIndex];

        uint256 totalPot = ENTRY_FEE * MAX_PLAYERS;   // 0.005 ETH
        uint256 prize    = (totalPot * WINNER_PERCENT) / 100; // 0.0045 ETH
        uint256 fee      = totalPot - prize;            // 0.0005 ETH

        accumulatedFees += fee;

        // ── Checks-Effects-Interactions 패턴 ──
        // 상태 초기화를 외부 호출(송금)보다 먼저 수행하여
        // 재진입(reentrancy) 공격을 원천 차단
        uint256 completedRound = roundNumber;

        for (uint256 i = 0; i < MAX_PLAYERS; i++) {
            playerEntered[players[i]] = false;
        }
        delete players;
        roundNumber++;

        emit WinnerSelected(winner, prize, completedRound);

        // 당첨금 송금 — 실패 시 전체 트랜잭션 revert
        (bool success, ) = winner.call{value: prize}("");
        require(success, "Prize transfer failed");
    }

    // ──────────────────────────────────────
    // 조회 함수 (view)
    // ──────────────────────────────────────

    /// @notice 현재 라운드 참가자 수
    function getPlayerCount() external view returns (uint256) {
        return players.length;
    }

    /// @notice 현재 라운드 참가자 목록
    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }

    /// @notice 현재 잭팟 금액 (참가자 수 * 0.001 ETH)
    function getJackpot() external view returns (uint256) {
        return players.length * ENTRY_FEE;
    }

    /// @notice 특정 주소의 현재 라운드 참가 여부
    function isPlayerEntered(address player) external view returns (bool) {
        return playerEntered[player];
    }

    /// @notice 컨트랙트 누적 수수료 조회
    function getAccumulatedFees() external view returns (uint256) {
        return accumulatedFees;
    }

    /// @notice 현재 라운드 번호 조회
    function getRoundNumber() external view returns (uint256) {
        return roundNumber;
    }

    // ──────────────────────────────────────
    // 관리자 함수
    // ──────────────────────────────────────

    /// @notice 누적 수수료 출금 (관리자 전용)
    /// @dev 참가자 자금(잭팟)은 절대 인출 불가 — accumulatedFees만 출금
    function withdrawFees() external onlyOwner {
        uint256 amount = accumulatedFees;
        require(amount > 0, "No fees to withdraw");

        // 상태 먼저 변경, 이벤트 발행 후 외부 호출 (CEI 패턴)
        accumulatedFees = 0;
        emit FeesWithdrawn(owner, amount);

        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Withdrawal failed");
    }
}
