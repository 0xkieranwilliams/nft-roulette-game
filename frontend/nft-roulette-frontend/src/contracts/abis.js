const NFTGameABI = 
  [
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "_priceFeedAddress",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "_subscriptionId",
					"type": "uint256"
				},
				{
					"internalType": "bytes32",
					"name": "_gasLane",
					"type": "bytes32"
				},
				{
					"internalType": "uint32",
					"name": "_callbackGasLimit",
					"type": "uint32"
				},
				{
					"internalType": "address",
					"name": "_vrfCoordinatorV2PlusAddress",
					"type": "address"
				},
				{
					"internalType": "address",
					"name": "_treasuryAddress",
					"type": "address"
				},
				{
					"internalType": "address",
					"name": "_developerAddress",
					"type": "address"
				}
			],
			"stateMutability": "nonpayable",
			"type": "constructor"
		},
		{
			"inputs": [],
			"name": "EnforcedPause",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "ExpectedPause",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "NFTGame__CallerMustBeGameCreator",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "NFTGame__CanNotCancelGameBeforeEndTime",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "NFTGame__CanNotCancelGameThatIsAlreadyCanceledOrIsNotActive",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "NFTGame__CanNotClaimFundsBeforeGameHasEndedAndBeenCanceled",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "NFTGame__CanNotEndGameThatIsNotActive",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "NFTGame__CantChooseWinnerIfThereAreNoPlayersInAnyBands",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "NFTGame__FloorPriceMustBeGreaterThanZero",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "NFTGame__FundsAllocatedMustBeHigherThanMinimumContribution",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "NFTGame__FundsCanNotBeAllocatedToNonActiveGames",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "NFTGame__GameCanNotEndBeforeGracePeriodIsOver",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "NFTGame__GameCanNotEndBeforeSetEndTime",
			"type": "error"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "requiredFee",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "sentFee",
					"type": "uint256"
				}
			],
			"name": "NFTGame__InsufficientCreationFee",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "NFTGame__InvalidETHPrice",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "NFTGame__NoFundsToClaim",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "NFTGame__OnlyTheNFTOwnerCanStartTheGame",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "NFTGame__SaltCanNotBeZeroValueBytes",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "NFTGame__TransferFailed",
			"type": "error"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "have",
					"type": "address"
				},
				{
					"internalType": "address",
					"name": "want",
					"type": "address"
				}
			],
			"name": "OnlyCoordinatorCanFulfill",
			"type": "error"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "have",
					"type": "address"
				},
				{
					"internalType": "address",
					"name": "owner",
					"type": "address"
				},
				{
					"internalType": "address",
					"name": "coordinator",
					"type": "address"
				}
			],
			"name": "OnlyOwnerOrCoordinator",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "ReentrancyGuardReentrantCall",
			"type": "error"
		},
		{
			"inputs": [],
			"name": "ZeroAddress",
			"type": "error"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": false,
					"internalType": "address",
					"name": "vrfCoordinator",
					"type": "address"
				}
			],
			"name": "CoordinatorSet",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				},
				{
					"indexed": true,
					"internalType": "address",
					"name": "player",
					"type": "address"
				},
				{
					"indexed": false,
					"internalType": "uint256",
					"name": "amount",
					"type": "uint256"
				}
			],
			"name": "FundsAllocated",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				},
				{
					"indexed": true,
					"internalType": "address",
					"name": "player",
					"type": "address"
				},
				{
					"indexed": false,
					"internalType": "uint256",
					"name": "playerShare",
					"type": "uint256"
				}
			],
			"name": "FundsClaimed",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				},
				{
					"indexed": false,
					"internalType": "address",
					"name": "canceller",
					"type": "address"
				}
			],
			"name": "GameCancelled",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				},
				{
					"indexed": true,
					"internalType": "address",
					"name": "nftOwner",
					"type": "address"
				},
				{
					"indexed": false,
					"internalType": "address",
					"name": "nftContract",
					"type": "address"
				},
				{
					"indexed": false,
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "GameCreated",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				},
				{
					"indexed": false,
					"internalType": "address",
					"name": "winner",
					"type": "address"
				}
			],
			"name": "GameEnded",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				},
				{
					"indexed": false,
					"internalType": "address",
					"name": "forceEnder",
					"type": "address"
				},
				{
					"indexed": false,
					"internalType": "uint256",
					"name": "reward",
					"type": "uint256"
				}
			],
			"name": "GameForceEnded",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				},
				{
					"indexed": false,
					"internalType": "uint256",
					"name": "newMinContribution",
					"type": "uint256"
				}
			],
			"name": "MinContributionUpdated",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "address",
					"name": "from",
					"type": "address"
				},
				{
					"indexed": true,
					"internalType": "address",
					"name": "to",
					"type": "address"
				}
			],
			"name": "OwnershipTransferRequested",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "address",
					"name": "from",
					"type": "address"
				},
				{
					"indexed": true,
					"internalType": "address",
					"name": "to",
					"type": "address"
				}
			],
			"name": "OwnershipTransferred",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": false,
					"internalType": "address",
					"name": "account",
					"type": "address"
				}
			],
			"name": "Paused",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "requestId",
					"type": "uint256"
				},
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				}
			],
			"name": "RandomnessRequested",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				},
				{
					"indexed": false,
					"internalType": "uint256[]",
					"name": "randomWords",
					"type": "uint256[]"
				}
			],
			"name": "RandomnessRequested",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				},
				{
					"indexed": true,
					"internalType": "address",
					"name": "player",
					"type": "address"
				},
				{
					"indexed": false,
					"internalType": "uint256",
					"name": "amount",
					"type": "uint256"
				}
			],
			"name": "RefundWithdrawn",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": false,
					"internalType": "address",
					"name": "account",
					"type": "address"
				}
			],
			"name": "Unpaused",
			"type": "event"
		},
		{
			"inputs": [],
			"name": "BASE_MIN_CONTRIBUTION",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "DEVELOPER_FEE",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "FORCE_END_REWARD_PERCENTAGE",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "GRACE_PERIOD",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "MAX_ACTIVE_GAMES_PER_USER",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "TREASURY_FEE_FORCED_END",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "TREASURY_FEE_NORMAL_END",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "acceptOwnership",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				}
			],
			"name": "allocateFunds",
			"outputs": [],
			"stateMutability": "payable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_totalFunds",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "_floorPrice",
					"type": "uint256"
				}
			],
			"name": "calculateMinContribution",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "pure",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				}
			],
			"name": "cancelGame",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				}
			],
			"name": "claimFunds",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "_nftContract",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "_tokenId",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "_floorPrice",
					"type": "uint256"
				},
				{
					"internalType": "bytes32",
					"name": "_salt",
					"type": "bytes32"
				},
				{
					"internalType": "uint256",
					"name": "_gameDuration",
					"type": "uint256"
				}
			],
			"name": "createGame",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				}
			],
			"stateMutability": "payable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				}
			],
			"name": "endGame",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				}
			],
			"name": "forceEndGame",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				},
				{
					"internalType": "address",
					"name": "_playerAddress",
					"type": "address"
				}
			],
			"name": "getAllPlayerActiveBands",
			"outputs": [
				{
					"internalType": "uint8",
					"name": "",
					"type": "uint8"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "_creatorAddress",
					"type": "address"
				}
			],
			"name": "getCreatorActiveGames",
			"outputs": [
				{
					"internalType": "uint256[]",
					"name": "",
					"type": "uint256[]"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				}
			],
			"name": "getGameInfo",
			"outputs": [
				{
					"internalType": "address",
					"name": "nftOwner",
					"type": "address"
				},
				{
					"internalType": "address",
					"name": "nftContract",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "endTime",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "totalFunds",
					"type": "uint256"
				},
				{
					"internalType": "bool",
					"name": "isActive",
					"type": "bool"
				},
				{
					"internalType": "bool",
					"name": "isCanceled",
					"type": "bool"
				},
				{
					"internalType": "bool",
					"name": "nftClaimed",
					"type": "bool"
				},
				{
					"internalType": "uint256",
					"name": "playerCount",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "minContribution",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "floorPrice",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				}
			],
			"name": "getGamesCurrentExtractableValueForNftTransfer",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "extractableValue",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				}
			],
			"name": "getMinContribution",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				}
			],
			"name": "getNFTDetails",
			"outputs": [
				{
					"internalType": "address",
					"name": "nftContract",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "_playerAddress",
					"type": "address"
				}
			],
			"name": "getPlayerActiveGames",
			"outputs": [
				{
					"internalType": "uint256[]",
					"name": "",
					"type": "uint256[]"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				},
				{
					"internalType": "address",
					"name": "_playerAddress",
					"type": "address"
				}
			],
			"name": "getPlayerBand",
			"outputs": [
				{
					"internalType": "uint8",
					"name": "",
					"type": "uint8"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				},
				{
					"internalType": "address",
					"name": "_playerAddress",
					"type": "address"
				}
			],
			"name": "getPlayerContribution",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				},
				{
					"internalType": "address",
					"name": "_playerAddress",
					"type": "address"
				}
			],
			"name": "getPlayerIndexInBand",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				},
				{
					"internalType": "uint8",
					"name": "_bandNumber",
					"type": "uint8"
				}
			],
			"name": "getPlayersInBand",
			"outputs": [
				{
					"internalType": "address[]",
					"name": "",
					"type": "address[]"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_floorPriceInETH",
					"type": "uint256"
				}
			],
			"name": "getRequiredFee",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				}
			],
			"name": "getTotalPlayersInGame",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "i_developerAddress",
			"outputs": [
				{
					"internalType": "address",
					"name": "",
					"type": "address"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "i_treasuryAddress",
			"outputs": [
				{
					"internalType": "address",
					"name": "",
					"type": "address"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				}
			],
			"name": "isGameActive",
			"outputs": [
				{
					"internalType": "bool",
					"name": "",
					"type": "bool"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				}
			],
			"name": "isGracePeriodOver",
			"outputs": [
				{
					"internalType": "bool",
					"name": "",
					"type": "bool"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_gameId",
					"type": "uint256"
				},
				{
					"internalType": "address",
					"name": "_playerAddress",
					"type": "address"
				}
			],
			"name": "isPlayerInGame",
			"outputs": [
				{
					"internalType": "bool",
					"name": "",
					"type": "bool"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "",
					"type": "address"
				},
				{
					"internalType": "address",
					"name": "",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				},
				{
					"internalType": "bytes",
					"name": "",
					"type": "bytes"
				}
			],
			"name": "onERC721Received",
			"outputs": [
				{
					"internalType": "bytes4",
					"name": "",
					"type": "bytes4"
				}
			],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "owner",
			"outputs": [
				{
					"internalType": "address",
					"name": "",
					"type": "address"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "paused",
			"outputs": [
				{
					"internalType": "bool",
					"name": "",
					"type": "bool"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "requestId",
					"type": "uint256"
				},
				{
					"internalType": "uint256[]",
					"name": "randomWords",
					"type": "uint256[]"
				}
			],
			"name": "rawFulfillRandomWords",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"name": "s_activeGames",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				},
				{
					"internalType": "uint8",
					"name": "bandNumber",
					"type": "uint8"
				},
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"name": "s_bandedPlayers",
			"outputs": [
				{
					"internalType": "address",
					"name": "players",
					"type": "address"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "playerAddress",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"name": "s_creatorActiveGames",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "gameIds",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "s_gameCounter",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"name": "s_gameIdToActiveGameIndex",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				}
			],
			"name": "s_gameIdToRequestId",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "requestID",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"name": "s_gameParticipants",
			"outputs": [
				{
					"internalType": "address",
					"name": "playerAddresses",
					"type": "address"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				}
			],
			"name": "s_games",
			"outputs": [
				{
					"internalType": "address",
					"name": "nftOwner",
					"type": "address"
				},
				{
					"internalType": "address",
					"name": "nftContract",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "endTime",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "totalFunds",
					"type": "uint256"
				},
				{
					"internalType": "bool",
					"name": "isActive",
					"type": "bool"
				},
				{
					"internalType": "bool",
					"name": "isCanceled",
					"type": "bool"
				},
				{
					"internalType": "bool",
					"name": "nftClaimed",
					"type": "bool"
				},
				{
					"internalType": "uint256",
					"name": "playerCount",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "minContribution",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "floorPrice",
					"type": "uint256"
				},
				{
					"internalType": "bytes32",
					"name": "salt",
					"type": "bytes32"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				},
				{
					"internalType": "address",
					"name": "playerAddress",
					"type": "address"
				}
			],
			"name": "s_playerActiveBand",
			"outputs": [
				{
					"internalType": "uint8",
					"name": "activeBand",
					"type": "uint8"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "playerAddress",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"name": "s_playerActiveGames",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "gameIds",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				},
				{
					"internalType": "address",
					"name": "playerAddress",
					"type": "address"
				}
			],
			"name": "s_playerContributions",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "contributionAmount",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				},
				{
					"internalType": "address",
					"name": "playerAddress",
					"type": "address"
				}
			],
			"name": "s_playerGameIndexInActiveGames",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "indexOfPlayer",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				},
				{
					"internalType": "address",
					"name": "playerAddress",
					"type": "address"
				}
			],
			"name": "s_playerIndexInBand",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "indexOfPlayer",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "requestId",
					"type": "uint256"
				}
			],
			"name": "s_requestIdToGameId",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "gameId",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "s_vrfCoordinator",
			"outputs": [
				{
					"internalType": "contract IVRFCoordinatorV2Plus",
					"name": "",
					"type": "address"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "_vrfCoordinator",
					"type": "address"
				}
			],
			"name": "setCoordinator",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "to",
					"type": "address"
				}
			],
			"name": "transferOwnership",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		}
	]

export {NFTGameABI}
