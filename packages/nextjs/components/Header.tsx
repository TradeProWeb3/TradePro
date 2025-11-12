"use client";

import React, { useRef } from "react";
import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { hardhat } from "viem/chains";
import { Bars3Icon, BugAntIcon } from "@heroicons/react/24/outline";
import { RainbowKitCustomConnectButton } from "~~/components/scaffold-eth";
import { useOutsideClick, useTargetNetwork } from "~~/hooks/scaffold-eth";
import {FaGithub} from "react-icons/fa"
import { FaXTwitter } from "react-icons/fa6";
import { FaBook } from "react-icons/fa";
import { CiMail } from "react-icons/ci";



/**
 * Site header
 */
export const Header = () => {
  const { targetNetwork } = useTargetNetwork();
  const isLocalNetwork = targetNetwork.id === hardhat.id;

  const burgerMenuRef = useRef<HTMLDetailsElement>(null);
  useOutsideClick(burgerMenuRef, () => {
    burgerMenuRef?.current?.removeAttribute("open");
  });

  return (
    <div className="sticky lg:static top-0 navbar bg-base-100 min-h-0 shrink-0 justify-between z-20 shadow-md shadow-secondary px-0 sm:px-2">
      <div className="navbar-start w-auto lg:w-1/2">
        <details className="dropdown" ref={burgerMenuRef}>
          <summary className="ml-1 btn btn-ghost lg:hidden hover:bg-transparent">
            <Bars3Icon className="h-1/2" />
          </summary>

        </details>
<div className="flex items-center gap-3">
  <Image
    src="/logo2.jpg"
    alt="TRADE-PRO Logo"
    width={114}   // width ≈ 3 cm
    height={76}   // height ≈ 2 cm
    className="object-contain"
  />
</div>
         <li className="flex items-center gap-4 ml-4">
    <div className="flex items-center gap-x-6">
    <Link
    href="https://x.com/TradeProWeb3"
    target="_blank"
    rel="noopener noreferrer"
    className="text-3xl text-slate-600 hover:text-amber-400 dark:text-slate-200 dark:hover:text-amber-300 transition-colors duration-200"
  >
    <FaXTwitter/>
  </Link>
 <Link
    href="https://github.com/TradeProWeb3/TradePro"
    target="_blank"
    rel="noopener noreferrer"
    className="text-3xl text-slate-600 hover:text-amber-400 dark:text-slate-200 dark:hover:text-amber-300 transition-colors duration-200"
  >
    <FaGithub />
  </Link>
 <Link
    href="https://docs.google.com/presentation/d/1Iw2cUxO_S5Vv2UQPCAiTglm8uVvyb059X0x86JlfMX4/edit?usp=sharing"
    target="_blank"
    rel="noopener noreferrer"
    className="text-3xl text-slate-600 hover:text-amber-400 dark:text-slate-200 dark:hover:text-amber-300 transition-colors duration-200"
      >
    <FaBook />
  </Link>
 <Link
    href="mailto:tradepro.web3@gmail.com"
    target="_blank"
    rel="noopener noreferrer"
    className="text-3xl text-slate-600 hover:text-amber-400 dark:text-slate-200 dark:hover:text-amber-300 transition-colors duration-200"
  >
    <CiMail />
  </Link>
  </div>
</li>
  
      </div>
      <div className="navbar-end grow mr-4">
        <RainbowKitCustomConnectButton />
        
      </div>
    </div>
  );
};
