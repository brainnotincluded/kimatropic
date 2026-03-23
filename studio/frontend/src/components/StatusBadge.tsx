interface Props {
  status: "pending" | "approved" | "rejected";
}

const config = {
  pending: {
    bg: "rgba(0, 217, 255, 0.1)",
    text: "#00D9FF",
    label: "Pending",
  },
  approved: {
    bg: "rgba(34, 197, 94, 0.1)",
    text: "#22C55E",
    label: "Approved",
  },
  rejected: {
    bg: "rgba(239, 68, 68, 0.1)",
    text: "#EF4444",
    label: "Rejected",
  },
} as const;

export function StatusBadge({ status }: Props) {
  const c = config[status];
  return (
    <span
      className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-medium leading-tight"
      style={{ backgroundColor: c.bg, color: c.text }}
    >
      {c.label}
    </span>
  );
}
