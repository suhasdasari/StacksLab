# Bynomo on Stacks

Experimental on-chain options game inspired by the "bynomo" hackathon demo — rebuilt for the Stacks ecosystem.

## Vision

Provide a one-click interface to open ultra-short options on BTC / ETH / BNB using Stacks smart contracts (Clarity), Stacks-native liquidity, and Bitcoin-secured settlement. Players click multiplier boxes; every click opens an option position that settles automatically when the round expires.

## High-level architecture

- **Clarity contracts**
  - `options-core`: manages rounds, bets, payouts.
  - `liquidity-pool`: houses bankroll, fees, and LP accounting.
  - `oracle-adapter`: consumes signed price feeds (Pyth / Switchboard / custom relay).
- **Oracle relay**: lightweight service that posts signed price snapshots every round.
- **Game coordinator**: optional service to start rounds on cadence + stream events via websockets.
- **Frontend**: React/Next.js client with Stacks wallet integration (Leather, Hiro), optimistic UI, and leaderboards.

## Getting started (dev contracts)

1. **Set vault + oracle addresses**
   ```clarity
   (contract-call? .options-core set-contracts 'ST123..options-core 'ST123..oracle-adapter)
   ```
   For the basic prototype, point the vault to the `options-core` contract principal so STX stakes escrow inside the same contract.
2. **Create a round**
   ```clarity
   (contract-call? .options-core create-round u1 "BTC" u62000000000 u123456 "pyth-btc")
   ```
   Arguments: round id, asset ticker, strike price (scaled to oracle precision), expiry height, lock height, oracle id string.
3. **Place a bet**
   ```clarity
   (contract-call? .options-core place-bet u1 u1000000 u20000 true)
   ```
   Args: round id, stake in micro-STX, multiplier in basis points, direction (`true` = up).
4. **Lock & settle**
   - `lock-round` once entries should stop.
   - `settle-round` with the observed final oracle price.
5. **Claim**
   - Players call `claim-winnings` to receive payouts based on strike vs. final price.

## Roadmap (short)

1. **Product & economic design** (this week)
   - Define round cadence, strike logic, multiplier table, liquidity model, fee flow.
   - Finalize oracle + token choices (STX vs. sBTC vs. SIP-010 stable).
2. **Smart-contract MVP** (weeks 2–3)
   - Scaffold contracts, data maps, and settlement logic; add Clarinet tests.
   - Formalize oracle message verification + price sanity checks.
3. **Middleware services** (week 4)
   - Build price-relay + round scheduler + alerting.
4. **Frontend alpha** (weeks 4–5)
   - Implement grid UI, wallet flows, history, admin toggles.
5. **Testnet & audits** (weeks 6+)
   - Deploy to Stacks testnet, run alpha tournament, fix bugs, then plan audit + mainnet launch.

## Repo layout (initial)

```
contracts/          # Clarity smart contracts (options-core, liquidity pool, oracle adapter)
docs/               # Architecture diagrams, specs, tokenomics
services/           # Backend services (price relay, coordinator)
scripts/            # Dev scripts, simulations, analyzers
```

More docs coming soon in `docs/`. Track tasks via GitHub Issues / Projects.
