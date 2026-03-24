interface Props {
  status: "pending" | "approved" | "rejected";
}

const config = {
  pending: {
    bg: "#F5F3FF",
    text: "#7C6EF6",
    label: "Pending",
  },
  approved: {
    bg: "#E8F8F0",
    text: "#5CC99B",
    label: "Approved",
  },
  rejected: {
    bg: "#FDE8EC",
    text: "#E8677A",
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
