# SCRATCHIN' — Reactive Network RSC Debug & Fix

**Symptom:** The RSC deployed on Reactive Lasna never reacts to `CardPurchased`,
so cards are never auto-revealed. Nothing shows up on the Lasna explorer.

## Root causes (the old `ReactiveReveal.sol`)

| # | Bug | Effect |
|---|-----|--------|
| 1 | Subscription was created from an **external owner tx** calling a hand-rolled `subscribe()`, not from the RSC **constructor** via the framework's injected `service`. | The ReactVM never registered a subscription → `react()` was **never called**. This is the primary failure. |
| 2 | Callback payload targeted `revealCard(uint256)`. Reactive injects the **RVM id as the first arg** of every callback. | Even if a callback fired, the destination signature was wrong. |
| 3 | `reactiveRevealer` on Unichain was set to the **RSC's Lasna address**. The destination call's `msg.sender` is the **Callback Proxy**. | The reveal would revert `Unauthorized`. |
| 4 | Funded the **RSC with ETH** for "callback gas." Reactive pays destination gas from the **Callback Proxy** (debt/credit), not the RSC balance. | Funds unused; callbacks could stall on unpaid debt. |
| 5 | `react()` guarded by a hand-rolled `onlyVMOrOwner`; `_isVM` was computed but never used. | Fragile / could reject legitimate VM calls. |
| 6 | **`react()` must be gated with `vmOnly`, not `authorizedSenderOnly`.** | Inside the ReactVM the caller is the VM itself, *not* `SERVICE_ADDR`. An ACL (`authorizedSenderOnly`) check therefore reverts on every delivered event — the subscription looks healthy, the RSC is funded, but `react()` silently reverts and **no `Callback` is ever emitted**. This was the live failure: card stayed Pending forever. The official Reactive demos all use `vmOnly`. |

## The fix (now in the repo)

- `src/ReactiveReveal.sol` now inherits `reactive-lib`'s **`AbstractReactive`**, and
  **subscribes inside the constructor** against the injected `service` (only when
  `!vm`). `react()` is gated by `authorizedSenderOnly` (system contract only).
- Callback now targets **`revealCardCallback(address,uint256)`** with an `address(0)`
  placeholder the proxy overwrites with the RVM id.
- `src/ScratchCard.sol` gains **`revealCardCallback(address rvm_id, uint256 tokenId)`**,
  authorized to `reactiveRevealer` (= the Callback Proxy). The owner path
  `revealCard(uint256)` is unchanged.
- `script/DeployReactive.s.sol` funds the RSC with **REACT** (Lasna gas) and prints
  the exact post-deploy wiring steps.

## Key addresses

| Thing | Value |
|---|---|
| Reactive Lasna chain id | `5318007` |
| Lasna RPC | `https://lasna-rpc.rnk.dev/` |
| Subscription service (reactive-lib) | `0x000000000000000000000000000000000000fffFfF` |
| **Unichain Sepolia Callback Proxy** | `0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4` |
| Unichain Sepolia chain id | `1301` |
| `CardPurchased` topic0 | `0xa90b50bfe45a40fae07e02f3195c6c6d8080611cb497b9ceec8d7e81dd80dc75` |

## Live deployment (redeployed 2026-06-04)

| Contract | Chain | Address |
|---|---|---|
| ScratchCard | Unichain Sepolia | `0xd051dD659844CFe4e2093a357368c57fe7d0a3c4` |
| PrizePool | Unichain Sepolia | `0xd7F50EaAEf4CcC922816261C142E3e1581dB9f3c` |
| Referral | Unichain Sepolia | `0xB830f8634d10a5B4F8FE16d70D531034AE4cA668` |
| ReactiveReveal RSC | Reactive Lasna | `0x77ec0037Bf4928BeaC8Cb943D249b0045209C464` |

Wiring already done: RSC subscribed to `CardPurchased` in its constructor; RSC funded
with 0.5 REACT; `ScratchCard.reactiveRevealer` set to the Callback Proxy; proxy funded
via `depositTo(ScratchCard)`.

> **Deployment note:** `forge script` cannot deploy the RSC because its constructor calls
> the Lasna node precompile `0x64` (resolves the system contract impl), which foundry's
> local simulation doesn't implement — the script reverts with `Failure` before broadcast.
> Deploy with **`forge create`** instead (sends the raw creation tx straight to the node):
>
> ```bash
> forge create src/ReactiveReveal.sol:ReactiveReveal \
>   --rpc-url https://lasna-rpc.rnk.dev --private-key $PRIVATE_KEY --broadcast \
>   --constructor-args $SCRATCH_CARD_ADDRESS
> ```

## Redeploy + verify runbook

```bash
# 1. Deploy the new RSC on Lasna (subscribes in the constructor). Use forge create,
#    NOT forge script (see deployment note above).
cd contract
forge create src/ReactiveReveal.sol:ReactiveReveal \
  --rpc-url https://lasna-rpc.rnk.dev --private-key "$PRIVATE_KEY" --broadcast \
  --constructor-args "$SCRATCH_CARD_ADDRESS"
# -> note the printed "Deployed to" address (call it $RSC), then fund it:
cast send $RSC --value 0.5ether --rpc-url https://lasna-rpc.rnk.dev --private-key "$PRIVATE_KEY"

# 2. On Unichain Sepolia, authorize the Callback Proxy as the revealer.
cast send "$SCRATCH_CARD_ADDRESS" \
  "setReactiveRevealer(address)" 0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4 \
  --rpc-url "$UNICHAIN_SEPOLIA_RPC" --private-key "$PRIVATE_KEY"

# 3. Fund the Callback Proxy on Unichain so it can pay reveal gas
#    (depositTo on the proxy — see Reactive docs for the exact method/amount).

# 4. END-TO-END TEST: buy a card on Unichain and watch the reveal fire.
#    - Buy emits CardPurchased on Unichain.
#    - The RSC's react() fires on Lasna (visible at https://lasna.reactscan.net/address/$RSC).
#    - A Callback is delivered to revealCardCallback() on Unichain ~revealDelay blocks later.
```

### What to check if it still doesn't fire

1. **Lasna explorer** for `$RSC` — is there a subscription + incoming `react()` txns?
   No subscription ⇒ the constructor's `service.subscribe` reverted or `vm` was true
   at deploy (re-run on the real Lasna RPC, not a fork).
2. **`reactiveRevealer`** on ScratchCard == the Callback Proxy
   `0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4`? If it's the RSC address, the reveal
   reverts `Unauthorized`.
3. **Proxy debt** — if the proxy has unpaid debt for your destination, callbacks stall.
   Fund it / `coverDebt`.
4. **RSC REACT balance** — must be non-zero to cover Lasna-side debt.
