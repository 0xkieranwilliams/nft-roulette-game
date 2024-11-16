import localFont from "next/font/local";
import "./globals.css";

import Providers from "@/lib/providers"

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
      <Providers> 
        <body
          className={`${geistSans.variable} ${geistMono.variable} antialiased`}
        >
          {children}
        </body>
      </Providers> 
    </html>
  );
}
