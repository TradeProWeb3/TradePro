// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../contracts/VaultFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultFactoryTest is Test {
    VaultFactory public vaultFactory;
    address public owner;
    address public user1;
    address public user2;
    address public user3;

    // Events to test
    event VaultCreated(uint256 indexed vaultId, string name, uint256 joinFee);
    event JoinedVault(uint256 indexed vaultId, address indexed user, uint256 paidFee, uint256 ethDeposit);
    event EthWithdrawn(uint256 indexed vaultId, address indexed user, uint256 amount);

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        // Deploy contract as owner
        vm.prank(owner);
        vaultFactory = new VaultFactory();

        // Give test users some ETH
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
        vm.deal(owner, 100 ether);
    }

    // ============ DEPLOYMENT TESTS ============

    function testDeploymentCreatesDefaultVaults() public {
        // Check that 3 default vaults are created
        assertEq(vaultFactory.vaultsCount(), 3);

        // Check Mike's vault
        (string memory name1, uint256 fee1, address[] memory members1) = vaultFactory.getVault(0);
        assertEq(name1, "Mike's vault");
        assertEq(fee1, 10000000000000);
        assertEq(members1.length, 0);

        // Check Jame's vault
        (string memory name2, uint256 fee2, address[] memory members2) = vaultFactory.getVault(1);
        assertEq(name2, "Jame's vault");
        assertEq(fee2, 20000000000000);
        assertEq(members2.length, 0);

        // Check John's vault
        (string memory name3, uint256 fee3, address[] memory members3) = vaultFactory.getVault(2);
        assertEq(name3, "John's vault");
        assertEq(fee3, 30000000000000);
        assertEq(members3.length, 0);
    }

    function testOwnerIsSetCorrectly() public {
        assertEq(vaultFactory.owner(), owner);
    }

    // ============ VAULT CREATION TESTS ============

    function testOnlyOwnerCanCreateVault() public {
        // Owner should be able to create vault
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit VaultCreated(3, "Test Vault", 1 ether);
        vaultFactory.createVault("Test Vault", 1 ether);

        assertEq(vaultFactory.vaultsCount(), 4);
    }

    function testNonOwnerCannotCreateVault() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        vaultFactory.createVault("Test Vault", 1 ether);
    }

    function testCreateVaultWithZeroFee() public {
        vm.prank(owner);
        vaultFactory.createVault("Free Vault", 0);
        
        (string memory name, uint256 fee, ) = vaultFactory.getVault(3);
        assertEq(name, "Free Vault");
        assertEq(fee, 0);
    }

    function testCreateVaultEmitsEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit VaultCreated(3, "New Vault", 5 ether);
        vaultFactory.createVault("New Vault", 5 ether);
    }

    // ============ JOIN VAULT TESTS ============

    function testJoinVaultSuccess() public {
        uint256 joinFee = 10000000000000; // Mike's vault fee
        
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit JoinedVault(0, user1, joinFee, 0);
        vaultFactory.joinVault{value: joinFee}(0);

        // Check user is member
        assertTrue(vaultFactory.isMember(0, user1));
        
        // Check vault member list
        (, , address[] memory members) = vaultFactory.getVault(0);
        assertEq(members.length, 1);
        assertEq(members[0], user1);
    }

    function testJoinVaultIncorrectFee() public {
        uint256 correctFee = 10000000000000;
        uint256 incorrectFee = 5000000000000;
        
        vm.prank(user1);
        vm.expectRevert("Exact payment required");
        vaultFactory.joinVault{value: incorrectFee}(0);
    }

    function testJoinVaultAlreadyJoined() public {
        uint256 joinFee = 10000000000000;
        
        // Join first time
        vm.prank(user1);
        vaultFactory.joinVault{value: joinFee}(0);
        
        // Try to join again
        vm.prank(user1);
        vm.expectRevert("Already joined");
        vaultFactory.joinVault{value: joinFee}(0);
    }

    function testJoinNonExistentVault() public {
        vm.prank(user1);
        vm.expectRevert("Vault does not exist");
        vaultFactory.joinVault{value: 1 ether}(999);
    }

    function testMultipleUsersJoinSameVault() public {
        uint256 joinFee = 10000000000000;
        
        // User1 joins
        vm.prank(user1);
        vaultFactory.joinVault{value: joinFee}(0);
        
        // User2 joins
        vm.prank(user2);
        vaultFactory.joinVault{value: joinFee}(0);
        
        // User3 joins
        vm.prank(user3);
        vaultFactory.joinVault{value: joinFee}(0);
        
        // Check all are members
        assertTrue(vaultFactory.isMember(0, user1));
        assertTrue(vaultFactory.isMember(0, user2));
        assertTrue(vaultFactory.isMember(0, user3));
        
        // Check member list
        (, , address[] memory members) = vaultFactory.getVault(0);
        assertEq(members.length, 3);
    }

    // ============ SHORTCUT JOIN FUNCTION TESTS ============

    function testJoinMikesVault() public {
        uint256 joinFee = 10000000000000;
        uint256 ethDeposit = 0; // No deposit
        
        vm.prank(user1);
        vaultFactory.joinMikesVault{value: joinFee}(ethDeposit);
        
        assertTrue(vaultFactory.isMember(0, user1));
    }

    function testJoinJamesVault() public {
        uint256 joinFee = 20000000000000;
        uint256 ethDeposit = 0; // No deposit
        
        vm.prank(user1);
        vaultFactory.joinJamesVault{value: joinFee}(ethDeposit);
        
        assertTrue(vaultFactory.isMember(1, user1));
    }

    function testJoinJohnsVault() public {
        uint256 joinFee = 30000000000000;
        uint256 ethDeposit = 0; // No deposit
        
        vm.prank(user1);
        vaultFactory.joinJohnsVault{value: joinFee}(ethDeposit);
        
        assertTrue(vaultFactory.isMember(2, user1));
    }

    function testShortcutJoinWithIncorrectFee() public {
        uint256 incorrectFee = 5000000000000;
        uint256 ethDeposit = 0;
        
        vm.prank(user1);
        vm.expectRevert("Exact payment required");
        vaultFactory.joinMikesVault{value: incorrectFee}(ethDeposit);
    }

    // ============ VIEW FUNCTION TESTS ============

    function testGetVaultNonExistent() public {
        vm.expectRevert("Vault does not exist");
        vaultFactory.getVault(999);
    }

    function testIsMemberNonExistentVault() public {
        vm.expectRevert("Vault does not exist");
        vaultFactory.isMember(999, user1);
    }

    function testIsMemberFalse() public {
        assertFalse(vaultFactory.isMember(0, user1));
    }

    function testVaultsCount() public {
        assertEq(vaultFactory.vaultsCount(), 3);
        
        vm.prank(owner);
        vaultFactory.createVault("New Vault", 1 ether);
        
        assertEq(vaultFactory.vaultsCount(), 4);
    }

    function testCalculateJoinCost() public {
        uint256 ethDeposit = 1 ether;
        
        // Test Mike's vault (fee: 10000000000000)
        uint256 mikeCost = vaultFactory.calculateJoinCost(0, ethDeposit);
        assertEq(mikeCost, 10000000000000 + ethDeposit);
        
        // Test with zero deposit
        uint256 mikeCostNoDeposit = vaultFactory.calculateJoinCost(0, 0);
        assertEq(mikeCostNoDeposit, 10000000000000);
    }

    function testCalculateJoinCostNonExistentVault() public {
        vm.expectRevert("Vault does not exist");
        vaultFactory.calculateJoinCost(999, 1 ether);
    }

    // ============ WITHDRAW TESTS ============

    function testWithdrawByOwner() public {
        // Users join and pay fees
        vm.prank(user1);
        vaultFactory.joinMikesVault{value: 10000000000000}();
        
        vm.prank(user2);
        vaultFactory.joinJamesVault{value: 20000000000000}();
        
        uint256 totalFees = 30000000000000;
        assertEq(address(vaultFactory).balance, totalFees);
        
        uint256 ownerBalanceBefore = owner.balance;
        
        vm.prank(owner);
        vaultFactory.withdraw();
        
        assertEq(address(vaultFactory).balance, 0);
        assertEq(owner.balance, ownerBalanceBefore + totalFees);
    }

    function testWithdrawByNonOwner() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        vaultFactory.withdraw();
    }

    function testWithdrawEmptyBalance() public {
        vm.prank(owner);
        vaultFactory.withdraw(); // Should not revert even with 0 balance
        
        assertEq(address(vaultFactory).balance, 0);
    }

    // ============ INTEGRATION TESTS ============

    function testCompleteWorkflow() public {
        // Owner creates a new vault
        vm.prank(owner);
        vaultFactory.createVault("Premium Vault", 1 ether);
        
        // Multiple users join different vaults
        vm.prank(user1);
        vaultFactory.joinMikesVault{value: 10000000000000}();
        
        vm.prank(user2);
        vaultFactory.joinVault{value: 1 ether}(3); // Join new vault
        
        vm.prank(user3);
        vaultFactory.joinJohnsVault{value: 30000000000000}();
        
        // Check memberships
        assertTrue(vaultFactory.isMember(0, user1));
        assertTrue(vaultFactory.isMember(3, user2));
        assertTrue(vaultFactory.isMember(2, user3));
        
        // Check contract balance
        uint256 expectedBalance = 10000000000000 + 1 ether + 30000000000000;
        assertEq(address(vaultFactory).balance, expectedBalance);
        
        // Owner withdraws all fees
        uint256 ownerBalanceBefore = owner.balance;
        vm.prank(owner);
        vaultFactory.withdraw();
        
        assertEq(owner.balance, ownerBalanceBefore + expectedBalance);
        assertEq(address(vaultFactory).balance, 0);
    }

    // ============ EDGE CASE TESTS ============

    function testJoinVaultWithZeroFee() public {
        // Create vault with zero fee
        vm.prank(owner);
        vaultFactory.createVault("Free Vault", 0);
        
        // Join with zero value
        vm.prank(user1);
        vaultFactory.joinVault{value: 0}(3);
        
        assertTrue(vaultFactory.isMember(3, user1));
    }

    function testCreateVaultWithEmptyName() public {
        vm.prank(owner);
        vaultFactory.createVault("", 1 ether);
        
        (string memory name, , ) = vaultFactory.getVault(3);
        assertEq(name, "");
    }

    function testVaultWithMaxUint256Fee() public {
        vm.prank(owner);
        vaultFactory.createVault("Expensive Vault", type(uint256).max);
        
        (, uint256 fee, ) = vaultFactory.getVault(3);
        assertEq(fee, type(uint256).max);
    }

    // ============ FUZZ TESTS ============

    function testFuzzCreateVault(string calldata name, uint256 joinFee) public {
        vm.assume(bytes(name).length > 0); // Assume non-empty name for practical purposes
        
        vm.prank(owner);
        vaultFactory.createVault(name, joinFee);
        
        uint256 vaultId = vaultFactory.vaultsCount() - 1;
        (string memory storedName, uint256 storedFee, ) = vaultFactory.getVault(vaultId);
        
        assertEq(storedName, name);
        assertEq(storedFee, joinFee);
    }

    function testFuzzJoinVault(uint256 joinFee) public {
        vm.assume(joinFee <= 100 ether); // Reasonable upper bound
        
        // Create vault with fuzzed fee
        vm.prank(owner);
        vaultFactory.createVault("Fuzz Vault", joinFee);
        
        // Give user enough ETH
        vm.deal(user1, joinFee + 1 ether);
        
        // Join vault
        vm.prank(user1);
        vaultFactory.joinVault{value: joinFee}(3);
        
        assertTrue(vaultFactory.isMember(3, user1));
        assertEq(address(vaultFactory).balance, joinFee);
    }

    // ============ GAS OPTIMIZATION TESTS ============

    function testJoinVaultGasCost() public {
        uint256 gasBefore = gasleft();
        
        vm.prank(user1);
        vaultFactory.joinMikesVault{value: 10000000000000}();
        
        uint256 gasUsed = gasBefore - gasleft();
        
        // Gas usage should be reasonable (less than 100k gas)
        assertLt(gasUsed, 100000);
    }

    // ============ DEPOSIT AND WITHDRAWAL TESTS ============

    function testJoinVaultWithEthDeposit() public {
        uint256 joinFee = 10000000000000;
        uint256 ethDeposit = 1 ether;
        uint256 totalPayment = joinFee + ethDeposit;
        
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit JoinedVault(0, user1, joinFee, ethDeposit);
        vaultFactory.joinVault{value: totalPayment}(0, ethDeposit);

        assertTrue(vaultFactory.isMember(0, user1));
        
        // Check deposit was recorded
        uint256 userEthAmount = vaultFactory.getUserVaultDeposits(0, user1);
        assertEq(userEthAmount, ethDeposit);
        
        // Check vault total
        uint256 totalEth = vaultFactory.getVaultTotalDeposits(0);
        assertEq(totalEth, ethDeposit);
    }

    function testJoinVaultInsufficientPayment() public {
        uint256 joinFee = 10000000000000;
        uint256 ethDeposit = 1 ether;
        uint256 insufficientPayment = joinFee + ethDeposit - 1;
        
        vm.prank(user1);
        vm.expectRevert("Exact payment required");
        vaultFactory.joinVault{value: insufficientPayment}(0, ethDeposit);
    }

    function testJoinVaultExcessivePayment() public {
        uint256 joinFee = 10000000000000;
        uint256 ethDeposit = 1 ether;
        uint256 excessivePayment = joinFee + ethDeposit + 1;
        
        vm.prank(user1);
        vm.expectRevert("Exact payment required");
        vaultFactory.joinVault{value: excessivePayment}(0, ethDeposit);
    }

    function testWithdrawEth() public {
        uint256 joinFee = 10000000000000;
        uint256 ethDeposit = 1 ether;
        uint256 totalPayment = joinFee + ethDeposit;
        uint256 withdrawAmount = 0.5 ether;
        
        // Join with ETH deposit
        vm.prank(user1);
        vaultFactory.joinVault{value: totalPayment}(0, ethDeposit);
        
        uint256 balanceBefore = user1.balance;
        
        // Withdraw ETH
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit EthWithdrawn(0, user1, withdrawAmount);
        vaultFactory.withdrawEth(0, withdrawAmount);
        
        // Check user balance increased
        assertEq(user1.balance, balanceBefore + withdrawAmount);
        
        // Check deposit reduced
        uint256 userEthAmount = vaultFactory.getUserVaultDeposits(0, user1);
        assertEq(userEthAmount, ethDeposit - withdrawAmount);
    }

    function testWithdrawEthInsufficientBalance() public {
        uint256 joinFee = 10000000000000;
        uint256 ethDeposit = 1 ether;
        uint256 totalPayment = joinFee + ethDeposit;
        
        vm.prank(user1);
        vaultFactory.joinVault{value: totalPayment}(0, ethDeposit);
        
        vm.prank(user1);
        vm.expectRevert("Insufficient ETH balance");
        vaultFactory.withdrawEth(0, ethDeposit + 1);
    }

    function testWithdrawAllDeposits() public {
        uint256 joinFee = 10000000000000;
        uint256 ethDeposit = 1 ether;
        
        // Setup: join with ETH deposit
        vm.prank(user1);
        vaultFactory.joinVault{value: joinFee + ethDeposit}(0, ethDeposit);
        
        uint256 ethBalanceBefore = user1.balance;
        
        // Withdraw all
        vm.prank(user1);
        vaultFactory.withdrawAllDeposits(0);
        
        // Check ETH balance returned
        assertEq(user1.balance, ethBalanceBefore + ethDeposit);
        
        // Check deposits are zero
        uint256 userEthAmount = vaultFactory.getUserVaultDeposits(0, user1);
        assertEq(userEthAmount, 0);
    }

    function testGetUserInfo() public {
        uint256 joinFee1 = 10000000000000; // Mike's vault
        uint256 joinFee2 = 20000000000000; // Jame's vault
        uint256 ethDeposit1 = 1 ether;
        uint256 ethDeposit2 = 2 ether;
        
        // Join multiple vaults
        vm.prank(user1);
        vaultFactory.joinVault{value: joinFee1 + ethDeposit1}(0, ethDeposit1);
        vm.prank(user1);
        vaultFactory.joinVault{value: joinFee2 + ethDeposit2}(1, ethDeposit2);
        
        // Get user info
        VaultFactory.UserInfo memory userInfo = vaultFactory.getUserInfo(user1);
        
        assertEq(userInfo.vaultIds.length, 2);
        assertEq(userInfo.vaultIds[0], 0);
        assertEq(userInfo.vaultIds[1], 1);
        assertEq(userInfo.ethDeposits[0], ethDeposit1);
        assertEq(userInfo.ethDeposits[1], ethDeposit2);
    }

    function testShortcutFunctionsWithDeposit() public {
        uint256 ethDeposit = 1 ether;
        
        // Test Mike's vault
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit JoinedVault(0, user1, 10000000000000, ethDeposit);
        vaultFactory.joinMikesVault{value: 10000000000000 + ethDeposit}(ethDeposit);
        
        uint256 userEthAmount = vaultFactory.getUserVaultDeposits(0, user1);
        assertEq(userEthAmount, ethDeposit);
    }

    function testJoinWithoutDeposit() public {
        // Test joining vault with 0 deposit
        uint256 ethDeposit = 0;
        vm.prank(user1);
        vaultFactory.joinMikesVault{value: 10000000000000}(ethDeposit);
        
        assertTrue(vaultFactory.isMember(0, user1));
        
        uint256 userEthAmount = vaultFactory.getUserVaultDeposits(0, user1);
        assertEq(userEthAmount, 0); // No deposit
    }
}