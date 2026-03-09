# Project Status — 2026-03-09

## TL;DR
- Repository currently contains design docs plus skeleton Clarity contracts; no runnable product yet.
- No smart-contract tests, backend services, or frontend assets exist in the repo.
- Tooling gap: the Clarinet CLI is not installed locally, so even static type checking can’t run.

## Critical blockers
1. **Toolchain** — Install Clarinet (and ideally `clarinet integrate` deps) so contracts can be compiled/tested.
2. **Oracle + liquidity plumbing** — `options-core` references an oracle adapter and LP contract, but both are placeholders with no token transfers or signature validation.
3. **End-to-end flow** — No middleware/frontend, so there’s no way to drive rounds, submit prices, or display the game.

## Component readiness snapshot
| Component | Status | Notes |
|-----------|--------|-------|
| `options-core` contract | 🚧 60% | Core round lifecycle implemented, but oracle validation, events, and richer risk checks remain TODO.
| `liquidity-pool` contract | 🚧 20% | Admin + bookkeeping vars exist; deposits/withdrawals lack token transfers and share math.
| `oracle-adapter` contract | 🚧 15% | Stores latest price per asset; no signature verification or timestamp guards yet.
| Clarinet tests | ❌ 0% | No tests or simulations committed.
| Oracle relay service | ❌ 0% | Directory empty.
| Round coordinator service | ❌ 0% | Not started.
| Frontend (Next.js) | ❌ 0% | No app scaffolding, wallet integration, or UI components checked in.
| DevOps / deployment | ❌ 0% | No scripts, configs, or runbooks.

## Path to "complete project ready"
1. **Tooling setup**
   - Install Clarinet and verify `clarinet check` + `clarinet test` succeed locally.
   - Add `package.json` (or `justfile`) to pin scripts for lint/check/test.

2. **Milestone A (basic playable prototype)**
   - Finish STX escrow + payout plumbing between `options-core` and `liquidity-pool`.
   - Hardcode oracle signer flow (`oracle-adapter`) and wire `settle-round` to fetch/validate prices.
   - Add Clarinet unit tests for create → bet → lock → settle → claim.
   - Build the lightweight round-runner + manual oracle relay script (Node/TypeScript) to drive the contracts on devnet.
   - Scaffold a barebones Next.js page with wallet connect + bet buttons hitting read-only endpoints.

3. **Milestone B (MVP polish)**
   - Implement LP share accounting, fee splits, and circuit breakers.
   - Add oracle signature checks, timestamp drift limits, and structured events.
   - Flesh out middleware (proper relay with retries, scheduler with multi-asset config).
   - Expand frontend: multiplier grid, history, admin toggles, leaderboard, alerts.
   - Stand up basic observability (logging, error notifications).

4. **Milestone C (production readiness)**
   - Support sBTC/SIP-010 tokens, add audits, optimize gas, codify incident response.
   - Deploy Chainhook indexer + Postgres for analytics, wire dashboards.
   - Harden frontend UX, add referrals/quests, prep launch materials.

## Immediate next actions
- [ ] Install Clarinet locally and confirm `clarinet check` succeeds.
- [ ] Implement STX transfer calls + LP accounting so `place-bet`/`claim-winnings` actually move funds.
- [ ] Write the first Clarinet test covering the happy-path round lifecycle.
- [ ] Decide on the stack for services/frontend (Node + Next.js + pnpm?) and scaffold those directories with real code.
- [ ] Push README/status updates outlining the above so contributors share the same roadmap.
