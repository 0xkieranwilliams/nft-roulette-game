"use client";
import { useContractRead } from 'wagmi';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import GameCard from '@/components/GameCard';
import { NFTGameABI } from '@/contracts/abis';

const CONTRACT_ADDRESS = "0x27013320E8e71995609240D61914E2f25437181c";

// Dummy game data
const DUMMY_GAMES = [
  {
    id: "demo-1",
    nftOwner: "0x1234...5678",
    nftContract: "0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D", // BAYC contract
    tokenId: "1234",
    endTime: (Date.now() / 1000 + 7 * 24 * 60 * 60).toString(), // 7 days from now
    totalFunds: BigInt("1500000000000000000"), // 1.5 ETH
    isActive: true,
    playerCount: BigInt("25"),
    minContribution: BigInt("20000000000000000"), // 0.02 ETH
    floorPrice: BigInt("200000000000000000"), // 0.2 ETH
    isDummy: true
  },
  {
    id: "demo-2",
    nftOwner: "0x9876...4321",
    nftContract: "0x60E4d786628Fea6478F785A6d7e704777c86a7c6", // MAYC contract
    tokenId: "5678",
    endTime: (Date.now() / 1000 + 3 * 24 * 60 * 60).toString(), // 3 days from now
    totalFunds: BigInt("2500000000000000000"), // 2.5 ETH
    isActive: true,
    playerCount: BigInt("42"),
    minContribution: BigInt("50000000000000000"), // 0.05 ETH
    floorPrice: BigInt("300000000000000000"), // 0.3 ETH
    isDummy: true
  }
];

export default function Home() {
  const [games, setGames] = useState([]);
  const [showDummy, setShowDummy] = useState(true);

  // Get active games array
  const { data: activeGames, isLoading: isLoadingGames } = useContractRead({
    address: CONTRACT_ADDRESS,
    abi: NFTGameABI,
    functionName: 's_activeGames'
  });

  // Get game info for each active game
  const { data: gamesInfo, isLoading: isLoadingInfo } = useContractRead({
    address: CONTRACT_ADDRESS,
    abi: NFTGameABI,
    functionName: 'getGameInfo',
    watch: true,
    args: activeGames ? [activeGames[0]] : undefined,
    enabled: !!activeGames?.length
  });

  useEffect(() => {
    if (activeGames && gamesInfo) {
      const formattedGames = activeGames.map((gameId, index) => ({
        id: gameId,
        nftOwner: gamesInfo[0],
        nftContract: gamesInfo[1],
        tokenId: gamesInfo[2],
        endTime: gamesInfo[3],
        totalFunds: gamesInfo[4],
        isActive: gamesInfo[5],
        playerCount: gamesInfo[8],
        minContribution: gamesInfo[9],
        floorPrice: gamesInfo[10],
        isDummy: false
      }));
      setGames(formattedGames);
      setShowDummy(formattedGames.length === 0);
    }
  }, [activeGames, gamesInfo]);

  if (isLoadingGames || isLoadingInfo) {
    return (
      <div className="container pt-24">
        <div className="text-center">
          <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-[#00ffb3] border-r-transparent"></div>
          <p className="mt-4 text-gray-400">Loading games...</p>
        </div>
      </div>
    );
  }

  const displayGames = showDummy ? DUMMY_GAMES : games;

  return (
    <main className="container pt-24">
      <div className="mb-12">
        <h1 className="text-4xl font-bold mb-2">Active Games</h1>
        <p className="text-gray-400">Join an active game from the discovery page</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        {displayGames.map((game) => (
          <GameCard key={game.id.toString()} game={game} />
        ))}
        
        {displayGames.length === 0 && (
          <div className="card text-center py-12 col-span-full">
            <p className="text-xl text-gray-400 mb-6">No active games found</p>
            <Link href="/create-game">
              <button>Create a Game</button>
            </Link>
          </div>
        )}
      </div>

    </main>
  );
}
