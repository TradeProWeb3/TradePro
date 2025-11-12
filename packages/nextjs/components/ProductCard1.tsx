"use client";

import React, { useState, useEffect } from "react";
import { useAccount } from "wagmi";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth/useScaffoldReadContract";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth/useScaffoldWriteContract";
import { formatEther, parseEther } from "viem";
import { ThumbsUp, ThumbsDown } from "lucide-react";

// 🏦 component for James's Vault
export default function ProductCard1() {
  const { address } = useAccount(); // current connected wallet
  const vaultId = BigInt(1); // vaultId = 1 → James's vault

  // --- Reading from contract ---
  const { data: userDeposit, refetch } = useScaffoldReadContract({
    contractName: "VaultFactory",
    functionName: "getUserVaultDeposits",
    args: [vaultId, address],
  });

  const { data: vaultData, refetch: reloadVaultData } = useScaffoldReadContract({
    contractName: "VaultFactory",
    functionName: "getVault",
    args: [vaultId],
  });

  const { data: TVL, refetch: reloadTVL } = useScaffoldReadContract({
    contractName: "VaultFactory",
    functionName: "getVaultTotalDeposits",
    args: [vaultId],
  });

  const { data: isMember } = useScaffoldReadContract({
    contractName: "VaultFactory",
    functionName: "isMember",
    args: [vaultId, address],
  });

  // --- writing the contract ---
  const { writeContractAsync } = useScaffoldWriteContract("VaultFactory");

  // --- Interface states ---
  const [ethPrice, setEthPrice] = useState<number>(0);
  const [randomBonus, setRandomBonus] = useState<number>(0);
  const [currentIncome, setCurrentIncome] = useState<number>(0);

  const [showDepositModal, setShowDepositModal] = useState(false);
  const [depositAmount, setDepositAmount] = useState("");

  const [showAddAmount, setShowAddAmount] = useState(false);
  const [addAmount, setAddAmount] = useState("");

  const [showWithdrawModal, setShowWithdrawModal] = useState(false);
  const [withdrawAmount, setWithdrawAmount] = useState("");

  const [showVaultDetails, setShowVaultDetails] = useState(false);

  // --- Rating and votes ---
  const [likes, setLikes] = useState(0);
  const [dislikes, setDislikes] = useState(0);
  const [userVoted, setUserVoted] = useState(false);
  const [rating, setRating] = useState(4.0);

  // --- Loading saved likes ---
  useEffect(() => {
    if (!address) return;
    const savedLikes = localStorage.getItem("jamesVaultLikes");
    const savedDislikes = localStorage.getItem("jamesVaultDislikes");
    const voted = localStorage.getItem(`jamesVaultVoted_${address}`);

    if (savedLikes) setLikes(parseInt(savedLikes));
    if (savedDislikes) setDislikes(parseInt(savedDislikes));
    setUserVoted(voted === "true");
  }, [address]);

  // --- Saving likes/dislikes ---
  useEffect(() => {
    localStorage.setItem("jamesVaultLikes", likes.toString());
    localStorage.setItem("jamesVaultDislikes", dislikes.toString());
  }, [likes, dislikes]);

  // --- Recalculating rating ---
  useEffect(() => {
    const total = likes + dislikes;
    if (total === 0) return setRating(4.0);
    const ratio = (likes / total) * 100;

    if (ratio >= 81) setRating(5.0);
    else if (ratio >= 61) setRating(4.0);
    else if (ratio >= 41) setRating(3.0);
    else if (ratio >= 21) setRating(2.0);
    else setRating(1.0);
  }, [likes, dislikes]);

  // --- ETH price (USD) ---
  useEffect(() => {
    async function fetchPrice() {
      try {
        const res = await fetch(
          "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd"
        );
        const data = await res.json();
        setEthPrice(data.ethereum.usd);
      } catch (err) {
        console.error("ETH price error:", err);
      }
    }
    fetchPrice();
  }, []);

  // --- Random bonus (0–100 USDT every 30 sec) ---
  useEffect(() => {
    const getRandom = () => Math.floor(Math.random() * 101);
    setRandomBonus(getRandom());
    const interval = setInterval(() => setRandomBonus(getRandom()), 30000);
    return () => clearInterval(interval);
  }, []);

  // --- Calculating current income ---
  useEffect(() => {
    if (!userDeposit || ethPrice === 0) return setCurrentIncome(0);
    const depositEth = parseFloat(formatEther(userDeposit));
    const depositUsdt = depositEth * ethPrice;
    const income = depositUsdt * 0.5 + randomBonus;
    setCurrentIncome(income);
  }, [userDeposit, ethPrice, randomBonus]);

console.log("address:", address);
console.log("userDeposit raw:", userDeposit);
console.log("vaultData raw:", vaultData);
console.log("TVL raw:", TVL);

  
  // --- JSX interface ---
  return (
    <div className="w-full max-w-sm bg-white border border-gray-200 rounded-lg shadow-sm dark:bg-gray-800 dark:border-gray-700 relative group mt-0">
      <img className="p-8 rounded-t-lg" src="/James.png" alt="Trader James" />

      {/* Tooltip description */}
   <div
  className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-3 py-1 
             text-xl text-white bg-gray-900 rounded-md opacity-0 
             group-hover:opacity-100 transition-opacity duration-300 cursor-pointer 
             whitespace-nowrap"
  onClick={() => setShowVaultDetails(true)}
>
  Click to get details about James's vault
</div>

      <div className="px-5 pb-5">
        {/* title */}
       <h5
  className="font-sans text-xl md:text-xl font-extrabold 
             bg-gradient-to-r from-blue-300 via-indigo-400 to-purple-600 
             dark:from-blue-400 dark:via-indigo-500 dark:to-purple-700 
             bg-clip-text text-transparent 
             drop-shadow-[0_0_10px_rgba(90,90,255,0.3)]
             tracking-wider leading-snug text-center uppercase"
>
  YOU CAN JOIN JAMES'S VAULT NOW
  <br />
  <span className="text-lg md:text-xl font-semibold text-gray-700 dark:text-gray-300">
    FOR 15 USD PER MONTH — APY&nbsp;<span className="text-yellow-400">70%</span>
  </span>
</h5>


        {/* ⭐ Rating + like buttons */}
        <div className="flex items-center mt-2.5 mb-5">
          <div className="flex items-center space-x-1">
            {[...Array(5)].map((_, i) => (
              <svg
                key={i}
                className={`w-5 h-5 transition-all duration-500 ${
                  i < Math.round(rating)
                    ? "text-purple-300 scale-110"
                    : "text-gray-300 dark:text-gray-600 opacity-60"
                }`}
                fill="currentColor"
                viewBox="0 0 22 20"
              >
               <path d="M20.924 7.625a1.523 1.523 0 0 0-1.238-1.044l-5.051-.734-2.259-4.577a1.534 1.534 0 0 0-2.752 0L7.365 5.847l-5.051.734A1.535 1.535 0 0 0 1.463 9.2l3.656 3.563-.863 5.031a1.532 1.532 0 0 0 2.226 1.616L11 17.033l4.518 2.375a1.534 1.534 0 0 0 2.226-1.617l-.863-5.03L20.537 9.2a1.523 1.523 0 0 0 .387-1.575Z" />

              </svg>
            ))}
          </div>

          <span className="bg-blue-100 text-blue-800 text-xs font-semibold px-2.5 py-0.5 rounded-sm ms-3">
            {rating.toFixed(1)}
          </span>

          {/* 👍 👎 buttons */}
          <div className="flex items-center space-x-2 ml-3">
            <button
              onClick={() => {
                if (!isMember) return alert("Only members can vote.");
                if (userVoted) return alert("You already voted!");
                setLikes(likes + 1);
                setUserVoted(true);
                localStorage.setItem(`jamesVaultVoted_${address}`, "true");
              }}
              className="p-1 rounded-full hover:bg-blue-100 dark:hover:bg-gray-700"
            >
              <ThumbsUp className="w-5 h-5 text-blue-600 dark:text-blue-400" />
            </button>

            <button
              onClick={() => {
                if (!isMember) return alert("Only members can vote.");
                if (userVoted) return alert("You already voted!");
                setDislikes(dislikes + 1);
                setUserVoted(true);
                localStorage.setItem(`jamesVaultVoted_${address}`, "true");
              }}
              className="p-1 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700"
            >
              <ThumbsDown className="w-5 h-5 text-gray-600 dark:text-gray-400" />
            </button>
          </div>
        </div>

        {/* 💰 Deposit and income */}
        <span> </span>

  {/* ✅ container for DEPOSIT */}
   <div className="flex flex-col text-gray-500 dark:text-gray-400">
 <span className="text-lg font-semibold text-gray-800 dark:text-gray-200 border border-gray-300 rounded-md px-3 py-1">
      YOUR DEPOSIT
   
    
      {userDeposit
        ? ` ${formatEther(userDeposit)} ETH (~$${(
            parseFloat(formatEther(userDeposit)) * ethPrice
          ).toFixed(2)} USDT)`
        : "  0"}
    </span>
 

  {/* ✅ container for CURRENT INCOME */}
<span className="text-lg font-semibold text-gray-800 dark:text-gray-200 border border-gray-300 rounded-md px-3 py-1">
      YOUR CURRENT INCOME
   
      {currentIncome ? ` ${currentIncome.toFixed(2)} USDT` : "  0"}
</span>

</div>

        {/* 🔘 Action buttons */}
        <div className="flex flex-col gap-0">
          <button
            onClick={() => setShowDepositModal(true)}
            className="text-white bg-purple-600 hover:bg-purple-800 font-semibold rounded-lg text-xl px-8 py-4 border-2 border-black"
          >
            JOIN VAULT
          </button>

          <button
            onClick={() => setShowAddAmount(true)}
            className="text-white bg-purple-600 hover:bg-purple-800 font-semibold rounded-lg text-xl px-8 py-4 border-2 border-black"
          >
            ADD DEPOSIT
          </button>

          <button
            onClick={() => setShowWithdrawModal(true)}
            className="text-white bg-purple-600 hover:bg-purple-800 font-semibold rounded-lg text-xl px-8 py-4 border-2 border-black"
          >
            WITHDRAW
          </button>
        </div>
      </div>

      {/* 🧾 Modal windows */}
      {/* JOIN VAULT */}
      {showDepositModal && (
        <Modal
          title="Join James's Vault"
          value={depositAmount}
          onChange={setDepositAmount}
          onClose={() => setShowDepositModal(false)}
          onConfirm={async () => {
            try {
              const wei = BigInt(parseFloat(depositAmount) * 1e18);
              const fee = BigInt(20000000000000); // joinFee JamesVault
              await writeContractAsync({
                functionName: "joinJamesVault",
                args: [wei],
                value: wei + fee,
              });
              setShowDepositModal(false);
              setDepositAmount("");
              setTimeout(() => refetch(), 3000);
            } catch (e) {
              console.error(e);
            }
          }}
        />
      )}

      {/* ADD DEPOSIT */}
      {showAddAmount && (
        <Modal
          title="Add Deposit to Vault"
          value={addAmount}
          onChange={setAddAmount}
          onClose={() => setShowAddAmount(false)}
          onConfirm={async () => {
            try {
              const wei = BigInt(parseFloat(addAmount) * 1e18);
              await writeContractAsync({
                functionName: "addDeposit",
                args: [vaultId],
                value: wei,
              });
              setShowAddAmount(false);
              setAddAmount("");
              setTimeout(() => refetch(), 3000);
            } catch (e) {
              console.error(e);
            }
          }}
        />
      )}

      {/* WITHDRAW */}
      {showWithdrawModal && (
        <Modal
          title="Withdraw ETH"
          value={withdrawAmount}
          onChange={setWithdrawAmount}
          onClose={() => setShowWithdrawModal(false)}
          onConfirm={async () => {
            try {
              const wei = parseEther(withdrawAmount);
              await writeContractAsync({
                functionName: "withdrawEth",
                args: [vaultId, wei],
              });
              setShowWithdrawModal(false);
              setWithdrawAmount("");
              setTimeout(() => refetch(), 3000);
            } catch (e) {
              console.error(e);
            }
          }}
        />
      )}

      {/* DETAILS */}
      {showVaultDetails && (
        <VaultDetails
          name="James's Vault"
          vaultData={vaultData}
          TVL={TVL}
          onClose={() => setShowVaultDetails(false)}
        />
      )}
    </div>
  );
}

