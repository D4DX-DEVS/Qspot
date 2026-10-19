import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// Same API the mobile app talks to by default (mobile-app/lib/utils/api_urls.dart).
const PRODUCTION_API = 'https://qspot-app-vcbgp.ondigitalocean.app'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  return {
    plugins: [react(), tailwindcss()],
    server: {
      // In development the browser calls /api on this dev server, which
      // forwards to the API, so no CORS setup is needed while working locally.
      proxy: {
        '/api': {
          target: env.VITE_API_PROXY_TARGET || PRODUCTION_API,
          changeOrigin: true,
        },
      },
    },
    test: {
      environment: 'node',
      setupFiles: ['src/test/setup.js'],
    },
  }
})
