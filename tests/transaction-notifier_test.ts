import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Transaction Notifier: Register transaction event",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        // Register a new transaction event
        let block = chain.mineBlock([
            Tx.contractCall('transaction-notifier', 'register-transaction-event', [
                types.ascii("event-123"),
                types.ascii("transfer"),
                types.ascii("my-game"),
                types.utf8("Test event description"),
                types.some(types.utf8("{\"key\":\"value\"}"))
            ], deployer.address)
        ]);

        // Assert event was registered successfully
        assertEquals(block.receipts[0].result, '(ok true)');
    }
});

Clarinet.test({
    name: "Transaction Notifier: Subscribe to event",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        // First, register the event
        chain.mineBlock([
            Tx.contractCall('transaction-notifier', 'register-transaction-event', [
                types.ascii("event-456"),
                types.ascii("interaction"),
                types.ascii("another-game"),
                types.utf8("Another test event"),
                types.none()
            ], deployer.address)
        ]);

        // Then subscribe to the event
        let block = chain.mineBlock([
            Tx.contractCall('transaction-notifier', 'subscribe-to-event', [
                types.ascii("event-456")
            ], wallet1.address)
        ]);

        // Assert subscription was successful
        assertEquals(block.receipts[0].result, '(ok true)');
    }
});

Clarinet.test({
    name: "Transaction Notifier: Prevent duplicate event registration",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        // First registration should succeed
        chain.mineBlock([
            Tx.contractCall('transaction-notifier', 'register-transaction-event', [
                types.ascii("event-789"),
                types.ascii("conversion"),
                types.ascii("test-platform"),
                types.utf8("Duplicate event test"),
                types.none()
            ], deployer.address)
        ]);

        // Second registration with same event ID should fail
        let block = chain.mineBlock([
            Tx.contractCall('transaction-notifier', 'register-transaction-event', [
                types.ascii("event-789"),
                types.ascii("conversion"),
                types.ascii("another-platform"),
                types.utf8("Duplicate event attempt"),
                types.none()
            ], deployer.address)
        ]);

        // Assert that duplicate registration is prevented
        assertEquals(block.receipts[0].result, '(err u101)');
    }
});