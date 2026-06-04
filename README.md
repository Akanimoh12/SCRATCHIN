<div align="center">

# SCRATCHIN'

**On-Chain Scratch Card Game — Powered by Uniswap V4 · Reactive Network · Unichain**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Unichain](https://img.shields.io/badge/Chain-Unichain%20Sepolia-7B3FE4)](https://unichain-sepolia.blockscout.com)
[![Reactive Network](https://img.shields.io/badge/Automation-Reactive%20Lasna-00C2FF)](https://reactive.network)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.26-363636)](https://soliditylang.org)
[![Tests](https://img.shields.io/badge/Tests-79%20passing-39FF14)](contract/test)

*Scratch. Win. Repeat. On-chain forever.*

</div>

---

## What is SCRATCHIN'?

SCRATCHIN' is a fully on-chain scratch card lottery game on **Unichain Sepolia**. Players buy scratch card NFTs with USDC; block-hash entropy captured at purchase reveals three symbols — match two for a small win, match three for the jackpot. Card reveals are triggered automatically by a **Reactive Network RSC** with no backend or manual interaction needed.

---

## Deployed Contracts

### Unichain Sepolia (Chain ID: 1301)

| Contract | Address | Explorer |
|---|---|---|
| ScratchCard (ERC-721) | `0xd051dD659844CFe4e2093a357368c57fe7d0a3c4` | [View ↗](https://unichain-sepolia.blockscout.com/address/0xd051dD659844CFe4e2093a357368c57fe7d0a3c4) |
| PrizePool | `0xd7F50EaAEf4CcC922816261C142E3e1581dB9f3c` | [View ↗](https://unichain-sepolia.blockscout.com/address/0xd7F50EaAEf4CcC922816261C142E3e1581dB9f3c) |
| Referral | `0xB830f8634d10a5B4F8FE16d70D531034AE4cA668` | [View ↗](https://unichain-sepolia.blockscout.com/address/0xB830f8634d10a5B4F8FE16d70D531034AE4cA668) |
| USDC (token) | `0x31d0220469e10c4E71834a79b1f276d740d3768F` | [View ↗](https://unichain-sepolia.blockscout.com/address/0x31d0220469e10c4E71834a79b1f276d740d3768F) |
| Reactive Callback Proxy | `0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4` | [View ↗](https://unichain-sepolia.blockscout.com/address/0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4) |

### Reactive Lasna Testnet (Chain ID: 5318007)

| Contract | Address | Explorer |
|---|---|---|
| ReactiveReveal RSC | `0x20E8307cFe2C5CF7E434b5Cb2C92494fa4BAF01C` | [View ↗](https://lasna.reactscan.net/address/0x20E8307cFe2C5CF7E434b5Cb2C92494fa4BAF01C) |

> **ScratchHook** (Uniswap V4 `afterSwap`) requires CREATE2 address mining for V4 hook flags. It is deployed separately and optional for testnet — the prize pool can be seeded manually via `PrizePool.seed()`.

---

## How It Works

```
Player → buyCards(qty, referrer) → ScratchCard.sol (ERC-721 mint)
                                         |
              ┌──────────────────────────┘
              │  100% of card price → PrizePool.reserve
              │  5% → Referral.sol (if referrer set)
              │
              ▼
         PrizePool.sol
         ├── reserve  → funds small wins (0.25 USDC) + refunds
         └── jackpot  → funded by V4 hook fees + owner seed()

Reactive Lasna (chain 5318007):
  ReactiveReveal.react(LogRecord) ← Reactive VM fires on CardPurchased event
         │
         └── emit Callback(1301, scratchCard, 200k gas, revealCardCallback(rvm_id, tokenId))
                   │
                   ▼
         ScratchCard.revealCardCallback(rvm_id, tokenId) [on Unichain, via Callback Proxy]
              │
              └── card.seedHash (captured at purchase) seeds 3 symbols
                   ├── 2-of-3 match → paySmallWin(0.25 USDC) from reserve
                   └── 3-of-3 match → payJackpot(full jackpot) to winner
```

---

## Prize Structure

| Outcome | Payout | Source |
|---|---|---|
| 3-of-3 match | 100% of current jackpot | `PrizePool.jackpot` |
| 2-of-3 match | 0.25 USDC | `PrizePool.reserve` |
| No match | 0 | — |
| Expired card (>250 blocks unscratched) | Full card price refund | `PrizePool.reserve` |

**Why does the jackpot show 20 USDC?**
The jackpot starts at the seeded amount (20 USDC in this deployment). Card purchases go 100% to the **reserve** (to guarantee refunds and small wins). The jackpot only grows from Uniswap V4 swap fee diversions and owner `seed()` calls. The 20 USDC jackpot is safe until a 3-of-3 match hits.

**What does a player actually receive?**
- Small win: +0.25 USDC sent directly to wallet on reveal
- Jackpot: entire jackpot balance sent directly to wallet on reveal
- Referral reward: 5% of every card purchase by their referrals — claimable any time from the dashboard

---

## Key Parameters

| Parameter | Value |
|---|---|
| Card price | 0.50 USDC |
| Small win payout | 0.25 USDC |
| Referral cut | 5% of purchase |
| Reveal delay | 3 blocks (~6 seconds) |
| Card expiry | 250 blocks (~8 minutes) |
| Symbols per card | 3 (from pool of 5) |
| Jackpot trigger | All 3 symbols match |
| Hustler badge | 10+ referrals |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Blockchain | Unichain Sepolia (L2, chain 1301) |
| Smart Contracts | Solidity ^0.8.26 · Foundry · ERC-721 (OpenZeppelin) |
| Swap Hook | Uniswap V4 `afterSwap` hook (fee diversion) |
| Automation | Reactive Network RSC (chain 5318007) |
| Randomness | On-chain block hash entropy (captured at purchase) |
| Frontend | Next.js 16 · TypeScript · Tailwind CSS v4 |
| Wallet | wagmi v2 · viem · RainbowKit |
| Animations | Framer Motion · canvas-confetti |
| Font | Bangers (Google Fonts — fire/game style) |

---

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/) — `curl -L https://foundry.paradigm.xyz | bash && foundryup`
- Node.js 18+
- Testnet ETH on Unichain Sepolia: [faucet.unichain.org](https://faucet.unichain.org)
- Testnet REACT on Reactive Lasna: [dev.reactive.network/docs/faucet](https://dev.reactive.network/docs/faucet)
- A free [WalletConnect project ID](https://cloud.walletconnect.com)

### Contracts

```bash
cd contract
forge install
cp .env.example .env
# Fill in PRIVATE_KEY, USDC_ADDRESS, SEED_AMOUNT

forge test                          # 79 tests must pass
forge script script/Deploy.s.sol \
  --rpc-url unichain_sepolia \
  --broadcast -vvvv                 # deploy to Unichain Sepolia

# After deploy — set SCRATCH_CARD_ADDRESS in .env, then deploy the RSC on Lasna.
# NOTE: use forge create, not forge script — the RSC constructor calls a Lasna node
# precompile that foundry's local simulation can't run. (See docs/reactive-debug.md.)
forge create src/ReactiveReveal.sol:ReactiveReveal \
  --rpc-url "https://lasna-rpc.rnk.dev" --private-key $PRIVATE_KEY --broadcast \
  --constructor-args $SCRATCH_CARD_ADDRESS    # subscribes in the constructor
cast send <RSC_ADDRESS> --value 0.5ether \
  --rpc-url "https://lasna-rpc.rnk.dev" --private-key $PRIVATE_KEY   # fund REACT

# Wire ScratchCard to the Reactive Callback Proxy (NOT the RSC address)
cast send <SCRATCH_CARD_ADDRESS> "setReactiveRevealer(address)" \
  0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4 \
  --rpc-url https://sepolia.unichain.org --private-key $PRIVATE_KEY
```

### Frontend

```bash
cd frontend
npm install
cp .env.example .env.local
# Fill in NEXT_PUBLIC_* contract addresses and WalletConnect project ID

npm run dev     # http://localhost:3000
```

---

## Project Structure

```
scratchin/
├── contract/
│   ├── src/
│   │   ├── ScratchCard.sol       # ERC-721 — buy, reveal, refund, leaderboard
│   │   ├── PrizePool.sol         # USDC jackpot + reserve, payout logic
│   │   ├── ScratchHook.sol       # Uniswap V4 afterSwap hook (fee → jackpot)
│   │   ├── Referral.sol          # On-chain referral tracking + USDC rewards
│   │   └── ReactiveReveal.sol    # Reactive Network RSC — auto-reveal
│   ├── script/
│   │   ├── Deploy.s.sol          # Deploy PrizePool + Referral + ScratchCard
│   │   └── DeployReactive.s.sol  # Deploy + fund + subscribe ReactiveReveal
│   ├── test/
│   │   ├── ScratchCard.t.sol     # 79 integration tests
│   │   └── mocks/MockUSDC.sol
│   ├── .env.example
│   └── foundry.toml
├── frontend/
│   ├── src/
│   │   ├── app/
│   │   │   ├── page.tsx          # Landing page (public, no wallet required)
│   │   │   └── play/page.tsx     # Game dashboard (/play route)
│   │   ├── components/
│   │   │   ├── game/             # BuyCards, MyCards (card fan), GameDashboard,
│   │   │   │                     # ReferralPanel, Leaderboard
│   │   │   └── ui/               # JackpotTicker, ParticleBackground
│   │   ├── hooks/                # usePlayerCards, useUsdcBalance, useJackpot,
│   │   │                         # useReferral, useRecentWinners
│   │   ├── abis/                 # ScratchCard, PrizePool, Referral, ERC20
│   │   └── lib/                  # wagmi config, contract addresses, formatUsdc
│   ├── .env.example
│   └── package.json
├── docs/
│   ├── scratchin-game-concept.md
│   └── pitch-deck-prompt.md
└── README.md
```

---

## MVP Status

### Contracts ✅
- [x] `ScratchCard.sol` — ERC-721, buy/reveal/refund, weekly leaderboard, ring buffer
- [x] `PrizePool.sol` — full-reserve model, guaranteed refunds, safe jackpot
- [x] `ScratchHook.sol` — V4 `afterSwap` fee diversion (requires hook address mining)
- [x] `Referral.sol` — on-chain referral, 5% USDC rewards, Hustler badge
- [x] `ReactiveReveal.sol` — correct `react(LogRecord)` + `Callback` with gas_limit
- [x] Deployed on Unichain Sepolia
- [x] ReactiveReveal deployed, funded (0.5 ETH), subscribed on Reactive Lasna
- [x] 79 tests passing, full branch coverage on core contracts

### Frontend ✅
- [x] Landing page — particle background, fire font, jackpot ticker, all sections
- [x] `/play` route — game dashboard (no forced wallet redirect)
- [x] ATM card fan UI — stacked cards, swipe nav, priority sort (jackpot first)
- [x] Two-column layout (cards left, buy right on desktop; cards above buy on mobile)
- [x] USDC approve → buy flow
- [x] Live block-based reveal/refund buttons
- [x] Referral link generation, copy/share, claim rewards
- [x] Leaderboard — recent wins, biggest win, all-time tabs
- [x] Confetti on jackpot win
- [x] Responsive — mobile optimised, jackpot hidden on mobile

---

## License

[MIT](LICENSE)

---

<div align="center">
Built with ❤️ on Uniswap V4 · Reactive Network · Unichain
</div>
