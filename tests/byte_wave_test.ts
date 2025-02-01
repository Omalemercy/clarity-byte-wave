import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register new student with skill levels",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('byte_wave', 'register-student', [
                types.ascii("test_student")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        let infoBlock = chain.mineBlock([
            Tx.contractCall('byte_wave', 'get-student-info', [
                types.principal(wallet1.address)
            ], wallet1.address)
        ]);
        
        const studentData = infoBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(studentData['skill-levels'].algorithms, types.uint(1));
        assertEquals(studentData['skill-levels'].web, types.uint(1));
        assertEquals(studentData.badges.length, 0);
    }
});

Clarinet.test({
    name: "Can complete challenge and earn skill points",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        // Register student
        let registerBlock = chain.mineBlock([
            Tx.contractCall('byte_wave', 'register-student', [
                types.ascii("test_student")
            ], wallet1.address)
        ]);
        
        // Add challenge with skill category
        let challengeBlock = chain.mineBlock([
            Tx.contractCall('byte_wave', 'add-challenge', [
                types.uint(1),
                types.ascii("Algorithm Challenge"),
                types.uint(100),
                types.uint(1),
                types.ascii("algorithms"),
                types.uint(5)
            ], deployer.address)
        ]);
        
        // Complete challenge
        let completeBlock = chain.mineBlock([
            Tx.contractCall('byte_wave', 'complete-challenge', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        completeBlock.receipts[0].result.expectOk();
        
        // Verify skill levels
        let skillBlock = chain.mineBlock([
            Tx.contractCall('byte_wave', 'get-skill-levels', [
                types.principal(wallet1.address)
            ], wallet1.address)
        ]);
        
        const skillData = skillBlock.receipts[0].result.expectOk();
        assertEquals(skillData.algorithms, types.uint(6));
        assertEquals(skillData.web, types.uint(1));
    }
});
