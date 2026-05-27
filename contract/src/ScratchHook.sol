// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "lib/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "lib/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "lib/v4-core/src/types/BeforeSwapDelta.sol";
import {Currency, CurrencyLibrary} from "lib/v4-core/src/types/Currency.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

interface IPrizePool {
    function recordFeeDeposit(uint256 amount) external;
    function usdc() external view returns (IERC20);
}

/// @notice Uniswap V4 afterSwap hook that diverts a fraction of USDC swap fees
/// into the SCRATCHIN' prize pool.
///
/// How it works:
///   - afterSwap fires after every swap on the registered pool.
///   - We look at the swap delta to determine how much USDC the swapper paid in.
///   - We track a per-pool accumulated USDC fee amount.
///   - Anyone can call flushFeesToPool() to:
///       1. Pull the accumulated USDC from the PoolManager via take().
///       2. Transfer it to PrizePool.
///       3. Notify PrizePool via recordFeeDeposit().
///
/// Deployment note:
///   The hook address must be mined so its least-significant bits match the
///   Hooks.AFTER_SWAP_FLAG (see Hooks.sol). Use a CREATE2 deployer / HookMiner.
///
/// @dev Deploy address must have bit 0x0080 set (afterSwap = bit 7).
contract ScratchHook is IHooks, Ownable {
    using SafeERC20 for IERC20;
    using CurrencyLibrary for Currency;

    IPoolManager public immutable poolManager;
    IPrizePool   public prizePool;

    // USDC token address — must match the currency in the registered pool
    address public immutable usdcAddress;

    // How much of each swap's fee goes to the prize pool (default 10%)
    uint256 public feeDiversionBps = 1000;

    // Accumulated USDC fees waiting to be flushed to PrizePool
    uint256 public accumulatedFees;

    event FeesAccumulated(uint256 amount, uint256 newTotal);
    event FeesFlushed(uint256 amount);

    error OnlyPoolManager();

    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert OnlyPoolManager();
        _;
    }

    constructor(
        IPoolManager _poolManager,
        address      _prizePool,
        address      _usdc,
        address      _owner
    ) Ownable(_owner) {
        poolManager = _poolManager;
        prizePool   = IPrizePool(_prizePool);
        usdcAddress = _usdc;
    }

    // ─── IHooks — only afterSwap is active ───────────────────────────────────

    function beforeInitialize(address, PoolKey calldata, uint160)
        external pure returns (bytes4)
    { return IHooks.beforeInitialize.selector; }

    function afterInitialize(address, PoolKey calldata, uint160, int24)
        external pure returns (bytes4)
    { return IHooks.afterInitialize.selector; }

    function beforeAddLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
        external pure returns (bytes4)
    { return IHooks.beforeAddLiquidity.selector; }

    function afterAddLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, BalanceDelta, BalanceDelta, bytes calldata)
        external pure returns (bytes4, BalanceDelta)
    { return (IHooks.afterAddLiquidity.selector, BalanceDelta.wrap(0)); }

    function beforeRemoveLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
        external pure returns (bytes4)
    { return IHooks.beforeRemoveLiquidity.selector; }

    function afterRemoveLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, BalanceDelta, BalanceDelta, bytes calldata)
        external pure returns (bytes4, BalanceDelta)
    { return (IHooks.afterRemoveLiquidity.selector, BalanceDelta.wrap(0)); }

    function beforeSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        external pure returns (bytes4, BeforeSwapDelta, uint24)
    { return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0); }

    /// @notice afterSwap: accumulate a portion of USDC input as fees for the prize pool.
    function afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata
    ) external onlyPoolManager returns (bytes4, int128) {
        // Determine which currency is USDC in this pool
        address c0 = Currency.unwrap(key.currency0);
        address c1 = Currency.unwrap(key.currency1);

        uint256 usdcIn = 0;

        if (c0 == usdcAddress) {
            // currency0 is USDC; positive amount0 means USDC flowed into pool
            int128 a0 = delta.amount0();
            if (a0 > 0) usdcIn = uint256(uint128(a0));
        } else if (c1 == usdcAddress) {
            int128 a1 = delta.amount1();
            if (a1 > 0) usdcIn = uint256(uint128(a1));
        }

        if (usdcIn > 0) {
            uint256 cut = (usdcIn * feeDiversionBps) / 10000;
            if (cut > 0) {
                accumulatedFees += cut;
                emit FeesAccumulated(cut, accumulatedFees);
            }
        }

        return (IHooks.afterSwap.selector, 0);
    }

    function beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        external pure returns (bytes4)
    { return IHooks.beforeDonate.selector; }

    function afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        external pure returns (bytes4)
    { return IHooks.afterDonate.selector; }

    // ─── Flush ────────────────────────────────────────────────────────────────

    /// @notice Pull accumulated USDC fees from PoolManager and forward to PrizePool.
    /// Anyone can call this — permissionless.
    function flushFeesToPool(PoolKey calldata key) external {
        uint256 amount = accumulatedFees;
        require(amount > 0, "No fees accumulated");
        accumulatedFees = 0;

        // Determine the USDC currency in this pool
        Currency usdcCurrency;
        address c0 = Currency.unwrap(key.currency0);
        if (c0 == usdcAddress) {
            usdcCurrency = key.currency0;
        } else {
            usdcCurrency = key.currency1;
        }

        // Take USDC from PoolManager to this contract
        poolManager.take(usdcCurrency, address(this), amount);

        // Forward to PrizePool
        IERC20(usdcAddress).safeTransfer(address(prizePool), amount);
        prizePool.recordFeeDeposit(amount);

        emit FeesFlushed(amount);
    }

    // ─── Admin ────────────────────────────────────────────────────────────────

    function setFeeDiversionBps(uint256 _bps) external onlyOwner {
        require(_bps <= 5000, "Max 50%");
        feeDiversionBps = _bps;
    }

    function setPrizePool(address _prizePool) external onlyOwner {
        prizePool = IPrizePool(_prizePool);
    }
}
