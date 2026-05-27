# SCRATCHIN' — On-Chain Scratch Card Game

## Brand
**SCRATCHIN'** — Say it like you mean it. Short, loud, unforgettable.

Tagline: *"Scratch. Win. Repeat. On-chain forever."*

---

## Concept Summary
SCRATCHIN' is a fully on-chain scratch card lottery game deployed on **Unichain**.  
Players buy scratch cards with tokens, reveal results from block hash entropy, compete on a live leaderboard, and win from a jackpot funded by **Uniswap V4 swap fees** — all automated by **Reactive Network**.

---

## How It Works (Simple Logic)

### 1. Buy a Card
- Player pays a small fixed amount (e.g. 0.01 ETH or a token) to mint a scratch card NFT.
- Players can buy as many cards as they want in one session.
- Each card is assigned a unique ID tied to the block number at purchase.

### 2. Scratch the Card
- After N blocks pass, the card becomes "scratchable."
- The reveal uses the block hash of (purchase block + N) as randomness seed.
- Each card has 3 symbols revealed — match 2 = small win, match 3 = jackpot.
- Reactive Network watches the target block and auto-triggers the reveal.

### 3. Prize Pool (V4 Hook)
- A Uniswap V4 pool has a custom hook that diverts a % of swap fees into the SCRATCHIN' prize pool.
- The more swaps happen on the pool, the bigger the jackpot grows.
- Small wins pay out instantly from a reserve fund.
- The jackpot accumulates until a 3-symbol match hits.

### 4. Leaderboard
- Every win is logged on-chain with the player's address and prize amount.
- Leaderboard tracks:
  - **Most cards bought** (Volume King)
  - **Biggest single win** (Jackpot Legend)
  - **Most wins this week** (Hot Streak)
  - **Total lifetime winnings** (All-Time Rich)
- Resets weekly for fresh competition. Hall of Fame preserves all-time records.

### 5. Referral System
- Every player gets a unique referral link tied to their wallet address.
- When a referred player buys cards, the referrer earns **5% of the card purchase value** instantly.
- Referral rewards are claimable any time from the game UI.
- Referral chain is stored on-chain — no backend needed, fully trustless.
- Referral stats visible on the player's profile: total referred players, total earnings from referrals.
- Bonus: refer 10+ active players and earn a **"Hustler" badge** on the leaderboard.

---

## UI Design — Two Views, One Bold Experience

### Color Palette
- Background: **Deep black** `#0A0A0A`
- Primary accent: **Electric gold** `#FFD700`
- Secondary accent: **Neon green** `#39FF14`
- Card surface: **Dark slate** `#1A1A2E`
- Text: **Pure white** `#FFFFFF`

---

### VIEW 1 — Landing Page (Before Wallet Connect)

This is the first thing every visitor sees. No wallet required. Pure hype.

```
┌────────────────────────────────────────────────────────┐
│  SCRATCHIN'                              [How It Works] │
├────────────────────────────────────────────────────────┤
│                                                        │
│         S C R A T C H I N '                            │
│                                                        │
│    The world's first on-chain scratch card game.       │
│    Powered by Uniswap V4 · Reactive Network · Unichain │
│                                                        │
│         🏆 CURRENT JACKPOT: 4,200 ETH 🏆               │
│              [ live ticker — pulses gold ]             │
│                                                        │
│          [  PLAY NOW — Connect Wallet  ]  ← big CTA    │
│                                                        │
├────────────────────────────────────────────────────────┤
│  HOW IT WORKS                                          │
│                                                        │
│  [🎴 Buy a Card]  →  [⏳ Wait for Block]  →  [🎉 Win]  │
│                                                        │
│  Buy cards with ETH. Block hash reveals your result.   │
│  Jackpot grows with every swap on the V4 pool.         │
│                                                        │
├────────────────────────────────────────────────────────┤
│  RECENT WINNERS                                        │
│  🥇 0xAbc...  won  12.5 ETH   2 mins ago               │
│  🥈 0xDef...  won   0.8 ETH   5 mins ago               │
│  🥉 0x123...  won   2.1 ETH   9 mins ago               │
│                         [ scrolling ticker ]           │
├────────────────────────────────────────────────────────┤
│  LEADERBOARD PREVIEW                                   │
│  👑 All-Time King: 0xAbc...  →  420 ETH won            │
│  🔥 This Week's Hot: 0xDef...  →  12 wins              │
│                    [ See Full Leaderboard → ]          │
├────────────────────────────────────────────────────────┤
│  Built on Unichain  |  Powered by V4 Hooks             │
│  Automated by Reactive Network  |  Fully On-Chain      │
└────────────────────────────────────────────────────────┘
```

