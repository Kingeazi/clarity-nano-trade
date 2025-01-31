import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure that listings can be created and purchased",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;
    
    // Test listing creation
    let block = chain.mineBlock([
      Tx.contractCall(
        "nano-marketplace",
        "create-listing",
        [types.uint(1000000), types.utf8("Test listing"), types.uint(30)],
        wallet1.address
      ),
    ]);
    assertEquals(block.receipts[0].result.expectOk(), "0");
    
    // Test get-listing function
    let result = chain.callReadOnlyFn(
      "nano-marketplace",
      "get-listing",
      [types.uint(0)],
      deployer.address
    );
    assertEquals(result.result.expectSome().status, "active");
    
    // Test buying
    block = chain.mineBlock([
      Tx.contractCall(
        "nano-marketplace",
        "buy-listing",
        [types.uint(0)],
        deployer.address
      ),
    ]);
    assertEquals(block.receipts[0].result.expectOk(), "true");
  },
});
