import React, { useState } from 'react';
import { ChevronRight } from 'lucide-react';
import { FortuneResult } from '../types';

interface FortuneHistoryChartProps {
  history: FortuneResult[];
  currentFortune?: FortuneResult | null;
  onSelectFortune?: (fortune: FortuneResult) => void;
  onOpenFullHistory?: () => void;
}

export const FortuneHistoryChart: React.FC<FortuneHistoryChartProps> = ({
  history,
  currentFortune,
  onSelectFortune,
  onOpenFullHistory,
}) => {
  const [hoveredIdx, setHoveredIdx] = useState<number | null>(null);

  // Fallback initial data points if history is short, ensuring a lively chart
  const defaultItems: { score: number; tier: '大吉' | '上吉' | '中吉' | '小吉'; hero: string; time: string }[] = [
    { score: 82, tier: '小吉', hero: '庄周', time: '前天 14:20' },
    { score: 78, tier: '小吉', hero: '亚瑟', time: '昨天 09:15' },
    { score: 92, tier: '大吉', hero: '诸葛亮', time: '昨天 20:40' },
    { score: 88, tier: '中吉', hero: '孙尚香', time: '今天 11:05' },
  ];

  // Combine real history + current result, fallback to mock if empty
  const chartData: { score: number; tier: string; hero: string; timeStr: string; item?: FortuneResult }[] = [];

  if (history && history.length > 0) {
    history.slice(-6).forEach((item) => {
      chartData.push({
        score: item.luckScore,
        tier: item.luckTier,
        hero: item.recommendedHeroes?.[0]?.name || '铠',
        timeStr: new Date(item.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        item,
      });
    });
  } else {
    // Fill default demo trend
    defaultItems.forEach((d, idx) => {
      chartData.push({
        score: d.score,
        tier: d.tier,
        hero: d.hero,
        timeStr: d.time || `第${idx + 1}爻`,
      });
    });
    if (currentFortune) {
      chartData.push({
        score: currentFortune.luckScore,
        tier: currentFortune.luckTier,
        hero: currentFortune.recommendedHeroes?.[0]?.name || '铠',
        timeStr: '当爻',
        item: currentFortune,
      });
    }
  }

  // SVG Chart dimensions
  const width = 340;
  const height = 70;
  const paddingX = 22;
  const paddingY = 14;

  const minScore = 60;
  const maxScore = 100;

  const getX = (index: number) => {
    if (chartData.length <= 1) return width / 2;
    return paddingX + (index / (chartData.length - 1)) * (width - paddingX * 2);
  };

  const getY = (score: number) => {
    const clamped = Math.max(minScore, Math.min(maxScore, score));
    const ratio = (clamped - minScore) / (maxScore - minScore);
    return height - paddingY - ratio * (height - paddingY * 2);
  };

  // Generate smooth SVG curve path
  const points = chartData.map((d, i) => ({ x: getX(i), y: getY(d.score) }));

  let pathD = '';
  if (points.length > 0) {
    pathD = `M ${points[0].x},${points[0].y}`;
    for (let i = 0; i < points.length - 1; i++) {
      const curr = points[i];
      const next = points[i + 1];
      const mx = (curr.x + next.x) / 2;
      pathD += ` C ${mx},${curr.y} ${mx},${next.y} ${next.x},${next.y}`;
    }
  }

  // Closed path for subtle gradient fill under curve
  const areaD = points.length > 0
    ? `${pathD} L ${points[points.length - 1].x},${height - 2} L ${points[0].x},${height - 2} Z`
    : '';

  return (
    <div className="w-full bg-slate-950/15 border border-amber-400/25 rounded-2xl p-2.5 shadow-2xl backdrop-blur-[2px] pointer-events-auto relative overflow-hidden">
      {/* Decorative Silk Corners */}
      <div className="absolute top-1 left-2 text-amber-300/40 text-[10px] font-serif">☯</div>
      <div className="absolute top-1 right-2 text-amber-300/40 text-[10px] font-serif">☯</div>

      {/* Header Bar */}
      <div className="flex items-center justify-between mb-0.5 px-1 font-serif">
        <div className="flex items-center gap-1.5">
          <span className="text-amber-300 text-xs font-black tracking-widest flex items-center gap-1">
            <span className="text-amber-400 text-sm">☯</span>
            <span>爻象气运轨</span>
          </span>
          <span className="text-[10px] text-amber-200/60 font-mono">({chartData.length}爻演变)</span>
        </div>
        {onOpenFullHistory && (
          <button
            onClick={onOpenFullHistory}
            className="text-[11px] text-amber-300 hover:text-amber-200 flex items-center gap-0.5 font-bold cursor-pointer transition-colors"
          >
            <span>全爻录</span>
            <ChevronRight className="w-3 h-3 text-amber-400" />
          </button>
        )}
      </div>

      {/* SVG Chart Area */}
      <div className="relative w-full overflow-visible my-0.5 flex justify-center">
        <svg viewBox={`0 0 ${width} ${height}`} className="w-full h-auto overflow-visible">
          <defs>
            {/* Gradient under line */}
            <linearGradient id="chartAreaGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#f59e0b" stopOpacity="0.25" />
              <stop offset="100%" stopColor="#f43f5e" stopOpacity="0.0" />
            </linearGradient>

            {/* Glowing line stroke gradient */}
            <linearGradient id="chartLineGrad" x1="0" y1="0" x2="1" y2="0">
              <stop offset="0%" stopColor="#fef08a" />
              <stop offset="50%" stopColor="#f59e0b" />
              <stop offset="100%" stopColor="#fb7185" />
            </linearGradient>
          </defs>

          {/* Reference grid line for 80 pts */}
          <line
            x1={paddingX}
            y1={getY(80)}
            x2={width - paddingX}
            y2={getY(80)}
            stroke="#fef08a"
            strokeOpacity="0.12"
            strokeDasharray="2 3"
          />

          {/* Filled Area */}
          {areaD && <path d={areaD} fill="url(#chartAreaGrad)" />}

          {/* Curve Stroke */}
          {pathD && (
            <path
              d={pathD}
              fill="none"
              stroke="url(#chartLineGrad)"
              strokeWidth="2.2"
              strokeLinecap="round"
            />
          )}

          {/* Data Nodes / Points */}
          {points.map((pt, idx) => {
            const data = chartData[idx];
            const isHovered = hoveredIdx === idx;
            const isLatest = idx === points.length - 1;

            return (
              <g
                key={idx}
                className="cursor-pointer group"
                onMouseEnter={() => setHoveredIdx(idx)}
                onMouseLeave={() => setHoveredIdx(null)}
                onClick={() => data.item && onSelectFortune && onSelectFortune(data.item)}
              >
                {/* Outer Glow Halo for Latest/Hovered */}
                {(isHovered || isLatest) && (
                  <circle
                    cx={pt.x}
                    cy={pt.y}
                    r={isHovered ? 7.5 : 5.5}
                    fill={isLatest ? '#f43f5e' : '#f59e0b'}
                    fillOpacity="0.5"
                    className="animate-pulse"
                  />
                )}

                {/* Point Dot */}
                <circle
                  cx={pt.x}
                  cy={pt.y}
                  r={isHovered ? 4 : 3}
                  fill={isLatest ? '#fef08a' : '#fbbf24'}
                  stroke="#0f172a"
                  strokeWidth="1.2"
                />

                {/* Score Label above Dot */}
                <text
                  x={pt.x}
                  y={pt.y - 6}
                  fill={isLatest ? '#fef08a' : '#fef3c7'}
                  fontSize="8.5"
                  fontWeight="800"
                  textAnchor="middle"
                  className="font-serif drop-shadow-md select-none"
                >
                  {data.score}
                </text>
              </g>
            );
          })}
        </svg>

        {/* Hover Tooltip Popup */}
        {hoveredIdx !== null && chartData[hoveredIdx] && (
          <div
            className="absolute -top-9 left-1/2 -translate-x-1/2 px-2.5 py-1 rounded-xl bg-slate-950/90 border border-amber-400/80 text-amber-200 text-[11px] font-serif font-bold shadow-xl backdrop-blur-md flex items-center gap-1.5 z-20 pointer-events-none"
          >
            <span className="text-amber-400">☯</span>
            <span>{chartData[hoveredIdx].tier} ({chartData[hoveredIdx].score}分)</span>
            <span className="text-amber-200/70">· 符将{chartData[hoveredIdx].hero}</span>
          </div>
        )}
      </div>

      {/* Footer Legend / Tip */}
      <div className="flex items-center justify-between text-[10px] text-amber-200/70 pt-0.5 px-1 border-t border-amber-500/15 font-serif">
        <span>✦ 爻数过八十 · 顺风无敌</span>
        <span className="text-amber-300 font-semibold">点击节点索卦</span>
      </div>
    </div>
  );
};
