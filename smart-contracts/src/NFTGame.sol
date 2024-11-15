// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console} from "forge-std/Console.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {ConfirmedOwnerWithProposal} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwnerWithProposal.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title NFTGame
 * @author Your Name or Organization
 * @notice This contract implements a decentralized NFT-based game platform
 * @dev Implements game creation, fund allocation, and winner selection using Chainlink VRF
 *
 * The NFTGame contract allows users to create and participate in games where they can win NFTs.
 * Players contribute funds to the game, and a winner is selected using verifiable random function (VRF) 
 * provided by Chainlink. The contract implements a banding system to give higher chances of winning 
 * to players who contribute more.
 *
 * Key Features:
 * - Game creation with NFT staking
 * - Dynamic minimum contribution based on total funds and floor price
 * - Chainlink VRF integration for fair winner selection
 * - Banding system for weighted winner selection
 * - Game cancellation and fund claiming mechanisms
 * - Treasury and developer fee collection
 *
 * Security Measures:
 * - ReentrancyGuard to prevent re-entrancy attacks
 * - Pausable to allow pausing the contract in case of emergencies
 * - ERC721Holder to safely receive NFTs
 *
 * This contract uses OpenZeppelin libraries for standard implementations and 
 * Chainlink for VRF and price feed functionalities.
 *
 * DISCLAIMER: This contract is provided as-is. Users should conduct their own audits and security checks 
 * before using it in a production environment. The authors are not responsible for any losses incurred 
 * through the use of this contract.
 */
