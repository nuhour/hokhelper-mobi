import React, { useState } from 'react';
import { Settings2, ChevronDown, ChevronUp, Play, Sparkles, WifiOff, AlertTriangle, RotateCcw, Hand } from 'lucide-react';
import { CubeState } from '../types';

interface StateControlBarProps {
  currentState: CubeState;
  onSelectState: (state: CubeState) => void;
}

export const StateControlBar: React.FC<StateControlBarProps> = ({
  currentState,
  onSelectState,
}) => {
  const [isOpen, setIsOpen] = useState(false);

  const states: Array<{ id: CubeState; name: string; icon: React.ReactNode; desc: string }> = [
    { id: 'INITIAL', name: '初始展示', icon: <Sparkles className="w-3.5 h-3.5 text-amber-400" />, desc: '3D卦象仪悬浮待命' },
    { id: 'AUTO_ROTATING', name: '自动旋转', icon: <Play className="w-3.5 h-3.5 text-cyan-400" />, desc: 'CG双环自检巡航' },
    { id: 'DRAGGING', name: '用户拖动', icon: <Hand className="w-3.5 h-3.5 text-indigo-400" />, desc: '单指旋转/双指缩放' },
    { id: 'SHAKING', name: '摇签触发', icon: <RotateCcw className="w-3.5 h-3.5 text-rose-400" />, desc: '气焰运转双环旋转' },
    { id: 'RESULT_REVEALED', name: '结果揭示', icon: <Sparkles className="w-3.5 h-3.5 text-emerald-400" />, desc: '运势加成/推荐英雄' },
    { id: 'NETWORK_ERROR', name: '网络失败', icon: <WifiOff className="w-3.5 h-3.5 text-rose-400" />, desc: '网络请求超时重试' },
    { id: 'RESOURCE_3D_ERROR', name: '3D加载失败', icon: <AlertTriangle className="w-3.5 h-3.5 text-red-500" />, desc: 'CSS 3D极简降级模式' },
  ];

  return (
    <div className="w-full max-w-[420px] mx-auto mt-4 px-2">
      <div className="rounded-2xl bg-slate-900/80 border border-slate-800 backdrop-blur-md overflow-hidden transition-all">
        {/* Toggle Button */}
        <button
          onClick={() => setIsOpen(!isOpen)}
          className="w-full px-4 py-2.5 flex items-center justify-between text-xs font-semibold text-slate-300 hover:text-amber-300 transition-all"
        >
          <div className="flex items-center gap-2">
            <Settings2 className="w-4 h-4 text-amber-400" />
            <span>状态控制台 (切换 7 种测试状态)</span>
            <span className="px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-300 text-[10px] font-medium border border-amber-500/30">
              当前: {states.find((s) => s.id === currentState)?.name}
            </span>
          </div>
          {isOpen ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
        </button>

        {/* State Selection Grid */}
        {isOpen && (
          <div className="p-3 border-t border-slate-800/80 grid grid-cols-2 gap-2 text-xs bg-slate-950/60 animate-fadeIn">
            {states.map((st) => (
              <button
                key={st.id}
                onClick={() => {
                  onSelectState(st.id);
                }}
                className={`p-2.5 rounded-xl border text-left transition-all flex flex-col justify-between gap-1 ${
                  currentState === st.id
                    ? 'bg-amber-500/15 border-amber-500/60 text-amber-200 shadow-md shadow-amber-500/10'
                    : 'bg-slate-900/60 border-slate-800 text-slate-400 hover:border-slate-700 hover:text-slate-200'
                }`}
              >
                <div className="flex items-center gap-1.5 font-bold">
                  {st.icon}
                  <span>{st.name}</span>
                </div>
                <div className="text-[10px] text-slate-400/80 truncate">{st.desc}</div>
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
