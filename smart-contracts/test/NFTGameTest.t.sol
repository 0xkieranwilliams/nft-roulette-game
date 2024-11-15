// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {MockNFT} from "./mocks/MockNFT.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployNFTGame} from "script/DeployNFTGame.s.sol";
import {NFTGame} from "src/NFTGame.sol";


contract NFTGameTest is Test {

    NFTGame public game;
    HelperConfig public helperConfig;
    MockNFT public mockNFT;
    address wethUsdPriceFeedAddress;
    AggregatorV3Interface public wethUsdPriceFeed;
    address vrfCoordinatorMockAddress;
    VRFCoordinatorV2_5Mock public vrfCoordinatorMock;
    uint256 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit;
 
    uint256 public deployerKey;
    address public deployer;
    address public treasury;
    address public developer;
    address public gameCreator;
    address public player1;
    address public player2; 

    uint256 private constant INITIAL_BALANCE = 10 ether;
    uint256 private constant FLOOR_PRICE = 1 ether;
    uint256 private constant GAME_DURATION = 7 days;
    bytes32 private constant SALT = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;

    event RandomnessRequested(uint256 indexed requestId, uint256 indexed gameId);

    function setUp() public {


        gameCreator = address(uint160(uint256(keccak256(abi.encodePacked("gameCreator")))));
        player1 = address(uint160(uint256(keccak256(abi.encodePacked("player1"))))); 
        player2 = address(uint160(uint256(keccak256(abi.encodePacked("player2")))));


        vm.deal(gameCreator, INITIAL_BALANCE);
        vm.deal(player1, INITIAL_BALANCE);
        vm.deal(player2, INITIAL_BALANCE);

        // Deploy NFTGame contract with the VRFCoordinatorV2Mock address and other parameters
        DeployNFTGame nftGameDeployer = new DeployNFTGame();
        (game, helperConfig) = nftGameDeployer.run();

        (deployerKey, treasury, developer,  wethUsdPriceFeedAddress, , vrfCoordinatorMockAddress, subscriptionId, , ) = helperConfig.activeNetworkConfig();

        wethUsdPriceFeed = AggregatorV3Interface(wethUsdPriceFeedAddress);
        console.log("vrf contract address");
        console.log(vrfCoordinatorMockAddress);
        vrfCoordinatorMock = VRFCoordinatorV2_5Mock(vrfCoordinatorMockAddress);
        console.log("weiiii-----------");
        console.log(vrfCoordinatorMock.i_wei_per_unit_link());
        console.log("weiiii-----------");


        // Deploy MockNFT
        mockNFT = new MockNFT();
    }

    function testInitialization() public view {
        assertEq(game.i_treasuryAddress(), treasury);
        assertEq(game.i_developerAddress(), developer);
        assertEq(game.s_gameCounter(), 0);
    }

    function testCreateGame() public {
        uint256 tokenId = 1;
        uint256 floorPrice = 1 ether;

        // Mint NFT to game creator
        mockNFT.mint(gameCreator, tokenId);

        // Approve game contract to transfer NFT
        vm.prank(gameCreator);
        mockNFT.approve(address(game), tokenId);

        // Create game
        vm.prank(gameCreator);
        game.createGame
            {value: 0.1 ether + ((floorPrice * 3)/ 100)}
            (address(mockNFT), tokenId, floorPrice, SALT, GAME_DURATION);

        // Check game details
        (
            address nftOwner,
            address nftContract,
            uint256 gameTokenId,
            uint256 endTime,
            uint256 totalFunds,
            bool isActive,
            bool isCanceled,
            bool nftClaimed,
            uint256 playerCount,
            uint256 minContribution,
            uint256 gameFloorPrice,
        ) = game.s_games(0);

        assertEq(nftOwner, gameCreator);
        assertEq(nftContract, address(mockNFT));
        assertEq(gameTokenId, tokenId);
        assertEq(endTime, block.timestamp + GAME_DURATION);
        assertEq(totalFunds, 0);
        assertTrue(isActive);
        assertFalse(isCanceled);
        assertFalse(nftClaimed);
        assertEq(playerCount, 0);
        assertEq(minContribution, game.BASE_MIN_CONTRIBUTION());
        assertEq(gameFloorPrice, floorPrice);

        // Check game counter
        assertEq(game.s_gameCounter(), 1);

        // Check NFT ownership
        assertEq(mockNFT.ownerOf(tokenId), address(game));
    }

    function testFailCreateGameNotOwner() public {
        uint256 tokenId = 1;
        uint256 floorPrice = 1 ether;

        // Mint NFT to a different address
        mockNFT.mint(address(6), tokenId);

        // Try to create game with NFT not owned by gameCreator
        vm.prank(gameCreator);
        game.createGame
            {value: 0.1 ether + ((floorPrice * 3)/ 100)}
            (address(mockNFT), tokenId, floorPrice, SALT, GAME_DURATION);
    }

    function testGetRequiredFee() public view {
        uint256 floorPriceInETH = 1 ether;
        uint256 requiredFee = game.getRequiredFee(floorPriceInETH);

        // Expected required fee calculation:
        // ETH/USD price = $2500 * 1e8
        uint256 ethPriceInUSD = 2500 * 1e8;

        // Floor price in USD (with 8 decimals)
        uint256 floorPriceInUSD = (floorPriceInETH * ethPriceInUSD) / 1e18;

        // 3% of the floor price in USD
        uint256 threePercentOfFloorPrice = (floorPriceInUSD * 3) / 100;

        // Total required fee in USD
        uint256 totalFeeInUSD = (15 * 1e8) + threePercentOfFloorPrice;

        // Convert total required fee to ETH
        uint256 expectedRequiredFeeInETH = (totalFeeInUSD * 1e18) / ethPriceInUSD;

        // Now, assert that requiredFee == expectedRequiredFeeInETH
        assertEq(requiredFee, expectedRequiredFeeInETH, "Required fee should match expected value");
    }

    function testCreateGameWithInsufficientFee() public {
        uint256 tokenId = 1;
        uint256 floorPrice = 1 ether;

        // Mint NFT to game creator
        mockNFT.mint(gameCreator, tokenId);

        // Approve game contract to transfer NFT
        vm.prank(gameCreator);
        mockNFT.approve(address(game), tokenId);

        // Compute required fee
        uint256 requiredFee = game.getRequiredFee(floorPrice);

        // Try to create game with insufficient fee
        vm.prank(gameCreator);
        vm.expectRevert(
            abi.encodeWithSelector(
                NFTGame.NFTGame__InsufficientCreationFee.selector,
                requiredFee,
                requiredFee - 1
            )
        );
        game.createGame{value: requiredFee - 1}(address(mockNFT), tokenId, floorPrice, SALT, GAME_DURATION);

        // Now try to create game with sufficient fee
        vm.prank(gameCreator);
        game.createGame{value: requiredFee}(address(mockNFT), tokenId, floorPrice, SALT, GAME_DURATION);

        // Check that the game is created
        uint256 gameId = 0;
        (address nftOwner,,,,,,,,,,,) = game.s_games(gameId);
        assertEq(nftOwner, gameCreator, "Game should be created by gameCreator");
    }

    function testFailCreateGameZeroFloorPrice() public {
        uint256 tokenId = 1;
        uint256 floorPrice = 0;

        // Mint NFT to game creator
        mockNFT.mint(gameCreator, tokenId);

        // Approve game contract to transfer NFT
        vm.prank(gameCreator);
        mockNFT.approve(address(game), tokenId);

        // Try to create game with zero floor price
        vm.prank(gameCreator);
        game.createGame
            {value: 0.1 ether + ((floorPrice * 3)/ 100)}
            (address(mockNFT), tokenId, floorPrice, SALT, GAME_DURATION);
    }

    function testGetPlayerActiveGames() public {
        uint256 tokenId1 = 1;
        uint256 tokenId2 = 2;
        uint256 floorPrice = 1 ether;
        uint256 contributionAmount1 = 0.04 ether;
        uint256 contributionAmount2 = 0.08 ether;

        // Mint NFTs to game creator
        mockNFT.mint(gameCreator, tokenId1);
        mockNFT.mint(gameCreator, tokenId2);

        // Approve game contract to transfer NFTs
        vm.startPrank(gameCreator);
        mockNFT.approve(address(game), tokenId1);
        mockNFT.approve(address(game), tokenId2);

        // Create games
        game.createGame
            {value: 0.1 ether + ((floorPrice * 3)/ 100)}
            (address(mockNFT), tokenId1, floorPrice, SALT, GAME_DURATION);
        game.createGame
            {value: 0.1 ether + ((floorPrice * 3)/ 100)}
            (address(mockNFT), tokenId2, floorPrice, bytes32(uint256(SALT) - 100), GAME_DURATION);
        vm.stopPrank();

        vm.deal(player1, 1 ether);
        vm.startPrank(player1);
        game.allocateFunds{value: contributionAmount1}(0);
        game.allocateFunds{value: contributionAmount2}(1);
        vm.stopPrank();

        // Check active games for game creator
        uint256[] memory activeGames = game.getPlayerActiveGames(player1);
        assertEq(activeGames.length, 2);
        assertEq(activeGames[0], 0);
        assertEq(activeGames[1], 1);
    }

    function testGetCreatorActiveGames() public {
        uint256 tokenId1 = 1;
        uint256 tokenId2 = 2;
        uint256 floorPrice = 1 ether;

        // Mint NFTs to game creator
        mockNFT.mint(gameCreator, tokenId1);
        mockNFT.mint(gameCreator, tokenId2);

        // Approve game contract to transfer NFTs
        vm.startPrank(gameCreator);
        mockNFT.approve(address(game), tokenId1);
        mockNFT.approve(address(game), tokenId2);

        // Create games
        game.createGame
            {value: 0.1 ether + ((floorPrice * 3)/ 100)}
            (address(mockNFT), tokenId1, floorPrice, SALT, GAME_DURATION);
        game.createGame
            {value: 0.1 ether + ((floorPrice * 3)/ 100)}
            (address(mockNFT), tokenId2, floorPrice, bytes32(uint256(SALT) - 100), GAME_DURATION);
        vm.stopPrank();

        // Check active games for game creator
        uint256[] memory activeGames = game.getCreatorActiveGames(gameCreator);
        assertEq(activeGames.length, 2);
        assertEq(activeGames[0], 0);
        assertEq(activeGames[1], 1);
    }

    // Additional Tests for allocateFunds with multiple players
    function testAllocateFundsMultiplePlayers() public {
        uint256 tokenId = 1;
        uint256 floorPrice = 1 ether;
        uint256 contributionAmount1 = 0.02 ether;
        uint256 contributionAmount2 = 0.08 ether;

        // Mint NFT to game creator and create a game
        mockNFT.mint(gameCreator, tokenId);
        vm.prank(gameCreator);
        mockNFT.approve(address(game), tokenId);
        vm.prank(gameCreator);
        game.createGame
            {value: 0.1 ether + ((floorPrice * 3)/ 100)}
            (address(mockNFT), tokenId, floorPrice, SALT, GAME_DURATION);

        // First player contributes
        vm.deal(player1, 1 ether); // Give player1 some ether
        vm.startPrank(player1); // Start prank for player1
        game.allocateFunds{value: contributionAmount1}(0);
        vm.stopPrank(); // Stop prank for player1

        // Second player contributes
        vm.deal(player2, 1 ether); // Give player2 some ether
        vm.startPrank(player2); // Start prank for player2
        game.allocateFunds{value: contributionAmount2}(0);
        vm.stopPrank(); // Stop prank for player2

        // Check total funds
        (,,,, uint256 totalFunds,,,,,,,) = game.s_games(0);
        assertEq(totalFunds, contributionAmount1 + contributionAmount2);

        // Check player contributions
        uint256 playerContribution1 = game.s_playerContributions(0, player1);
        assertEq(playerContribution1, contributionAmount1);
        uint256 playerContribution2 = game.s_playerContributions(0, player2);
        assertEq(playerContribution2, contributionAmount2);
    }

    function testFailAllocateFundsBelowMinimum() public {
        uint256 tokenId = 1;
        uint256 floorPrice = 1 ether;
        uint256 contributionAmount = 0.005 ether; // Below min contribution

        // Mint NFT to game creator and create a game
        mockNFT.mint(gameCreator, tokenId);
        vm.prank(gameCreator);
        mockNFT.approve(address(game), tokenId);
        vm.prank(gameCreator);
        game.createGame
            {value: 0.1 ether + ((floorPrice * 3)/ 100)}
            (address(mockNFT), tokenId, floorPrice, SALT, GAME_DURATION);

        // Try to allocate less than the minimum contribution
        vm.prank(player1);
        game.allocateFunds{value: contributionAmount}(0); // This should fail
    }

function testMinContributionScalingWithTotalFunds() public view {
    console.log("| Floor Price (wei) | Total Funds Ratio | Total Funds (wei) | Min Contribution (wei) |");
    console.log("|-------------------|-------------------|-------------------|------------------------|");

    for (uint256 i = 1; i <= 40; i++) {
        uint256 floorPrice = i * 0.2 ether;
        
        for (uint256 j = 0; j <= 14; j++) {
            uint256 totalFundsRatio = j * 10; // 0%, 10%, 20%, ..., 200% of floor price
            uint256 totalFunds = (floorPrice * totalFundsRatio) / 100;
            
            uint256 minContribution = game.calculateMinContribution(totalFunds, floorPrice);

            console.log(
                string(
                    abi.encodePacked(
                        "| ",
                        padRight(uint2str(floorPrice), 18),
                        "| ",
                        padRight(string(abi.encodePacked(uint2str(totalFundsRatio), "%")), 18),
                        "| ",
                        padRight(uint2str(totalFunds), 18),
                        "| ",
                        padRight(uint2str(minContribution), 23),
                        "|"
                    )
                )
            );
        }
        
        console.log("|-------------------|-------------------|-------------------|------------------------|");
    }
}

function testMinContributionSquareRootScaling() public {
        uint256 tokenId = 1;
        uint256 floorPrice = 1 ether;
        uint256 initialContribution = 0.02 ether;

        // Mint NFT to game creator and create a game
        mockNFT.mint(gameCreator, tokenId);
        vm.prank(gameCreator);
        mockNFT.approve(address(game), tokenId);
        vm.prank(gameCreator);
        game.createGame
            {value: 0.1 ether + ((floorPrice * 3)/ 100)}
            (address(mockNFT), tokenId, floorPrice, SALT, GAME_DURATION);

        (,,,,,,,,, uint256 minContributionAfterInitial,,) = game.s_games(0);
        assertEq(minContributionAfterInitial, game.BASE_MIN_CONTRIBUTION());

        // Initial contribution by player1
        vm.deal(player1, 2 ether); // Give player1 some ether
        vm.startPrank(player1);
        game.allocateFunds{value: initialContribution}(0);
        vm.stopPrank();

        // Check the min contribution after initial contribution
        (,,,,,,,,, uint256 minContributionAfterSmall,,) = game.s_games(0);
        
        // The minimum contribution should have increased after the initial contribution
        assert(minContributionAfterSmall > minContributionAfterInitial);

        // Add a large contribution
        uint256 largeContribution = 0.5 ether;
        vm.deal(player2, 2 ether);
        vm.startPrank(player2);
        game.allocateFunds{value: largeContribution}(0);
        vm.stopPrank();

        // Check the min contribution after a large contribution
        (,,,,,,,,, uint256 minContributionAfterLarge,,) = game.s_games(0);

        // The minimum contribution should have increased more significantly after a large contribution
        assert(minContributionAfterLarge > minContributionAfterSmall);

        // Calculate expected min contribution
        uint256 totalFunds = initialContribution + largeContribution;
        uint256 expectedMinContribution = game.calculateMinContribution(totalFunds, floorPrice);

        // Assert that the actual min contribution matches the expected value
        assertEq(minContributionAfterLarge, expectedMinContribution);

        // Add several smaller contributions to test the square root scaling
        uint256 numSmallContributions = 10;
        uint256 smallContributionAmount = 0.05 ether;
        uint256 previousMinContribution = minContributionAfterLarge;

        for (uint256 i = 0; i < numSmallContributions; i++) {
            address newPlayer = address(uint160(6 + i)); // Create new player addresses
            vm.deal(newPlayer, 1 ether); // Give new players some ether
            vm.startPrank(newPlayer);
            (,,,,,,,,, uint256 currentMinContribution,,) = game.s_games(0);
            game.allocateFunds{value: smallContributionAmount + currentMinContribution}(0);
            vm.stopPrank();

            // Check that the min contribution is increasing, but at a decreasing rate
            (,,,,,,,,, uint256 newMinContribution,,) = game.s_games(0);
            assert(newMinContribution >= currentMinContribution);
            if (i > 0) {
                assert(newMinContribution - currentMinContribution <= currentMinContribution - previousMinContribution);
            }
            previousMinContribution = currentMinContribution;
        }

        // Check the final min contribution
        (,,,,,,,,, uint256 finalMinContribution,,) = game.s_games(0);

        // Assert that the final min contribution is less than or equal to the maximum allowed (8% of floor price)
        assert(finalMinContribution <= (floorPrice * 8) / 100);

        // Assert that the final min contribution is greater than the initial BASE_MIN_CONTRIBUTION
        assert(finalMinContribution > game.BASE_MIN_CONTRIBUTION());
    }

    function testEndGameBasicScenario() public {
        // Create and set up a game
        uint256 tokenId = 1;
        mockNFT.mint(gameCreator, tokenId);
        console.log(mockNFT.ownerOf(tokenId));
        vm.startPrank(gameCreator);
        mockNFT.approve(address(game), tokenId);
        game.createGame
            {value: 0.1 ether + ((FLOOR_PRICE * 3)/ 100)}
            (address(mockNFT), tokenId, FLOOR_PRICE, SALT, GAME_DURATION);
        console.log(mockNFT.ownerOf(tokenId));
        vm.stopPrank();

        // Players contribute
        vm.prank(player1);
        game.allocateFunds{value: 0.5 ether}(0);
        vm.prank(player2);
        game.allocateFunds{value: 0.7 ether}(0);

        // Fast forward to end of game
        vm.warp(block.timestamp + GAME_DURATION + 1);

        // End the game
        vm.prank(gameCreator);
        game.endGame(0);

        console.log("Is NFTGame registered as consumer:", vrfCoordinatorMock.consumerIsAdded(subscriptionId, address(game)));
        console.log("test - subId: %i", subscriptionId);
        vrfCoordinatorMock.fulfillRandomWords(1, address(game));
        console.log(mockNFT.ownerOf(tokenId));
        console.log("in test herre");

        // Verify game state
        (,,,, uint256 totalFunds, bool isActive,,,,,,) = game.s_games(0);
        assertFalse(isActive);
        assertEq(totalFunds, 1.2 ether);

        // Verify NFT transfer (winner is either player1 or player2)
        address nftOwner = mockNFT.ownerOf(tokenId);
        assertTrue(nftOwner == player1 || nftOwner == player2);
    }

    function testEndGameOnlyCreatorCanEnd() public {
        // Create and set up a game
        uint256 tokenId = 1;
        mockNFT.mint(gameCreator, tokenId);
        vm.startPrank(gameCreator);
        mockNFT.approve(address(game), tokenId);
        game.createGame
            {value: 0.1 ether + ((FLOOR_PRICE * 3)/ 100)}
            (address(mockNFT), tokenId, FLOOR_PRICE, SALT, GAME_DURATION);
        vm.stopPrank();

        // Fast forward to end of game
        vm.warp(block.timestamp + GAME_DURATION + 1);

        // Try to end game as non-creator (should fail)
        vm.prank(player1);
        vm.expectRevert(NFTGame.NFTGame__CallerMustBeGameCreator.selector);
        game.endGame(0);

        // End game as creator (should succeed)
        vm.prank(gameCreator);
        game.endGame(0);
    }

    function testEndGameCannotEndBeforeEndTime() public {
        // Create and set up a game
        uint256 tokenId = 1;
        mockNFT.mint(gameCreator, tokenId);
        vm.startPrank(gameCreator);
        mockNFT.approve(address(game), tokenId);
        game.createGame
            {value: 0.1 ether + ((FLOOR_PRICE * 3)/ 100)}
            (address(mockNFT), tokenId, FLOOR_PRICE, SALT, GAME_DURATION);
        vm.stopPrank();

        // Try to end game before end time (should fail)
        vm.prank(gameCreator);
        vm.expectRevert(NFTGame.NFTGame__GameCanNotEndBeforeSetEndTime.selector);
        game.endGame(0);
    }

    function testEndGameFundDistribution() public {
        // Create and set up a game
        uint256 tokenId = 1;
        mockNFT.mint(gameCreator, tokenId);
        vm.startPrank(gameCreator);
        mockNFT.approve(address(game), tokenId);
        game.createGame
            {value: 0.1 ether + ((FLOOR_PRICE * 3)/ 100)}
            (address(mockNFT), tokenId, FLOOR_PRICE, SALT, GAME_DURATION);
        vm.stopPrank();

        // Players contribute
        vm.prank(player1);
        game.allocateFunds{value: 1 ether}(0);
        vm.prank(player2);
        game.allocateFunds{value: 1 ether}(0);

        // Fast forward to end of game
        vm.warp(block.timestamp + GAME_DURATION + 1);

        // Record balances before ending game
        uint256 treasuryBalanceBefore = treasury.balance;
        uint256 developerBalanceBefore = developer.balance;
        uint256 creatorBalanceBefore = gameCreator.balance;

        // End the game
        vm.prank(gameCreator);
        game.endGame(0);

        // Calculate expected distributions
        uint256 totalFunds = 2 ether;
        uint256 expectedTreasuryFee = (totalFunds * game.TREASURY_FEE_NORMAL_END()) / 100;
        uint256 expectedDeveloperFee = (totalFunds * game.DEVELOPER_FEE()) / 100;
        uint256 expectedCreatorAmount = totalFunds - expectedTreasuryFee - expectedDeveloperFee;

        // Verify fund distribution
        assertEq(treasury.balance - treasuryBalanceBefore, expectedTreasuryFee);
        assertEq(developer.balance - developerBalanceBefore, expectedDeveloperFee);
        assertEq(gameCreator.balance - creatorBalanceBefore, expectedCreatorAmount);
    }

    function testPlayerBandChangesCorrectly() public {
        uint256 tokenId = 1;
        uint256 floorPrice = 1 ether;

        // Mint NFT to game creator and create a game
        mockNFT.mint(gameCreator, tokenId);
        vm.prank(gameCreator);
        mockNFT.approve(address(game), tokenId);
        vm.prank(gameCreator);
        game.createGame
            {value: 0.1 ether + ((floorPrice * 3)/ 100)}
            (address(mockNFT), tokenId, floorPrice, SALT, GAME_DURATION);

        // Player contributes an initial amount that places them in Band 1
        vm.deal(player1, 10 ether);
        uint256 initialContribution = 0.04 ether; // 4% of floor price
        vm.prank(player1);
        game.allocateFunds{value: initialContribution}(0);

        // Verify player's initial band is Band 1
        uint8 initialBand = game.s_playerActiveBand(0, player1);
        assertEq(initialBand, 1, "Player should be in Band 1 after initial contribution");

        // Verify that player is in the correct band array
        address[] memory playersInInitialBand = game.getPlayersInBand(0, initialBand);
        assertEq(playersInInitialBand.length, 1, "There should be 1 player in Band 1");
        assertEq(playersInInitialBand[0], player1, "Player1 should be in Band 1");

        // Player contributes additional funds to move to Band 4
        uint256 additionalContribution = 0.08 ether; // Total contribution becomes 0.12 ether (48% of floor price)
        vm.prank(player1);
        game.allocateFunds{value: additionalContribution}(0);

        // Verify player's new band is Band 4
        uint8 newBand = game.s_playerActiveBand(0, player1);
        assertEq(newBand, 4, "Player should be in Band 4 after additional contribution");

        // Verify that player is no longer in the old band
        playersInInitialBand = game.getPlayersInBand(0, initialBand);
        assertEq(playersInInitialBand.length, 0, "Band 1 should have 0 players after band change");

        // Verify that player is in the new band array
        address[] memory playersInNewBand = game.getPlayersInBand(0, newBand);
        assertEq(playersInNewBand.length, 1, "There should be 1 player in the new band");
        assertEq(playersInNewBand[0], player1, "Player1 should be in Band 4");

        // Verify internal mappings are updated correctly
        uint256 playerIndexInNewBand = game.getPlayerIndexInBand(0, player1);
        assertEq(playerIndexInNewBand, 0, "Player's index in new band should be 0");

        // Verify that the player's contribution is updated
        uint256 totalContribution = game.s_playerContributions(0, player1);
        assertEq(
            totalContribution,
            initialContribution + additionalContribution,
            "Player's total contribution should be updated"
        );

        // Verify that the player's index in the old band mapping has been cleared
        uint256 playerIndexInOldBand = game.s_playerIndexInBand(0, player1);
        assertEq(playerIndexInOldBand, 0, "Player's index in old band mapping should be reset to 0");
    }



    function testForceEndGameBeforeGracePeriod() public {
        uint256 tokenId = 1;
        uint256 floorPrice = 1 ether;

        // Create a game
        _createGame(tokenId, floorPrice);

        // Try to force end the game before the grace period
        vm.prank(player1);
        vm.expectRevert(NFTGame.NFTGame__GameCanNotEndBeforeGracePeriodIsOver.selector);
        game.forceEndGame(0);
    }

    function testForceEndGameAfterGracePeriod() public {
        uint256 tokenId = 1;
        uint256 floorPrice = 1 ether;

        // Create a game
        _createGame(tokenId, floorPrice);

        // Allocate funds
        _allocateFunds(player1, 0.5 ether);
        _allocateFunds(player2, 0.5 ether);

        // Fast forward to after the grace period
        vm.warp(block.timestamp + GAME_DURATION + game.GRACE_PERIOD() + 1);

        // Record balances before force ending
        uint256 forceEndInitiatorBalanceBefore = address(player1).balance;
        uint256 gameCreatorBalanceBefore = gameCreator.balance;
        uint256 treasuryBalanceBefore = treasury.balance;
        uint256 developerBalanceBefore = developer.balance;

        // Force end the game
        vm.prank(player1);
        uint256 gasBefore = gasleft();
        game.forceEndGame(0);
        uint256 gasUsed = gasBefore - gasleft();

        // Check game state
        (,,,, uint256 totalFunds, bool isActive, bool isCanceled, bool nftClaimed,,,,) = game.s_games(0);
        assertFalse(isActive);
        assertFalse(isCanceled);
        assertTrue(nftClaimed);

        // Calculate expected distributions
        uint256 expectedTreasuryFee = (totalFunds * game.TREASURY_FEE_FORCED_END()) / 100;
        uint256 expectedDeveloperFee = (totalFunds * game.DEVELOPER_FEE()) / 100;
        uint256 expectedForceEndReward = (totalFunds * game.FORCE_END_REWARD_PERCENTAGE()) / 100;
        uint256 expectedGameCreatorAmount = totalFunds - expectedTreasuryFee - expectedDeveloperFee - expectedForceEndReward;

        // Check fee distribution
        assertEq(treasury.balance - treasuryBalanceBefore, expectedTreasuryFee, "Treasury fee incorrect");
        assertEq(developer.balance - developerBalanceBefore, expectedDeveloperFee, "Developer fee incorrect");
        assertEq(address(player1).balance - forceEndInitiatorBalanceBefore, expectedForceEndReward, "Force end reward incorrect");
        assertEq(gameCreator.balance - gameCreatorBalanceBefore, expectedGameCreatorAmount, "Game creator amount incorrect");

        // Check that the force end reward is more than the gas cost
        uint256 gasPrice = tx.gasprice;
        uint256 gasCost = gasUsed * gasPrice;
        assertTrue(expectedForceEndReward > gasCost, "Force end reward should be greater than gas cost");
    }

    function testForceEndGameRewardComparison() public {
        uint256 tokenId = 1;
        uint256 floorPrice = 1 ether;

        // Create a game
        _createGame(tokenId, floorPrice);

        // Allocate funds (varying amounts to test different scenarios)
        _allocateFunds(player1, 0.1 ether);
        _allocateFunds(player2, 0.2 ether);

        // Fast forward to after the grace period
        vm.warp(block.timestamp + GAME_DURATION + game.GRACE_PERIOD() + 1);

        // Force end the game and measure gas used
        vm.prank(player1);
        uint256 gasBefore = gasleft();
        game.forceEndGame(0);
        uint256 gasUsed = gasBefore - gasleft();

        // Calculate actual reward and gas cost
        (,,,, uint256 totalFunds,,,,,,,) = game.s_games(0);
        uint256 actualReward = (totalFunds * game.FORCE_END_REWARD_PERCENTAGE()) / 100;
        uint256 gasCost = gasUsed * tx.gasprice;

        console.log("Force End Reward:", actualReward);
        console.log("Gas Cost:", gasCost);
        console.log("Profit:", actualReward > gasCost ? actualReward - gasCost : 0);

        assertTrue(actualReward > gasCost, "Force end reward should be greater than gas cost");
    }

    function testForceEndGameTwice() public {
        uint256 tokenId = 1;
        uint256 floorPrice = 1 ether;

        // Create a game
        _createGame(tokenId, floorPrice);

        // Allocate funds
        _allocateFunds(player1, 0.5 ether);
        _allocateFunds(player2, 0.5 ether);

        // Fast forward to after the grace period
        vm.warp(block.timestamp + GAME_DURATION + game.GRACE_PERIOD() + 1);

        // Force end the game
        vm.prank(player1);
        game.forceEndGame(0);

        // Try to force end the game again
        vm.prank(player1);
        vm.expectRevert(NFTGame.NFTGame__CanNotEndGameThatIsNotActive.selector);
        game.forceEndGame(0);
    }

    function testForceEndGameWithNoFunds() public {
        uint256 tokenId = 1;
        uint256 floorPrice = 1 ether;

        // Create a game
        _createGame(tokenId, floorPrice);

        // Fast forward to after the grace period
        vm.warp(block.timestamp + GAME_DURATION + game.GRACE_PERIOD() + 1);

        // Force end the game
        vm.prank(player1);
        game.forceEndGame(0);

        // Check that no fees were distributed
        assertEq(treasury.balance, 0);
        assertEq(developer.balance, 0);
        assertEq(player1.balance, INITIAL_BALANCE); // player1's balance should remain unchanged
    }

    // Helper function to create a game (reusing your existing logic)
    function _createGame(uint256 tokenId, uint256 floorPrice) internal {
        // Mint NFT to game creator
        mockNFT.mint(gameCreator, tokenId);

        // Approve game contract to transfer NFT
        vm.prank(gameCreator);
        mockNFT.approve(address(game), tokenId);

        // Create game
        vm.prank(gameCreator);
        game.createGame
            {value: 0.1 ether + ((floorPrice * 3)/ 100)}
            (address(mockNFT), tokenId, floorPrice, SALT, GAME_DURATION);
    }

    // Helper function to allocate funds (reusing your existing logic)
    function _allocateFunds(address player, uint256 amount) internal {
        vm.deal(player, amount);
        vm.prank(player);
        game.allocateFunds{value: amount}(0);
    }



    function testGameCancellation() public {
        uint256 tokenId = 1;
        uint256 floorPrice = 1 ether;
        uint256 contributionPlayer1 = 0.5 ether;
        uint256 contributionPlayer2 = 0.7 ether;
        uint256 gameId = 0;

        // Set up game
        testGameCancellation__setUpGame(tokenId, floorPrice);

        // Players contribute to the game
        testGameCancellation__playersContribute(gameId, contributionPlayer1, contributionPlayer2);

        // Calculate expected values
        uint256 expectedTotalFunds = contributionPlayer1 + contributionPlayer2;
        uint256 treasuryFee = (expectedTotalFunds * game.TREASURY_FEE_NORMAL_END()) / 100;
        uint256 developerFee = (expectedTotalFunds * game.DEVELOPER_FEE()) / 100;
        uint256 expectedAvailableFunds = expectedTotalFunds - treasuryFee - developerFee;

        // Record balances before cancellation
        (uint256 treasuryBalanceBefore, uint256 developerBalanceBefore, uint256 creatorBalanceBefore) =
            testGameCancellation__recordBalancesBeforeCancellation();

        // Fast forward time to after the game's end time
        vm.warp(block.timestamp + GAME_DURATION + 1);

        // Cancel the game as the game creator
        vm.prank(gameCreator);
        game.cancelGame(gameId);

        // Verify game variables
        testGameCancellation__verifyGameCancellation(gameId, expectedTotalFunds);

        // Verify that the NFT is returned to the game creator
        testGameCancellation__verifyNftOwnership(tokenId, gameCreator);

        // Check that the treasury and developer received their fees
        testGameCancellation__verifyFees(treasuryBalanceBefore, developerBalanceBefore, treasuryFee, developerFee);

        // Players claim their refunds
        testGameCancellation__playerClaimsRefund(
            gameId, player1, contributionPlayer1, expectedAvailableFunds, expectedTotalFunds
        );
        testGameCancellation__playerClaimsRefund(
            gameId, player2, contributionPlayer2, expectedAvailableFunds, expectedTotalFunds
        );

        // Verify that game creator did not receive any funds (since the game was canceled)
        uint256 creatorBalanceAfter = gameCreator.balance;
        assertEq(
            creatorBalanceAfter - creatorBalanceBefore, 0, "Game creator should not receive funds upon cancellation"
        );
    }

    function testGameCancellation__setUpGame(uint256 tokenId, uint256 floorPrice) internal {
        // Mint NFT to game creator and create a game
        mockNFT.mint(gameCreator, tokenId);
        vm.startPrank(gameCreator);
        mockNFT.approve(address(game), tokenId);
        game.createGame
            {value: 0.1 ether + ((floorPrice * 3)/ 100)}
            (address(mockNFT), tokenId, floorPrice, SALT, GAME_DURATION);
        vm.stopPrank();
    }

    function testGameCancellation__playersContribute(
        uint256 gameId,
        uint256 contributionPlayer1,
        uint256 contributionPlayer2
    ) internal {
        vm.deal(player1, 2 ether);
        vm.prank(player1);
        game.allocateFunds{value: contributionPlayer1}(gameId);

        vm.deal(player2, 2 ether);
        vm.prank(player2);
        game.allocateFunds{value: contributionPlayer2}(gameId);
    }

    function testGameCancellation__recordBalancesBeforeCancellation()
        internal
        view
        returns (uint256, uint256, uint256)
    {
        uint256 treasuryBalanceBefore = treasury.balance;
        uint256 developerBalanceBefore = developer.balance;
        uint256 creatorBalanceBefore = gameCreator.balance;
        return (treasuryBalanceBefore, developerBalanceBefore, creatorBalanceBefore);
    }

    function testGameCancellation__verifyGameCancellation(uint256 gameId, uint256 expectedTotalFunds) internal view {
        (,,,, uint256 totalFunds, bool isActive, bool isCanceled,,,,) = game.getGameInfo(gameId);

        assertFalse(isActive, "Game should be inactive after cancellation");
        assertTrue(isCanceled, "Game should be marked as canceled");
        assertEq(totalFunds, expectedTotalFunds, "Total funds should match expected total contributions");
    }

    function testGameCancellation__verifyNftOwnership(uint256 tokenId, address expectedOwner) internal view {
        address nftOwner = mockNFT.ownerOf(tokenId);
        assertEq(nftOwner, expectedOwner, "NFT should be returned to the game creator");
    }

    function testGameCancellation__verifyFees(
        uint256 treasuryBalanceBefore,
        uint256 developerBalanceBefore,
        uint256 treasuryFee,
        uint256 developerFee
    ) internal view {
        uint256 treasuryBalanceAfter = treasury.balance;
        uint256 developerBalanceAfter = developer.balance;

        assertEq(treasuryBalanceAfter - treasuryBalanceBefore, treasuryFee, "Treasury should receive correct fee");
        assertEq(developerBalanceAfter - developerBalanceBefore, developerFee, "Developer should receive correct fee");
    }

    function testGameCancellation__playerClaimsRefund(
        uint256 gameId,
        address player,
        uint256 playerContribution,
        uint256 expectedAvailableFunds,
        uint256 expectedTotalFunds
    ) internal {
        uint256 playerBalanceBefore = player.balance;
        vm.prank(player);
        game.claimFunds(gameId);
        uint256 playerBalanceAfter = player.balance;

        // Verify that the player's contribution is reset
        uint256 playerStoredContribution = game.s_playerContributions(gameId, player);
        assertEq(playerStoredContribution, 0, "Player's contribution should be reset after claiming funds");

        // Calculate expected refund
        uint256 playerExpectedRefund = (expectedAvailableFunds * playerContribution) / expectedTotalFunds;

        assertEq(playerBalanceAfter - playerBalanceBefore, playerExpectedRefund, "Player should receive correct refund");
    }




    function testChooseWinnerDistribution() public {
    // function testChooseWinnerDistribution() public {
        uint256 numPlayers = 200;
        uint256 numSimulations = 1000;

        // Arrays to store players, contributions, and win counts
        address[] memory players = new address[](numPlayers);
        uint256[] memory contributions = new uint256[](numPlayers);
        uint256[] memory winCounts = new uint256[](numPlayers);

        uint256 lastGameId;
        for (uint256 i = 0; i < numSimulations; i++) {
            console.log("iteration: %i", i);
            // Modify block data to change randomness
            vm.roll(block.number + i + 1); // Increment block number to change randomness
            vm.prevrandao(uint256(keccak256(abi.encodePacked(i)))); // Vary prev randao
            vm.resetGasMetering();

            // Set up the game for this simulation
            uint256 gameId = testChooseWinnerDistribution__setupGame(i);
            lastGameId = gameId;

            // Players contribute funds to the game
            for (uint256 j = 0; j < numPlayers; j++) {
                players[j] = address(uint160(1000 + j)); // Unique addresses for each player
                contributions[j] = testChooseWinnerDistribution__playerContributes(j, gameId); // Players contribute to the game
            }

            // End the game and determine the winner
            testChooseWinnerDistribution__endAndDetermineWinner(gameId, players, winCounts, i);

            // Reset NFT ownership for the next simulation
            testChooseWinnerDistribution__resetNFTOwnership(i + 1);
        }

        // Print and verify win distribution
        testChooseWinnerDistribution__printWinDistribution(players, contributions, winCounts, lastGameId);
    }

    // Helper function to set up the game
    function testChooseWinnerDistribution__setupGame(uint256 i) internal returns (uint256 gameId) {
        uint256 tokenId = i + 1; // Different tokenId for each simulation

        vm.startPrank(gameCreator);
        mockNFT.mint(gameCreator, tokenId);
        mockNFT.approve(address(game), tokenId);
        bytes32 salt = keccak256(abi.encodePacked(SALT, block.number, block.timestamp, i, block.prevrandao));
        uint256 floorPrice = 1 ether;
        gameId = game.createGame
            {value: 0.1 ether + ((floorPrice * 3)/ 100)}
            (address(mockNFT), tokenId, floorPrice, salt, GAME_DURATION);
        vm.stopPrank();
        console.log("Game id : %i", gameId);

        return gameId;
    }

    // Helper function to handle players' contributions
    function testChooseWinnerDistribution__playerContributes(uint256 playerIndex, uint256 gameId)
        internal
        returns (uint256 contribution)
    {
        address player = address(uint160(1000 + playerIndex)); // Unique addresses for each player
        vm.deal(player, 10000 ether); // Fund each player with 10000 ether

        (,,,,,,,,, uint256 minContributionFee,,) = game.s_games(gameId);
        contribution = minContributionFee + (0.0008 ether * playerIndex);  // Assign varied contributions
        // contribution = minContributionFee; // ONLY CONTRIBUTE MIN CONTRIBUTION FEE

        vm.prank(player);
        game.allocateFunds{value: contribution}(gameId); // Player allocates funds

        return contribution;
    }

    // Helper function to end the game and determine the winner
    function testChooseWinnerDistribution__endAndDetermineWinner(
        uint256 gameId,
        address[] memory players,
        uint256[] memory winCounts,
        uint256 i
    ) internal {
        console.log("==========================");
        console.log("before");
        console.log(block.timestamp);
        vm.warp(block.timestamp + GAME_DURATION + 1);
        console.log("after");
        console.log(block.timestamp);
        console.log("endGameTimeStamp");
        console.log("==========================");

        // End the game
        vm.prank(gameCreator);
        game.endGame(gameId);
        vrfCoordinatorMock.fulfillRandomWords(i + 1, address(game)); // Use VRF to get randomness

        // Record the winner
        address winner = mockNFT.ownerOf(i + 1); // Use correct tokenId (if needed, pass it to this function)
        for (uint256 j = 0; j < players.length; j++) {
            if (winner == players[j]) {
                winCounts[j]++;
                break;
            }
        }
    }

    // Helper function to reset NFT ownership for the next simulation
    function testChooseWinnerDistribution__resetNFTOwnership(uint256 tokenId) internal {
        address winner = mockNFT.ownerOf(tokenId);
        vm.prank(winner);
        mockNFT.transferFrom(winner, address(gameCreator), tokenId); // Reset NFT ownership
    }

    // Helper function to print the win distribution for analysis
    function testChooseWinnerDistribution__printWinDistribution(
        address[] memory players,
        uint256[] memory contributions,
        uint256[] memory winCounts,
        uint256 _gameId
    ) internal view {
        console.log("Win distribution:");
        for (uint256 i = 0; i < players.length; i++) {
            console.log(
                string(
                    abi.encodePacked(
                        "Player ",
                        uint2str(i),
                        " Contribution: ",
                        uint2str(contributions[i]),
                        " Address: ",
                        toAsciiString(players[i]),
                        " Wins: ",
                        uint2str(winCounts[i])
                    )
                )
            );
            console.log(" Contribution Band: ");
            console.log(game.s_playerActiveBand(_gameId, players[i]));
        }
    }

    // Helper function to convert uint to string
    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    // Helper function to pad a string to a certain length
    function padRight(string memory s, uint256 length) internal pure returns (string memory) {
        bytes memory bytesString = bytes(s);
        if (bytesString.length >= length) {
            return s;
        }
        
        bytes memory paddedBytes = new bytes(length);
        for (uint i = 0; i < bytesString.length; i++) {
            paddedBytes[i] = bytesString[i];
        }
        for (uint i = bytesString.length; i < length; i++) {
            paddedBytes[i] = " ";
        }
        
        return string(paddedBytes);
    }

}