---

### VIEW 2 — Game Page (After Wallet Connect)

Slides in after wallet is connected. Same page, content swaps.

```
┌────────────────────────────────────────────────────────┐
│  SCRATCHIN'        🔗 0xAbc...de    [Your Referral Link]│
├──────────────────┬─────────────────────────────────────┤
│                  │                                      │
│  🏆 JACKPOT      │         BUY CARDS                    │
│  4,200 ETH       │   [ 1 ]  [ 5 ]  [ 10 ]  [ Custom ]  │
│  (live pulse)    │                                      │
│                  │   Card price: 0.01 ETH each          │
│  YOUR BALANCE    │   Your referral bonus: +0.3 ETH      │
│  2.4 ETH         │                                      │
│                  │     [ SCRATCH NOW ] ← big gold CTA   │
│  REFERRAL EARNED │                                      │
│  0.3 ETH [Claim] │                                      │
│                  │                                      │
├──────────────────┴─────────────────────────────────────┤
│  YOUR CARDS                                            │
│  [ 🎴 #001 ]   [ 🎴 #002 ]   [ 🎴 #003 ]   [ 🎴 #004 ] │
│   PENDING       SCRATCH ME!   ✅ WON 0.5     ❌ NO WIN  │
├────────────────────────────────────────────────────────┤
│  REFER & EARN                                          │
│  Your link: scratchin.gg/?ref=0xAbc...   [Copy] [Share]│
│  Referred players: 7   |   Total earned: 0.3 ETH       │
│  [ 3 more referrals to unlock Hustler badge 🏅 ]       │
├────────────────────────────────────────────────────────┤
│  LEADERBOARD                                           │
│  [ 🔥 Hot Streak ] [ 💰 Biggest Win ] [ 👑 All-Time ]   │
│  1. 0xAbc...   12 wins this week                       │
│  2. 0xDef...    9 wins this week                       │
│  3. 0x123...    7 wins this week          YOU → #14    │
└────────────────────────────────────────────────────────┘
```

---

### Icons Used (Real Libraries)
| Element | Icon | Source |
|---|---|---|
| Jackpot / Trophy | `Trophy` | `lucide-react` |
| Wallet | `Wallet` | `lucide-react` |
| Copy referral link | `Copy` | `lucide-react` |
| Share | `Share2` | `lucide-react` |
| Leaderboard rank | `Crown`, `Flame`, `TrendingUp` | `lucide-react` |
| Win notification | `CheckCircle2` | `lucide-react` |
| No win | `XCircle` | `lucide-react` |
| Pending card | `Hourglass` | `lucide-react` |
| Claim reward | `BadgeDollarSign` | `lucide-react` |
| Hustler badge | `BadgeCheck` | `lucide-react` |
| Uniswap brand | `SiUniswap` | `react-icons/si` |
| Ethereum | `SiEthereum` | `react-icons/si` |
| External link | `ExternalLink` | `lucide-react` |

