import React, { useState, useEffect } from 'react';
import {
  Sparkles,
  Zap,
  RotateCcw,
  Volume2,
  VolumeX,
  History,
  Compass,
  ChevronRight,
} from 'lucide-react';
import { CubeState, FortuneResult, PlayerProfile } from './types';
import { HexagramInstrument3D } from './components/HexagramInstrument3D';
import { ProceduralCubeFallback } from './components/ProceduralCubeFallback';
import { NetworkErrorBanner } from './components/NetworkErrorBanner';
import { FortuneResultModal } from './components/FortuneResultModal';
import { FortuneHistoryChart } from './components/FortuneHistoryChart';
import { generateHokFortune } from './utils/fortuneGenerator';
import { playFortuneSpinSound, toggleAudioMute, getIsMuted } from './utils/audio';

export default function App() {
  const [cubeState, setCubeState] = useState<CubeState>('AUTO_ROTATING');
  const [isMuted, setIsMuted] = useState<boolean>(false);
  const [fortuneResult, setFortuneResult] = useState<FortuneResult | null>(null);
  const [fortuneHistory, setFortuneHistory] = useState<FortuneResult[]>([]);
  const [showHistoryModal, setShowHistoryModal] = useState<boolean>(false);
  const [showDetailModal, setShowDetailModal] = useState<boolean>(false);
  const [showChart, setShowChart] = useState<boolean>(false);

  const [player] = useState<PlayerProfile>({
    name: '峡谷上分王',
    avatar: 'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=150',
    rank: '最强王者',
    stars: 25,
    winStreak: 4,
    preferredLane: '全能位',
  });

  useEffect(() => {
    setIsMuted(getIsMuted());
  }, []);

  const handleToggleMute = () => {
    const updated = toggleAudioMute();
    setIsMuted(updated);
  };

  // Action: Trigger Shake Fortune Spin
  const handleShakeFortune = () => {
    if (cubeState === 'SHAKING') return;

    setShowDetailModal(false);
    playFortuneSpinSound();
    setCubeState('SHAKING');
  };

  // Called when 3D Hexagram Instrument finishes spin animation
  const handleShakeComplete = () => {
    const result = generateHokFortune(player.preferredLane, player.rank);
    setFortuneResult(result);
    setFortuneHistory((prev) => [result, ...prev]);
    setCubeState('RESULT_REVEALED');
  };

  // Retry action for Network or 3D error
  const handleRetryState = () => {
    setCubeState('INITIAL');
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans select-none overflow-x-hidden relative">
      {/* 1. Full Page 3D Background Canvas (3D背景占满整个页面) */}
      <div className="fixed inset-0 z-0 pointer-events-auto">
        {cubeState === 'RESOURCE_3D_ERROR' ? (
          <ProceduralCubeFallback
            cubeState={cubeState}
            onRetry={handleRetryState}
            onShakeComplete={handleShakeComplete}
          />
        ) : (
          <HexagramInstrument3D
            cubeState={cubeState}
            fortuneResult={fortuneResult}
            onStateChange={(st) => setCubeState(st)}
            onShakeComplete={handleShakeComplete}
            onResourceError={() => setCubeState('RESOURCE_3D_ERROR')}
            onOpenDetailModal={() => setShowDetailModal(true)}
            onReroll={handleShakeFortune}
            onCloseResult={() => setCubeState('AUTO_ROTATING')}
          />
        )}
      </div>

      {/* Background CG Atmosphere Energy Lines */}
      <div className="fixed inset-0 pointer-events-none z-0">
        <div className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] bg-rose-500/10 rounded-full blur-[120px]" />
        <div className="absolute bottom-[-10%] right-[-10%] w-[50%] h-[50%] bg-cyan-500/10 rounded-full blur-[120px]" />
        <div className="absolute top-[30%] right-[-5%] w-[35%] h-[35%] bg-amber-600/10 rounded-full blur-[100px]" />
      </div>

      {/* 2. Floating UI Layer Overlay */}
      <div className="relative z-10 min-h-screen max-w-md w-full mx-auto px-4 py-3 flex flex-col justify-between pointer-events-none">
        {/* Top Minimal Header Bar */}
        <header className="flex items-center justify-between py-1 pointer-events-auto">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-slate-950/30 backdrop-blur-md border border-amber-400/30 text-amber-200 text-xs font-serif font-bold shadow-md">
            <span className="text-amber-400 text-sm">☯</span>
            <span>方舟秘仪 · 奇门卜卦</span>
          </div>

          <button
            onClick={handleToggleMute}
            className="p-2 rounded-full bg-slate-950/30 backdrop-blur-md border border-amber-400/20 text-amber-200 hover:text-amber-400 active:scale-90 transition-all cursor-pointer"
            title={isMuted ? '取消静音' : '静音'}
          >
            {isMuted ? <VolumeX className="w-4 h-4 text-rose-400" /> : <Volume2 className="w-4 h-4 text-amber-400" />}
          </button>
        </header>

        {/* Network Error Alert Banner */}
        {cubeState === 'NETWORK_ERROR' && (
          <div className="pointer-events-auto my-2">
            <NetworkErrorBanner onRetry={handleRetryState} />
          </div>
        )}

        {/* Middle Flexible Space for Viewing 3D Instrument */}
        <div className="flex-1 pointer-events-none" />

        {/* Bottom Section: History Trend Line Chart & Core CTA Button */}
        <div className="my-2 space-y-2 text-center pointer-events-auto">
          {/* History Fortune Line Chart at Bottom (hidden by default) */}
          {showChart && (
            <FortuneHistoryChart
              history={fortuneHistory}
              currentFortune={fortuneResult}
              onSelectFortune={(item) => {
                setFortuneResult(item);
                setShowDetailModal(true);
              }}
              onOpenFullHistory={() => setShowHistoryModal(true)}
            />
          )}

          {/* Shake Fortune Core Button */}
          <button
            onClick={handleShakeFortune}
            disabled={cubeState === 'SHAKING'}
            className={`w-full py-3.5 px-6 rounded-2xl font-serif font-black text-base tracking-widest transition-all duration-200 shadow-xl flex items-center justify-center gap-2.5 relative overflow-hidden group cursor-pointer backdrop-blur-md ${
              cubeState === 'SHAKING'
                ? 'bg-slate-950/40 text-amber-200/50 border border-amber-500/20 cursor-not-allowed'
                : 'bg-gradient-to-r from-amber-600/70 via-rose-600/70 to-amber-600/70 hover:from-amber-500/85 hover:to-rose-500/85 text-amber-100 shadow-rose-950/30 active:scale-95 border border-amber-300/40'
            }`}
          >
            {/* Energy Particle Shine effect */}
            <div className="absolute inset-0 bg-gradient-to-r from-transparent via-amber-200/20 to-transparent translate-x-[-100%] group-hover:translate-x-[100%] transition-transform duration-1000" />

            {cubeState === 'SHAKING' ? (
              <>
                <RotateCcw className="w-5 h-5 animate-spin text-amber-300" />
                <span className="text-amber-200">方舟爻盘周转演算中...</span>
              </>
            ) : (
              <>
                <span className="text-amber-300 text-lg">☯</span>
                <span>摇卦求爻 · 窥演天机</span>
              </>
            )}
          </button>

          {/* Quick Sub-status */}
          <div className="flex items-center justify-between text-xs font-serif text-amber-200/70 px-2 pb-1">
            <button
              onClick={() => setShowHistoryModal(true)}
              className="flex items-center gap-1 hover:text-amber-200 transition-all cursor-pointer"
            >
              <History className="w-3.5 h-3.5 text-amber-400" />
              <span>历演天机 ({fortuneHistory.length})</span>
            </button>

            <button
              onClick={() => setShowChart(!showChart)}
              className="flex items-center gap-1 text-amber-300/80 hover:text-amber-200 transition-all cursor-pointer"
            >
              <Compass className="w-3.5 h-3.5 text-amber-400" />
              <span>{showChart ? '收起气运轨' : '展开气运轨'}</span>
            </button>
          </div>
        </div>
      </div>

      {/* Full Fortune Detail Modal */}
      {showDetailModal && fortuneResult && (
        <FortuneResultModal
          fortune={fortuneResult}
          player={player}
          onClose={() => setShowDetailModal(false)}
          onReroll={handleShakeFortune}
        />
      )}

      {/* History Modal Drawer */}
      {showHistoryModal && (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-slate-950/80 backdrop-blur-md p-0 sm:p-4 animate-fadeIn">
          <div className="w-full max-w-md bg-slate-900 border border-slate-800 rounded-t-3xl sm:rounded-3xl p-5 max-h-[80vh] flex flex-col shadow-2xl animate-slideUp">
            <div className="flex items-center justify-between mb-4">
              <div className="font-bold text-slate-100 text-sm flex items-center gap-2">
                <History className="w-4 h-4 text-amber-400" />
                <span>今日测算运势历史</span>
              </div>
              <button
                onClick={() => setShowHistoryModal(false)}
                className="text-xs text-slate-400 hover:text-white px-2 py-1 rounded-lg bg-slate-800 cursor-pointer"
              >
                关闭
              </button>
            </div>

            {fortuneHistory.length === 0 ? (
              <div className="text-center py-12 text-slate-500 text-xs">
                尚无测算记录，点击“摇签”测试今日运势吧！
              </div>
            ) : (
              <div className="overflow-y-auto space-y-2.5 text-xs pr-1">
                {fortuneHistory.map((item) => (
                  <div
                    key={item.id}
                    onClick={() => {
                      setFortuneResult(item);
                      setShowHistoryModal(false);
                      setShowDetailModal(true);
                    }}
                    className="p-3 rounded-2xl bg-slate-800/60 border border-slate-700/60 hover:border-amber-500/40 cursor-pointer transition-all flex items-center justify-between"
                  >
                    <div>
                      <div className="font-bold text-amber-300 text-xs flex items-center gap-2">
                        <span>{item.luckTier}</span>
                        <span className="text-[10px] text-slate-400 font-normal">{item.timestamp}</span>
                      </div>
                      <div className="text-slate-300 text-xs mt-0.5 truncate max-w-[220px]">
                        {item.summary}
                      </div>
                    </div>
                    <div className="flex items-center gap-1 text-cyan-400 text-xs font-semibold">
                      <span>查看</span>
                      <ChevronRight className="w-3.5 h-3.5" />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
