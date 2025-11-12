
"use client";

import React from "react";
import { useState, useEffect } from "react";
import { useAccount } from "wagmi";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth/useScaffoldReadContract";
import { formatEther, parseEther } from "viem";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth/useScaffoldWriteContract";
import { ThumbsUp, ThumbsDown } from "lucide-react";


export default function ProductCard() {
   const { address } = useAccount(); //current user balance

   // Reading user deposit from contract (vaultId = 0 для Mike's vault)
   const { data: userDeposit, refetch } = useScaffoldReadContract({
    contractName: "VaultFactory",
    functionName: "getUserVaultDeposits",
    args: [BigInt(0), address]
  });
  
  const { data: numberOfVaults, refetch: reloadVaults } = useScaffoldReadContract({
  contractName: "VaultFactory",
  functionName: "vaultsCount",
});

const { data: vaultData, refetch: reloadVaultData } = useScaffoldReadContract({
  contractName: "VaultFactory",
  functionName: "getVault",
  args: [BigInt(0)], // vaultId = 0 for Mike's vault
});

const { data: TVL, refetch: reloadTVL } = useScaffoldReadContract({
  contractName: "VaultFactory",
  functionName: "getVaultTotalDeposits",
  args: [BigInt(0)], // vaultId = 0 for Mike's vault
});


const [showDepositModal, setShowDepositModal] = useState(false);

const [depositAmount, setDepositAmount] = useState(""); // amount ETH

const { writeContractAsync } = useScaffoldWriteContract("VaultFactory");

const [ethPrice, setEthPrice] = useState<number>(0); // receive ETH price data inUSDT

const [randomBonus, setRandomBonus] = useState<number>(0);

const [currentIncome, setCurrentIncome] = useState<number>(0);

const [showWithdrawModal, setShowWithdrawModal] = useState(false);

const [withdrawAmount, setWithdrawAmount] = useState("");

const [showAddAmount, setShowAddAmount] = useState(false);

const [addAmount, setAddAmount] = useState("");

const [showVaultDetails, setShowVaultDetails] = useState(false);

// --- Rating and votes ---
const [likes, setLikes] = useState(0);
const [dislikes, setDislikes] = useState(0);
const [userVoted, setUserVoted] = useState(false);
const [rating, setRating] = useState(4.0); 

// Checking if user is a member
const { data: isMember } = useScaffoldReadContract({
  contractName: "VaultFactory",
  functionName: "isMember",
  args: [BigInt(0), address],
});

// Loading saved likes/dislikes
useEffect(() => {
  if (!address) return;

  // Loading saved values from localStorage
  const savedLikes = localStorage.getItem("mikeVaultLikes");
  const savedDislikes = localStorage.getItem("mikeVaultDislikes");
  const voted = localStorage.getItem(`mikeVaultVoted_${address}`);

  if (savedLikes) setLikes(parseInt(savedLikes));
  if (savedDislikes) setDislikes(parseInt(savedDislikes));
  setUserVoted(voted === "true");
}, [address]);


// 1️⃣ — saving likes/dislikes
useEffect(() => {
  localStorage.setItem("mikeVaultLikes", likes.toString());
  localStorage.setItem("mikeVaultDislikes", dislikes.toString());
}, [likes, dislikes]);

// 2️⃣ — Recalculating rating
useEffect(() => {
  const totalVotes = likes + dislikes;
  if (totalVotes === 0) {
    setRating(4.0);
    return;
  }

  const likeRatio = (likes / totalVotes) * 100;
  let newRating = 1.0;
  if (likeRatio >= 81) newRating = 5.0;
  else if (likeRatio >= 61) newRating = 4.0;
  else if (likeRatio >= 41) newRating = 3.0;
  else if (likeRatio >= 21) newRating = 2.0;
  else newRating = 1.0;

  setRating(newRating);
}, [likes, dislikes]);

  useEffect(() => {
  async function fetchEthPrice() {
    try {
      const res = await fetch(
        "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd"
      );
      const data = await res.json();
      setEthPrice(data.ethereum.usd);
    } catch (err) {
      console.error("Failed to fetch ETH price:", err);
    }
  }
  fetchEthPrice();
}, []);

useEffect(() => {
  // random bonus (0–100 USDT every 30 sec)
  const getRandomNumber = (min: number, max: number) => {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  };

  // set initial random bonus
  setRandomBonus(getRandomNumber(0, 100));

  // interval for updating every 30 seconds
  const interval = setInterval(() => {
    setRandomBonus(getRandomNumber(0, 100));
  }, 30000);

  // cleanup
  return () => clearInterval(interval);
}, []);

useEffect(() => {
  if (userDeposit && ethPrice > 0) {
    const depositInEth = parseFloat(formatEther(userDeposit));

    // if depositInEth === 0
    if (depositInEth === 0) {
      setCurrentIncome(0);
      console.log("User not a participant, currentIncome = 0");
      return;
    }

    const depositInUsdt = depositInEth * ethPrice;
    
    const income = depositInUsdt * 0.5 + randomBonus;
    
    setCurrentIncome(income);

   } else {
    // if no deposit or data — income = 0
    setCurrentIncome(0);
    console.log("No deposit or ethPrice = 0, currentIncome = 0");
  }
}, [userDeposit, randomBonus, ethPrice]);

  return (
    
<div className="w-full max-w-sm bg-white border border-gray-200 rounded-lg shadow-sm dark:bg-gray-800 dark:border-gray-700 relative group mt-0">
  <img
    className="p-8 rounded-t-lg"
    src="/Mike1.png"
    alt="Trader Mike"
  />
  {/* Tooltip */}
<div
  className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-3 py-1 text-xl text-white bg-gray-900 rounded-md whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity duration-300 cursor-pointer"
  onClick={() => {
    reloadVaults();             // ← adding vault details reload
    setShowVaultDetails(true);}
  }
>
  Click to get details about Mike's vault
</div>

      <div className="px-5 pb-5">

       <h5
  className="font-sans text-xl md:text-xl font-extrabold 
             bg-gradient-to-r from-blue-300 via-indigo-400 to-purple-600 
             dark:from-blue-400 dark:via-indigo-500 dark:to-purple-700 
             bg-clip-text text-transparent 
             drop-shadow-[0_0_10px_rgba(90,90,255,0.3)]
             tracking-wider leading-snug text-center uppercase"
>
  YOU CAN JOIN MIKE'S VAULT NOW
  <br />
  <span className="text-lg md:text-xl font-semibold text-gray-700 dark:text-gray-300">
    FOR 10 USD PER MONTH — APY&nbsp;<span className="text-yellow-400">50%</span>
  </span>
</h5>


        {/* Rating */}
        <div className="flex items-center mt-2.5 mb-5">
          <div className="flex items-center space-x-1">
            {[...Array(5)].map((_, i) => (
              <svg
                key={i}
                className={`w-5 h-5 transition-all duration-500 ${
                  i < Math.round(rating)
                    ? "text-yellow-300 scale-110"
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


{/* Like / Dislike buttons */}
<div className="flex items-center space-x-2 ml-3">
<button
  onClick={() => {
    if (!isMember) {
      alert("Only vault members can vote.");
      return;
    }
    if (userVoted) {
      alert("You already voted!");
      return;
    }

    setLikes(likes + 1);
    setUserVoted(true);

    localStorage.setItem(`mikeVaultVoted_${address}`, "true");
  }}
  className="p-1 rounded-full hover:bg-blue-100 dark:hover:bg-gray-700 transition"
>
  <ThumbsUp className="w-5 h-5 text-blue-600 dark:text-blue-400" />
</button>


<button
  onClick={() => {
    if (!isMember) {
      alert("Only vault members can vote.");
      return;
    }
    if (userVoted) {
      alert("You already voted!");
      return;
    }

    setDislikes(dislikes + 1);
    setUserVoted(true);

    localStorage.setItem(`mikeVaultVoted_${address}`, "true");
  }}
  className="p-1 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 transition"
>
  <ThumbsDown className="w-5 h-5 text-gray-600 dark:text-gray-400" />
</button>

</div>


        </div>

        {/* Price and button */}
        <div className="flex flex-col text-gray-500 dark:text-gray-400">
<span className="text-lg font-semibold text-gray-800 dark:text-gray-200 border border-gray-300 rounded-md px-3 py-1">
  YOUR DEPOSIT: {userDeposit ? formatEther(userDeposit) + " ETH" : "0 ETH"} 
  {userDeposit && ethPrice > 0 ? ` (~$${(parseFloat(formatEther(userDeposit)) * ethPrice).toFixed(2)} USDT)` : ""}
</span>

<span className="text-lg font-semibold text-gray-800 dark:text-gray-200 border border-gray-300 rounded-md px-3 py-1">
  YOUR CURRENT INCOME: {currentIncome.toFixed(2)} USDT
</span>
<button
  type="button"
  onClick={() => setShowDepositModal(true)}
  className="text-white bg-blue-700 hover:bg-blue-800 hover:scale-105 transition transform duration-200 
             shadow-lg hover:shadow-xl focus:ring-4 focus:outline-none focus:ring-blue-300 
             font-semibold rounded-lg text-xl px-8 py-4 text-center 
             border-2 border-black              /* ← добавлена чёрная рамка */
             dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
>
  JOIN VAULT
</button>
<button
  type="button"
 onClick={() => setShowAddAmount(true)}
  className="text-white bg-blue-700 hover:bg-blue-800 hover:scale-105 transition transform duration-200 
             shadow-lg hover:shadow-xl focus:ring-4 focus:outline-none focus:ring-blue-300 
             font-semibold rounded-lg text-xl px-8 py-4 text-center 
             border-2 border-black              /* ← добавлена чёрная рамка */
             dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
>
  ADD DEPOSIT
</button>
<button
  type="button"
  onClick={() => setShowWithdrawModal(true)}
  className="text-white bg-blue-700 hover:bg-blue-800 hover:scale-105 transition transform duration-200 
             shadow-lg hover:shadow-xl focus:ring-4 focus:outline-none focus:ring-blue-300 
             font-semibold rounded-lg text-xl px-8 py-4 text-center 
             border-2 border-black            /* <-- добавлена рамка */
             dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
>
  WITHDRAW
</button>
{showWithdrawModal && (
  <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
    <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-lg w-80">
      <h3 className="text-lg font-semibold mb-4 text-gray-800 dark:text-gray-200">Withdraw ETH</h3>

      <input
        type="number"
        placeholder="Amount in ETH"
        value={withdrawAmount}
        onChange={(e) => setWithdrawAmount(e.target.value)}
        className="w-full p-2 border border-gray-300 rounded mb-4 text-gray-800 dark:text-gray-200 dark:bg-gray-700"
      />

      <div className="flex justify-end space-x-2">
        <button
          onClick={() => setShowWithdrawModal(false)}
          className="px-4 py-2 rounded bg-gray-300 hover:bg-gray-400 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-800 dark:text-gray-200"
        >
          Cancel
        </button>

        <button
          onClick={async () => {
            try {
              const weiAmount = parseEther(withdrawAmount); // ETH -> wei
              await writeContractAsync({
                functionName: "withdrawEth",
                args: [BigInt(0), weiAmount], // vaultId = 0
              });

              setShowWithdrawModal(false);
              setWithdrawAmount("");

              // reload data
              setTimeout(() => {
                refetch();
              }, 3000);
            } catch (err) {
              console.error("Withdraw error:", err);
            }
          }}
          className="px-4 py-2 rounded bg-blue-700 hover:bg-blue-800 text-white"
        >
          Send
        </button>
      </div>
    </div>
  </div>
)}

{showVaultDetails && ( 
  <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
    <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-lg w-80">
      <h3 className="text-lg font-semibold mb-4 text-gray-800 dark:text-gray-200">Vault Mike's Details</h3>
      <p className="text-gray-700 dark:text-gray-300 text-justify">
 Mike has 10 years of investment expertise.
He has proved APY: 2022-60%; 2023 - 45%; 2024 - 70%;
His strategy is middle risk strategy and portfolio is 
shared in the following proportions:
60% - low and middle risk assets
30% - high risk assets
10% - very high risk assets
        </p>
      

<p className="text-gray-700 dark:text-gray-300">
  Number of participants: {vaultData ? vaultData[2].length : "loading..."}
</p>
<p className="text-gray-700 dark:text-gray-300">
  Total Vault Balance: {TVL ? formatEther(TVL) : "loading..."} ETH
</p>
<p className="text-gray-700 dark:text-gray-300">
  Current Investment Portfolio:
</p>
<ul className="list-disc list-inside text-gray-700 dark:text-gray-300">
   <li>BTC</li>
   <li>ETH</li>
   <li>ZORA</li>
   <li>INJ</li>
   <li>SUI</li>
   <li>VIRTUAL</li>
   <li>TAO</li>
   <li>FLOCK</li>
   <li>STX</li>
   <li>SONIC</li>
   <li>CETUS</li>
   <li>ARB</li>
</ul>
      <div className="flex justify-end mt-4">
        <button
          onClick={() => setShowVaultDetails(false)}
          className="px-4 py-2 rounded bg-gray-300 hover:bg-gray-400 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-800 dark:text-gray-200"
        >
          Close
        </button>
      </div>
    </div>
  </div>
)}

{showAddAmount && (
  <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
    <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-lg w-80">
      <h3 className="text-lg font-semibold mb-4 text-gray-800 dark:text-gray-200">Deposit ETH</h3>
      <input
        type="number"
        placeholder="Amount in ETH"
        value={addAmount}
        onChange={(e) => setAddAmount(e.target.value)}
        className="w-full p-2 border border-gray-300 rounded mb-4 text-gray-800 dark:text-gray-200 dark:bg-gray-700"
      />
      <div className="flex justify-end space-x-2">
        <button
          onClick={() => setShowAddAmount(false)}
          className="px-4 py-2 rounded bg-gray-300 hover:bg-gray-400 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-800 dark:text-gray-200"
        >
          Cancel
        </button>
  <button
  onClick={async () => {
    try {
      const weiAmount = BigInt(parseFloat(addAmount) * 1e18); // ETH -> wei
        await writeContractAsync({
        functionName: "addDeposit",
        args: [BigInt(0)],
        value: weiAmount,
      });

      setShowAddAmount(false);
      setAddAmount("");

      // small pause for blockchain to process transaction
setTimeout(() => {
  refetch();
}, 3000); // 3 seconds

    } catch (err) {
      console.error(err);
    }
  }}
  className="px-4 py-2 rounded bg-blue-700 hover:bg-blue-800 text-white"
>
  Send
</button>

      </div>
    </div>
  </div>
)}

{showDepositModal && (
  <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
    <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-lg w-80">
      <h3 className="text-lg font-semibold mb-4 text-gray-800 dark:text-gray-200">Deposit ETH</h3>
      <input
        type="number"
        placeholder="Amount in ETH"
        value={depositAmount}
        onChange={(e) => setDepositAmount(e.target.value)}
        className="w-full p-2 border border-gray-300 rounded mb-4 text-gray-800 dark:text-gray-200 dark:bg-gray-700"
      />
      <div className="flex justify-end space-x-2">
        <button
          onClick={() => setShowDepositModal(false)}
          className="px-4 py-2 rounded bg-gray-300 hover:bg-gray-400 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-800 dark:text-gray-200"
        >
          Cancel
        </button>
  <button
  onClick={async () => {
    try {
      const weiAmount = BigInt(parseFloat(depositAmount) * 1e18); // ETH -> wei
      const joinFee = BigInt(10000000000000);
       await writeContractAsync({
        functionName: "joinMikesVault",
        args: [weiAmount],
        value: weiAmount + joinFee,
      });
    
      setShowDepositModal(false);
      setDepositAmount("");


      // small pause for blockchain to process transaction
setTimeout(() => {
  refetch();
   reloadVaults();  // number of participants
}, 3000); // 3 seconds

    } catch (err) {
      console.error(err);
    }
  }}
  className="px-4 py-2 rounded bg-blue-700 hover:bg-blue-800 text-white"
>
  Send
</button>

      </div>
    </div>
  </div>
)}
        </div>
      </div>
    </div>
  );
}
