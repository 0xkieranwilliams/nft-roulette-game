import Image from "next/image";
import {DynamicWidget } from '@dynamic-labs/sdk-react-core';
import Link from 'next/link';
import { useAccount } from 'wagmi';

function AccountInfo() {
  const { address, isConnected, chain } = useAccount();
  return (
    <div>
      <p>
        wagmi connected: {isConnected ? 'true' : 'false'}
      </p>
      <p>wagmi address: {address}</p>
      <p>wagmi network: {chain?.id}</p>
    </div>
  );
}

export default function Navbar() {
  return (
    <div className="navbar relative flex items-center justify-between px-6 py-4 bg-black" style={{height: "120px"}}>
      <Link href="/" className="absolute top-0 left-6">
        <Image 
          src="/spiinz-logo.png" 
          width="170" 
          height="170" 
          alt="logo"
          className="transform translate-y-[10px] translate-x-[30px]" // This makes the logo overlap the bottom
        />
      </Link>
      <div className="flex-1 flex justify-center">
        <div className="flex gap-4 ml-[180px]">
          <Link 
            href="/game-portfolio?user=player" 
            className="text-white hover:text-[#00ffb3] transition-colors"
          >
            My Plays
          </Link>
          <Link 
            href="/game-portfolio?user=creator" 
            className="text-white hover:text-[#00ffb3] transition-colors"
          >
            Created Games
          </Link>
          <Link 
            href="/create-game" 
            className="text-white hover:text-[#00ffb3] transition-colors"
          >
            Create New Game
          </Link>
        </div>
      </div>
      <div className="flex-none">
        <DynamicWidget />
      </div>
    </div>
  )
}
