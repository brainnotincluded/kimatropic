import { motion } from "framer-motion";
import { useStore } from "../store";
import { StatusBadge } from "./StatusBadge";
import type { QueueItem as QueueItemType } from "../types";

interface Props {
  item: QueueItemType;
}

const borderColors: Record<QueueItemType["status"], string> = {
  pending: "#7C6EF6",
  approved: "#5CC99B",
  rejected: "#E8677A",
};

const bgColors: Record<QueueItemType["status"], string> = {
  pending: "#F5F3FF",
  approved: "#ECFDF3",
  rejected: "#FEF2F4",
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
      className="w-full text-left rounded-xl cursor-pointer transition-all duration-200 outline-none focus-visible:ring-2 focus-visible:ring-[#7C6EF6]/40"
      style={{
        backgroundColor: isSelected ? bgColors[item.status] : "#FFFFFF",
        borderLeft: `3px solid ${borderColors[item.status]}`,
        padding: "10px 12px",
        boxShadow: isSelected
          ? "0 1px 3px rgba(124, 110, 246, 0.08)"
          : "0 1px 2px rgba(0,0,0,0.03)",
      }}
      whileHover={{ backgroundColor: "#EDEEF5" }}
    >
      <div className="flex items-start gap-3">
        {/* Thumbnail placeholder */}
        <div
          className="w-14 h-14 rounded-lg flex-shrink-0 flex items-center justify-center overflow-hidden bg-[#F3F4F8]"
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
                stroke="#D0CEE8"
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
          <h4 className="text-[#2D2B42] font-medium text-[13px] leading-tight truncate">
            {item.component_name}
          </h4>
          <div className="mt-1.5">
            <StatusBadge status={item.status} />
          </div>
          <p className="mt-1.5 text-[10px] text-[#B8B6CC]">{timeLabel}</p>
        </div>
      </div>
    </motion.button>
  );
}