/* 🧱 Modal component */
function Modal({ title, value, onChange, onClose, onConfirm }: any) {
  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-lg w-80">
        <h3 className="text-lg font-semibold mb-4">{title}</h3>
        <input
          type="number"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder="Amount in ETH"
          className="w-full p-2 border border-gray-300 rounded mb-4"
        />
        <div className="flex justify-end space-x-2">
          <button onClick={onClose} className="px-4 py-2 bg-gray-300 rounded">
            Cancel
          </button>
          <button
            onClick={onConfirm}
            className="px-4 py-2 bg-blue-700 text-white rounded"
          >
            Send
          </button>
        </div>
      </div>
    </div>
  );
}

/* 📄 Vault details component */
function VaultDetails({ name, vaultData, TVL, onClose }: any) {
  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-lg w-96">
        <h3 className="text-lg font-semibold mb-4 text-gray-900 dark:text-gray-100 ">{name} Details</h3>
        <p className="text-gray-800 dark:text-gray-100 mb-2">
          James has 12 years of trading experience.
          His strategy is high-return balanced.
          He has deep knowledge of Defi liquidity and market trends.
        </p>
        <p className="text-gray-800 dark:text-gray-100">
          Participants: {vaultData ? vaultData[2].length : "loading..."}
        </p>
        <p className="text-gray-800 dark:text-gray-100">
          Total Vault Balance: {TVL ? formatEther(TVL) : "loading..."} ETH
        </p>

        <ul className="list-disc list-inside mt-2">
          <li>BTC</li>
          <li>ETH</li>
          <li>LINK</li>
          <li>AVAX</li>
          <li>APT</li>
          <li>MATIC</li>
          <li>DOT</li>
        </ul>

        <div className="flex justify-end mt-4">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-gray-300 rounded hover:bg-gray-400"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}
