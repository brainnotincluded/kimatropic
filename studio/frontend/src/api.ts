import { io, type Socket } from "socket.io-client";
import { useStore } from "./store";
import type { QueueItem, FeedbackEntry } from "./types";

const API_BASE = "/api";

class API {
  private socket: Socket | null = null;

  async fetchQueue(): Promise<QueueItem[]> {
    const res = await fetch(`${API_BASE}/queue`);
    if (!res.ok) throw new Error("Failed to fetch queue");
    const data = await res.json();
    return data.items;
  }

  async addItem(
    item: Pick<QueueItem, "component_name" | "screenshot_path" | "code_snippet" | "viewport">
  ): Promise<QueueItem> {
    const res = await fetch(`${API_BASE}/queue`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(item),
    });
    if (!res.ok) throw new Error("Failed to add item");
    return res.json();
  }

  async submitFeedback(
    id: string,
    action: "approve" | "reject",
    comment: string,
    file?: File
  ): Promise<{ item: QueueItem }> {
    const form = new FormData();
    form.append("action", action);
    form.append("comment", comment);
    if (file) form.append("attachment", file);

    const res = await fetch(`${API_BASE}/feedback/${id}`, {
      method: "POST",
      body: form,
    });
    if (!res.ok) throw new Error("Failed to submit feedback");
    return res.json();
  }

  async getFeedback(id: string): Promise<FeedbackEntry[]> {
    const res = await fetch(`${API_BASE}/feedback/${id}`);
    if (!res.ok) throw new Error("Failed to get feedback");
    const data = await res.json();
    return data.feedback_history;
  }

  connectSocket(): void {
    if (this.socket) return;

    const store = useStore.getState();
    store.setConnectionStatus("connecting");

    this.socket = io({
      path: "/socket.io",
      transports: ["websocket", "polling"],
      reconnection: true,
      reconnectionAttempts: Infinity,
      reconnectionDelay: 1000,
      reconnectionDelayMax: 5000,
    });

    this.socket.on("connect", () => {
      useStore.getState().setConnectionStatus("connected");
    });

    this.socket.on("disconnect", () => {
      useStore.getState().setConnectionStatus("disconnected");
    });

    this.socket.on("connect_error", () => {
      useStore.getState().setConnectionStatus("disconnected");
    });

    // The server emits the full queue on queue_update
    this.socket.on("queue_update", (data: { items: QueueItem[] }) => {
      useStore.getState().setItems(data.items);
    });

    // The server emits a feedback_update with the updated item
    this.socket.on(
      "feedback_update",
      (data: { item_id: string; feedback: FeedbackEntry; item: QueueItem }) => {
        useStore.getState().updateItem(data.item_id, {
          status: data.item.status,
          feedback_history: data.item.feedback_history,
        });
      }
    );
  }

  disconnectSocket(): void {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
    }
  }
}

export const api = new API();
