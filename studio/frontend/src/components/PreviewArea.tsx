import { useState, useMemo } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useStore } from "../store";

type ZoomLevel = "fit" | 0.5 | 1 | 2;

const zoomLevels: { label: string; value: ZoomLevel }[] = [
  { label: "Fit", value: "fit" },
  { label: "50%", value: 0.5 },
  { label: "100%", value: 1 },
  { label: "200%", value: 2 },
];

function buildSrcdoc(code: string): string {
  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      padding: 24px;
      background: #FFFFFF;
      color: #2D2B42;
    }
    /* Tailwind-like utility reset for demo components */
    .flex { display: flex; }
    .items-center { align-items: center; }
    .justify-center { justify-content: center; }
    .gap-4 { gap: 1rem; }
    .gap-2 { gap: 0.5rem; }
    .p-6 { padding: 1.5rem; }
    .p-4 { padding: 1rem; }
    .px-4 { padding-left: 1rem; padding-right: 1rem; }
    .px-6 { padding-left: 1.5rem; padding-right: 1.5rem; }
    .py-2 { padding-top: 0.5rem; padding-bottom: 0.5rem; }
    .rounded-md { border-radius: 0.375rem; }
    .rounded-lg { border-radius: 0.5rem; }
    .font-medium { font-weight: 500; }
    .font-semibold { font-weight: 600; }
    .text-white { color: #fff; }
    .text-sm { font-size: 0.875rem; }
    .text-lg { font-size: 1.125rem; }
    .mb-3 { margin-bottom: 0.75rem; }
    .ml-auto { margin-left: auto; }
    .h-14 { height: 3.5rem; }
    .border-b { border-bottom: 1px solid #E4E3F1; }
  </style>
</head>
<body>
  <div id="preview-root"></div>
  <script>
    // Render HTML code snippet directly as live component
    const root = document.getElementById('preview-root');
    const code = ${JSON.stringify(code)};
    // If the code looks like HTML (starts with < or contains tags), render it directly
    if (code.trim().startsWith('<') || code.includes('</')) {
      root.innerHTML = code;
    } else {
      // For non-HTML code (e.g. JSX/TSX), show as formatted code block
      root.innerHTML = '<pre style="font-family: JetBrains Mono, monospace; font-size: 13px; line-height: 1.6; color: #2D2B42; white-space: pre-wrap; word-wrap: break-word; padding: 16px; background: #F5F4FA; border-radius: 12px; border: 1px solid #E4E3F1;">' + code.replace(/</g, '&lt;').replace(/>/g, '&gt;') + '</pre>';
    }
  </script>
</body>
</html>`;
}

export function PreviewArea() {
  const items = useStore((s) => s.items);
  const selectedId = useStore((s) => s.selectedId);
  const [zoom, setZoom] = useState<ZoomLevel>("fit");

  const selectedItem = items.find((i) => i.id === selectedId);

  const scaleStyle =
    zoom === "fit"
      ? {}
      : { transform: `scale(${zoom})`, transformOrigin: "center center" };

  const srcdoc = useMemo(() => {
    if (selectedItem?.code_snippet) {
      return buildSrcdoc(selectedItem.code_snippet);
    }
    return null;
  }, [selectedItem?.code_snippet]);

  return (
    <div className="flex-1 relative overflow-auto bg-[#F3F4F8] flex items-center justify-center">
      <AnimatePresence mode="wait">
        {selectedItem ? (
          <motion.div
            key={selectedItem.id}
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.98 }}
            transition={{ duration: 0.2, ease: "easeOut" }}
            className="w-full h-full flex items-center justify-center p-4"
            style={scaleStyle}
          >
            {srcdoc ? (
              /* Render code_snippet in sandboxed iframe */
              <iframe
                srcDoc={srcdoc}
                sandbox="allow-scripts"
                title={selectedItem.component_name}
                className="rounded-2xl shadow-lg border border-[#E4E3F1] bg-white"
                style={{
                  width: "100%",
                  height: "100%",
                  maxWidth: zoom === "fit" ? "100%" : "none",
                  maxHeight: zoom === "fit" ? "100%" : "none",
                }}
              />
            ) : selectedItem.screenshot_path ? (
              <img
                src={
                  selectedItem.screenshot_path.startsWith("/")
                    ? selectedItem.screenshot_path
                    : `/uploads/${selectedItem.screenshot_path}`
                }
                alt={selectedItem.component_name}
                className="rounded-2xl shadow-lg border border-[#E4E3F1]"
                style={{
                  maxWidth: zoom === "fit" ? "90%" : "none",
                  maxHeight: zoom === "fit" ? "90%" : "none",
                }}
              />
            ) : (
              /* Placeholder when nothing is available */
              <div
                className="w-[480px] h-[320px] bg-white rounded-2xl border border-[#E4E3F1] flex flex-col items-center justify-center gap-4"
                style={{ boxShadow: "0 1px 3px rgba(124, 110, 246, 0.08)" }}
              >
                <div
                  className="w-16 h-16 rounded-xl flex items-center justify-center"
                  style={{
                    background:
                      "linear-gradient(135deg, rgba(124,110,246,0.08), rgba(91,156,246,0.08))",
                    border: "1px solid #E4E3F1",
                  }}
                >
                  <svg
                    width="28"
                    height="28"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="#7C6EF6"
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
                  <p className="text-[#2D2B42] font-medium text-base">
                    {selectedItem.component_name}
                  </p>
                  <p className="text-[#B8B6CC] text-xs mt-1.5">
                    No screenshot available
                  </p>
                </div>
              </div>
            )}

            {/* Viewport badge */}
            <div
              className="absolute top-3 right-3 px-2.5 py-1 bg-white/90 backdrop-blur-sm rounded-lg text-[11px] text-[#8B89A3] border border-[#E4E3F1] font-mono"
              style={{ boxShadow: "0 1px 3px rgba(124, 110, 246, 0.08)" }}
            >
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
                    "linear-gradient(135deg, rgba(124,110,246,0.06), rgba(91,156,246,0.06))",
                  border: "1px solid #E4E3F1",
                }}
              >
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
                  <rect x="2" y="3" width="20" height="14" rx="2" />
                  <line x1="8" y1="21" x2="16" y2="21" />
                  <line x1="12" y1="17" x2="12" y2="21" />
                </svg>
              </div>
              <div>
                <p className="text-[#8B89A3] text-sm">
                  Select a component to preview
                </p>
                <p className="text-[#B8B6CC] text-[11px] mt-1">
                  Choose an item from the queue on the left
                </p>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Zoom controls */}
      <div
        className="absolute bottom-4 right-4 flex items-center gap-0.5 bg-white/90 backdrop-blur-sm rounded-xl border border-[#E4E3F1] p-1"
        style={{ boxShadow: "0 1px 3px rgba(124, 110, 246, 0.08)" }}
      >
        {zoomLevels.map((z) => (
          <button
            key={z.label}
            onClick={() => setZoom(z.value)}
            className="px-3 py-1.5 text-[11px] font-medium rounded-lg transition-all duration-200"
            style={{
              backgroundColor:
                zoom === z.value ? "#7C6EF6" : "transparent",
              color: zoom === z.value ? "#FFFFFF" : "#2D2B42",
            }}
          >
            {z.label}
          </button>
        ))}
      </div>
    </div>
  );
}
