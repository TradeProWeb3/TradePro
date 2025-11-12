//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./DeployHelpers.s.sol";
import { DeployVaultFactory } from "./DeployVaultFactory.s.sol";

/**
 * @notice Main deployment script for VaultFactory contract
 * @dev Run this when you want to deploy VaultFactory
 *
 * Example: yarn deploy # runs this script(without`--file` flag)
 */
contract DeployScript is ScaffoldETHDeploy {
    function run() external {
        // Deploy VaultFactory contract
        DeployVaultFactory deployVaultFactory = new DeployVaultFactory();
        deployVaultFactory.run();
    }
}
