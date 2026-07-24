import React from 'react';
import { WifiOff, RefreshCw } from 'lucide-react';

interface NetworkErrorBannerProps {
  onRetry: () => void;
}

export const NetworkErrorBanner: React.FC<NetworkErrorBannerProps> = ({ onRetry }) => {
  return (
    <div className="w-full max-w-[420px] mx-auto mb-4 p-3.5 rounded-2xl bg-rose-950/90 border border-rose-500/50 backdrop-blur-xl text-rose-200 text-xs shadow-2xl flex items-center justify-between animate-fadeIn">
      <div className="flex items-center gap-2.5">
        <div className="p-2 rounded-xl bg-rose-900/60 text-rose-400 shrink-0">
          <WifiOff className="w-4 h-4" />
        </div>
        <div>
          <div className="font-semibold text-rose-100 text-sm">网络连接异常</div>
          <div className="text-rose-300/80 text-xs">无法实时拉取峡谷运势数据，请检查网络</div>
        </div>
      </div>
      <button
        onClick={onRetry}
        className="px-3 py-1.5 rounded-xl bg-gradient-to-r from-rose-600 to-amber-600 hover:from-rose-500 hover:to-amber-500 text-white font-medium text-xs shadow-lg flex items-center gap-1.5 shrink-0 transition-all active:scale-95"
      >
        <RefreshCw className="w-3.5 h-3.5 animate-spin-slow" />
        <span>重新加载</span>
      </button>
    </div>
  );
};
