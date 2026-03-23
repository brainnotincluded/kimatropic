import { motion } from "framer-motion";
import { useStore } from "../store";

export function TopBar() {
  const items = useStore((s) => s.items);
  const connectionStatus = useStore((s) => s.connectionStatus);

  const pending = items.filter((i) => i.status === "pending").length;
  const approved = items.filter((i) => i.status === "approved").length;
  const rejected = items.filter((i) => i.status === "rejected").length;

  const isConnected = connectionStatus === "connected";

  return (
    <header className="h-12 shrink-0 bg-[#0F1114] border-b border-[#2A3038] flex items-center justify-between px-5 select-none">
      {/* Logo */}
      <div className="flex items-center gap-3">
        <span
          className="text-base font-semibold tracking-tight"
          style={{
            background: "linear-gradient(135deg, #00D9FF, #7C3AED)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
          }}
        >
          Kimatropic Studio
        </span>
        <span className="text-[10px] text-[#9CA3AF] bg-[#15181C] px-1.5 py-0.5 rounded font-medium">
          BETA
        </span>
      </div>

      {/* Stats + Connection */}
      <div className="flex items-center gap-6">
        {/* Queue stats */}
        <div className="hidden sm:flex items-center gap-4 text-xs">
          <div className="flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-[#00D9FF]" />
            <span className="text-[#9CA3AF]">
              Pending <span className="text-[#00D9FF] font-medium">{pending}</span>
            </span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-[#22C55E]" />
            <span className="text-[#9CA3AF]">
              Approved <span className="text-[#22C55E] font-medium">{approved}</span>
            </span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-[#EF4444]" />
            <span className="text-[#9CA3AF]">
              Rejected <span className="text-[#EF4444] font-medium">{rejected}</span>
            </span>
          </div>
        </div>

        {/* Divider */}
        <div className="w-px h-4 bg-[#2A3038]" />

        {/* Connection status */}
        <div className="flex items-center gap-2">
          <motion.div
            className={`w-2 h-2 rounded-full ${isConnected ? "bg-[#22C55E]" : "bg-[#EF4444]"}`}
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
          <span className="text-[11px] text-[#9CA3AF]">
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
