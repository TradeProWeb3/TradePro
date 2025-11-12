// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./DeployHelpers.s.sol";
import "../contracts/VaultFactory.sol";
import "forge-std/console.sol";

/**
 * @notice Deploy script for VaultFactory contract
 * @dev Inherits ScaffoldETHDeploy which:
 *      - Includes forge-std/Script.sol for deployment
 *      - Includes ScaffoldEthDeployerRunner modifier
 *      - Provides `deployer` variable
 * Example:
 * yarn deploy --file DeployVaultFactory.s.sol  # local anvil chain
 * yarn deploy --file DeployVaultFactory.s.sol --network optimism # live network (requires keystore)
 */
contract DeployVaultFactory is ScaffoldETHDeploy {
    /**
     * @dev Deployer setup based on `ETH_KEYSTORE_ACCOUNT` in `.env`:
     *      - "scaffold-eth-default": Uses Anvil's account #9 (0xa0Ee7A142d267C1f36714E4a8F75612F20a79720), no password prompt
     *      - "scaffold-eth-custom": requires password used while creating keystore
     *
     * Note: Must use ScaffoldEthDeployerRunner modifier to:
     *      - Setup correct `deployer` account and fund it
     *      - Export contract addresses & ABIs to `nextjs` packages
     */
    function run() external ScaffoldEthDeployerRunner {
        // Deploy VaultFactory contract
        VaultFactory vaultFactory = new VaultFactory();
        
        console.log("VaultFactory deployed to:", address(vaultFactory));
        console.log("Owner set to:", vaultFactory.owner());
        console.log("Total vaults created:", vaultFactory.vaultsCount());
        
        // Log default vaults information
        for (uint256 i = 0; i < vaultFactory.vaultsCount(); i++) {
            (string memory name, uint256 joinFee, ) = vaultFactory.getVault(i);
            console.log("Vault ID:", i);
            console.log("Name:", name);
            console.log("Join fee:", joinFee, "wei");
            console.log("---");
        }
    }
}