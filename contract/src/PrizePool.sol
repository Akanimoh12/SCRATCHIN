// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Holds the SCRATCHIN' jackpot and small-win reserve in USDC.
/// - ScratchCard sends USDC here on every card purchase (90% jackpot, 10% reserve).
/// - ScratchHook sends USDC fee diversions here.
/// - ScratchCard calls paySmallWin / payJackpot on reveal.
contract PrizePool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdc;

    address public scratchCard;
    address public scratchHook;

    uint256 public jackpot;
    uint256 public reserve;

    // 10% of each card purchase goes to reserve for small wins
    uint256 public constant RESERVE_BPS = 1000;

    event Deposited(address indexed from, uint256 jackpotAmount, uint256 reserveAmount);
    event FeeDeposited(uint256 amount);
    event SmallWinPaid(address indexed winner, uint256 amount);
    event JackpotPaid(address indexed winner, uint256 amount);

    error Unauthorized();
    error InsufficientFunds();

    modifier onlyScratchCard() {
        if (msg.sender != scratchCard) revert Unauthorized();
        _;
    }

    modifier onlyScratchHook() {
        if (msg.sender != scratchHook) revert Unauthorized();
        _;
    }

    constructor(address _usdc, address _owner) Ownable(_owner) {
        usdc = IERC20(_usdc);
    }

    // ─── Admin ────────────────────────────────────────────────────────────────

    function setScratchCard(address _scratchCard) external onlyOwner {
        scratchCard = _scratchCard;
    }

    function setScratchHook(address _scratchHook) external onlyOwner {
        scratchHook = _scratchHook;
    }

    // ─── Deposits ─────────────────────────────────────────────────────────────

    /// @notice Called by ScratchCard after transferring USDC to this contract.
    /// Splits the amount into jackpot (90%) and reserve (10%).
    function recordDeposit(uint256 amount) external onlyScratchCard {
        uint256 toReserve = (amount * RESERVE_BPS) / 10000;
        uint256 toJackpot = amount - toReserve;
        reserve += toReserve;
        jackpot += toJackpot;
        emit Deposited(msg.sender, toJackpot, toReserve);
    }

    /// @notice Called by ScratchHook after transferring USDC fee diversion here.
    function recordFeeDeposit(uint256 amount) external onlyScratchHook {
        jackpot += amount;
        emit FeeDeposited(amount);
    }

    /// @notice Owner seeds the jackpot directly (must approve USDC first).
    function seed(uint256 amount) external onlyOwner {
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        jackpot += amount;
    }

    // ─── Payouts ──────────────────────────────────────────────────────────────

    /// @notice Pay a small win from reserve (2-of-3 match).
    function paySmallWin(address winner, uint256 amount) external nonReentrant onlyScratchCard {
        if (reserve < amount) revert InsufficientFunds();
        reserve -= amount;
        usdc.safeTransfer(winner, amount);
        emit SmallWinPaid(winner, amount);
    }

    /// @notice Pay the entire jackpot (3-of-3 match).
    function payJackpot(address winner) external nonReentrant onlyScratchCard returns (uint256 amount) {
        amount = jackpot;
        if (amount == 0) revert InsufficientFunds();
        jackpot = 0;
        usdc.safeTransfer(winner, amount);
        emit JackpotPaid(winner, amount);
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    function totalPool() external view returns (uint256) {
        return jackpot + reserve;
    }

    /// @notice Actual USDC balance held (sanity check — should equal jackpot + reserve).
    function usdcBalance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    /// @notice Emergency: owner can recover any accidentally sent tokens (not USDC used for pool).
    function recoverToken(address token, uint256 amount) external onlyOwner {
        require(token != address(usdc), "Cannot recover prize USDC");
        IERC20(token).safeTransfer(owner(), amount);
    }
}
