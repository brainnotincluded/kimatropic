import { create } from 'zustand';
import type { QueueItem, ConnectionStatus } from './types';

interface StoreState {
  items: QueueItem[];
  selectedId: string | null;
  connectionStatus: ConnectionStatus;
  setItems: (items: QueueItem[]) => void;
  addItem: (item: QueueItem) => void;
  updateItem: (id: string, updates: Partial<QueueItem>) => void;
  selectItem: (id: string | null) => void;
  setConnectionStatus: (status: ConnectionStatus) => void;
}

export const useStore = create<StoreState>((set) => ({
  items: [],
  selectedId: null,
  connectionStatus: 'disconnected',
  setItems: (items) => set({ items }),
  addItem: (item) => set((state) => ({ items: [...state.items, item] })),
  updateItem: (id, updates) => set((state) => ({
    items: state.items.map((item) =>
      item.id === id ? { ...item, ...updates } : item
    )
  })),
  selectItem: (id) => set({ selectedId: id }),
  setConnectionStatus: (status) => set({ connectionStatus: status }),
}));
