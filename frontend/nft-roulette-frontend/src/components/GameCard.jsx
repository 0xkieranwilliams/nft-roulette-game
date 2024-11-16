import { formatEther } from 'viem';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';

export default function GameCard({ game, userType }) {
  const searchParams = useSearchParams();
  const {
    id,
    nftContract,
    tokenId,
    endTime,
    totalFunds,
    playerCount,
    minContribution,
    floorPrice
  } = game;

  const timeLeft = Math.max(0, Math.floor((new Date(Number(endTime) * 1000) - new Date()) / (1000 * 60 * 60 * 24)));

  return (
    <div className="card hover:transform hover:-translate-y-2 transition-all duration-300">
      <div className="flex justify-between items-start mb-6">
        <h3 className="text-xl font-bold text-white">Game #{id.toString()}</h3>
        <div className="bg-[#1e1e1e] px-3 py-1 rounded-full">
          <span className="text-[#00ffb3] text-sm font-medium">
            {timeLeft} days left
          </span>
        </div>
      </div>
      
      <div className="space-y-6">
        <div className="grid grid-cols-2 gap-6">
          <div>
            <p className="text-sm text-gray-400 mb-1">Floor Price</p>
            <p className="text-lg font-bold text-white">{formatEther(floorPrice)} ETH</p>
          </div>
          <div>
            <p className="text-sm text-gray-400 mb-1">Total Pool</p>
            <p className="text-lg font-bold text-white">{formatEther(totalFunds)} ETH</p>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-6">
          <div>
            <p className="text-sm text-gray-400 mb-1">Players</p>
            <p className="text-lg font-bold text-white">{playerCount.toString()}</p>
          </div>
          <div>
            <p className="text-sm text-gray-400 mb-1">Min Entry</p>
            <p className="text-lg font-bold text-white">{formatEther(minContribution)} ETH</p>
          </div>
        </div>

        <div className="border-t border-gray-800 pt-4">
          <p className="text-sm text-gray-400 truncate mb-4">
            NFT: {nftContract}#{tokenId.toString()}
          </p>
          <Link href={`/game?user=${userType}`} className="block w-full">
            <button className="w-full">Open Game</button>
          </Link>
        </div>
      </div>
    </div>
  );
}
