"use client";

import { useContractRead } from 'wagmi';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import GameCard from '@/components/GameCard';
import { NFTGameABI } from '@/contracts/abis';

const CONTRACT_ADDRESS = "0x27013320E8e71995609240D61914E2f25437181c";

export default function Home() {
  const [games, setGames] = useState([]);

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
        floorPrice: gamesInfo[10]
      }));
      setGames(formattedGames);
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

  return (
    <main className="container pt-24">
      <div className="mb-12">
        <h1 className="text-4xl font-bold mb-2">Active Games</h1>
        <p className="text-gray-400">Join an active game or create your own</p>
      </div>

      {games.length === 0 ? (
        <div className="card text-center py-12">
          <p className="text-xl text-gray-400 mb-6">No active games found</p>
          <Link href="/create-game">
            <button>Create a Game</button>
          </Link>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {games.map((game) => (
            <GameCard key={game.id.toString()} game={game} />
          ))}
        </div>
      )}
    </main>
  );
}
