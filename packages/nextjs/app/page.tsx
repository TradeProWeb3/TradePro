"use client";

import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { Address } from "~~/components/scaffold-eth";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth/useScaffoldReadContract";
import { formatEther } from "viem";
import ProductCard from "../components/ProductCard";
import ProductCard1 from "~~/components/ProductCard1";
import ProductCard2 from "~~/components/Productcard2";
import Start from "~~/components/startbutton";



export default function Page() {
return (
  <main className="min-h-screen flex flex-col justify-start bg-black pt-2 px-8">

    {/* container for button and cards */}
    <div className="flex flex-row items-start space-x-10 mt-4">

      {/* Button on the left */}
      <div className="self-start scale-90">
        <Start />
      </div>

      {/* Cards on the right */}
      <div className="scale-80 flex flex-row items-start space-x-10 -mt-10">
        <ProductCard />
        <ProductCard1 />
        <ProductCard2 />
      </div>

    </div>

  </main>
);

}