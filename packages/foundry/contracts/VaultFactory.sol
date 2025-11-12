// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// OpenZeppelin imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract VaultFactory is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

   event DepositAdded(uint256 indexed vaultId, address indexed user, uint256 amount);

   
    struct Vault {
        string name;
        uint256 joinFee;
        EnumerableSet.AddressSet members;
        mapping(address => uint256) userEthDeposits; // user address => ETH deposit amount
        uint256 totalEthDeposited;
    }

    struct UserInfo {
        uint256[] vaultIds;
        uint256[] ethDeposits;
    }

    Vault[] private vaults;

    event VaultCreated(uint256 indexed vaultId, string name, uint256 joinFee);
    event JoinedVault(uint256 indexed vaultId, address indexed user, uint256 paidFee, uint256 ethDeposit);
    event EthWithdrawn(uint256 indexed vaultId, address indexed user, uint256 amount);

    constructor() Ownable(msg.sender) {
        // 1st vault: Mike's vault, 10000000000000 wei
        _createVault("Mike's vault", 10000000000000);
        // 2nd vault: Jame's vault, 20000000000000 wei
        _createVault("Jame's vault", 20000000000000);
        // 3rd vault: John's vault, 30000000000000 wei
        _createVault("John's vault", 30000000000000);
    }

    // --- Only owner can create new vaults ---
    function createVault(string calldata name, uint256 joinFee) external onlyOwner {
        _createVault(name, joinFee);
    }
