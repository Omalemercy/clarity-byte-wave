import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register new student",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('byte_wave', 'register-student', [
                types.ascii("test_student")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Verify student info
        let infoBlock = chain.mineBlock([
            Tx.contractCall('byte_wave', 'get-student-info', [
                types.principal(wallet1.address)
            ], wallet1.address)
        ]);
        
        const studentData = infoBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(studentData.level, types.uint(1));
        assertEquals(studentData.total-points, types.uint(0));
    }
});

Clarinet.test({
    name: "Can complete challenge and earn points",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        // First register student
        let registerBlock = chain.mineBlock([
            Tx.contractCall('byte_wave', 'register-student', [
                types.ascii("test_student")
            ], wallet1.address)
        ]);
        
        // Add challenge
        let challengeBlock = chain.mineBlock([
            Tx.contractCall('byte_wave', 'add-challenge', [
                types.uint(1),
                types.ascii("Test Challenge"),
                types.uint(100),
                types.uint(1)
            ], deployer.address)
        ]);
        
        // Complete challenge
        let completeBlock = chain.mineBlock([
            Tx.contractCall('byte_wave', 'complete-challenge', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        completeBlock.receipts[0].result.expectOk();
        
        // Verify points
        let pointsBlock = chain.mineBlock([
            Tx.contractCall('byte_wave', 'get-student-points', [
                types.principal(wallet1.address)
            ], wallet1.address)
        ]);
        
        assertEquals(pointsBlock.receipts[0].result.expectOk(), types.uint(100));
    }
});

Clarinet.test({
    name: "Can unlock achievement",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // First register student
        let registerBlock = chain.mineBlock([
            Tx.contractCall('byte_wave', 'register-student', [
                types.ascii("test_student")
            ], wallet1.address)
        ]);
        
        // Unlock achievement
        let achievementBlock = chain.mineBlock([
            Tx.contractCall('byte_wave', 'unlock-achievement', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        achievementBlock.receipts[0].result.expectOk();
        
        // Verify achievement status
        let statusBlock = chain.mineBlock([
            Tx.contractCall('byte_wave', 'get-achievement-status', [
                types.principal(wallet1.address),
                types.uint(1)
            ], wallet1.address)
        ]);
        
        const achievementData = statusBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(achievementData.unlocked, true);
    }
});