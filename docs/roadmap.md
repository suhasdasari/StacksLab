# Implementation Roadmap

## Phase 0 – Spec & research (Week 1)
- Finalize product requirements (round cadence, assets, strike logic).
- Decide on settlement asset (STX vs. sBTC vs. SIP-010) and how liquidity is sourced.
- Pick oracle provider + contingency plan for unsupported assets (BNB).
- Formalize risk + compliance checklist.

**Deliverables:** Updated PRD, finalized tokenomics, mockups.

## Phase 1 – Smart-contract MVP (Weeks 2–3)
- Flesh out `options-core`, `liquidity-pool`, and `oracle-adapter` contracts.
- Implement escrow of stakes, payout logic, and oracle verification.
- Write Clarinet tests + coverage for edge cases.
- Define events + read-only views for frontend/middleware.

**Deliverables:** Contracts deployed to localnet/testnet; CI running Clarinet.

## Phase 2 – Middleware services (Week 4)
- Build Node service for oracle relay (pluggable sources).
- Build round scheduler / heartbeat worker.
- Add monitoring + alerts (Grafana/Better Uptime) for oracle lag/liquidity.

**Deliverables:** Dockerized services, runbooks.

## Phase 3 – Frontend alpha (Weeks 4–5)
- Next.js UI with Leather/Hiro wallet integration.
- Multiplier grid, bet slip, countdown, mempool feedback.
- History + leaderboard views fed by Chainhook/Postgres.

**Deliverables:** Hosted alpha on Vercel or similar.

## Phase 4 – Testnet program (Week 6)
- Deploy to Stacks testnet, faucet distribution, run tournaments.
- Collect telemetry, patch UX bugs.
- Launch bug bounty.

## Phase 5 – Audit & mainnet preparation (Weeks 7–8)
- Commission 3rd party Clarity audit.
- Finalize legal/compliance stance, ToS, risk disclaimers.
- Mainnet deploy, seed liquidity, announce.

## Phase 6 – Post-launch
- Expand asset support (LSTs, memecoins), add social features, integrate MegaETH data for UX parity.
