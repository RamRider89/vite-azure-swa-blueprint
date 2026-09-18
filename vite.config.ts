import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [react()],
  build: {
    // Azure SWA Oryx builder expects 'build/' (CRA convention), not Vite's default 'dist/'
    outDir: 'build',
  },
})
