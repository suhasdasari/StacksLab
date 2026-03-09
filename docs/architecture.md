# Bynomo-on-Stacks Architecture Draft

## 1. Gameplay lifecycle
1. **Round creation**: coordinator (or any caller) starts a round with asset, expiry timestamp, multiplier table, and oracle id.
2. **User entry**: players sign and send `place-bet` transactions specifying multiplier bucket + stake (STX / sBTC / SIP-010).
3. **Lockdown**: once `lock-window` ends, contract rejects new bets; only settlement remains.
4. **Settlement**: after expiry the oracle adapter provides the final price. Contract computes win/loss vs. strike and pays from the liquidity pool.
5. **Finalization**: round marked resolved; unclaimed winnings can be pulled later; fees flow to DAO/LPs.

## 2. Contracts
- `options-core.clar`
  - Stores round metadata, player positions, and settlement state.
  - Handles bet intake, round locking, and payout dispatch.
  - Emits events for middleware/UI.
- `liquidity-pool.clar`
  - Accepts LP deposits, tracks LP tokens, manages bankroll.
  - Processes fee revenue and implements safety switches.
- `oracle-adapter.clar`
  - Validates signed price packages.
  - Sanitizes timestamps, asset ids, and drift before returning price.

## 3. Oracles
Preferred order:
1. **Pyth** via Switchboard adapters (fast, widely used on Stacks testnet).
2. **Custom signer**: Chainhook + off-chain feed posting signatures for fallback assets (e.g., BNB if not in official feeds yet).
3. **Cross-chain relay**: read MegaETH/Euphoria feeds, re-sign, and deliver to Stacks until native coverage lands.

## 4. Middleware services
- **Price relay** (`services/oracle-relay`): fetches off-chain price, signs payload, submits `submit-price` txn.
- **Round coordinator** (`services/frontend` placeholder or `services/game-coordinator`): ensures new rounds open continuously, publishes metadata to frontend via websocket.
- **Analytics + alerting**: monitors liquidity exhaustion, oracle delays, or stuck rounds.

## 5. Frontend plan
- Next.js + Typescript, Tailwind/Chakra.
- Hooks via `@stacks/connect-react` to Leather/Hiro.
- Live feed by subscribing to Chainhook or custom websocket for mempool updates.
- Includes leaderboard, history, admin toggles, and educational overlays.

## 6. Security & risk
- Unit tests via Clarinet for all branches.
- Property-based fuzzing for payout maths (consider ligo or python scripts in `scripts/`).
- Circuit breakers: pause if oracle gap > X, or liquidity < threshold.
- Audit with reputable Clarity team before mainnet.
