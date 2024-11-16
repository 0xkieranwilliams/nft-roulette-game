import Image from "next/image";
import {DynamicWidget } from '@dynamic-labs/sdk-react-core';

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
    <div className="navbar">
      <Image src="/spiinz-logo.png" width="130" height="130" alt="logo"/>
      <DynamicWidget />
    </div>
  )
}
