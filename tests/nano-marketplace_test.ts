import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure that contract pause functionality works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "nano-marketplace",
        "pause-contract",
        [],
        deployer.address
      ),
    ]);
    assertEquals(block.receipts[0].result.expectOk(), true);
    
    block = chain.mineBlock([
      Tx.contractCall(
        "nano-marketplace",
        "create-listing",
        [types.uint(1000000), types.utf8("Test listing"), types.uint(30)],
        wallet1.address
      ),
    ]);
    assertEquals(block.receipts[0].result.expectErr(), "u105");
  },
});

Clarinet.test({
  name: "Ensure that listings can be created and purchased",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "nano-marketplace",
        "create-listing",
        [types.uint(1000000), types.utf8("Test listing"), types.uint(30)],
        wallet1.address
      ),
    ]);
    assertEquals(block.receipts[0].result.expectOk(), "u0");
    
    let result = chain.callReadOnlyFn(
      "nano-marketplace",
      "get-listing",
      [types.uint(0)],
      deployer.address
    );
    assertEquals(result.result.expectSome().status, "active");
    
    block = chain.mineBlock([
      Tx.contractCall(
        "nano-marketplace",
        "buy-listing",
        [types.uint(0)],
        deployer.address
      ),
    ]);
    assertEquals(block.receipts[0].result.expectOk(), true);
  },
});

Clarinet.test({
  name: "Ensure price validation works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "nano-marketplace",
        "create-listing",
        [types.uint(0), types.utf8("Test listing"), types.uint(30)],
        wallet1.address
      ),
    ]);
    assertEquals(block.receipts[0].result.expectErr(), "u106");
  },
});

Clarinet.test({
  name: "Ensure listing cancellation works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "nano-marketplace",
        "create-listing",
        [types.uint(1000000), types.utf8("Test listing"), types.uint(30)],
        wallet1.address
      ),
    ]);
    
    block = chain.mineBlock([
      Tx.contractCall(
        "nano-marketplace",
        "cancel-listing",
        [types.uint(0)],
        wallet1.address
      ),
    ]);
    assertEquals(block.receipts[0].result.expectOk(), true);
    
    let result = chain.callReadOnlyFn(
      "nano-marketplace",
        "get-listing",
        [types.uint(0)],
        wallet1.address
    );
    assertEquals(result.result.expectSome().status, "cancelled");
  },
});
