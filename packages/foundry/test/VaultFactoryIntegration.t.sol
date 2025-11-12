// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../contracts/VaultFactory.sol";

/**
 * @title VaultFactory Integration Tests
 * @dev Additional integration tests for complex scenarios
 */
contract VaultFactoryIntegrationTest is Test {
    VaultFactory public vaultFactory;
    address public owner;
    address[] public users;
    
    event VaultCreated(uint256 indexed vaultId, string name, uint256 joinFee);
    event JoinedVault(uint256 indexed vaultId, address indexed user, uint256 paidFee);

    function setUp() public {
        owner = makeAddr("owner");
        
        // Create multiple test users
        for (uint256 i = 0; i < 10; i++) {
            users.push(makeAddr(string.concat("user", vm.toString(i))));
            vm.deal(users[i], 100 ether);
        }

        vm.prank(owner);
        vaultFactory = new VaultFactory();
        vm.deal(owner, 100 ether);
    }

    function testMassJoiningSingleVault() public {
        uint256 vaultId = 0;
        uint256 joinFee = 10000000000000;
        
        // All users join the same vault
        for (uint256 i = 0; i < users.length; i++) {
            vm.prank(users[i]);
            vaultFactory.joinVault{value: joinFee}(vaultId);
        }
        
        // Verify all users are members
        for (uint256 i = 0; i < users.length; i++) {
            assertTrue(vaultFactory.isMember(vaultId, users[i]));
        }
        
        // Check vault member count
        (, , address[] memory members) = vaultFactory.getVault(vaultId);
        assertEq(members.length, users.length);
        
        // Check contract balance
        assertEq(address(vaultFactory).balance, joinFee * users.length);
    }
    
    function testUsersJoinMultipleVaults() public {
        // First 3 users join Mike's vault
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(users[i]);
            vaultFactory.joinMikesVault{value: 10000000000000}();
        }
        
        // Next 3 users join Jame's vault
        for (uint256 i = 3; i < 6; i++) {
            vm.prank(users[i]);
            vaultFactory.joinJamesVault{value: 20000000000000}();
        }
        
        // Last 4 users join John's vault
        for (uint256 i = 6; i < 10; i++) {
            vm.prank(users[i]);
            vaultFactory.joinJohnsVault{value: 30000000000000}();
        }
        
        // Verify memberships
        for (uint256 i = 0; i < 3; i++) {
            assertTrue(vaultFactory.isMember(0, users[i]));
        }
        for (uint256 i = 3; i < 6; i++) {
            assertTrue(vaultFactory.isMember(1, users[i]));
        }
        for (uint256 i = 6; i < 10; i++) {
            assertTrue(vaultFactory.isMember(2, users[i]));
        }
        
        // Check total balance
        uint256 expectedBalance = (3 * 10000000000000) + (3 * 20000000000000) + (4 * 30000000000000);
        assertEq(address(vaultFactory).balance, expectedBalance);
    }
    
    function testCreateManyVaultsAndJoin() public {
        // Create 10 new vaults with different fees
        vm.startPrank(owner);
        for (uint256 i = 0; i < 10; i++) {
            string memory name = string.concat("Vault ", vm.toString(i + 3));
            uint256 fee = (i + 1) * 1e18; // 1 ETH, 2 ETH, 3 ETH, etc.
            vaultFactory.createVault(name, fee);
        }
        vm.stopPrank();
        
        assertEq(vaultFactory.vaultsCount(), 13); // 3 default + 10 new
        
        // Each user joins a different vault
        for (uint256 i = 0; i < users.length; i++) {
            uint256 vaultId = 3 + i; // Start from vault 3 (first new vault)
            (, uint256 joinFee, ) = vaultFactory.getVault(vaultId);
            
            vm.prank(users[i]);
            vaultFactory.joinVault{value: joinFee}(vaultId);
            
            assertTrue(vaultFactory.isMember(vaultId, users[i]));
        }
    }
    
    function testLargeWithdrawal() public {
        // Multiple users join different vaults to accumulate large balance
        uint256 totalExpected = 0;
        
        // Join Mike's vault (10 users)
        for (uint256 i = 0; i < users.length; i++) {
            vm.prank(users[i]);
            vaultFactory.joinMikesVault{value: 10000000000000}();
            totalExpected += 10000000000000;
        }
        
        // Create and join high-fee vaults
        vm.startPrank(owner);
        vaultFactory.createVault("Premium Vault", 10 ether);
        vm.stopPrank();
        
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(users[i]);
            vaultFactory.joinVault{value: 10 ether}(3);
            totalExpected += 10 ether;
        }
        
        assertEq(address(vaultFactory).balance, totalExpected);
        
        // Owner withdraws everything
        uint256 ownerBalanceBefore = owner.balance;
        vm.prank(owner);
        vaultFactory.withdraw();
        
        assertEq(address(vaultFactory).balance, 0);
        assertEq(owner.balance, ownerBalanceBefore + totalExpected);
    }
    
    function testSequentialOperations() public {
        // Create vault, users join, more vaults created, more joins, withdraw
        
        // Step 1: Create new vault
        vm.prank(owner);
        vaultFactory.createVault("Test Vault 1", 1 ether);
        
        // Step 2: Users join different vaults
        vm.prank(users[0]);
        vaultFactory.joinMikesVault{value: 10000000000000}();
        
        vm.prank(users[1]);
        vaultFactory.joinVault{value: 1 ether}(3);
        
        // Step 3: Create another vault
        vm.prank(owner);
        vaultFactory.createVault("Test Vault 2", 2 ether);
        
        // Step 4: More joins
        vm.prank(users[2]);
        vaultFactory.joinVault{value: 2 ether}(4);
        
        vm.prank(users[3]);
        vaultFactory.joinJohnsVault{value: 30000000000000}();
        
        // Verify state
        assertEq(vaultFactory.vaultsCount(), 5);
        assertTrue(vaultFactory.isMember(0, users[0]));
        assertTrue(vaultFactory.isMember(3, users[1]));
        assertTrue(vaultFactory.isMember(4, users[2]));
        assertTrue(vaultFactory.isMember(2, users[3]));
        
        uint256 expectedBalance = 10000000000000 + 1 ether + 2 ether + 30000000000000;
        assertEq(address(vaultFactory).balance, expectedBalance);
        
        // Step 5: Partial withdrawal simulation by checking balance
        uint256 balanceBeforeWithdraw = address(vaultFactory).balance;
        assertTrue(balanceBeforeWithdraw > 0);
    }
    
    function testVaultMembershipPersistence() public {
        // Join vaults
        vm.prank(users[0]);
        vaultFactory.joinMikesVault{value: 10000000000000}();
        
        vm.prank(users[1]);
        vaultFactory.joinJamesVault{value: 20000000000000}();
        
        // Create new vault and join
        vm.prank(owner);
        vaultFactory.createVault("Persistent Vault", 5 ether);
        
        vm.prank(users[0]); // Same user joins another vault
        vaultFactory.joinVault{value: 5 ether}(3);
        
        // Verify memberships are maintained
        assertTrue(vaultFactory.isMember(0, users[0])); // Still in Mike's
        assertTrue(vaultFactory.isMember(3, users[0])); // Also in new vault
        assertTrue(vaultFactory.isMember(1, users[1])); // Still in Jame's
        assertFalse(vaultFactory.isMember(1, users[0])); // Not in Jame's
        assertFalse(vaultFactory.isMember(0, users[1])); // Not in Mike's
    }
    
    function testGasOptimization() public {
        // Test gas usage for various operations
        uint256 gasBefore;
        uint256 gasUsed;
        
        // Test vault creation gas
        gasBefore = gasleft();
        vm.prank(owner);
        vaultFactory.createVault("Gas Test Vault", 1 ether);
        gasUsed = gasBefore - gasleft();
        
        // Should be reasonable gas usage
        assertLt(gasUsed, 200000); // Less than 200k gas
        
        // Test joining gas
        gasBefore = gasleft();
        vm.prank(users[0]);
        vaultFactory.joinMikesVault{value: 10000000000000}();
        gasUsed = gasBefore - gasleft();
        
        assertLt(gasUsed, 100000); // Less than 100k gas for joining
    }
}