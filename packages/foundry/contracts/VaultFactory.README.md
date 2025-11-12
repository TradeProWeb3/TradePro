# VaultFactory Contract

## Overview
VaultFactory is a smart contract that allows users to create and join trading vaults with specific join fees. Users can deposit ETH when joining vaults, which is managed by the contract. **All deposit amounts are specified in wei.**

## Features
- **Vault Creation**: Only the contract owner can create new vaults
- **Join Functionality**: Users can join vaults by paying the required fee and optionally deposit ETH
- **Default Vaults**: Three pre-created vaults (Mike's, Jame's, John's)
- **Membership Tracking**: Track which users are members of each vault
- **Fee Collection**: All join fees are collected and can be withdrawn by the owner
- **ETH Deposit Management**: Users can deposit ETH when joining vaults
- **Withdrawal System**: Users can withdraw their ETH deposits at any time

## Contract Functions

### Owner Functions
- `createVault(string name, uint256 joinFee)`: Create a new vault (owner only)
- `withdraw()`: Withdraw all collected fees (owner only)

### Public Functions
- `joinVault(uint256 vaultId)`: Join a specific vault by paying the fee (backward compatibility)
- `joinVault(uint256 vaultId, uint256 ethDepositWei)`: Join vault with ETH deposit (amount in wei)
- `joinMikesVault()` / `joinMikesVault(uint256 ethDepositWei)`: Join Mike's vault
- `joinJamesVault()` / `joinJamesVault(uint256 ethDepositWei)`: Join Jame's vault  
- `joinJohnsVault()` / `joinJohnsVault(uint256 ethDepositWei)`: Join John's vault
- `withdrawEth(uint256 vaultId, uint256 amount)`: Withdraw ETH from vault
- `withdrawAllDeposits(uint256 vaultId)`: Withdraw all ETH deposits from vault

### View Functions
- `getVault(uint256 vaultId)`: Get vault details (name, fee, members)
- `isMember(uint256 vaultId, address user)`: Check if user is a member
- `vaultsCount()`: Get total number of vaults
- `calculateJoinCost(uint256 vaultId, uint256 ethDepositWei)`: Calculate total cost to join vault with deposit
- `getUserVaultDeposits(uint256 vaultId, address user)`: Get user's ETH deposit in specific vault
- `getUserInfo(address user)`: Get comprehensive user information across all vaults
- `getVaultTotalDeposits(uint256 vaultId)`: Get vault's total ETH deposits

## Default Vaults
1. **Mike's vault** (ID: 0) - Fee: 10000000000000 wei
2. **Jame's vault** (ID: 1) - Fee: 20000000000000 wei  
3. **John's vault** (ID: 2) - Fee: 30000000000000 wei

## Testing

Run all tests:
```bash
forge test --match-contract VaultFactoryTest
```

Run with verbose output:
```bash
forge test --match-contract VaultFactoryTest -vv
```

Run specific test:
```bash
forge test --match-test testJoinVaultSuccess -vv
```

## Deployment

Deploy to local network:
```bash
yarn deploy --file DeployVaultFactory.s.sol
```

Deploy to specific network:
```bash
yarn deploy --file DeployVaultFactory.s.sol --network <network-name>
```

Deploy all contracts (including VaultFactory):
```bash
yarn deploy
```

## Gas Optimization Notes
- Uses OpenZeppelin's EnumerableSet for efficient member tracking
- Minimal storage usage with struct packing
- Events for off-chain monitoring

## ETH Deposit and Withdrawal Management

### Joining Vaults with Deposits

```solidity
// Calculate required payment first
uint256 ethDepositWei = 100000000; // Deposit amount in wei
uint256 totalCost = vaultFactory.calculateJoinCost(2, ethDepositWei); // John's vault

// Join vault with ETH deposit 
vaultFactory.joinVault{value: totalCost}(2, ethDepositWei);

// Or use shortcut functions
vaultFactory.joinJohnsVault{value: totalCost}(ethDepositWei);

// Manual calculation example:
uint256 joinFee = 30000000000000; // John's vault fee in wei
uint256 depositWei = 100000000;   // Deposit in wei
uint256 total = joinFee + depositWei; // Total = 30000100000000 wei
vaultFactory.joinJohnsVault{value: total}(depositWei);
```

### Managing ETH Deposits

```solidity
// Withdraw ETH from vault
vaultFactory.withdrawEth(0, 0.5 ether);

// Withdraw all ETH deposits at once
vaultFactory.withdrawAllDeposits(0);
```

### Viewing User Information

```solidity
// Get user's ETH deposits in specific vault
uint256 ethAmount = vaultFactory.getUserVaultDeposits(0, userAddress);

// Get comprehensive user info across all vaults
VaultFactory.UserInfo memory userInfo = vaultFactory.getUserInfo(userAddress);

// Get vault's total ETH deposits
uint256 totalEth = vaultFactory.getVaultTotalDeposits(0);
```

## Security Features
- Owner-only vault creation using OpenZeppelin's Ownable
- Protection against double-joining
- Exact payment validation for join fees and ETH deposits
- Member-only deposit and withdrawal functions
- Safe ETH transfer mechanism using OpenZeppelin patterns
- Input validation for vault IDs and amounts
- Proper ETH balance tracking and overflow protection