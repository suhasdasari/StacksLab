import { Clarinet, Tx, Chain, Account, types } from "clarinet";
import { assertEquals } from "https://deno.land/std@0.204.0/testing/asserts.ts";

Clarinet.test({
  name: "basic round lifecycle pays winning bettor",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const player = accounts.get("wallet_1")!;
    const contractPrincipal = `${deployer.address}.options-core`;

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
          types.uint(60000000000),
          types.uint(123456),
          types.uint(chain.blockHeight + 10),
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
        [types.uint(1), types.uint(61000000000)],
        deployer.address
      ),
      Tx.contractCall("options-core", "claim-winnings", [types.uint(1)], player.address)
    ]);

    block1.receipts.forEach((receipt) => {
      receipt.result.expectOk();
    });

    const payout = block1.receipts[5].result.expectOk().expectUint();
    assertEquals(payout, 2_000_000);
  }
});
