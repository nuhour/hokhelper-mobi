import React, { useEffect } from 'react';
import confetti from 'canvas-confetti';
import {
  Sparkles,
  Share2,
  RotateCcw,
  ShieldCheck,
  Clock,
  Swords,
  Users,
  X,
  Award,
  Zap,
} from 'lucide-react';
import { FortuneResult, PlayerProfile } from '../types';
import { playFortuneChimeSound, triggerHaptic } from '../utils/audio';

interface FortuneResultModalProps {
  fortune: FortuneResult | null;
  player: PlayerProfile;
  onClose: () => void;
  onReroll: () => void;
}

export const FortuneResultModal: React.FC<FortuneResultModalProps> = ({
  fortune,
  player,
  onClose,
  onReroll,
}) => {
  useEffect(() => {
    if (fortune) {
      playFortuneChimeSound();
      triggerHaptic([40, 80, 120]);

      // Fire celebratory confetti explosion
      try {
        confetti({
          particleCount: 80,
          spread: 70,
          origin: { y: 0.6 },
          colors: ['#f59e0b', '#06b6d4', '#8b5cf6', '#fbbf24', '#38bdf8'],
        });
      } catch {
        // Ignore confetti if unsupported
      }
    }
  }, [fortune]);

  if (!fortune) return null;

  const luckTierColor =
    fortune.luckTier === '大吉'
      ? 'from-amber-500 via-orange-500 to-red-600 text-amber-300 border-amber-400/60 shadow-amber-500/30'
      : fortune.luckTier === '上吉'
      ? 'from-cyan-500 via-blue-600 to-indigo-700 text-cyan-200 border-cyan-400/60 shadow-cyan-500/30'
      : fortune.luckTier === '中吉'
      ? 'from-emerald-500 via-teal-600 to-slate-800 text-emerald-200 border-emerald-400/60 shadow-emerald-500/30'
      : 'from-purple-500 via-slate-700 to-slate-900 text-purple-200 border-purple-400/60 shadow-purple-500/30';

  const handleCopyShare = () => {
    const text = `【王者荣耀排位运势】今日方舟魔方测得：${fortune.luckTier} (胜率指数${fortune.luckScore}分)！${fortune.summary} 最佳上分英雄：${fortune.recommendedHeroes.map(h => h.name).join('、')}。推荐最佳时段：${fortune.luckyTime}`;
    if (navigator.clipboard) {
      navigator.clipboard.writeText(text);
      alert('运势密语已复制到剪贴板，快分享给排位固排队友吧！');
    } else {
      alert(text);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-slate-950/80 backdrop-blur-xl animate-fadeIn">
      <div className="relative w-full max-w-lg bg-slate-900/95 border border-amber-500/40 rounded-t-3xl sm:rounded-3xl shadow-2xl overflow-hidden max-h-[90vh] flex flex-col animate-slideUp">
        {/* Background Energy Glow Header */}
        <div className="absolute top-0 left-0 right-0 h-32 bg-gradient-to-b from-amber-500/10 via-cyan-500/5 to-transparent pointer-events-none" />

        {/* Modal Close Button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 z-20 p-2 rounded-full bg-slate-800/80 text-slate-400 hover:text-white hover:bg-slate-700 transition-all"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Modal Header */}
        <div className="p-6 pb-2 text-center relative z-10">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-slate-800/80 border border-amber-500/30 text-amber-300 text-xs font-medium mb-3">
            <Zap className="w-3.5 h-3.5 text-amber-400 animate-bounce" />
            <span>{player.rank} · 方舟卦象仪窥见胜局</span>
          </div>

          <div className="flex items-center justify-center gap-4 my-2">
            {/* Luck Tier Badge */}
            <div className={`px-6 py-2.5 rounded-2xl bg-gradient-to-r border-2 shadow-xl font-black text-2xl tracking-widest flex items-center gap-2 ${luckTierColor}`}>
              <Sparkles className="w-6 h-6 animate-pulse" />
              <span>{fortune.luckTier}</span>
            </div>

            {/* Score */}
            <div className="flex flex-col items-start justify-center">
              <span className="text-3xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-amber-300 to-amber-500">
                {fortune.luckScore}
              </span>
              <span className="text-[10px] uppercase tracking-wider text-slate-400">峡谷运势指数</span>
            </div>
          </div>

          <p className="text-sm text-amber-100/90 font-medium leading-relaxed mt-2 px-2 italic">
            “{fortune.summary}”
          </p>
        </div>

        {/* Scrollable Content */}
        <div className="p-6 pt-2 overflow-y-auto space-y-4 text-xs text-slate-300">
          {/* Hextech Blessing & Protection */}
          <div className="p-3.5 rounded-2xl bg-gradient-to-r from-amber-950/40 via-slate-800/80 to-slate-900 border border-amber-500/30 flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-amber-500/20 text-amber-400 shrink-0">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div className="flex-1">
              <div className="text-amber-300 font-semibold text-xs flex items-center justify-between">
                <span>方舟核心契约</span>
                <span className="text-[10px] text-amber-400/80 bg-amber-500/10 px-2 py-0.5 rounded-full border border-amber-500/20">生效中</span>
              </div>
              <div className="text-slate-200 font-medium text-xs mt-0.5">{fortune.hextechBlessing}</div>
            </div>
          </div>

          {/* Hexagram Advice */}
          <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800 text-slate-300 text-xs leading-relaxed">
            <div className="font-semibold text-cyan-400 mb-1 flex items-center gap-1.5">
              <Award className="w-3.5 h-3.5" />
              <span>峡谷易数卦象</span>
            </div>
            {fortune.hexagramAdvice}
          </div>

          {/* Recommended Heroes */}
          <div>
            <div className="font-semibold text-slate-200 text-xs mb-2.5 flex items-center justify-between">
              <span className="flex items-center gap-1.5">
                <Swords className="w-4 h-4 text-amber-400" />
                <span>今日推荐上分英雄 (首选)</span>
              </span>
              <span className="text-[11px] text-amber-400">胜率加成</span>
            </div>

            <div className="space-y-2">
              {fortune.recommendedHeroes.map((hero, idx) => (
                <div
                  key={idx}
                  className="p-3 rounded-2xl bg-slate-800/60 border border-slate-700/60 flex items-center justify-between hover:border-amber-500/40 transition-all"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-amber-500 to-cyan-600 flex items-center justify-center text-white font-bold text-sm shadow-md">
                      {hero.name.slice(0, 1)}
                    </div>
                    <div>
                      <div className="font-bold text-white text-xs flex items-center gap-1.5">
                        <span>{hero.name}</span>
                        <span className="text-[10px] px-1.5 py-0.2 rounded bg-slate-700 text-slate-300 font-normal">
                          {hero.lane}
                        </span>
                      </div>
                      <div className="text-[11px] text-slate-400 mt-0.5">{hero.reason}</div>
                    </div>
                  </div>
                  <div className="text-right shrink-0">
                    <div className="font-extrabold text-emerald-400 text-xs">{hero.winRateBoost}</div>
                    <div className="text-[10px] text-rose-400/80">克制: {hero.counterHero}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Additional Parameters Grid */}
          <div className="grid grid-cols-2 gap-2.5">
            <div className="p-3 rounded-2xl bg-slate-800/40 border border-slate-800 flex items-center gap-2.5">
              <Clock className="w-4 h-4 text-cyan-400 shrink-0" />
              <div>
                <div className="text-[10px] text-slate-400">黄金排位时段</div>
                <div className="font-medium text-slate-200 text-xs truncate">{fortune.luckyTime}</div>
              </div>
            </div>

            <div className="p-3 rounded-2xl bg-slate-800/40 border border-slate-800 flex items-center gap-2.5">
              <Users className="w-4 h-4 text-purple-400 shrink-0" />
              <div>
                <div className="text-[10px] text-slate-400">默契搭档类型</div>
                <div className="font-medium text-slate-200 text-xs truncate">{fortune.teammateAffinity}</div>
              </div>
            </div>
          </div>
        </div>

        {/* Modal Action Buttons */}
        <div className="p-4 border-t border-slate-800 bg-slate-950/80 flex items-center gap-3">
          <button
            onClick={onReroll}
            className="flex-1 py-3 px-4 rounded-2xl bg-slate-800 hover:bg-slate-700 text-amber-300 font-semibold text-xs flex items-center justify-center gap-2 transition-all active:scale-95 border border-amber-500/30"
          >
            <RotateCcw className="w-4 h-4" />
            <span>再次摇签</span>
          </button>

          <button
            onClick={handleCopyShare}
            className="flex-1 py-3 px-4 rounded-2xl bg-gradient-to-r from-amber-500 via-orange-500 to-amber-600 hover:from-amber-400 hover:to-orange-400 text-slate-950 font-bold text-xs flex items-center justify-center gap-2 shadow-lg shadow-amber-500/20 transition-all active:scale-95"
          >
            <Share2 className="w-4 h-4" />
            <span>分享好运给队友</span>
          </button>
        </div>
      </div>
    </div>
  );
};
