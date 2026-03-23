import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    proxy: {
      "/api": "http://localhost:7860",
      "/socket.io": {
        target: "http://localhost:7860",
        ws: true,
      },
      "/uploads": "http://localhost:7860",
    },
  },
  build: {
    outDir: "dist",
  },
});
