// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {NFTGame} from "src/NFTGame.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployNFTGame is Script {
    function run() external returns (NFTGame game, HelperConfig helperConfig) {
        helperConfig = new HelperConfig();
        (
        uint256 deployerKey,
        address treasury,
        address developer,
        address wethUsdPriceFeed, 
        ,
        address vrfCoordinator, 
        uint256 subscriptionId, 
        bytes32 keyHash, 
        uint32 callbackGasLimit
        ) 
        = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        game = new NFTGame(
            wethUsdPriceFeed,
            subscriptionId,
            keyHash,
            callbackGasLimit,
            vrfCoordinator,
            treasury,
            developer
        );

        // Setup after initital contract deployments
        if (block.chainid == 11155111) { // Sepolia
        } 
        else if (false) {} // add in other chains as they are used 
        else { // anvil
          // Add NFTGame contract as a consumer of the VRF subscription
          VRFCoordinatorV2_5Mock vrfCoordinatorMock = VRFCoordinatorV2_5Mock(vrfCoordinator);
          console.log("deploy - subId: %i", subscriptionId);
          vrfCoordinatorMock.addConsumer(subscriptionId, address(game));

          console.log("deploy - vrf address:");
          console.log(address(vrfCoordinatorMock));
        }

        vm.stopBroadcast();

        return (game, helperConfig);
    }
}