contract NFTGame is ConfirmedOwnerWithProposal, ReentrancyGuard, Pausable, ERC721Holder, VRFConsumerBaseV2Plus {
    /**
     * @dev Struct representing a game in the NFTGame contract
     * @param nftOwner Address of the NFT owner
     * @param nftContract Address of the NFT contract
     * @param tokenId Token ID of the NFT
     * @param endTime Timestamp when the game ends
     * @param totalFunds Total funds contributed to the game
     * @param isActive Boolean indicating if the game is active
     * @param isCanceled Boolean indicating if the game is canceled
     * @param nftClaimed Boolean indicating if the NFT has been claimed
     * @param playerCount Number of players in the game
     * @param minContribution Minimum contribution required to join the game
     * @param floorPrice Floor price of the game
     * @param salt Random salt used for generating game-specific randomness
     */
    struct Game {
        address nftOwner;
        address nftContract;
        uint256 tokenId;
        uint256 endTime;
        uint256 totalFunds;
        bool isActive;
        bool isCanceled;
        bool nftClaimed;
        uint256 playerCount;
        uint256 minContribution;
        uint256 floorPrice;
        bytes32 salt;
    }

    /// @dev Counter for the total number of games created
    uint256 public s_gameCounter = 0;

    /// @dev Mapping of game ID to Game struct
    mapping(uint256 gameId => Game game) public s_games;

    /// @dev Mapping of game ID to list of player addresses
    mapping(uint256 gameId => address[] playerAddresses) public s_gameParticipants;

    /// @dev Mapping of player address to list of active game IDs
    mapping(address playerAddress => uint256[] gameIds) public s_playerActiveGames;

    /// @dev Mapping of creator address to list of active game IDs
    mapping(address playerAddress => uint256[] gameIds) public s_creatorActiveGames;

    /// @dev Mapping of game ID and player address to player's index in active games
    mapping(uint256 gameId => mapping(address playerAddress => uint256 indexOfPlayer)) public
        s_playerGameIndexInActiveGames;

    /// @dev Mapping of game ID and player address to player's contribution amount
    mapping(uint256 gameId => mapping(address playerAddress => uint256 contributionAmount)) public s_playerContributions;

    /// @dev Mapping of game ID and band number to list of players in that band
    mapping(uint256 gameId => mapping(uint8 bandNumber => address[] players)) public s_bandedPlayers;

    /// @dev Mapping of game ID and player address to player's index in their band
    mapping(uint256 gameId => mapping(address playerAddress => uint256 indexOfPlayer)) public s_playerIndexInBand;

    /// @dev Mapping of game ID and player address to player's active band
    mapping(uint256 gameId => mapping(address playerAddress => uint8 activeBand)) public s_playerActiveBand;

    /// @dev Mapping of Chainlink VRF request ID to game ID
    mapping(uint256 requestId => uint256 gameId) public s_requestIdToGameId;

    /// @dev Mapping of game ID to Chainlink VRF request ID
    mapping(uint256 gameId => uint256 requestID) public s_gameIdToRequestId;

    /// @dev Address of the treasury to receive fees
    address public immutable i_treasuryAddress;

    /// @dev Address of the developer to receive fees
    address public immutable i_developerAddress;

    /// @dev Duration after a game, where the game creator is the only one who can end/ cancel the game
    uint256 public constant GRACE_PERIOD = 7 days;

    /// @dev Percentage of funds allocated as developer fee (2%)
    uint256 public constant DEVELOPER_FEE = 2;

    /// @dev Percentage of funds allocated as treasury fee when the creator ends or cancels a game (3%)
    uint256 public constant TREASURY_FEE_NORMAL_END = 3; 

    /// @dev Percentage of funds allocated as treasury fee when the game is forcefully endeded (2%)
    /// @dev This should always be TREASURY_FEE_NORMAL_END - FORCE_END_REWARD_PERCENTAGE
    uint256 public constant TREASURY_FEE_FORCED_END = 2; 

    /// @dev Percentage of funds allocated as a reward to the user that forcefully ends a game (2%)
    uint256 public constant FORCE_END_REWARD_PERCENTAGE = 1;

    /// @dev Base minimum contribution required to join a game (0.01 ether)
    uint256 public constant BASE_MIN_CONTRIBUTION = 0.01 ether;

    /// @dev Maximum number of active games allowed per user
    uint256 public constant MAX_ACTIVE_GAMES_PER_USER = 10;

    // Chainlink Price Feed & VRF Variables
    AggregatorV3Interface private immutable i_priceFeed;
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 2;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;

    /**
     * @dev Emitted when a new game is created
     * @param gameId The ID of the newly created game
     * @param nftOwner The address of the NFT owner
     * @param nftContract The address of the NFT contract
     * @param tokenId The token ID of the NFT
     */
    event GameCreated(uint256 indexed gameId, address indexed nftOwner, address nftContract, uint256 tokenId);

    /**
     * @dev Emitted when funds are allocated to a game
     * @param gameId The ID of the game
     * @param player The address of the player allocating funds
     * @param amount The amount of funds allocated
     */
    event FundsAllocated(uint256 indexed gameId, address indexed player, uint256 amount);

    /**
     * @dev Emitted when a game ends
     * @param gameId The ID of the ended game
     * @param winner The address of the winning player
     */
    event GameEnded(uint256 indexed gameId, address winner);

    /**
     * @dev Emitted when a game is force ended
     * @param gameId The ID of the force ended game
     * @param forceEnder The address of the user that force ended the game
     * @param reward The reward amount for the force ender
     */
    event GameForceEnded(uint256 indexed gameId, address forceEnder, uint256 reward);

    /**
     * @dev Emitted when a game is cancelled
     * @param gameId The ID of the cancelled game
     * @param canceller The address of the account that cancelled the game
     */
    event GameCancelled(uint256 indexed gameId, address canceller);

    /**
     * @dev Emitted when the minimum contribution for a game is updated
     * @param gameId The ID of the game
     * @param newMinContribution The new minimum contribution amount
     */
    event MinContributionUpdated(uint256 indexed gameId, uint256 newMinContribution);

    /**
     * @dev Emitted when a player withdraws their refund
     * @param gameId The ID of the game
     * @param player The address of the player withdrawing the refund
     * @param amount The amount of the refund
     */
    event RefundWithdrawn(uint256 indexed gameId, address indexed player, uint256 amount);

    /**
     * @dev Emitted when randomness is requested from Chainlink VRF
     * @param requestId The ID of the randomness request
     * @param gameId The ID of the game for which randomness was requested
     */
    event RandomnessRequested(uint256 indexed requestId, uint256 indexed gameId);

    /**
     * @dev Emitted when randomness is fulfilled by Chainlink VRF
     * @param gameId The ID of the game for which randomness was fulfilled
     * @param randomWords The array of random words received from Chainlink VRF
     */
    event RandomnessRequested(uint256 indexed gameId, uint256[] randomWords);

    /**
     * @dev Emitted when a player claims their funds from a game
     * @param gameId The ID of the game
     * @param player The address of the player claiming funds
     * @param playerShare The amount of funds claimed by the player
     */
    event FundsClaimed(uint256 indexed gameId, address indexed player, uint256 playerShare);

    /// @dev Error thrown when someone other than the NFT owner tries to start a game
    error NFTGame__OnlyTheNFTOwnerCanStartTheGame();

    /// @dev Error thrown when the floor price is set to zero
    error NFTGame__FloorPriceMustBeGreaterThanZero();

    /// @dev Error thrown when trying to allocate funds to a non-active game
    error NFTGame__FundsCanNotBeAllocatedToNonActiveGames();

    /// @dev Error thrown when the allocated funds are less than the minimum contribution
    error NFTGame__FundsAllocatedMustBeHigherThanMinimumContribution();

    /// @dev Error thrown when trying to end a game that is not active
    error NFTGame__CanNotEndGameThatIsNotActive();

    /// @dev Error thrown when trying to end a game before its set end time
    error NFTGame__GameCanNotEndBeforeSetEndTime();

    /// @dev Error thrown when trying to end a game before its set end time +  grace Period
    error NFTGame__GameCanNotEndBeforeGracePeriodIsOver();

    /// @dev Error thrown when a transfer of funds fails
    error NFTGame__TransferFailed();

    /// @dev Error thrown when trying to choose a winner but no players are in any bands
    error NFTGame__CantChooseWinnerIfThereAreNoPlayersInAnyBands();

    /// @dev Error thrown when the provided salt is a zero value
    error NFTGame__SaltCanNotBeZeroValueBytes();

    /// @dev Error thrown when trying to cancel a game before its end time
    error NFTGame__CanNotCancelGameBeforeEndTime();

    /// @dev Error thrown when someone other than the game creator tries to perform a creator-only action
    error NFTGame__CallerMustBeGameCreator();

    /// @dev Error thrown when someone other than the game creator tries to perform a creator-only action
    error NFTGame__CanNotCancelGameThatIsAlreadyCanceledOrIsNotActive();

    /// @dev Error thrown when trying to claim funds before the game has ended and been canceled
    error NFTGame__CanNotClaimFundsBeforeGameHasEndedAndBeenCanceled();

    /// @dev Error thrown when trying to claim funds but no funds are available
    error NFTGame__NoFundsToClaim();

    /// @dev Error thrown when the creation fee is insufficient
    error NFTGame__InsufficientCreationFee(uint256 requiredFee, uint256 sentFee);

    /// @dev Error thrown when the ETH price from the price feed is invalid
    error NFTGame__InvalidETHPrice();


    /**
     * @dev Constructor for the NFTGame contract
     * @param _priceFeedAddress Address of the Chainlink price feed contract
     * @param _subscriptionId Chainlink VRF subscription ID
     * @param _gasLane Chainlink VRF gas lane (key hash)
     * @param _callbackGasLimit Gas limit for Chainlink VRF callback
     * @param _vrfCoordinatorV2PlusAddress Address of the Chainlink VRF Coordinator
     * @param _treasuryAddress Address to receive treasury fees
     * @param _developerAddress Address to receive developer fees
     */
    constructor(
        address _priceFeedAddress,
        uint256 _subscriptionId,
        bytes32 _gasLane, // keyHash
        uint32 _callbackGasLimit,
        address _vrfCoordinatorV2PlusAddress,
        address _treasuryAddress,
        address _developerAddress
    ) VRFConsumerBaseV2Plus(_vrfCoordinatorV2PlusAddress) {
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        i_priceFeed = AggregatorV3Interface(_priceFeedAddress);
        i_treasuryAddress = _treasuryAddress;
        i_developerAddress = _developerAddress;
    }

    //    =============================================================
    //      External & Public Functions
    //    =============================================================

    /**
     * @dev Creates a new game with the specified NFT
     * @param _nftContract Address of the NFT contract
     * @param _tokenId Token ID of the NFT
     * @param _floorPrice Floor price for the game
     * @param _salt Salt for randomness
     * @return gameId The ID of the newly created game
     */
    function createGame(address _nftContract, uint256 _tokenId, uint256 _floorPrice, bytes32 _salt, uint256 _gameDuration)
        payable
        external
        whenNotPaused
        returns (uint256 gameId)
    {
        // input validation checks
        if (_floorPrice == 0) {
            revert NFTGame__FloorPriceMustBeGreaterThanZero();
        }
        if (_salt == bytes32(0)) revert NFTGame__SaltCanNotBeZeroValueBytes();

        IERC721 nft = IERC721(_nftContract);

        // Check caller is the nft holder
        if (nft.ownerOf(_tokenId) != msg.sender) {
            revert NFTGame__OnlyTheNFTOwnerCanStartTheGame();
        }

        // Compute the required fee
        uint256 requiredFeeInETH = getRequiredFee(_floorPrice);

        // Check if enough ETH is sent
        if (msg.value < requiredFeeInETH) {
            revert NFTGame__InsufficientCreationFee(requiredFeeInETH, msg.value);
        }

        // Transfer nft from holder to this smart contract
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        uint256 currentGameId = s_gameCounter;

        // Create game
        s_games[currentGameId] = Game({
            nftOwner: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            endTime: block.timestamp + _gameDuration,
            totalFunds: 0,
            isActive: true,
            isCanceled: false,
            nftClaimed: false,
            playerCount: 0,
            minContribution: BASE_MIN_CONTRIBUTION,
            floorPrice: _floorPrice,
            salt: _salt
        });

        _addActiveGameForCreator(msg.sender, currentGameId);
        emit GameCreated(currentGameId, msg.sender, _nftContract, _tokenId);
        unchecked {
            s_gameCounter = currentGameId + 1;
        }
        return currentGameId;
    }

    /**
     * @dev Allows a player to allocate funds to a game
     * @param _gameId ID of the game to allocate funds to
     */
    function allocateFunds(uint256 _gameId) external payable nonReentrant whenNotPaused {
        Game storage game = s_games[_gameId];
        if (!game.isActive) revert NFTGame__FundsCanNotBeAllocatedToNonActiveGames();
        if (block.timestamp >= game.endTime) revert NFTGame__FundsCanNotBeAllocatedToNonActiveGames();
        if (msg.value < game.minContribution) revert NFTGame__FundsAllocatedMustBeHigherThanMinimumContribution();

        if (s_playerContributions[_gameId][msg.sender] == 0) {
            _addPlayerToGame(msg.sender, _gameId);
            game.playerCount++;
        }

        s_playerContributions[_gameId][msg.sender] += msg.value;
        game.totalFunds += msg.value;

        uint8 currentContributionBand = s_playerActiveBand[_gameId][msg.sender];

        // Banding used in winner selection processes to give an efficient way of selecting a winner
        // (Players in higher bands have a higher chance of winning).
        uint8 newContributionBand = _getBand(game.floorPrice, s_playerContributions[_gameId][msg.sender]);

        // if player's contributionBand is now different to what it was before, update it
        // and add the player to this calculated band based on their current contribution total
        if (currentContributionBand != newContributionBand) {
            _updatePlayersBand(msg.sender, _gameId, newContributionBand);
        }

        emit FundsAllocated(_gameId, msg.sender, msg.value);

        uint256 newMinContribution = calculateMinContribution(game.totalFunds, game.floorPrice);

        if (newMinContribution > game.minContribution) {
            game.minContribution = newMinContribution;
            emit MinContributionUpdated(_gameId, newMinContribution);
        }
    }

    /**
     * @dev Modifier to ensure only the game creator can perform certain actions
     * @param _gameId ID of the game
     */
    modifier onlyGameCreator(uint256 _gameId) {
        address gameCreator = s_games[_gameId].nftOwner;
        if (msg.sender != gameCreator) revert NFTGame__CallerMustBeGameCreator();
        _;
    }

    /**
     * @dev Allows the game creator to cancel the game after it ends
     * @param _gameId ID of the game to cancel
     */
    function cancelGame(uint256 _gameId) external onlyGameCreator(_gameId) nonReentrant whenNotPaused {
        Game storage game = s_games[_gameId];
        if (block.timestamp <= game.endTime) revert NFTGame__CanNotCancelGameBeforeEndTime();
        if (game.isCanceled || !game.isActive) revert NFTGame__CanNotCancelGameThatIsAlreadyCanceledOrIsNotActive();

        // Mark the game as canceled
        game.isCanceled = true;
        game.isActive = false;

        // developer & treasury fee taken
        _takeGameTax(game.totalFunds, false, address(0));

        // Transfer the NFT back to the game creator
        IERC721(game.nftContract).safeTransferFrom(address(this), msg.sender, game.tokenId);

        emit GameCancelled(_gameId, msg.sender);
    }

    /**
     * @dev Allows users to claim their funds after the game ends
     * @param _gameId ID of the game to claim funds from
     */
    function claimFunds(uint256 _gameId) external nonReentrant whenNotPaused {
        Game storage game = s_games[_gameId];
        uint256 playerContribution = s_playerContributions[_gameId][msg.sender];

        if (!game.isCanceled || game.isActive || block.timestamp < game.endTime || playerContribution == 0) {
            revert NFTGame__CanNotClaimFundsBeforeGameHasEndedAndBeenCanceled();
        }

        uint256 totalClaimableFunds = _getGamesTotalFundsAfterGameTax(game.totalFunds, false);
        uint256 playerClaimableFunds = (totalClaimableFunds * playerContribution) / game.totalFunds;

        // Mark the contribution as claimed
        s_playerContributions[_gameId][msg.sender] = 0;

        // Transfer player's share to their wallet
        (bool success,) = msg.sender.call{value: playerClaimableFunds}("");
        if (!success) revert NFTGame__TransferFailed();

        emit FundsClaimed(_gameId, msg.sender, playerClaimableFunds);
    }

    /**
     * @dev Ends the game and initiates the winner selection process
     * @param _gameId ID of the game to end
     */
    function endGame(uint256 _gameId) external nonReentrant whenNotPaused onlyGameCreator(_gameId) {
        Game storage game = s_games[_gameId];
        if (!game.isActive) revert NFTGame__CanNotEndGameThatIsNotActive();
        if (block.timestamp < game.endTime) revert NFTGame__GameCanNotEndBeforeSetEndTime();

        // Update game state before any external interactions
        game.isActive = false;
        game.nftClaimed = true;

        // Request randomness
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true}))
            })
        );

        emit RandomnessRequested(requestId, _gameId);

        s_requestIdToGameId[requestId] = _gameId;
        s_gameIdToRequestId[_gameId] = requestId;

        // Distribute the funds to the relevant accounts
        _distributeGameFunds(game.totalFunds, game.nftOwner);
    }

    /**
     * @dev Allows anyone to force end a game after the grace period
     * @param _gameId ID of the game to force end
     */
    function forceEndGame(uint256 _gameId) external nonReentrant whenNotPaused {
        Game storage game = s_games[_gameId];
        if (!game.isActive) revert NFTGame__CanNotEndGameThatIsNotActive();
        if (!isGracePeriodOver(_gameId)) revert NFTGame__GameCanNotEndBeforeGracePeriodIsOver();

        // Update game state before any external interactions
        game.isActive = false;
        game.nftClaimed = true;

        // Request randomness
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true}))
            })
        );

        emit RandomnessRequested(requestId, _gameId);

        s_requestIdToGameId[requestId] = _gameId;
        s_gameIdToRequestId[_gameId] = requestId;

        // Calculate fee distributions
        (uint256 treasuryAmount, uint256 developerAmount, uint256 forceEndReward) = _calculateGameTax(game.totalFunds, true);
        uint256 gameCreatorAmount = game.totalFunds - treasuryAmount - developerAmount - forceEndReward;

        // Distribute the funds
        _safeTransfer(i_treasuryAddress, treasuryAmount);
        _safeTransfer(i_developerAddress, developerAmount);
        _safeTransfer(msg.sender, forceEndReward);
        _safeTransfer(game.nftOwner, gameCreatorAmount);

        emit GameForceEnded(_gameId, msg.sender, (game.totalFunds * FORCE_END_REWARD_PERCENTAGE) / 100);
    }

    /**
     * @dev Calculates the minimum contribution based on total funds and floor price
     * @param _totalFunds Total funds in the game
     * @param _floorPrice Floor price of the game
     * @return The calculated minimum contribution
     */
    function calculateMinContribution(uint256 _totalFunds, uint256 _floorPrice) public pure returns (uint256) {
        if (_totalFunds == 0) {
            return BASE_MIN_CONTRIBUTION;
        }

        uint256 maxContribution = (_floorPrice * 8) / 100; // 8% of floor price
        
        if (_totalFunds >= _floorPrice) {
            return maxContribution;
        }

        // Calculate the proportion of total funds to floor price
        uint256 fundsProportion = (_totalFunds * 1e18) / _floorPrice;
        
        // Use a square root function to create a curve that starts slow and accelerates
        uint256 scaleFactor = sqrt(fundsProportion);

        // Interpolate between BASE_MIN_CONTRIBUTION and maxContribution
        uint256 range = maxContribution - BASE_MIN_CONTRIBUTION;
        uint256 increase = (range * scaleFactor) / 1e9; // Divide by 1e9 as sqrt returns a number * 1e9

        uint256 newMinContribution = BASE_MIN_CONTRIBUTION + increase;

        // Ensure the new minimum contribution is at least BASE_MIN_CONTRIBUTION
        return newMinContribution > BASE_MIN_CONTRIBUTION ? newMinContribution : BASE_MIN_CONTRIBUTION;
    }

    /**
     * @dev Checks if the grace period for a game is over
     * @param _gameId ID of the game to check
     * @return bool True if the grace period is over, false otherwise
     */
    function isGracePeriodOver(uint256 _gameId) public view returns (bool) {
        Game storage game = s_games[_gameId];
        return block.timestamp > game.endTime + GRACE_PERIOD;
    }

    /**
     * @notice Retrieves all active game IDs for a player
     * @param _playerAddress The address of the player
     * @return An array of game IDs the player is actively participating in
     */
    function getPlayerActiveGames(address _playerAddress) public view returns (uint256[] memory) {
        return s_playerActiveGames[_playerAddress];
    }

    /**
     * @notice Retrieves all active game IDs created by a specific address
     * @param _creatorAddress The address of the game creator
     * @return An array of game IDs created by the specified address
     */
    function getCreatorActiveGames(address _creatorAddress) public view returns (uint256[] memory) {
        return s_creatorActiveGames[_creatorAddress];
    }

    /**
     * @notice Retrieves detailed information about a specific game
     * @param _gameId The ID of the game to retrieve information for
     * @return nftOwner The address of the NFT owner
     * @return nftContract The address of the NFT contract
     * @return tokenId The token ID of the NFT
     * @return endTime The end time of the game
     * @return totalFunds The total funds in the game
     * @return isActive Whether the game is active
     * @return isCanceled Whether the game is canceled
     * @return nftClaimed Whether the NFT has been claimed
     * @return playerCount The number of players in the game
     * @return minContribution The minimum contribution required to allocate funds to a game (enter the game)
     * @return floorPrice The floor price of the game (bottom end of what the NFT is valued at)
     */
    function getGameInfo(uint256 _gameId)
        external
        view
        returns (
            address nftOwner,
            address nftContract,
            uint256 tokenId,
            uint256 endTime,
            uint256 totalFunds,
            bool isActive,
            bool isCanceled,
            bool nftClaimed,
            uint256 playerCount,
            uint256 minContribution,
            uint256 floorPrice
        )
    {
        Game storage game = s_games[_gameId];
        return (
            game.nftOwner,
            game.nftContract,
            game.tokenId,
            game.endTime,
            game.totalFunds,
            game.isActive,
            game.isCanceled,
            game.nftClaimed,
            game.playerCount,
            game.minContribution,
            game.floorPrice
        );
    }

    /**
     * @notice Calculates the current extractable value for NFT transfer in a game (game creator's current pull out value)
     * @param _gameId The ID of the game
     * @return extractableValue The current extractable value
     */
    function getGamesCurrentExtractableValueForNftTransfer(uint256 _gameId)
        external
        view
        returns (uint256 extractableValue)
    {
        uint256 totalFunds = s_games[_gameId].totalFunds;
        (uint256 treasuryAmount, uint256 developerAmount,  ) = _calculateGameTax(totalFunds, false);
        uint256 nftOwnerAmount = totalFunds - treasuryAmount - developerAmount;
        return nftOwnerAmount;
    }

    /**
     * @notice Calculates the required fee for creating a game based on the floor price
     * @param _floorPriceInETH The floor price in ETH
     * @return The required fee in ETH
     */
    function getRequiredFee(uint256 _floorPriceInETH) public view returns (uint256) {
        (, int256 price,,,) = i_priceFeed.latestRoundData();
        if (price <= 0) revert NFTGame__InvalidETHPrice();
        uint256 ethPriceInUSD = uint256(price); // ETH price in USD with 8 decimals

        // Calculate floor price in USD (with 8 decimals)
        uint256 floorPriceInUSD = (_floorPriceInETH * ethPriceInUSD) / 1e18;

        // Calculate 3% of the floor price in USD
        uint256 threePercentOfFloorPrice = (floorPriceInUSD * 3) / 100;

        // Total required fee in USD (with 8 decimals)
        uint256 totalFeeInUSD = (15 * 1e8) + threePercentOfFloorPrice;

        // Convert total required fee to ETH
        uint256 totalFeeInETH = (totalFeeInUSD * 1e18) / ethPriceInUSD;

        return totalFeeInETH;
    }

    /**
     * @notice Retrieves the contribution amount of a player in a specific game
     * @param _gameId The ID of the game
     * @param _playerAddress The address of the player
     * @return The contribution amount of the player
     */
    function getPlayerContribution(uint256 _gameId, address _playerAddress) public view returns (uint256) {
        return s_playerContributions[_gameId][_playerAddress];
    }

    /**
     * @notice Retrieves the total number of players in a game
     * @param _gameId The ID of the game
     * @return The total number of players
     */
    function getTotalPlayersInGame(uint256 _gameId) public view returns (uint256) {
        return s_games[_gameId].playerCount;
    }

    /**
     * @notice Checks if a game is active
     * @param _gameId The ID of the game
     * @return True if the game is active, false otherwise
     */
    function isGameActive(uint256 _gameId) public view returns (bool) {
        return s_games[_gameId].isActive && !s_games[_gameId].isCanceled;
    }

    /**
     * @notice Retrieves the band of a player in a specific game
     * @param _gameId The ID of the game
     * @param _playerAddress The address of the player
     * @return The band of the player
     */
    function getPlayerBand(uint256 _gameId, address _playerAddress) public view returns (uint8) {
        return s_playerActiveBand[_gameId][_playerAddress];
    }

    /**
     * @notice Retrieves the NFT details of a game
     * @param _gameId The ID of the game
     * @return nftContract The address of the NFT contract
     * @return tokenId The token ID of the NFT
     */
    function getNFTDetails(uint256 _gameId) public view returns (address nftContract, uint256 tokenId) {
        return (s_games[_gameId].nftContract, s_games[_gameId].tokenId);
    }

    /**
     * @notice Retrieves the minimum contribution required for a game
     * @param _gameId The ID of the game
     * @return The minimum contribution amount
     */
    function getMinContribution(uint256 _gameId) public view returns (uint256) {
        return s_games[_gameId].minContribution;
    }

    /**
     * @notice Checks if a player is participating in a specific game
     * @param _gameId The ID of the game
     * @param _playerAddress The address of the player
     * @return True if the player is in the game, false otherwise
     */
    function isPlayerInGame(uint256 _gameId, address _playerAddress) public view returns (bool) {
        return s_playerContributions[_gameId][_playerAddress] > 0;
    }

    /**
     * @notice Retrieves all players in a specific band of a game
     * @param _gameId The ID of the game
     * @param _bandNumber The band number
     * @return An array of player addresses in the specified band
     */
    function getPlayersInBand(uint256 _gameId, uint8 _bandNumber) external view returns (address[] memory) {
        return s_bandedPlayers[_gameId][_bandNumber];
    }

    /**
     * @notice Retrieves all active bands of a player in a specific game
     * @param _gameId The ID of the game
     * @param _playerAddress The address of the player
     * @return The active band of the player
     */
    function getAllPlayerActiveBands(uint256 _gameId, address _playerAddress) external view returns (uint8) {
        return s_playerActiveBand[_gameId][_playerAddress];
    }

    /**
     * @notice Retrieves the index of a player within their band in a specific game
     * @param _gameId The ID of the game
     * @param _playerAddress The address of the player
     * @return The index of the player in their band
     */
    function getPlayerIndexInBand(uint256 _gameId, address _playerAddress) external view returns (uint256) {
        return s_playerIndexInBand[_gameId][_playerAddress];
    }

    //    =============================================================
    //      Internal Functions
    //    =============================================================

    /**
     * @dev Callback function used by Chainlink VRF to fulfill random words
     * @param requestId ID of the randomness request
     * @param randomWords Array of random words generated by Chainlink VRF
     */
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 gameId = s_requestIdToGameId[requestId];
        Game storage game = s_games[gameId];

        uint256 randomNumber1 = uint256(keccak256(abi.encodePacked(randomWords[0], game.salt)));
        uint256 randomNumber2 = uint256(keccak256(abi.encodePacked(randomWords[1], game.salt)));

        console.log("randomNumber1"); console.log(randomNumber1);
        console.log("randomNumber2"); console.log(randomNumber2);

        address winner = _chooseWinner(gameId, randomNumber1, randomNumber2);
        console.log("winner"); console.log(winner);

        // Transfer NFT to winner
        IERC721(game.nftContract).safeTransferFrom(address(this), winner, game.tokenId);
        game.nftClaimed = true;

        emit GameEnded(gameId, winner);
    }

    /**
     * @notice Safely transfers Ether to a specified address
     * @param to The address to transfer Ether to
     * @param amount The amount of Ether to transfer
     */
    function _safeTransfer(address to, uint256 amount) internal {
        (bool success,) = to.call{value: amount}("");
        if (!success) revert NFTGame__TransferFailed();
    }

    /**
     * @notice Chooses a winner for a game using the provided random numbers
     * @param _gameId The ID of the game
     * @param randomNumber1 The first random number
     * @param randomNumber2 The second random number
     * @return winner The address of the chosen winner
     */
    function _chooseWinner(uint256 _gameId, uint256 randomNumber1, uint256 randomNumber2)
        internal
        view
        returns (address winner)
    {
        // Step 1: Get active bands and their weights
        (uint8[] memory activeBands, uint256[] memory bandWeights, uint256 totalWeight) =
            _getActiveBandsAndWeights(_gameId);

        if (activeBands.length == 0) {
            revert NFTGame__CantChooseWinnerIfThereAreNoPlayersInAnyBands();
        }

        // Step 2: Generate a weighted random number to select a band
        uint8 chosenBand = _selectBandByWeight(activeBands, bandWeights, totalWeight, randomNumber1);

        // Step 3: Choose the winner from the selected band
        winner = _chooseWinnerFromBand(_gameId, chosenBand, randomNumber2);
        return winner;
    }

    /**
     * @notice Determines the band of a player based on their contribution and the floor price
     * @param floorPrice The floor price of the game
     * @param contribution The contribution of the player
     * @return The band number of the player
     */
    function _getBand(uint256 floorPrice, uint256 contribution) internal pure returns (uint8) {
        // Contribution divided by the floor price to get a fractional value
        uint256 contributionPercentage = (contribution * 400) / floorPrice;

        if (contributionPercentage > 120) return 10; // Band 10: > 120%
        if (contributionPercentage >= 90) return 9; // Band 9: 90% - 120%
        if (contributionPercentage >= 80) return 8; // Band 8: 80% - 89%
        if (contributionPercentage >= 70) return 7; // Band 7: 70% - 79%
        if (contributionPercentage >= 60) return 6; // Band 6: 60% - 69%
        if (contributionPercentage >= 50) return 5; // Band 5: 50% - 59%
        if (contributionPercentage >= 40) return 4; // Band 4: 40% - 49%
        if (contributionPercentage >= 30) return 3; // Band 3: 30% - 39%
        if (contributionPercentage >= 20) return 2; // Band 2: 20% - 29%
        return 1; // Band 1: 0% - 19%
    }

    /**
     * @notice Chooses a winner from a specific band in a game
     * @param _gameId The ID of the game
     * @param _band The band number
     * @param _randomNumber A random number for winner selection
     * @return The address of the chosen winner
     */
    function _chooseWinnerFromBand(uint256 _gameId, uint8 _band, uint256 _randomNumber)
        internal
        view
        returns (address)
    {
        address[] memory playersInBand = s_bandedPlayers[_gameId][_band];
        uint256 playerCount = playersInBand.length;
        uint256 randomIndex = _randomNumber % playerCount;
        return playersInBand[randomIndex];
    }

    /**
     * @notice Retrieves active bands and their weights for a game
     * @param _gameId The ID of the game
     * @return activeBands An array of active band numbers
     * @return bandWeights An array of weights for each active band
     * @return totalWeight The total weight of all active bands
     */
    function _getActiveBandsAndWeights(uint256 _gameId)
        internal
        view
        returns (uint8[] memory activeBands, uint256[] memory bandWeights, uint256 totalWeight)
    {
        uint256 activeBandCount = 0;

        // Step 1: Count the number of active bands
        for (uint8 band = 1; band <= 10; band++) {
            if (s_bandedPlayers[_gameId][band].length > 0) {
                activeBandCount++;
            }
        }

        // Initialize arrays to store active bands and their corresponding weights
        activeBands = new uint8[](activeBandCount);
        bandWeights = new uint256[](activeBandCount);
        uint8 activeBandIndex = 0;

        // Step 2: Calculate total weight, considering both the band number and player count
        for (uint8 band = 1; band <= 10; band++) {
            uint256 playerCountInBand = s_bandedPlayers[_gameId][band].length;
            if (playerCountInBand > 0) {
                activeBands[activeBandIndex] = band;
                // Exponential weight: 2^band * player count in that band
                bandWeights[activeBandIndex] = playerCountInBand * (2 ** band);
                totalWeight += bandWeights[activeBandIndex];
                activeBandIndex++;
            }
        }

        return (activeBands, bandWeights, totalWeight);
    }

    /**
     * @notice Selects a band based on weights and a random number
     * @param activeBands An array of active band numbers
     * @param bandWeights An array of weights for each active band
     * @param totalWeight The total weight of all active bands
     * @param randomNumber A random number for band selection
     * @return The selected band number 
     */
    function _selectBandByWeight(
        uint8[] memory activeBands,
        uint256[] memory bandWeights,
        uint256 totalWeight,
        uint256 randomNumber
    ) internal pure returns (uint8) {
        // Step 1: Generate a weighted random number
        uint256 weightedRandom = randomNumber % totalWeight;

        // Step 2: Select the band based on the weighted random number
        uint256 cumulativeWeight = 0;
        uint8 chosenBand = 0;

        for (uint256 i = 0; i < activeBands.length; i++) {
            cumulativeWeight += bandWeights[i];
            if (weightedRandom < cumulativeWeight) {
                chosenBand = activeBands[i];
                break;
            }
        }

        return chosenBand;
    }

    /**
     * @notice Distributes the game funds to the treasury, developer, and NFT owner
     * @param _totalFunds The total funds in the game
     * @param _nftOwner The address of the NFT owner
     */
    function _distributeGameFunds(uint256 _totalFunds, address _nftOwner) internal {
        uint256 treasuryAmount = (_totalFunds * TREASURY_FEE_NORMAL_END) / 100;
        uint256 developerAmount = (_totalFunds * DEVELOPER_FEE) / 100;
        uint256 nftOwnerAmount = _totalFunds - treasuryAmount - developerAmount;

        _safeTransfer(i_treasuryAddress, treasuryAmount);
        _safeTransfer(i_developerAddress, developerAmount);
        _safeTransfer(_nftOwner, nftOwnerAmount);
    }
    
    /**
     * @notice Calculates the game tax (treasury and developer fees)
     * @param _totalFunds The total funds in the game
     * @param _isForceEnded Whether the game is being force-ended
     * @return treasuryAmount The amount for the treasury
     * @return developerAmount The amount for the developer
     * @return forceEndReward The reward for force-ending (0 if not force-ended)
     */
    function _calculateGameTax(uint256 _totalFunds, bool _isForceEnded)
        internal
        pure
        returns (uint256 treasuryAmount, uint256 developerAmount, uint256 forceEndReward)
    {
        developerAmount = (_totalFunds * DEVELOPER_FEE) / 100;
        
        if (_isForceEnded) {
            treasuryAmount = (_totalFunds * TREASURY_FEE_FORCED_END) / 100;
            forceEndReward = (_totalFunds * FORCE_END_REWARD_PERCENTAGE) / 100;
        } else {
            treasuryAmount = (_totalFunds * TREASURY_FEE_NORMAL_END) / 100;
            forceEndReward = 0;
        }
    }

    /**
     * @notice Takes the game tax and transfers it to the treasury and developer addresses
     * @param _totalFunds The total funds in the game
     * @param _isForceEnded Whether the game is being force-ended
     * @param _forceEndInitiator The address of the account that initiated the force end (address(0) if not force-ended)
     */
    function _takeGameTax(uint256 _totalFunds, bool _isForceEnded, address _forceEndInitiator) internal {
        (uint256 treasuryAmount, uint256 developerAmount, uint256 forceEndReward) = _calculateGameTax(_totalFunds, _isForceEnded);
        address payable treasuryAddress = payable(i_treasuryAddress);
        address payable developerAddress = payable(i_developerAddress);

        (bool successTreasury,) = treasuryAddress.call{value: treasuryAmount}("");
        (bool successDeveloper,) = developerAddress.call{value: developerAmount}("");
        
        if (_isForceEnded && _forceEndInitiator != address(0)) {
            (bool successForceEnd,) = _forceEndInitiator.call{value: forceEndReward}("");
            if (!successForceEnd) revert NFTGame__TransferFailed();
        }

        if (!successTreasury || !successDeveloper) revert NFTGame__TransferFailed();
    }

    /**
     * @notice Calculates the total funds after deducting the game tax
     * @param _totalFunds The total funds in the game
     * @param _isForceEnded Whether the game is being force-ended
     * @return The total funds after tax deduction
     */
    function _getGamesTotalFundsAfterGameTax(uint256 _totalFunds, bool _isForceEnded) internal pure returns (uint256) {
        (uint256 treasuryAmount, uint256 developerAmount, uint256 forceEndReward) = _calculateGameTax(_totalFunds, _isForceEnded);
        return _totalFunds - (treasuryAmount + developerAmount + forceEndReward);
    }

    /**
     * @notice Adds a player to a game and updates relevant data structures
     * @param _playerAddress The address of the player
     * @param _gameId The ID of the game
     */
    function _addPlayerToGame(address _playerAddress, uint256 _gameId) internal {
        s_gameParticipants[_gameId].push(_playerAddress);
        _addActiveGameForPlayer(_playerAddress, _gameId);
    }

    
    /**
     * @notice Adds a game to a creator's list of active games
     * @param _creatorAddress The address of the creator
     * @param _gameId The ID of the game
     */
    function _addActiveGameForCreator(address _creatorAddress, uint256 _gameId) internal {
        s_creatorActiveGames[_creatorAddress].push(_gameId);
    }

    /**
     * @notice Adds a game to a player's list of active games
     * @param _playerAddress The address of the player
     * @param _gameId The ID of the game
     */
    function _addActiveGameForPlayer(address _playerAddress, uint256 _gameId) internal {
        s_playerActiveGames[_playerAddress].push(_gameId);
        s_playerGameIndexInActiveGames[_gameId][_playerAddress] = (s_playerActiveGames[_playerAddress]).length - 1;
    }

    
    /**
     * @notice Updates a player's band in a game
     * @param _playerAddress The address of the player
     * @param _gameId The ID of the game
     * @param _newContributionBand The new band for the player
     */
    function _updatePlayersBand(address _playerAddress, uint256 _gameId, uint8 _newContributionBand) internal {
        uint8 currentBand = s_playerActiveBand[_gameId][_playerAddress];

        if (currentBand != 0 && currentBand != _newContributionBand) {
            // Remove player from their current band array
            _removePlayerFromBand(_playerAddress, _gameId, currentBand);
        }

        // Add player to the new contribution band
        s_bandedPlayers[_gameId][_newContributionBand].push(_playerAddress);
        s_playerActiveBand[_gameId][_playerAddress] = _newContributionBand;
    }

    
    /**
     * @notice Removes a player from a specific band in a game
     * @param _playerAddress The address of the player
     * @param _gameId The ID of the game
     * @param _band The band to remove the player from
     */
    function _removePlayerFromBand(address _playerAddress, uint256 _gameId, uint8 _band) internal {
        address[] storage playersInBand = s_bandedPlayers[_gameId][_band];
        uint256 playerIndex = s_playerIndexInBand[_gameId][_playerAddress];
        uint256 lastPlayerIndex = playersInBand.length - 1;

        if (playerIndex != lastPlayerIndex) {
            // Move the last player into the place of the player to be removed
            playersInBand[playerIndex] = playersInBand[lastPlayerIndex];
            // Update the index of the player that was moved
            s_playerIndexInBand[_gameId][playersInBand[playerIndex]] = playerIndex;
        }

        // Remove the last element (the player to be removed is now at the end)
        playersInBand.pop();

        // Clear the old player's index in the mapping
        delete s_playerIndexInBand[_gameId][_playerAddress];
    }

    /**
     * @notice Calculates an approximation of the square root of a number
     * @param x The number to calculate the square root of
     * @return y The approximate square root of x, multiplied by 1e9
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y * 1e9 / 1e9;
    }

}
