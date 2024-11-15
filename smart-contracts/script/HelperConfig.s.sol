// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 deployerPrivateKey;
        address treasury;
        address developer;
        address wethUsdPriceFeed;
        address weth;
        address vrfCoordinator;
        uint256 subscriptionId;
        bytes32 keyHash;
        uint32 callbackGasLimit;
    }

    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2500e8;
    uint256 public constant DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint96 public constant BASE_FEE = 0.1 ether;
    uint96 public constant GAS_PRICE_LINK = 1e9;
    bytes32 public constant DEFAULT_KEY_HASH = bytes32("keyHash");
    uint32 public constant CALLBACK_GAS_LIMIT = 100000;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            deployerPrivateKey: vm.envUint("PRIVATE_KEY"),
            treasury: vm.envAddress("TREASURY_ADDRESS"),
            developer: vm.envAddress("DEVELOPER_ADDRESS"),
            wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            vrfCoordinator: vm.envAddress("VRF_COORDINATOR"),
            subscriptionId: uint64(vm.envUint("SUBSCRIPTION_ID")),
            keyHash: bytes32(vm.envBytes("KEY_HASH")),
            callbackGasLimit: CALLBACK_GAS_LIMIT
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.wethUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast(DEFAULT_ANVIL_PRIVATE_KEY);
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        MockERC20 wethMock = new MockERC20("WETH", "WETH", msg.sender, 1000e8);

        // Deploy VRFCoordinatorV2Mock
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(0, 0, 0);

        // Create VRF Subscription
        uint256 subscriptionId = vrfCoordinatorMock.createSubscription();
        console.log("helper - subId: %i", subscriptionId);
        console.log(subscriptionId);
        vrfCoordinatorMock.fundSubscription(subscriptionId, 1000 ether);
        console.log("helper - vrf address:");
        console.log(address(vrfCoordinatorMock));

        vm.stopBroadcast();

        return NetworkConfig({
            deployerPrivateKey: DEFAULT_ANVIL_PRIVATE_KEY,
            treasury: address(uint160(uint256(keccak256(abi.encodePacked("treasury"))))),
            developer: address(uint160(uint256(keccak256(abi.encodePacked("developer"))))),
            wethUsdPriceFeed: address(ethUsdPriceFeed),
            weth: address(wethMock),
            vrfCoordinator: address(vrfCoordinatorMock),
            subscriptionId: subscriptionId,
            keyHash: DEFAULT_KEY_HASH,
            callbackGasLimit: CALLBACK_GAS_LIMIT
        });
    }
}
