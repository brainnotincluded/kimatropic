import { motion } from "framer-motion";
import { useStore } from "../store";
import { StatusBadge } from "./StatusBadge";
import type { QueueItem as QueueItemType } from "../types";

interface Props {
  item: QueueItemType;
}

const borderColors: Record<QueueItemType["status"], string> = {
  pending: "#00D9FF",
  approved: "#22C55E",
  rejected: "#EF4444",
};

export function QueueItem({ item }: Props) {
  const selectedId = useStore((s) => s.selectedId);
  const selectItem = useStore((s) => s.selectItem);
  const isSelected = selectedId === item.id;

  const timeLabel = (() => {
    try {
      return new Date(item.created_at).toLocaleTimeString([], {
        hour: "2-digit",
        minute: "2-digit",
      });
    } catch {
      return "";
    }
  })();

  return (
    <motion.button
      layout
      initial={{ x: -24, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      exit={{ opacity: 0, scale: 0.95 }}
      transition={{ duration: 0.2, ease: "easeOut" }}
      onClick={() => selectItem(item.id)}
      className="w-full text-left rounded-lg cursor-pointer transition-colors outline-none focus-visible:ring-1 focus-visible:ring-[#00D9FF]"
      style={{
        backgroundColor: isSelected ? "#1F242A" : "#15181C",
        borderLeft: `3px solid ${borderColors[item.status]}`,
        padding: "10px 12px",
      }}
      whileHover={{ backgroundColor: "#1F242A" }}
    >
      <div className="flex items-start gap-3">
        {/* Thumbnail placeholder */}
        <div
          className="w-14 h-14 rounded flex-shrink-0 flex items-center justify-center overflow-hidden checkerboard-sm"
        >
          {item.screenshot_path ? (
            <img
              src={item.screenshot_path.startsWith("/") ? item.screenshot_path : `/uploads/${item.screenshot_path}`}
              alt=""
              className="w-full h-full object-cover"
            />
          ) : (
            <div className="flex items-center justify-center w-full h-full">
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="#2A3038"
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <rect x="3" y="3" width="18" height="18" rx="2" />
                <circle cx="8.5" cy="8.5" r="1.5" />
                <path d="m21 15-5-5L5 21" />
              </svg>
            </div>
          )}
        </div>

        {/* Details */}
        <div className="flex-1 min-w-0">
          <h4 className="text-[#F7F8FA] font-medium text-[13px] leading-tight truncate">
            {item.component_name}
          </h4>
          <div className="mt-1.5">
            <StatusBadge status={item.status} />
          </div>
          <p className="mt-1.5 text-[10px] text-[#6B7280]">{timeLabel}</p>
        </div>
      </div>
    </motion.button>
  );
}
