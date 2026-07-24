export type CubeState =
  | 'INITIAL'             // 初始展示状态
  | 'AUTO_ROTATING'       // 自动旋转状态
  | 'DRAGGING'            // 用户拖动状态
  | 'SHAKING'             // 摇签触发状态
  | 'RESULT_REVEALED'     // 抽签结果揭示状态
  | 'NETWORK_ERROR'       // 网络加载失败状态
  | 'RESOURCE_3D_ERROR';  // 3D 资源加载失败状态

export type RankTier =
  | '倔强青铜'
  | '秩序白银'
  | '荣耀黄金'
  | '尊贵铂金'
  | '璀璨钻石'
  | '至尊星耀'
  | '最强王者'
  | '荣耀王者';

export type LaneRole = '全能位' | '对抗路' | '中路' | '发育路' | '打野' | '游走';

export interface HeroPick {
  name: string;
  title: string;
  avatar: string;
  lane: LaneRole;
  winRateBoost: string;
  reason: string;
  counterHero: string;
}

export interface FortuneResult {
  id: string;
  luckTier: '大吉' | '上吉' | '中吉' | '小吉';
  luckScore: number; // 0 - 100
  title: string;
  hextechBlessing: string; // 方舟能量/保星卡/加星卡
  luckyTime: string;
  luckyLane: LaneRole;
  recommendedHeroes: HeroPick[];
  teammateAffinity: string; // 适配队友类型
  summary: string;
  hexagramAdvice: string;
  timestamp: string;
}

export interface PlayerProfile {
  name: string;
  avatar: string;
  rank: RankTier;
  stars: number;
  winStreak: number;
  preferredLane: LaneRole;
}
