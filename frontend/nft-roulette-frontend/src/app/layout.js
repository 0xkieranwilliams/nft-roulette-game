import localFont from "next/font/local";
import "./globals.css";

import React, { Suspense } from 'react';
import { Toaster } from 'react-hot-toast';

import Providers from "@/lib/providers"
import Navbar from "@/components/Navbar/Navbar"

const geistSans = localFont({
  src: "./fonts/GeistVF.woff",
  variable: "--font-geist-sans",
  weight: "100 900",
});
const geistMono = localFont({
  src: "./fonts/GeistMonoVF.woff",
  variable: "--font-geist-mono",
  weight: "100 900",
});

export const metadata = {
  title: "Spiinz",
  description: "Onchain NFT Lottery Gaming",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
        <body
          className={`${geistSans.variable} ${geistMono.variable} antialiased`}
        >
          <Providers> 
            <Suspense fallback={<div>Loading...</div>}>
              <Navbar/>
              <Toaster position="top-right" />
              {children}
            </Suspense>
          </Providers> 
        </body>
    </html>
  );
}
