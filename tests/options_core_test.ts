
import { Clarinet, Tx, Chain, Account, types } from "clarinet";
import { assertEquals } from "https://deno.land/std@0.204.0/testing/asserts.ts";

Clarinet.test({
  name: "basic round lifecycle pays winning bettor",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const player = accounts.get("wallet_1")!;
    const contractPrincipal = `${deployer.address}.options-core`;

    const lockHeight = chain.blockHeight + 10;
    const expiry = lockHeight + 5;

    const block1 = chain.mineBlock([
      Tx.contractCall(
        "options-core",
        "set-contracts",
        [types.principal(contractPrincipal), types.principal(deployer.address)],
        deployer.address
      ),
      Tx.contractCall(
        "options-core",
        "create-round",
        [
          types.uint(1),
          types.ascii("BTC"),
          types.uint(60_000_000_000),
          types.uint(expiry),
          types.uint(lockHeight),
          types.ascii("pyth-btc")
        ],
        deployer.address
      ),
      Tx.contractCall(
        "options-core",
        "place-bet",
        [types.uint(1), types.uint(1_000_000), types.uint(20_000), types.bool(true)],
        player.address
      ),
      Tx.contractCall("options-core", "lock-round", [types.uint(1)], deployer.address),
      Tx.contractCall(
        "options-core",
        "settle-round",
        [types.uint(1), types.uint(61_000_000_000)],
        deployer.address
      ),
      Tx.contractCall("options-core", "claim-winnings", [types.uint(1)], player.address)
    ]);

    block1.receipts.forEach((receipt, index) => {
      receipt.result.expectOk(`tx ${index} failed`);
    });

    const payout = block1.receipts[5].result.expectOk().expectUint();
    assertEquals(payout, 2_000_000);
  }
});

Clarinet.test({
  name: "cannot create duplicate round ids",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const contractPrincipal = `${deployer.address}.options-core`;

    const lockHeight = chain.blockHeight + 5;
    const expiry = lockHeight + 5;

    const block = chain.mineBlock([
      Tx.contractCall(
        "options-core",
        "set-contracts",
        [types.principal(contractPrincipal), types.principal(deployer.address)],
        deployer.address
      ),
      Tx.contractCall(
        "options-core",
        "create-round",
        [
          types.uint(7),
          types.ascii("BTC"),
          types.uint(60_000_000_000),
          types.uint(expiry),
          types.uint(lockHeight),
          types.ascii("pyth-btc")
        ],
        deployer.address
      ),
      Tx.contractCall(
        "options-core",
        "create-round",
        [
          types.uint(7),
          types.ascii("BTC"),
          types.uint(61_000_000_000),
          types.uint(expiry + 1),
          types.uint(lockHeight + 1),
          types.ascii("pyth-btc")
        ],
        deployer.address
      )
    ]);

    block.receipts[1].result.expectOk();
    block.receipts[2].result.expectErr().expectUint(406);
  }
});

Clarinet.test({
  name: "player cannot place duplicate bet in same round",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const player = accounts.get("wallet_1")!;
    const contractPrincipal = `${deployer.address}.options-core`;

    const lockHeight = chain.blockHeight + 5;
    const expiry = lockHeight + 5;

    const block = chain.mineBlock([
      Tx.contractCall(
        "options-core",
        "set-contracts",
        [types.principal(contractPrincipal), types.principal(deployer.address)],
        deployer.address
      ),
      Tx.contractCall(
        "options-core",
        "create-round",
        [
          types.uint(9),
          types.ascii("BTC"),
          types.uint(60_000_000_000),
          types.uint(expiry),
          types.uint(lockHeight),
          types.ascii("pyth-btc")
        ],
        deployer.address
      ),
      Tx.contractCall(
        "options-core",
        "place-bet",
        [types.uint(9), types.uint(1_000_000), types.uint(10_000), types.bool(true)],
        player.address
      ),
      Tx.contractCall(
        "options-core",
        "place-bet",
        [types.uint(9), types.uint(2_000_000), types.uint(15_000), types.bool(false)],
        player.address
      )
    ]);

    block.receipts[2].result.expectOk();
    block.receipts[3].result.expectErr().expectUint(407);
  }
});

Clarinet.test({
  name: "bets are rejected after the round is locked",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const player = accounts.get("wallet_1")!;
    const contractPrincipal = `${deployer.address}.options-core`;

    const lockHeight = chain.blockHeight + 5;
    const expiry = lockHeight + 5;

    const setup = chain.mineBlock([
      Tx.contractCall(
        "options-core",
        "set-contracts",
        [types.principal(contractPrincipal), types.principal(deployer.address)],
        deployer.address
      ),
      Tx.contractCall(
        "options-core",
        "create-round",
        [
          types.uint(11),
          types.ascii("BTC"),
          types.uint(60_000_000_000),
          types.uint(expiry),
          types.uint(lockHeight),
          types.ascii("pyth-btc")
        ],
        deployer.address
      ),
      Tx.contractCall("options-core", "lock-round", [types.uint(11)], deployer.address)
    ]);

    setup.receipts.forEach((r, idx) => r.result.expectOk(`setup tx ${idx} failed`));

    const lockedBlock = chain.mineBlock([
      Tx.contractCall(
        "options-core",
        "place-bet",
        [types.uint(11), types.uint(1_000_000), types.uint(10_000), types.bool(true)],
        player.address
      )
    ]);

    lockedBlock.receipts[0].result.expectErr().expectUint(401);
  }
});

Clarinet.test({
  name: "admin can cancel an open round to block new bets",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const player = accounts.get("wallet_1")!;
    const contractPrincipal = `${deployer.address}.options-core`;

    const lockHeight = chain.blockHeight + 5;
    const expiry = lockHeight + 5;

    chain.mineBlock([
      Tx.contractCall(
        "options-core",
        "set-contracts",
        [types.principal(contractPrincipal), types.principal(deployer.address)],
        deployer.address
      ),
      Tx.contractCall(
        "options-core",
        "create-round",
        [
          types.uint(13),
          types.ascii("BTC"),
          types.uint(60_000_000_000),
          types.uint(expiry),
          types.uint(lockHeight),
          types.ascii("pyth-btc")
        ],
        deployer.address
      ),
      Tx.contractCall("options-core", "cancel-round", [types.uint(13)], deployer.address)
    ]);

    const betBlock = chain.mineBlock([
      Tx.contractCall(
        "options-core",
        "place-bet",
        [types.uint(13), types.uint(1_000_000), types.uint(10_000), types.bool(true)],
        player.address
      )
    ]);

    betBlock.receipts[0].result.expectErr().expectUint(401);
  }
});
