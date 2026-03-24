import { AnimatePresence } from "framer-motion";
import { useStore } from "../store";
import { QueueItem } from "./QueueItem";

export function QueueSidebar() {
  const items = useStore((s) => s.items);

  return (
    <aside className="w-[260px] min-w-[200px] max-w-[320px] shrink-0 bg-[#F5F4FA] border-r border-[#E4E3F1] flex flex-col select-none" style={{ flexBasis: '20%' }}>
      {/* Header */}
      <div className="px-4 py-3 border-b border-[#E4E3F1]">
        <div className="flex items-center justify-between">
          <h2 className="text-[#2D2B42] text-sm font-semibold">Review Queue</h2>
          <span className="text-[10px] text-[#8B89A3] bg-white px-1.5 py-0.5 rounded-full font-medium shadow-sm">
            {items.length}
          </span>
        </div>
      </div>

      {/* List */}
      <div className="flex-1 overflow-y-auto p-2 space-y-1.5">
        <AnimatePresence mode="popLayout">
          {items.map((item) => (
            <QueueItem key={item.id} item={item} />
          ))}
        </AnimatePresence>

        {items.length === 0 && (
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <svg
              width="32"
              height="32"
              viewBox="0 0 24 24"
              fill="none"
              stroke="#D0CEE8"
              strokeWidth="1.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M21 15V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9" />
              <path d="M3 15h18v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4Z" />
              <line x1="12" y1="10" x2="12" y2="14" />
            </svg>
            <p className="text-[#8B89A3] text-xs mt-3">Queue is empty</p>
            <p className="text-[#B8B6CC] text-[10px] mt-1">
              Components will appear here
            </p>
          </div>
        )}
      </div>
    </aside>
  );
}
