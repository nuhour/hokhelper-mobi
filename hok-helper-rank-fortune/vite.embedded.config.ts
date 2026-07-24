import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import {defineConfig} from 'vite';
import {viteSingleFile} from 'vite-plugin-singlefile';

export default defineConfig({
  base: './',
  plugins: [react(), tailwindcss(), viteSingleFile()],
  build: {
    outDir: 'dist-embedded',
    emptyOutDir: true,
    rollupOptions: {
      input: path.resolve(__dirname, 'embedded.html'),
    },
  },
});
