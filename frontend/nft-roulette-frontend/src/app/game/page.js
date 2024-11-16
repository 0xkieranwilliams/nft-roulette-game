"use client";
import React, { Suspense, useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import Image from 'next/image';

// Mock data
const MOCK_GAME = {
  id: "1",
  nftContract: "0x1234...5678",
  tokenId: "1234",
  nftOwner: "0xabcd...efgh",
  timeLeft: 7,
  floorPrice: "0.2",
  totalPool: "1.5",
  playerCount: "25",
  minContribution: "0.02",
  myContribution: "0.1",
  isActive: true
};

export default function GameDetail() {
  const searchParams = useSearchParams();
  const userType = searchParams.get('user');
  const isCreator = userType === 'creator';
  const [contributionAmount, setContributionAmount] = useState('');
  const [pendingTx, setPendingTx] = useState(false);

  const mockTransaction = async () => {
    setPendingTx(true);
    await new Promise(resolve => setTimeout(resolve, 2000)); // Simulate transaction
    setPendingTx(false);
  };

  return (
    <Suspense>
    <div className="container pt-24">
      <div className="max-w-4xl mx-auto">
        <div className="card p-6">
          <div className="flex justify-between items-start mb-6">
            <div>
              <h1 className="text-3xl font-bold mb-2">Game #{MOCK_GAME.id}</h1>
              <p className="text-gray-400">
                {MOCK_GAME.timeLeft} days remaining
              </p>
            </div>
          </div>

          <div className="grid md:grid-cols-2 gap-8 mb-8">
            <div>
              <h2 className="text-xl font-bold mb-4">Game Info</h2>
              <div className="space-y-2">
                <p>Floor Price: {MOCK_GAME.floorPrice} ETH</p>
                <p>Total Pool: {MOCK_GAME.totalPool} ETH</p>
                <p>Players: {MOCK_GAME.playerCount}</p>
                <p>Min Contribution: {MOCK_GAME.minContribution} ETH</p>
              </div>

            </div>

            <div>
              <div className="relative w-full h-[300px] rounded-lg overflow-hidden mb-4">
                <Image
                  src="/spiinz-logo.png" // Make sure to add this image to your public folder
                  alt="NFT"
                  fill
                  style={{ objectFit: "contain" }}
                />
              </div>
              <div className="space-y-2">
                <p>Contract: {MOCK_GAME.nftContract}</p>
                <p>Token ID: {MOCK_GAME.tokenId}</p>
                <p>Owner: {MOCK_GAME.nftOwner}</p>
              </div>
            </div>
          </div>

            <div style={{width: "320px" }}>
              {isCreator && MOCK_GAME.isActive && (
                <button 
                  onClick={mockTransaction}
                  disabled={MOCK_GAME.isActive}
                  className="!px-6"
                >
                  {pendingTx ? 'Processing...' : 'Cancel Game'}
                </button>
              )}
              {isCreator && MOCK_GAME.isActive && (
                <button 
                  onClick={mockTransaction}
                  disabled={MOCK_GAME.isActive}
                  className="!px-6 ml-2"
                >
                  {pendingTx ? 'Processing...' : 'End Game'}
                </button>
              )}
            </div>
          {!isCreator && MOCK_GAME.isActive && (
            <div className="bg-[#1e1e1e] p-6 rounded-lg">
              <h2 className="text-xl font-bold mb-4">Join Game</h2>
              <div className="grid grid-cols-2 gap-4 mb-4">
                <div>
                  <p className="text-sm text-gray-400 mb-1">Your Contribution</p>
                  <p className="text-lg font-bold">
                    {MOCK_GAME.myContribution} ETH
                  </p>
                </div>
                <div>
                  <p className="text-sm text-gray-400 mb-1">Minimum Contribution</p>
                  <p className="text-lg font-bold">{MOCK_GAME.minContribution} ETH</p>
                </div>
              </div>

              <div className="flex gap-4">
                <input
                  type="number"
                  step="0.01"
                  placeholder="Amount in ETH"
                  className="flex-1"
                  min={MOCK_GAME.minContribution}
                  value={contributionAmount}
                  onChange={(e) => setContributionAmount(e.target.value)}
                />
                <button
                  onClick={mockTransaction}
                  disabled={pendingTx || !contributionAmount}
                  className="!px-8"
                >
                  {pendingTx ? 'Contributing...' : 'Contribute'}
                </button>
              </div>
            </div>
          )}

          {/* Game Status Banner */}
          <div className="mt-6 p-4 bg-[rgba(0,255,179,0.1)] border border-[#00ffb3] rounded-lg">
            <p className="text-[#00ffb3] text-sm">
              {isCreator 
                ? "You're the creator of this game. You can end it once the time expires."
                : "You've contributed to this game. Wait for the game to end to see if you've won!"}
            </p>
          </div>
        </div>
      </div>
    </div>
    </Suspense>
  );
}
