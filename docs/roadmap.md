# Delivery Roadmap (Working → Production)

## Milestone A – Basic playable prototype (Weeks 1–2)
Purpose: deliver the simplest end-to-end flow (one asset, manual oracle, no LP shares) so we can click-through and demo mechanics quickly.

**Smart contracts**
- Lock-in settlement token (STX) and wire stake escrow inside `options-core`.
- Hardcode liquidity pool admin + bankroll; skip LP shares for now.
- Allow manual price submission via `oracle-adapter` (no signature validation yet).

**Backend / services**
- CLI or lightweight Node script to start rounds every few minutes and push prices.

**Frontend**
- One-page Next.js app with wallet connect, basic “bet up / bet down” buttons, and live round timer.
- Show pending bets + settlement result; data pulled directly from read-only contract calls.

**Definition of done**
- Anyone can stake STX in testnet, pick direction, and see win/loss + payout on settlement.
- At least one automated test per contract covering happy path.

## Milestone B – MVP with safety + UX polish (Weeks 3–5)
Purpose: make the game resilient enough for an open testnet and capture analytics.

**Smart contracts**
- Add LP share accounting + fee splits in `liquidity-pool`.
- Implement oracle signature validation and timestamp drift checks.
- Emit structured events for middleware and UI (round-created, bet-placed, settled).
- Add circuit breakers (pause, per-round risk caps).

**Middleware**
- Production-ready oracle relay with retry/backoff, metrics, and alerting.
- Round scheduler service with config for multiple assets / cadences.

**Frontend**
- Multiplier grid UI, mempool notifications, bet history, leaderboard.
- Admin controls (pause rounds, seed liquidity) gated by wallet role.

**Definition of done**
- Stable Stacks testnet deployment with monitoring + runbook.
- End-to-end tests for place/settle/claim flows via Clarinet + API tests.

## Milestone C – Production readiness (Weeks 6–8)
Purpose: ship to Stacks mainnet / BTC settlement with user protections.

**Smart contracts**
- Support sBTC (or SIP-010 token) payoff path, plus asset whitelists.
- Audited code, gas/perf optimizations, emergency upgrade/kill switches.

**Middleware & infra**
- Chainhook-powered event indexer feeding Postgres for analytics.
- Observability: dashboards for liquidity, volume, oracle latency.
- Incident response playbooks, alert routing.

**Frontend & growth**
- Polished UI/UX, tooltips, onboarding, translations.
- Referral codes, quests, shareable replays/screenshots.

**Definition of done**
- Third-party audit signed off, bug bounty live, mainnet contract addresses documented.
- Liquidity seeded, high-availability infra deployed, support channels staffed.

## Milestone D – Continuous improvement
- Expand asset list (LSTs, memecoins) by adding new oracle feeds.
- Layered multipliers (digital options, barrier games, streak modes).
- Mobile-first redesign + native app shells if needed.
- Explore composability with MegaETH / Euphoria data for co-marketing.

---
**Process reminder:** every atomic change (button, API function, contract line) gets its own descriptive commit so history mirrors progress.
