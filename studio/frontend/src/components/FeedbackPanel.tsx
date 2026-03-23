import { useState, useRef, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useStore } from "../store";
import { StatusBadge } from "./StatusBadge";
import { api } from "../api";

export function FeedbackPanel() {
  const items = useStore((s) => s.items);
  const selectedId = useStore((s) => s.selectedId);
  const updateItem = useStore((s) => s.updateItem);

  const [comment, setComment] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const [filePreview, setFilePreview] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showCode, setShowCode] = useState(false);
  const [isDragOver, setIsDragOver] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const selectedItem = items.find((i) => i.id === selectedId);

  const handleFileChange = useCallback((f: File) => {
    setFile(f);
    if (f.type.startsWith("image/")) {
      const reader = new FileReader();
      reader.onload = (e) => setFilePreview(e.target?.result as string);
      reader.readAsDataURL(f);
    } else {
      setFilePreview(null);
    }
  }, []);

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      setIsDragOver(false);
      const dropped = e.dataTransfer.files[0];
      if (dropped) handleFileChange(dropped);
    },
    [handleFileChange]
  );

  const clearFile = useCallback(() => {
    setFile(null);
    setFilePreview(null);
    if (fileInputRef.current) fileInputRef.current.value = "";
  }, []);

  const handleSubmit = async (action: "approve" | "reject") => {
    if (!selectedItem) return;
    setIsSubmitting(true);
    try {
      const result = await api.submitFeedback(
        selectedItem.id,
        action,
        comment,
        file || undefined
      );
      updateItem(selectedItem.id, {
        status: result.item.status,
        feedback_history: result.item.feedback_history,
      });
      setComment("");
      clearFile();
    } catch (err) {
      console.error("Failed to submit feedback:", err);
    } finally {
      setIsSubmitting(false);
    }
  };

  // Empty state
  if (!selectedItem) {
    return (
      <aside className="w-[360px] shrink-0 bg-[#0F1114] border-l border-[#2A3038] flex items-center justify-center">
        <div className="text-center">
          <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#2A3038"
            strokeWidth="1.5"
            strokeLinecap="round"
            strokeLinejoin="round"
            className="mx-auto mb-3"
          >
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
          </svg>
          <p className="text-[#9CA3AF] text-sm">Select an item to review</p>
        </div>
      </aside>
    );
  }

  return (
    <aside className="w-[360px] shrink-0 bg-[#0F1114] border-l border-[#2A3038] flex flex-col overflow-hidden">
      {/* Header */}
      <div className="px-5 py-4 border-b border-[#2A3038]">
        <div className="flex items-center justify-between gap-2">
          <h2 className="text-[#F7F8FA] font-semibold text-base truncate">
            {selectedItem.component_name}
          </h2>
          <StatusBadge status={selectedItem.status} />
        </div>
        <p className="text-[10px] text-[#6B7280] mt-1 font-mono">
          {selectedItem.viewport}
        </p>
      </div>

      {/* Scrollable content */}
      <div className="flex-1 overflow-y-auto">
        <div className="p-5 space-y-5">
          {/* Code Snippet (collapsible) */}
          {selectedItem.code_snippet && (
            <div>
              <button
                onClick={() => setShowCode(!showCode)}
                className="flex items-center justify-between w-full text-xs text-[#9CA3AF] hover:text-[#F7F8FA] transition-colors group"
              >
                <span className="font-medium">Code Snippet</span>
                <motion.svg
                  width="14"
                  height="14"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  animate={{ rotate: showCode ? 180 : 0 }}
                  transition={{ duration: 0.2 }}
                >
                  <polyline points="6 9 12 15 18 9" />
                </motion.svg>
              </button>

              <AnimatePresence initial={false}>
                {showCode && (
                  <motion.div
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: "auto", opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    transition={{ duration: 0.2 }}
                    className="overflow-hidden"
                  >
                    <pre className="mt-2 p-3 bg-[#0A0B0D] border border-[#1E2329] rounded-md overflow-x-auto text-[11px] text-[#9CA3AF] font-mono leading-relaxed">
                      <code>{selectedItem.code_snippet}</code>
                    </pre>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          )}

          {/* Divider */}
          <div className="h-px bg-[#1E2329]" />

          {/* Comment */}
          <div>
            <label className="block text-xs text-[#9CA3AF] font-medium mb-2">
              Feedback
            </label>
            <textarea
              value={comment}
              onChange={(e) => setComment(e.target.value)}
              placeholder="What needs to change?"
              rows={4}
              className="w-full p-3 bg-[#15181C] border border-[#2A3038] rounded-md text-[#F7F8FA] text-sm placeholder-[#6B7280] resize-y focus:outline-none focus:border-[#00D9FF] transition-colors leading-relaxed"
              style={{ minHeight: "100px" }}
            />
          </div>

          {/* File Upload */}
          <div>
            <label className="block text-xs text-[#9CA3AF] font-medium mb-2">
              Attachment
            </label>
            <div
              onDrop={handleDrop}
              onDragOver={(e) => {
                e.preventDefault();
                setIsDragOver(true);
              }}
              onDragLeave={() => setIsDragOver(false)}
              onClick={() => fileInputRef.current?.click()}
              className="relative p-4 border-2 border-dashed rounded-lg cursor-pointer transition-all duration-150 text-center"
              style={{
                borderColor: isDragOver ? "#00D9FF" : "#2A3038",
                backgroundColor: isDragOver ? "rgba(0,217,255,0.03)" : "#15181C",
              }}
            >
              <input
                ref={fileInputRef}
                type="file"
                onChange={(e) => {
                  const f = e.target.files?.[0];
                  if (f) handleFileChange(f);
                }}
                className="hidden"
                accept="image/*,video/*"
              />

              {file ? (
                <div className="flex items-center gap-3">
                  {filePreview && (
                    <img
                      src={filePreview}
                      alt=""
                      className="w-10 h-10 rounded object-cover border border-[#2A3038]"
                    />
                  )}
                  <div className="flex-1 min-w-0 text-left">
                    <p className="text-[#F7F8FA] text-xs truncate">
                      {file.name}
                    </p>
                    <p className="text-[#6B7280] text-[10px] mt-0.5">
                      {(file.size / 1024).toFixed(1)} KB
                    </p>
                  </div>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      clearFile();
                    }}
                    className="text-[#6B7280] hover:text-[#EF4444] transition-colors p-1"
                  >
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
                      <line x1="18" y1="6" x2="6" y2="18" />
                      <line x1="6" y1="6" x2="18" y2="18" />
                    </svg>
                  </button>
                </div>
              ) : (
                <div>
                  <svg
                    width="20"
                    height="20"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="#6B7280"
                    strokeWidth="1.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="mx-auto mb-2"
                  >
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                    <polyline points="17 8 12 3 7 8" />
                    <line x1="12" y1="3" x2="12" y2="15" />
                  </svg>
                  <p className="text-[#6B7280] text-xs">
                    Drop file or click to upload
                  </p>
                </div>
              )}
            </div>
          </div>

          {/* Action Buttons */}
          <div className="space-y-2.5 pt-1">
            <motion.button
              whileTap={{ scale: 0.97 }}
              onClick={() => handleSubmit("approve")}
              disabled={isSubmitting}
              className="w-full py-2.5 rounded-md font-medium text-sm transition-all duration-150 disabled:opacity-40 disabled:cursor-not-allowed"
              style={{
                backgroundColor: "#22C55E",
                color: "#fff",
              }}
            >
              {isSubmitting ? "Submitting..." : "Approve"}
            </motion.button>

            <motion.button
              whileTap={comment.trim() ? { scale: 0.97 } : {}}
              onClick={() => handleSubmit("reject")}
              disabled={isSubmitting || !comment.trim()}
              className="w-full py-2.5 rounded-md font-medium text-sm transition-all duration-150 disabled:opacity-40 disabled:cursor-not-allowed"
              style={{
                backgroundColor:
                  !comment.trim() || isSubmitting
                    ? "rgba(245,158,11,0.3)"
                    : "#F59E0B",
                color: "#fff",
              }}
            >
              Request Changes
            </motion.button>
          </div>

          {/* Feedback History */}
          <AnimatePresence>
            {selectedItem.feedback_history.length > 0 && (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                className="pt-4 border-t border-[#1E2329]"
              >
                <h3 className="text-xs text-[#9CA3AF] font-medium mb-3">
                  History ({selectedItem.feedback_history.length})
                </h3>
                <div className="space-y-2">
                  {selectedItem.feedback_history.map((fb, idx) => (
                    <div
                      key={idx}
                      className="p-3 bg-[#15181C] rounded-md border border-[#1E2329]"
                    >
                      <div className="flex items-center justify-between mb-1.5">
                        <span
                          className="text-[10px] font-medium"
                          style={{
                            color:
                              fb.action === "approve" ? "#22C55E" : "#F59E0B",
                          }}
                        >
                          {fb.action === "approve"
                            ? "Approved"
                            : "Changes Requested"}
                        </span>
                        <span className="text-[10px] text-[#6B7280]">
                          {(() => {
                            try {
                              return new Date(fb.timestamp).toLocaleString([], {
                                month: "short",
                                day: "numeric",
                                hour: "2-digit",
                                minute: "2-digit",
                              });
                            } catch {
                              return "";
                            }
                          })()}
                        </span>
                      </div>
                      {fb.comment && (
                        <p className="text-xs text-[#F7F8FA] leading-relaxed">
                          {fb.comment}
                        </p>
                      )}
                      {fb.attachment_path && (
                        <a
                          href={fb.attachment_path}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="inline-flex items-center gap-1 text-[10px] text-[#00D9FF] mt-1.5 hover:underline"
                        >
                          <svg
                            width="10"
                            height="10"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            strokeWidth="2"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                          >
                            <path d="m21.44 11.05-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48" />
                          </svg>
                          Attachment
                        </a>
                      )}
                    </div>
                  ))}
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
    </aside>
  );
}
