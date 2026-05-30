# SCRATCHIN' — Smart Contracts

On-chain scratch card game deployed on **Unichain Sepolia**. Randomness from block hashes, prizes in USDC, jackpot funded by Uniswap V4 swap fees, auto-reveal via Reactive Network.

---

## Contracts

| Contract | Chain | Purpose |
|---|---|---|
| `ScratchCard.sol` | Unichain Sepolia | ERC-721 cards — buy, reveal, refund, leaderboard |
| `PrizePool.sol` | Unichain Sepolia | Holds jackpot + reserve, pays winners in USDC |
| `Referral.sol` | Unichain Sepolia | On-chain referral tracking + USDC rewards |
| `ScratchHook.sol` | Unichain Sepolia | Uniswap V4 `afterSwap` hook — feeds prize pool |
| `ReactiveReveal.sol` | Reactive Lasna | RSC that auto-triggers card reveals cross-chain |

---

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed (`curl -L https://foundry.paradigm.xyz | bash && foundryup`)
- Testnet ETH on **Unichain Sepolia** — faucet: https://faucet.unichain.org
- Testnet ETH on **Reactive Lasna** — faucet: https://dev.reactive.network/docs/faucet
- USDC on Unichain Sepolia — bridge or faucet from the Unichain team
- A free [WalletConnect project ID](https://cloud.walletconnect.com) for the frontend

---

## Setup

```bash
# 1. Install Foundry library dependencies
cd contract
forge install

# 2. Copy env template and fill in your values
cp .env.example .env
```

Edit `.env` — the required fields are:

| Variable | Where to get it |
|---|---|
| `PRIVATE_KEY` | Your deployer wallet private key |
| `USDC_ADDRESS` | Search "USDC" on https://unichain-sepolia.blockscout.com/tokens |
| `UNICHAIN_SEPOLIA_RPC` | `https://sepolia.unichain.org` (already set in example) |
| `REACTIVE_LASNA_RPC` | `https://kopli-rpc.rkt.ink` (already set in example) |
| `ETHERSCAN_API_KEY` | Get free key at https://unichain-sepolia.blockscout.com/account/api-key |

---

## Run Tests

Always run tests before deploying:

```bash
forge test -vvv
```

All 34 tests should pass. To run a specific test or get a gas report:

```bash
# Single test
forge test --match-test test_buyCards -vvv

# Gas report
forge test --gas-report

# Coverage
forge coverage
```

---

## Deploy — Step 1: Unichain Sepolia (main contracts)

```bash
forge script script/Deploy.s.sol \
  --rpc-url unichain_sepolia \
  --broadcast \
  --verify \
  -vvvv
```

The script deploys `PrizePool`, `Referral`, and `ScratchCard`, wires them together, and optionally seeds the prize pool with USDC. It prints all addresses on completion.

**After this step**, copy the printed addresses into:
- `contract/.env` → `SCRATCH_CARD_ADDRESS`, `PRIZE_POOL_ADDRESS`, `REFERRAL_ADDRESS`
- `frontend/.env.local` → the `NEXT_PUBLIC_*` equivalents

---

## Deploy — Step 2: Reactive Lasna (auto-reveal RSC)

With `SCRATCH_CARD_ADDRESS` set in `.env`:

```bash
forge script script/DeployReactive.s.sol \
  --rpc-url reactive_lasna \
  --broadcast \
  -vvvv
```

Then fund the RSC with a small amount of REACT tokens for gas, and call `subscribe()`:

```bash
# Fund the RSC (replace with your deployed address)
cast send <REACTIVE_REVEAL_ADDRESS> \
  --value 0.1ether \
  --rpc-url https://kopli-rpc.rkt.ink \
  --private-key $PRIVATE_KEY

# Subscribe to CardPurchased events from ScratchCard
cast send <REACTIVE_REVEAL_ADDRESS> "subscribe()" \
  --rpc-url https://kopli-rpc.rkt.ink \
  --private-key $PRIVATE_KEY
```

---

## Wire ScratchCard to ReactiveRevealer

Back on Unichain Sepolia, tell ScratchCard which address is allowed to call `revealCard()` automatically:

```bash
cast send <SCRATCH_CARD_ADDRESS> \
  "setReactiveRevealer(address)" <REACTIVE_REVEAL_ADDRESS> \
  --rpc-url https://sepolia.unichain.org \
  --private-key $PRIVATE_KEY
```

---

## Post-Deployment Checklist

- [ ] `forge test` — all 34 tests pass
- [ ] `PrizePool.setScratchCard()` — wired (deploy script does this)
- [ ] `Referral.setScratchCard()` — wired (deploy script does this)
- [ ] `PrizePool.seed()` — initial USDC seeded (deploy script does this if `SEED_AMOUNT > 0`)
- [ ] `ScratchCard.setReactiveRevealer(<address>)` — set after Reactive deploy
- [ ] `ReactiveReveal` funded with ETH/REACT for gas
- [ ] `ReactiveReveal.subscribe()` called
- [ ] Contracts verified on https://unichain-sepolia.blockscout.com
- [ ] Frontend `.env.local` updated with all 4 addresses

---

## Contract Architecture

```
Player
  │
  ▼  buyCards(qty, referrer)
ScratchCard ──5%──► Referral.sol  (USDC claimable by referrer)
     │
     └──95%──► PrizePool.sol
                  ├── 90% → jackpot
                  └── 10% → reserve (small wins + refunds)
                       ▲
               ScratchHook.sol
                (afterSwap fee slice from V4 pool)

Reactive Network (Lasna)
  └── watches CardPurchased event on Unichain
         └── ReactiveReveal.react()
                  └── emits Callback
                           └── ScratchCard.revealCard(tokenId)
```

---

## Key Parameters

| Parameter | Value | Solidity constant |
|---|---|---|
| Card price | 0.50 USDC | `CARD_PRICE_DEFAULT = 500_000` |
| Small win payout | 0.25 USDC | `smallWinAmount = 250_000` |
| Jackpot trigger | 3-of-3 symbol match | — |
| Referral cut | 5% per purchase | `REFERRAL_BPS = 500` |
| Reveal delay | 3 blocks (~6s) | `revealDelay = 3` |
| Card expiry | 250 blocks (~8 min) | `EXPIRY_BLOCKS = 250` |
| Reserve split | 10% of pool deposits | `RESERVE_BPS = 1000` |
| Hook fee diversion | 10% of USDC swap fees | `feeDiversionBps = 1000` |
| Hustler threshold | 10 referrals | `HUSTLER_THRESHOLD = 10` |

---

## ScratchHook Deployment Note

The `ScratchHook` address **must have bit `0x0080` set** in its least-significant bytes to satisfy Uniswap V4's hook address validation (`AFTER_SWAP_FLAG`). This requires CREATE2 mining.

For testnet purposes you can skip the hook and seed the prize pool manually:

```bash
# Approve USDC then seed 50 USDC into the prize pool
cast send <PRIZE_POOL_ADDRESS> "seed(uint256)" 50000000 \
  --rpc-url https://sepolia.unichain.org \
  --private-key $PRIVATE_KEY
```

---

## Security Notes

- All USDC flows use `SafeERC20` — no raw `.transfer()` calls
- `ReentrancyGuard` on all external state-changing functions
- Randomness is Ethereum block hash — adequate for testnet; upgrade to a VRF oracle before high-value mainnet
- `blockhash()` only available for the last 256 blocks — cards expire at 250 blocks with a full refund path
- `tokensByOwner` is append-only and does not track NFT transfers — always use `ownerOf()` for current ownership
