import React, { useState } from 'react';
import { AlertTriangle, RefreshCw, RotateCcw } from 'lucide-react';
import { CubeState } from '../types';

interface ProceduralCubeFallbackProps {
  cubeState: CubeState;
  onRetry: () => void;
  onShakeComplete: () => void;
}

export const ProceduralCubeFallback: React.FC<ProceduralCubeFallbackProps> = ({
  cubeState,
  onRetry,
}) => {
  const [rotX, setRotX] = useState(-20);
  const [rotY, setRotY] = useState(35);
  const [isDragging, setIsDragging] = useState(false);
  const [startPos, setStartPos] = useState({ x: 0, y: 0 });

  const handleMouseDown = (e: React.MouseEvent) => {
    setIsDragging(true);
    setStartPos({ x: e.clientX, y: e.clientY });
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!isDragging) return;
    const dx = e.clientX - startPos.x;
    const dy = e.clientY - startPos.y;
    setRotY((prev) => prev + dx * 0.5);
    setRotX((prev) => Math.max(-80, Math.min(80, prev - dy * 0.5)));
    setStartPos({ x: e.clientX, y: e.clientY });
  };

  const handleMouseUp = () => setIsDragging(false);

  return (
    <div className="relative w-full aspect-square max-w-[380px] mx-auto flex flex-col items-center justify-center p-4">
      {/* 3D Asset Error Banner */}
      <div className="absolute top-2 left-0 right-0 z-30 mx-auto w-[92%] p-3 rounded-xl bg-red-950/90 border border-red-500/50 backdrop-blur-md text-red-200 text-xs shadow-xl flex items-center justify-between">
        <div className="flex items-center gap-2">
          <AlertTriangle className="w-4 h-4 text-rose-400 shrink-0 animate-bounce" />
          <span>3D 资源加载异常，已启用 CSS 3D 卦象仪降级模式</span>
        </div>
        <button
          onClick={onRetry}
          className="px-2.5 py-1 rounded-lg bg-rose-600 hover:bg-rose-500 text-white font-medium flex items-center gap-1 transition-all active:scale-95"
        >
          <RefreshCw className="w-3 h-3" />
          <span>重试</span>
        </button>
      </div>

      {/* CSS 3D Hexagram Instrument Visual */}
      <div
        className="w-56 h-56 my-8 cursor-grab active:cursor-grabbing select-none relative flex items-center justify-center"
        style={{ perspective: '800px' }}
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
      >
        <div
          className={`w-full h-full relative flex items-center justify-center transition-transform duration-100 ease-out ${
            cubeState === 'SHAKING' ? 'animate-spin' : ''
          }`}
          style={{
            transformStyle: 'preserve-3d',
            transform: `rotateX(${rotX}deg) rotateY(${rotY}deg)`,
          }}
        >
          {/* Octagonal Outer Metal Frame with Bagua Trigrams */}
          <div className="absolute inset-0 rounded-full border-8 border-slate-300 bg-gradient-to-tr from-slate-400 via-slate-200 to-slate-500 shadow-2xl flex items-center justify-center">
            {/* Bagua Trigram Markings */}
            {['☰', '☱', '☲', '☳', '☴', '☵', '☶', '☷'].map((trigram, i) => (
              <div
                key={i}
                className="absolute font-black text-slate-900 text-lg"
                style={{
                  transform: `rotate(${i * 45}deg) translateY(-88px)`,
                }}
              >
                {trigram}
              </div>
            ))}
          </div>

          {/* Outer Silver Ring */}
          <div className="absolute w-44 h-44 rounded-full border-4 border-slate-200/90 border-dashed animate-spin" style={{ animationDuration: '12s' }} />

          {/* Inner Crimson Red Ring */}
          <div className="absolute w-36 h-36 rounded-full border-4 border-rose-600/90 border-dotted animate-spin" style={{ animationDuration: '8s', animationDirection: 'reverse' }} />

          {/* Glowing Magenta Glass Core Sphere */}
          <div className="w-28 h-28 rounded-full bg-gradient-to-tr from-rose-600 via-pink-500 to-amber-300 shadow-2xl shadow-rose-500/80 flex items-center justify-center relative overflow-hidden animate-pulse">
            <div className="w-16 h-16 rounded-full bg-amber-200/40 blur-md animate-ping" />
            <div className="absolute inset-0 flex items-center justify-center font-black text-white text-xl drop-shadow-lg">
              ☯
            </div>
          </div>
        </div>
      </div>

      <div className="flex items-center gap-2 text-xs text-slate-400 z-10">
        <button
          onClick={() => {
            setRotX(-20);
            setRotY(35);
          }}
          className="flex items-center gap-1 text-cyan-400 hover:underline"
        >
          <RotateCcw className="w-3 h-3" /> 复位视角
        </button>
      </div>
    </div>
  );
};
