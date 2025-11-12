import { useState, useEffect } from "react";
import { createPortal } from "react-dom";

type Props = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  label?: string;
};

export default function Start({ label = "START INVESTING", className = "", disabled, ...rest }: Props) {
  const [open, setOpen] = useState(false);
  const [mounted, setMounted] = useState(false); // wait for browser

  useEffect(() => {
    setMounted(true);
  }, []);

  return (
    <>
      <button
        onClick={() => setOpen(true)}
        type="button"
        aria-label={label}
        disabled={disabled}
        className={`
          relative overflow-hidden inline-flex items-center justify-center
          px-7 py-3 rounded-full select-none
          text-sm font-semibold tracking-wide uppercase
          shadow-lg transform transition-all duration-200
          focus:outline-none focus-visible:ring-4 focus-visible:ring-yellow-300
          ${disabled ? "opacity-60 cursor-not-allowed" : "hover:scale-105 active:scale-95"}
          ${className}
        `}
        {...rest}
      >
        <span
          aria-hidden
          className="absolute inset-0 -z-10 rounded-full"
          style={{
            background:
              "linear-gradient(90deg, #b8860b 0%, #ffd36b 25%, #f5e6b3 50%, #ffd36b 75%, #b8860b 100%)",
            boxShadow: "0 6px 18px rgba(168, 132, 41, 0.25), inset 0 -6px 18px rgba(255,255,255,0.06)",
          }}
        />

        <span
          aria-hidden
          className="absolute -left-32 top-0 h-full w-40 rounded-full opacity-70 pointer-events-none animate-shimmer"
          style={{
            background:
              "linear-gradient(120deg, rgba(255,255,255,0.0) 0%, rgba(255,255,255,0.55) 50%, rgba(255,255,255,0.0) 100%)",
            mixBlendMode: "screen",
          }}
        />

        <span
          aria-hidden
          className="absolute inset-0 -z-20 rounded-full"
          style={{ boxShadow: "inset 0 1px 0 rgba(255,255,255,0.25), inset 0 -10px 30px rgba(0,0,0,0.12)" }}
        />

        <span className="relative z-10 text-black">{label}</span>

        <style jsx>{`
          @keyframes shimmer {
            0% { transform: translateX(-120%) skewX(-12deg); }
            50% { transform: translateX(120%) skewX(-12deg); }
            100% { transform: translateX(240%) skewX(-12deg); }
          }
          .animate-shimmer {
            animation: shimmer 2.2s linear infinite;
          }
        `}</style>
      </button>

{mounted && open &&
  createPortal(
    <div className="fixed inset-0 bg-black bg-opacity-80 flex justify-center items-center z-50 backdrop-blur-sm">
      <div className="bg-gradient-to-b from-white to-gray-100 text-black p-10 rounded-2xl w-[70vw] max-w-[900px] shadow-2xl border border-gray-300">

        <div className="space-y-6 text-[18px] leading-relaxed text-gray-800 font-medium">
          <p>
            By joining the vault, you start earning a share of the total investment income. Your profit grows together with the performance of the traders you support.
          </p>

          <p>
            You remain fully in control. You can deposit funds, withdraw them, and vote for traders using like and dislike options. The vault system adapts to your decisions.
          </p>

          <p>
            Every trader is verified by our internal team, and all investment operations are managed by a smart contract. This ensures your funds can only be used within approved investment strategies.
          </p>

          <p>
            Your investment stays transparent, protected, and backed by contract-regulated rules. You invest confidently knowing only qualified traders manage the vault.
          </p>
        </div>

        <button
          onClick={() => setOpen(false)}
          className="mt-8 w-full bg-black text-white py-3 rounded-lg font-semibold hover:bg-gray-900 transition"
        >
          Close
              </button>
            </div>
          </div>,
          document.body
        )
      }
    </>
  );
}
