import { motion } from "framer-motion";
import { useStore } from "../store";
import { api } from "../api";
import { useState } from "react";

export function TopBar() {
  const items = useStore((s) => s.items);
  const connectionStatus = useStore((s) => s.connectionStatus);
  const gatherComponents = useStore((s) => s.gatherComponents);
  const [isGathering, setIsGathering] = useState(false);

  const pending = items.filter((i) => i.status === "pending").length;
  const approved = items.filter((i) => i.status === "approved").length;
  const rejected = items.filter((i) => i.status === "rejected").length;

  const isConnected = connectionStatus === "connected";

  const handleGather = async () => {
    setIsGathering(true);
    try {
      await gatherComponents();
    } catch (err) {
      console.error("Failed to gather components:", err);
    } finally {
      setIsGathering(false);
    }
  };

  return (
    <header className="h-12 shrink-0 bg-white border-b border-[#E4E3F1] flex items-center justify-between px-5 select-none">
      {/* Logo */}
      <div className="flex items-center gap-3">
        <span
          className="text-base font-semibold tracking-tight gradient-text"
        >
          Kimatropic Studio
        </span>
        <span className="text-[10px] text-[#8B89A3] bg-[#F3F4F8] px-1.5 py-0.5 rounded font-medium">
          BETA
        </span>
      </div>

      {/* Center: Gather button */}
      <div className="flex items-center">
        <motion.button
          whileTap={{ scale: 0.96 }}
          onClick={handleGather}
          disabled={isGathering}
          className="flex items-center gap-2 px-4 py-1.5 rounded-lg text-white text-xs font-medium transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
          style={{
            background: "linear-gradient(135deg, #7C6EF6, #5B9CF6)",
            boxShadow: "0 2px 8px rgba(124, 110, 246, 0.25)",
          }}
        >
          {/* Scan icon */}
          <svg
            width="14"
            height="14"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M3 7V5a2 2 0 0 1 2-2h2" />
            <path d="M17 3h2a2 2 0 0 1 2 2v2" />
            <path d="M21 17v2a2 2 0 0 1-2 2h-2" />
            <path d="M7 21H5a2 2 0 0 1-2-2v-2" />
            <circle cx="12" cy="12" r="3" />
          </svg>
          {isGathering ? "Gathering..." : "Gather Components"}
        </motion.button>
      </div>

      {/* Stats + Connection */}
      <div className="flex items-center gap-6">
        {/* Queue stats */}
        <div className="hidden sm:flex items-center gap-4 text-xs">
          <div className="flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-[#7C6EF6]" />
            <span className="text-[#8B89A3]">
              Pending <span className="text-[#7C6EF6] font-medium">{pending}</span>
            </span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-[#5CC99B]" />
            <span className="text-[#8B89A3]">
              Approved <span className="text-[#5CC99B] font-medium">{approved}</span>
            </span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-[#E8677A]" />
            <span className="text-[#8B89A3]">
              Rejected <span className="text-[#E8677A] font-medium">{rejected}</span>
            </span>
          </div>
        </div>

        {/* Divider */}
        <div className="w-px h-4 bg-[#E4E3F1]" />

        {/* Connection status */}
        <div className="flex items-center gap-2">
          <motion.div
            className={`w-2 h-2 rounded-full ${isConnected ? "bg-[#5CC99B]" : "bg-[#E8677A]"}`}
            animate={
              isConnected
                ? { opacity: [1, 0.5, 1] }
                : {}
            }
            transition={{
              duration: 2,
              repeat: Infinity,
              ease: "easeInOut",
            }}
          />
          <span className="text-[11px] text-[#8B89A3]">
            {connectionStatus === "connected"
              ? "Connected"
              : connectionStatus === "connecting"
                ? "Connecting..."
                : "Disconnected"}
          </span>
        </div>
      </div>
    </header>
  );
}
