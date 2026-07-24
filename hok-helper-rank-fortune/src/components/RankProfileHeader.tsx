import React from 'react';
import { Shield, Sparkles, Volume2, VolumeX, Flame, Compass } from 'lucide-react';
import { LaneRole, PlayerProfile, RankTier } from '../types';

interface RankProfileHeaderProps {
  player: PlayerProfile;
  onUpdatePlayer: (updated: Partial<PlayerProfile>) => void;
  isMuted: boolean;
  onToggleMute: () => void;
}

const ALL_RANKS: RankTier[] = [
  '倔强青铜',
  '秩序白银',
  '荣耀黄金',
  '尊贵铂金',
  '璀璨钻石',
  '至尊星耀',
  '最强王者',
  '荣耀王者',
];

const ALL_LANES: LaneRole[] = ['全能位', '对抗路', '中路', '发育路', '打野', '游走'];

export const RankProfileHeader: React.FC<RankProfileHeaderProps> = ({
  player,
  onUpdatePlayer,
  isMuted,
  onToggleMute,
}) => {
  return (
    <div className="w-full max-w-[420px] mx-auto space-y-3 mb-2">
      {/* Top Bar with Title, Player Avatar, and Audio Toggle */}
      <div className="p-4 rounded-3xl bg-slate-900/90 border border-amber-500/30 backdrop-blur-xl shadow-xl flex items-center justify-between">
        <div className="flex items-center gap-3">
          {/* Avatar with Glow Badge */}
          <div className="relative">
            <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-amber-500 via-orange-500 to-cyan-500 p-0.5 shadow-lg shadow-amber-500/20">
              <div className="w-full h-full rounded-[14px] bg-slate-950 flex items-center justify-center font-black text-amber-400 text-lg">
                王者
              </div>
            </div>
            <div className="absolute -bottom-1 -right-1 px-1.5 py-0.2 rounded-full bg-amber-500 text-slate-950 text-[9px] font-black tracking-tight shadow">
              {player.stars}★
            </div>
          </div>

          {/* Player Name and Rank Info */}
          <div>
            <div className="flex items-center gap-1.5">
              <span className="font-bold text-white text-sm tracking-wide">{player.name}</span>
              <span className="px-2 py-0.5 rounded-full bg-amber-500/15 border border-amber-500/30 text-amber-300 text-[10px] font-semibold flex items-center gap-1">
                <Flame className="w-3 h-3 text-orange-400 fill-orange-400" />
                {player.winStreak}连胜
              </span>
            </div>

            <div className="flex items-center gap-2 mt-0.5 text-xs text-slate-400">
              <span className="text-amber-400/90 font-medium">{player.rank}</span>
              <span>·</span>
              <span className="text-cyan-400 font-medium">{player.preferredLane}</span>
            </div>
          </div>
        </div>

        {/* Audio Sound FX Mute Button */}
        <button
          onClick={onToggleMute}
          className="p-2.5 rounded-2xl bg-slate-800/80 hover:bg-slate-700 text-slate-300 hover:text-amber-300 transition-all border border-slate-700/60 active:scale-95"
          title={isMuted ? '开启音效' : '静音'}
        >
          {isMuted ? <VolumeX className="w-4 h-4 text-slate-500" /> : <Volume2 className="w-4 h-4 text-amber-400" />}
        </button>
      </div>

      {/* Rank Tier & Lane Filter Selector Chips */}
      <div className="p-3 rounded-2xl bg-slate-900/60 border border-slate-800/80 backdrop-blur-md space-y-2.5">
        {/* Rank Tier Row */}
        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar py-0.5">
          <span className="text-[10px] text-amber-400/80 font-semibold shrink-0 flex items-center gap-1 pl-1">
            <Shield className="w-3 h-3" /> 段位:
          </span>
          {ALL_RANKS.map((r) => (
            <button
              key={r}
              onClick={() => onUpdatePlayer({ rank: r })}
              className={`px-2.5 py-1 rounded-xl text-xs font-medium whitespace-nowrap transition-all ${
                player.rank === r
                  ? 'bg-gradient-to-r from-amber-500 to-orange-500 text-slate-950 font-bold shadow-md shadow-amber-500/20'
                  : 'bg-slate-800/60 text-slate-400 hover:text-slate-200 hover:bg-slate-800'
              }`}
            >
              {r}
            </button>
          ))}
        </div>

        {/* Lane Selector Row */}
        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar py-0.5">
          <span className="text-[10px] text-cyan-400/80 font-semibold shrink-0 flex items-center gap-1 pl-1">
            <Compass className="w-3 h-3" /> 分路:
          </span>
          {ALL_LANES.map((lane) => (
            <button
              key={lane}
              onClick={() => onUpdatePlayer({ preferredLane: lane })}
              className={`px-2.5 py-1 rounded-xl text-xs font-medium whitespace-nowrap transition-all ${
                player.preferredLane === lane
                  ? 'bg-cyan-500 text-slate-950 font-bold shadow-md shadow-cyan-500/20'
                  : 'bg-slate-800/60 text-slate-400 hover:text-slate-200 hover:bg-slate-800'
              }`}
            >
              {lane}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};