### Card Scratch Animation
- Cards start face-down with a silver foil shimmer effect (Tailwind `animate-pulse` + custom gradient).
- Clicking "Scratch" triggers a Framer Motion reveal animation exposing 3 symbol slots.
- Symbols are SVG icons from `lucide-react`: `Gem`, `Star`, `Bell`, `Zap`, `Circle` (styled gold/white).
- Match 3 → `canvas-confetti` explosion + Framer Motion gold flash.
- Match 2 → green border pulse via Framer Motion.
- No win → Framer Motion `x` shake + grey desaturate transition.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Blockchain | Unichain (L2) |
| Smart Contracts | Solidity — ERC-721 scratch cards |
| Swap Hook | Uniswap V4 custom hook (fee diversion to prize pool) |
| Automation | Reactive Network (block watcher → auto-reveal) |
| Randomness | Block hash entropy (purchase block + N) |
| Frontend | Next.js 14 (App Router), single-page layout |
| Wallet | wagmi + viem + RainbowKit |
| Styling | Tailwind CSS + Framer Motion (animations) |
| Icons | Lucide React (UI icons) + React Icons (brand/misc) |

---

## Smart Contracts Needed

### 1. `ScratchCard.sol` (ERC-721)
- `buyCard(uint quantity)` — mint cards, record purchase block
- `revealCard(uint tokenId)` — called by Reactive or user after N blocks
- `claimPrize(uint tokenId)` — transfer winnings to winner

### 2. `PrizePool.sol`
- Holds jackpot and reserve funds
- Accepts deposits from V4 hook
- Pays out on reveal trigger

### 3. `ScratchHook.sol` (V4 Hook)
- `afterSwap` hook — diverts X% of fees to PrizePool
- Configurable fee diversion rate (e.g. 10%)

### 4. Reactive Contract
- Watches Unichain blocks
- Calls `revealCard()` when target block is reached
- Emits result event for frontend to pick up

### 5. `Referral.sol`
- `registerReferral(address referrer)` — links buyer to referrer at card purchase time
- `claimRewards()` — referrer pulls accumulated 5% rewards
- One referrer per buyer, set at first purchase, immutable
- Emits `ReferralEarned(referrer, buyer, amount)` for frontend tracking

---

## Game Feel Goals
- Feels like a real scratch lottery, not a DeFi app
- Instant feedback — animations, sounds, notifications
- Buying 10 cards at once is satisfying
- Leaderboard creates FOMO and return visits
- Jackpot ticker always visible — makes the prize feel real

---

## MVP Scope (Phase 1)

### Smart Contracts
- [ ] Deploy `ScratchCard.sol` (ERC-721) on Unichain Sepolia
- [ ] Deploy `PrizePool.sol` and connect to ScratchCard
- [ ] Deploy `ScratchHook.sol` — V4 hook diverts fees to prize pool
- [ ] Deploy `Referral.sol` — on-chain referral tracking and reward claims
- [ ] Deploy Reactive contract — auto-reveal on target block

### Frontend
- [ ] Landing page — jackpot ticker, how it works, recent winners, leaderboard preview
- [ ] Game page — buy cards, scratch cards, referral panel, full leaderboard
- [ ] Wallet connect gates landing → game transition
- [ ] Referral link generation and copy/share on game page
- [ ] Card scratch animation (CSS scratch-off effect)
- [ ] Confetti + sound on jackpot win

### Dependencies (Frontend)
- [ ] `next` `react` `react-dom`
- [ ] `wagmi` `viem` `@rainbow-me/rainbowkit`
- [ ] `lucide-react` `react-icons`
- [ ] `framer-motion`
- [ ] `canvas-confetti`
- [ ] `tailwindcss`

### Launch
- [ ] Testnet launch on Unichain Sepolia with test ETH
- [ ] Referral links live at launch (growth from day 1)

## Phase 2
- [ ] Real token / mainnet deployment on Unichain
- [ ] Mobile-optimized UI
- [ ] Weekly leaderboard resets + Hall of Fame
- [ ] Card rarity tiers (Bronze / Silver / Gold cards with different win odds)
- [ ] Hustler badge display on leaderboard for power referrers
