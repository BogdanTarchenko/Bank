import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  define: {
    global: 'globalThis',
  },
  optimizeDeps: {
    esbuildOptions: {
      define: {
        global: 'globalThis',
      },
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api/client': {
        target: 'http://localhost:8084',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/api\/client/, '/api/v1'),
      },
      '/api/employee': {
        target: 'http://localhost:8085',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/api\/employee/, '/api/v1'),
      },
      '/auth': {
        target: 'http://localhost:8081',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/auth/, ''),
      },
      '/ws': {
        target: 'http://localhost:8084',
        ws: true,
        changeOrigin: true,
      },
    },
  },
})