// function that lets user add amounts to his existing deposit in the vault

    function addDeposit(uint256 vaultId) external payable {
    require(vaultId < vaults.length, "Vault does not exist");
    Vault storage vault = vaults[vaultId];
    
    require(vault.members.contains(msg.sender), "Not a vault member");
    require(msg.value > 0, "Must send some ETH to add");

    // adding eth to current deposit
    vault.userEthDeposits[msg.sender] += msg.value;
    vault.totalEthDeposited += msg.value;

    // Emit DepositAdded event
    emit DepositAdded(vaultId, msg.sender, msg.value);
}


    // --- Internal vault creation logic ---
    function _createVault(string memory name, uint256 joinFee) internal {
        Vault storage newVault = vaults.push();
        newVault.name = name;
        newVault.joinFee = joinFee;
        emit VaultCreated(vaults.length - 1, name, joinFee);
    }
    /**
     * @notice Join a vault with optional ETH deposit
     * @param vaultId The ID of the vault to join
     * @param ethDepositWei Amount of ETH to deposit in wei (0 for no deposit)
     * @dev msg.value must equal exactly joinFee + ethDepositWei
     */
    function joinVault(uint256 vaultId, uint256 ethDepositWei) public payable {
        require(vaultId < vaults.length, "Vault does not exist");
        Vault storage vault = vaults[vaultId];
        require(!vault.members.contains(msg.sender), "Already joined");
        
        uint256 requiredAmount = vault.joinFee + ethDepositWei;
        require(msg.value == requiredAmount, "Exact payment required");
 

        vault.members.add(msg.sender);
        
        // Handle ETH deposit
        if (ethDepositWei > 0) {
            vault.userEthDeposits[msg.sender] = ethDepositWei;
            vault.totalEthDeposited += ethDepositWei;
        }

        emit JoinedVault(vaultId, msg.sender, vault.joinFee, ethDepositWei);
    }

 
    /**
     * @notice Shortcut functions for joining specific vaults with ETH deposit
     * @param ethDepositWei Amount of ETH to deposit in wei (0 for no deposit)
     */
    function joinMikesVault(uint256 ethDepositWei) external payable {
        joinVault(0, ethDepositWei);
    }

    function joinJamesVault(uint256 ethDepositWei) external payable {
        joinVault(1, ethDepositWei);
    }

    function joinJohnsVault(uint256 ethDepositWei) external payable {
        joinVault(2, ethDepositWei);
    }

    // --- View function: returns name, fee, and list of members ---
    function getVault(uint256 vaultId)
        external
        view
        returns (
            string memory name,
            uint256 joinFee,
            address[] memory members
        )
    {
        require(vaultId < vaults.length, "Vault does not exist");
        Vault storage vault = vaults[vaultId];

        uint256 length = vault.members.length();
        address[] memory memberList = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            memberList[i] = vault.members.at(i);
        }

        return (vault.name, vault.joinFee, memberList);
    }

    // --- Other helpers ---
    function isMember(uint256 vaultId, address user) external view returns (bool) {
        require(vaultId < vaults.length, "Vault does not exist");
        return vaults[vaultId].members.contains(user);
    }

    function vaultsCount() external view returns (uint256) {
        return vaults.length;
    }

    /**
     * @notice Calculate the total amount needed to join a vault with deposit
     * @param vaultId The vault ID
     * @param ethDepositWei The deposit amount in wei
     * @return totalRequired The total amount (joinFee + deposit) needed to send as msg.value
     */
    function calculateJoinCost(uint256 vaultId, uint256 ethDepositWei) external view returns (uint256 totalRequired) {
        require(vaultId < vaults.length, "Vault does not exist");
        return vaults[vaultId].joinFee + ethDepositWei;
    }

    // --- Withdraw all collected fees ---
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // --- DEPOSIT AND WITHDRAWAL FUNCTIONS ---

    /**
     * @notice Withdraw ETH from a vault
     * @param vaultId The vault ID to withdraw from
     * @param amount The amount to withdraw
     */
    function withdrawEth(uint256 vaultId, uint256 amount) external {
        require(vaultId < vaults.length, "Vault does not exist");
        require(vaults[vaultId].members.contains(msg.sender), "Not a vault member");
        require(amount > 0, "Amount must be greater than 0");
        require(vaults[vaultId].userEthDeposits[msg.sender] >= amount, "Insufficient ETH balance");

        vaults[vaultId].userEthDeposits[msg.sender] -= amount;
        vaults[vaultId].totalEthDeposited -= amount;

        payable(msg.sender).transfer(amount);

        emit EthWithdrawn(vaultId, msg.sender, amount);
    }

    /**
     * @notice Withdraw all ETH deposits from a vault
     * @param vaultId The vault ID to withdraw from
     */
    function withdrawAllDeposits(uint256 vaultId) external {
        require(vaultId < vaults.length, "Vault does not exist");
        require(vaults[vaultId].members.contains(msg.sender), "Not a vault member");

        // Withdraw ETH
        uint256 ethAmount = vaults[vaultId].userEthDeposits[msg.sender];
        if (ethAmount > 0) {
            vaults[vaultId].userEthDeposits[msg.sender] = 0;
            vaults[vaultId].totalEthDeposited -= ethAmount;
            payable(msg.sender).transfer(ethAmount);
            emit EthWithdrawn(vaultId, msg.sender, ethAmount);
        }
    }

    // --- USER INFO VIEW FUNCTIONS ---

    /**
     * @notice Get user's ETH deposit information for a specific vault
     * @param vaultId The vault ID
     * @param user The user address
     * @return ethAmount The ETH deposit amount
     */
    function getUserVaultDeposits(uint256 vaultId, address user) 
        external 
        view 
        returns (uint256 ethAmount) 
    {
        require(vaultId < vaults.length, "Vault does not exist");
        require(vaults[vaultId].members.contains(user), "User not a vault member");

        ethAmount = vaults[vaultId].userEthDeposits[user];
    }

    /**
     * @notice Get comprehensive user information across all vaults
     * @param user The user address
     * @return info UserInfo struct containing all user's vault memberships and deposits
     */
    function getUserInfo(address user) external view returns (UserInfo memory info) {
        uint256 totalVaults = vaults.length;
        uint256[] memory tempVaultIds = new uint256[](totalVaults);
        uint256[] memory tempEthDeposits = new uint256[](totalVaults);
        
        uint256 membershipCount = 0;
        
        for (uint256 i = 0; i < totalVaults; i++) {
            if (vaults[i].members.contains(user)) {
                tempVaultIds[membershipCount] = i;
                tempEthDeposits[membershipCount] = vaults[i].userEthDeposits[user];
                membershipCount++;
            }
        }
        
        // Create properly sized arrays
        info.vaultIds = new uint256[](membershipCount);
        info.ethDeposits = new uint256[](membershipCount);
        
        for (uint256 i = 0; i < membershipCount; i++) {
            info.vaultIds[i] = tempVaultIds[i];
            info.ethDeposits[i] = tempEthDeposits[i];
        }
    }

    /**
     * @notice Get vault's total ETH deposits information
     * @param vaultId The vault ID
     * @return totalEth Total ETH deposited in the vault
     */
    function getVaultTotalDeposits(uint256 vaultId) 
        external 
        view 
        returns (uint256 totalEth) 
    {
        require(vaultId < vaults.length, "Vault does not exist");
        totalEth = vaults[vaultId].totalEthDeposited;
    }
}