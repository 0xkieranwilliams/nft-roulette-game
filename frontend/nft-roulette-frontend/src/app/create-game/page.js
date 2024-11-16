"use client";

import { useState, useCallback } from 'react';
import { useContractRead, useWriteContract, useConfig, useAccount } from 'wagmi';
import { parseEther } from 'viem';
import { NFTGameABI } from '@/contracts/abis';
import { waitForTransactionReceipt } from 'wagmi/actions';
import toast from 'react-hot-toast';

const CONTRACT_ADDRESS = "0x27013320E8e71995609240D61914E2f25437181c";

export default function CreateGame() {
  const [nftAddress, setNftAddress] = useState('');
  const [tokenId, setTokenId] = useState('');
  const [duration, setDuration] = useState('');
  const [floorPrice, setFloorPrice] = useState('');
  const [pendingTx, setPendingTx] = useState(false);

  const { address } = useAccount();
  const wagmiConfig = useConfig();

  // Get required fee for game creation based on floor price
  const { data: requiredFee } = useContractRead({
    address: CONTRACT_ADDRESS,
    abi: NFTGameABI,
    functionName: 'getRequiredFee',
    args: [floorPrice ? parseEther(floorPrice) : '0'],
    enabled: !!floorPrice
  });

  const { writeContract } = useWriteContract();

  const handleSubmit = async (e) => {
    e.preventDefault();

    console.log("helloooo")
    
    if (!address) {
      toast.error('Please connect your wallet first');
      return;
    }

    setPendingTx(true);
    console.log("Starting game creation...");
    
    try {
      // Generate random salt for the game (32 bytes)
      const saltArray = new Uint8Array(32);
      crypto.getRandomValues(saltArray);
      const salt = `0x${Array.from(saltArray).map(b => b.toString(16).padStart(2, '0')).join('')}`;

      console.log("Contract params:", {
        address: CONTRACT_ADDRESS,
        nftAddress,
        tokenId,
        floorPrice: parseEther(floorPrice).toString(),
        salt,
        duration: (BigInt(duration) * 86400n).toString(),
        requiredFee: requiredFee?.toString()
      });

      const tx =  writeContract({
        address: CONTRACT_ADDRESS,
        abi: NFTGameABI,
        functionName: 'createGame',
        args: [
          nftAddress,                     // NFT contract address
          BigInt(tokenId),                // Token ID
          parseEther(floorPrice),         // Floor price in ETH
          salt,                           // Random salt
          BigInt(duration) * 86400n       // Duration in seconds (converting days to seconds)
        ],
        value: requiredFee               // Creation fee
      });

      console.log("Transaction submitted:", tx);
      console.log("Transaction submitted:");

      if (tx) {
        const receipt = await waitForTransactionReceipt(wagmiConfig, { hash: tx });
        console.log("Transaction receipt:", receipt);
        toast.success('Game created successfully!');
        
        // Reset form
        setNftAddress('');
        setTokenId('');
        setDuration('');
        setFloorPrice('');
      }
      
    } catch (err) {
      console.error('Error creating game:', err);
      toast.error(err.message || 'Failed to create game');
    } finally {
      setPendingTx(false);
    }
  };

  return (
    <div className="container pt-24">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-4xl font-bold mb-2">Create New Game</h1>
        <p className="text-gray-400 mb-8">Stake your NFT and set game parameters</p>

        <div className="card">
          <form className="space-y-6">
            <div>
              <label className="text-sm text-gray-400 block mb-2">
                NFT Contract Address
              </label>
              <input
                type="text"
                value={nftAddress}
                onChange={(e) => setNftAddress(e.target.value)}
                placeholder="0x..."
                required
                className="w-full"
              />
            </div>

            <div className="grid grid-cols-2 gap-6">
              <div>
                <label className="text-sm text-gray-400 block mb-2">
                  Token ID
                </label>
                <input
                  type="number"
                  value={tokenId}
                  onChange={(e) => setTokenId(e.target.value)}
                  placeholder="1234"
                  required
                  className="w-full"
                />
              </div>

              <div>
                <label className="text-sm text-gray-400 block mb-2">
                  Duration (Days)
                </label>
                <input
                  type="number"
                  value={duration}
                  onChange={(e) => setDuration(e.target.value)}
                  placeholder="7"
                  required
                  min="1"
                  className="w-full"
                />
              </div>
            </div>

            <div>
              <label className="text-sm text-gray-400 block mb-2">
                Floor Price (ETH)
              </label>
              <input
                type="number"
                step="0.01"
                value={floorPrice}
                onChange={(e) => setFloorPrice(e.target.value)}
                placeholder="0.1"
                required
                min="0"
                className="w-full"
              />
            </div>

            {requiredFee && (
              <div className="bg-[#1e1e1e] p-4 rounded-lg">
                <p className="text-sm text-gray-400">Required Creation Fee</p>
                <p className="text-lg font-bold">
                  {(Number(requiredFee) / 1e18).toFixed(4)} ETH
                </p>
              </div>
            )}

            <button 
              onClick={handleSubmit}
              disabled={pendingTx || !requiredFee || !address}
              className="w-full"
            >
              {!address ? 'Connect Wallet to Create' :
               pendingTx ? 'Creating Game...' : 'Create Game'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
