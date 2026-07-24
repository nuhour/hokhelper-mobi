import {StrictMode} from 'react';
import {createRoot} from 'react-dom/client';
import App from './App.tsx';
import EmbeddedApp from './EmbeddedApp.tsx';
import './index.css';

const embedded = new URLSearchParams(window.location.search).get('embedded') === '1';

createRoot(document.getElementById('root')!).render(
  embedded ? (
    <EmbeddedApp />
  ) : (
    <StrictMode>
      <App />
    </StrictMode>
  ),
);
