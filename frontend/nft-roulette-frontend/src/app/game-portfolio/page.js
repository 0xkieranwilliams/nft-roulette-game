"use client";
import React, { Suspense } from 'react';
import { useContractRead } from 'wagmi';
import { useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';
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
];

export default function GamePortfolio() {
  const [games, setGames] = useState([]);
  const [showDummy, setShowDummy] = useState(true);
  const searchParams = useSearchParams();
  const userType = searchParams.get('user');

  // Get page title based on user type
  const getPageTitle = () => {
    switch (userType) {
      case 'creator':
        return {
          title: "My Created Games",
          subtitle: "Games where you've staked your NFTs"
        };
      case 'player':
        return {
          title: "My Active Games",
          subtitle: "Games you've entered"
        };
      default:
        return {
          title: "Game Portfolio",
          subtitle: "View your games"
        };
    }
  };

  // Get active games array
  const { data: activeGames, isLoading: isLoadingGames } = useContractRead({
    address: CONTRACT_ADDRESS,
    abi: NFTGameABI,
    functionName: userType === 'creator' ? 's_creatorActiveGames' : 's_playerActiveGames'
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
  const { title, subtitle } = getPageTitle();

  return (
    <Suspense fallback={<div>Loading...</div>}>
    <main className="container pt-24">
      <div className="mb-12">
        <h1 className="text-4xl font-bold mb-2">{title}</h1>
        <p className="text-gray-400">{subtitle}</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        {displayGames.map((game) => (
          <GameCard key={game.id.toString()} game={game} userType={userType}/>
        ))}
        
        {displayGames.length === 0 && (
          <div className="card text-center py-12 col-span-full">
            <p className="text-xl text-gray-400 mb-6">
              {userType === 'creator' 
                ? "You haven't created any games yet" 
                : "You haven't entered any games yet"}
            </p>
          </div>
        )}
      </div>
    </main>
    </Suspense>
  );
}
