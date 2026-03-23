import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useStore } from "../store";

type ZoomLevel = "fit" | 0.5 | 1 | 2;

const zoomLevels: { label: string; value: ZoomLevel }[] = [
  { label: "Fit", value: "fit" },
  { label: "50%", value: 0.5 },
  { label: "100%", value: 1 },
  { label: "200%", value: 2 },
];

export function PreviewArea() {
  const items = useStore((s) => s.items);
  const selectedId = useStore((s) => s.selectedId);
  const [zoom, setZoom] = useState<ZoomLevel>("fit");

  const selectedItem = items.find((i) => i.id === selectedId);

  const scaleStyle =
    zoom === "fit"
      ? {}
      : { transform: `scale(${zoom})`, transformOrigin: "center center" };

  return (
    <div className="flex-1 relative overflow-auto checkerboard flex items-center justify-center">
      <AnimatePresence mode="wait">
        {selectedItem ? (
          <motion.div
            key={selectedItem.id}
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.98 }}
            transition={{ duration: 0.2, ease: "easeOut" }}
            className="relative"
            style={scaleStyle}
          >
            {selectedItem.screenshot_path ? (
              <img
                src={
                  selectedItem.screenshot_path.startsWith("/")
                    ? selectedItem.screenshot_path
                    : `/uploads/${selectedItem.screenshot_path}`
                }
                alt={selectedItem.component_name}
                className="rounded-lg shadow-2xl"
                style={{
                  maxWidth: zoom === "fit" ? "90%" : "none",
                  maxHeight: zoom === "fit" ? "90%" : "none",
                }}
              />
            ) : (
              /* Placeholder when no screenshot is available */
              <div className="w-[480px] h-[320px] bg-[#15181C] rounded-xl border border-[#2A3038] flex flex-col items-center justify-center gap-4 shadow-2xl">
                <div
                  className="w-16 h-16 rounded-xl flex items-center justify-center"
                  style={{
                    background:
                      "linear-gradient(135deg, rgba(0,217,255,0.1), rgba(124,58,237,0.1))",
                    border: "1px solid #2A3038",
                  }}
                >
                  <svg
                    width="28"
                    height="28"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="#00D9FF"
                    strokeWidth="1.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <rect x="3" y="3" width="18" height="18" rx="2" />
                    <circle cx="8.5" cy="8.5" r="1.5" />
                    <path d="m21 15-5-5L5 21" />
                  </svg>
                </div>
                <div className="text-center">
                  <p className="text-[#F7F8FA] font-medium text-base">
                    {selectedItem.component_name}
                  </p>
                  <p className="text-[#6B7280] text-xs mt-1.5">
                    No screenshot available
                  </p>
                </div>
              </div>
            )}

            {/* Viewport badge */}
            <div className="absolute top-3 right-3 px-2.5 py-1 bg-[#0A0B0D]/80 backdrop-blur-sm rounded-md text-[11px] text-[#9CA3AF] border border-[#2A3038] font-mono">
              {selectedItem.viewport}
            </div>
          </motion.div>
        ) : (
          <motion.div
            key="empty"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="text-center"
          >
            <div className="flex flex-col items-center gap-4">
              <div
                className="w-20 h-20 rounded-2xl flex items-center justify-center"
                style={{
                  background:
                    "linear-gradient(135deg, rgba(0,217,255,0.05), rgba(124,58,237,0.05))",
                  border: "1px solid #1E2329",
                }}
              >
                <svg
                  width="32"
                  height="32"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="#2A3038"
                  strokeWidth="1.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <rect x="2" y="3" width="20" height="14" rx="2" />
                  <line x1="8" y1="21" x2="16" y2="21" />
                  <line x1="12" y1="17" x2="12" y2="21" />
                </svg>
              </div>
              <div>
                <p className="text-[#9CA3AF] text-sm">
                  Select a component to preview
                </p>
                <p className="text-[#6B7280] text-[11px] mt-1">
                  Choose an item from the queue on the left
                </p>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Zoom controls */}
      <div className="absolute bottom-4 right-4 flex items-center gap-0.5 bg-[#15181C]/90 backdrop-blur-sm rounded-lg border border-[#2A3038] p-1">
        {zoomLevels.map((z) => (
          <button
            key={z.label}
            onClick={() => setZoom(z.value)}
            className="px-3 py-1.5 text-[11px] font-medium rounded-md transition-all duration-150"
            style={{
              backgroundColor:
                zoom === z.value ? "#00D9FF" : "transparent",
              color: zoom === z.value ? "#0A0B0D" : "#F7F8FA",
            }}
          >
            {z.label}
          </button>
        ))}
      </div>
    </div>
  );
}
