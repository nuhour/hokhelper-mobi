import {useCallback, useEffect, useState} from 'react';
import {HexagramInstrument3D} from './components/HexagramInstrument3D';
import {CubeState} from './types';

declare global {
  interface Window {
    RankFortuneBridge?: {postMessage: (message: string) => void};
    rankFortune3D?: {
      spin: () => boolean;
      reset: () => void;
    };
  }
}

const postToFlutter = (type: string) => {
  window.RankFortuneBridge?.postMessage(JSON.stringify({type}));
};

export default function EmbeddedApp() {
  const [cubeState, setCubeState] = useState<CubeState>('AUTO_ROTATING');

  useEffect(() => {
    window.rankFortune3D = {
      spin: () => {
        if (cubeState === 'SHAKING') return false;
        setCubeState('SHAKING');
        return true;
      },
      reset: () => setCubeState('AUTO_ROTATING'),
    };
    postToFlutter('ready');
    return () => {
      delete window.rankFortune3D;
    };
  }, [cubeState]);

  const handleShakeComplete = useCallback(() => {
    postToFlutter('spinComplete');
    setCubeState('AUTO_ROTATING');
  }, []);

  return (
    <HexagramInstrument3D
      embedded
      cubeState={cubeState}
      onStateChange={setCubeState}
      onShakeComplete={handleShakeComplete}
      onResourceError={() => postToFlutter('resourceError')}
    />
  );
}
