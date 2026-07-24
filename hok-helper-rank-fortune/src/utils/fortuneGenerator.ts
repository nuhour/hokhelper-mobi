import { FortuneResult, LaneRole, RankTier } from '../types';

interface HeroData {
  name: string;
  title: string;
  lane: LaneRole;
  avatarBg: string;
  counterHero: string;
}

const HERO_DATABASE: HeroData[] = [
  // 对抗路
  { name: '李信', title: '谋世之战', lane: '对抗路', avatarBg: 'from-amber-600 to-red-800', counterHero: '马超' },
  { name: '亚瑟', title: '圣骑之力', lane: '对抗路', avatarBg: 'from-blue-600 to-indigo-900', counterHero: '程咬金' },
  { name: '关羽', title: '一骑当千', lane: '对抗路', avatarBg: 'from-emerald-600 to-teal-900', counterHero: '吕布' },
  { name: '花木兰', title: '传说之刃', lane: '对抗路', avatarBg: 'from-orange-500 to-red-700', counterHero: '老夫子' },
  { name: '夏洛特', title: '玫瑰剑士', lane: '对抗路', avatarBg: 'from-sky-500 to-blue-800', counterHero: '狂铁' },

  // 中路
  { name: '诸葛亮', title: '绝代智谋', lane: '中路', avatarBg: 'from-cyan-500 to-blue-900', counterHero: '司马懿' },
  { name: '貂蝉', title: '绝世舞姬', lane: '中路', avatarBg: 'from-pink-500 to-purple-800', counterHero: '张良' },
  { name: '上官婉儿', title: '惊鸿之笔', lane: '中路', avatarBg: 'from-zinc-600 to-slate-900', counterHero: '东皇太一' },
  { name: '不知火舞', title: '明媚烈焰', lane: '中路', avatarBg: 'from-red-500 to-orange-800', counterHero: '王昭君' },
  { name: '安琪拉', title: '暗夜萝莉', lane: '中路', avatarBg: 'from-purple-600 to-red-900', counterHero: '小乔' },

  // 发育路
  { name: '鲁班七号', title: '机关造物', lane: '发育路', avatarBg: 'from-amber-500 to-orange-700', counterHero: '兰陵王' },
  { name: '马可波罗', title: '远游之枪', lane: '发育路', avatarBg: 'from-yellow-600 to-amber-900', counterHero: '公孙离' },
  { name: '孙尚香', title: '千金重弩', lane: '发育路', avatarBg: 'from-emerald-500 to-green-800', counterHero: '狄仁杰' },
  { name: '公孙离', title: '幻舞玲珑', lane: '发育路', avatarBg: 'from-rose-500 to-pink-800', counterHero: '百里守约' },
  { name: '伽罗', title: '箭羽风息', lane: '发育路', avatarBg: 'from-sky-400 to-blue-800', counterHero: '阿轲' },

  // 打野
  { name: '李白', title: '青莲剑仙', lane: '打野', avatarBg: 'from-indigo-500 to-purple-900', counterHero: '韩信' },
  { name: '韩信', title: '国士无双', lane: '打野', avatarBg: 'from-orange-600 to-red-900', counterHero: '典韦' },
  { name: '孙悟空', title: '齐天大圣', lane: '打野', avatarBg: 'from-yellow-500 to-red-800', counterHero: '刘备' },
  { name: '澜', title: '鲨之猎刃', lane: '打野', avatarBg: 'from-cyan-600 to-teal-900', counterHero: '盘古' },
  { name: '镜', title: '破镜之刃', lane: '打野', avatarBg: 'from-slate-400 to-indigo-900', counterHero: '玄策' },

  // 游走
  { name: '瑶', title: '鹿灵守心', lane: '游走', avatarBg: 'from-teal-400 to-emerald-700', counterHero: '盾山' },
  { name: '庄周', title: '逍遥幻梦', lane: '游走', avatarBg: 'from-cyan-400 to-blue-700', counterHero: '鬼谷子' },
  { name: '大乔', title: '沧海之曜', lane: '游走', avatarBg: 'from-blue-400 to-indigo-800', counterHero: '王昭君' },
  { name: '东皇太一', title: '噬灭日蚀', lane: '游走', avatarBg: 'from-purple-700 to-black', counterHero: '蔡文姬' },
  { name: '张飞', title: '禁血狂兽', lane: '游走', avatarBg: 'from-red-600 to-amber-900', counterHero: '吕布' },
];

const LUCK_TIERS: Array<{
  tier: '大吉' | '上吉' | '中吉' | '小吉';
  minScore: number;
  maxScore: number;
  blessings: string[];
  quotes: string[];
}> = [
  {
    tier: '大吉',
    minScore: 92,
    maxScore: 99,
    blessings: [
      '方舟核心激活 · 连胜概率 +35%',
      '荣耀星光护体 · 触发保星卡加成',
      '王者降临 · 必定配对意识高超队友',
      '峡谷天时 · 前10分钟风暴龙王气运爆发'
    ],
    quotes: [
      '紫气东来聚方舟，今日排位手感爆棚，一波十连胜直接登顶！',
      '天命所归，今日BP环节绝不被针对，拿本命英雄轻松carry全场。',
      '峡谷气运极佳，打野控龙精准无误，中辅联动天衣无缝！'
    ]
  },
  {
    tier: '上吉',
    minScore: 82,
    maxScore: 91,
    blessings: [
      '方舟灵能 · 关键团战命中率提升',
      '星向指引 · MVP概率增加 25%',
      '峡谷东风 · 逆风翻盘率显著提升'
    ],
    quotes: [
      '吉星高照，适合组队或单排上分，逆风局也能抓住破绽一波反推！',
      '气运亨通，技能预判神准，野区拉扯如鱼得水！',
      '今日队友配合默契，及时支援到位，稳扎稳打分到擒来。'
    ]
  },
  {
    tier: '中吉',
    minScore: 72,
    maxScore: 81,
    blessings: [
      '稳健之誓 · 败方MVP不扣分概率增加',
      '智力之环 · 视野意识提升',
      '守护结界 · 降低遇见挂机队友概率'
    ],
    quotes: [
      '运势平稳增上，建议选用操作稳健的本命英雄，切勿盲目上头。',
      '小增胜率，注意多观察小地图，谨防草丛埋伏，稳中求胜。',
      '适宜晚间黄金段排位，多与队友沟通信号，胜利尽在掌握。'
    ]
  },
  {
    tier: '小吉',
    minScore: 65,
    maxScore: 71,
    blessings: [
      '灵光一闪 · 关键抢龙成功率小幅上升',
      '避险光环 · 减少挂机坑队友匹配',
      '试炼卡增益 · 胜率微幅护航'
    ],
    quotes: [
      '今日宜先打两把匹配热手，心态保持从容，避免连败后赌气冲分。',
      '峡谷气运波动，建议拉上靠谱固排队友一起上分，互相保驾护航。',
      '沉着冷静是关键，优先推塔拿资源，切记发育才是硬道理。'
    ]
  }
];

export function generateHokFortune(preferredLane: LaneRole = '全能位', rank: RankTier = '最强王者'): FortuneResult {
  // Pick random luck tier
  const luckTemplate = LUCK_TIERS[Math.floor(Math.random() * LUCK_TIERS.length)];
  const luckScore = Math.floor(Math.random() * (luckTemplate.maxScore - luckTemplate.minScore + 1)) + luckTemplate.minScore;

  const quote = luckTemplate.quotes[Math.floor(Math.random() * luckTemplate.quotes.length)];
  const blessing = luckTemplate.blessings[Math.floor(Math.random() * luckTemplate.blessings.length)];

  // Filter hero pool by preferred lane or pick top matches
  let candidateHeroes = HERO_DATABASE;
  if (preferredLane !== '全能位') {
    candidateHeroes = HERO_DATABASE.filter(h => h.lane === preferredLane);
  }
  if (candidateHeroes.length < 2) {
    candidateHeroes = HERO_DATABASE;
  }

  // Shuffle and pick 2-3 heroes
  const shuffled = [...candidateHeroes].sort(() => 0.5 - Math.random());
  const selected = shuffled.slice(0, 3);

  const recommendedHeroes = selected.map(h => ({
    name: h.name,
    title: h.title,
    avatar: h.name,
    lane: h.lane,
    winRateBoost: `+${(Math.random() * 8 + 12).toFixed(1)}%`,
    reason: `符合今日方舟气运，对线${h.counterHero}有天克优势，团战上限极高`,
    counterHero: h.counterHero
  }));

  const luckyTimes = [
    '12:30 - 14:00 (午间避坑连胜窗口)',
    '18:00 - 20:30 (傍晚黄金冲分时段)',
    '21:00 - 23:30 (深夜默契极速晋级)',
    '15:00 - 17:00 (下午茶运势高光)'
  ];
  const luckyTime = luckyTimes[Math.floor(Math.random() * luckyTimes.length)];

  const affinityTypes = [
    '进攻型打野 (开局反野带飞节奏)',
    '稳健型肉辅 (前排抗伤给足视野)',
    '高爆发法刺 (中后期闪现秒C)',
    '极致输出拉扯射手 (后期无伤站桩)'
  ];
  const teammateAffinity = affinityTypes[Math.floor(Math.random() * affinityTypes.length)];

  const hexagramAdvices = [
    `【${rank}专属局势】易：乾卦·飞龙在天。宜选强力开团英雄，主导峡谷团战节奏。`,
    `【${rank}专属局势】易：坤卦·地势坤。宜守不宜急，稳健发育待敌方失误一波反推。`,
    `【${rank}专属局势】易：泰卦·天地交泰。宜与打野/辅助积极联动，掌握双龙区视野。`,
    `【${rank}专属局势】易：谦卦·尊光大光。切忌独自带线过深，保持团战阵型即可大获全胜。`
  ];
  const hexagramAdvice = hexagramAdvices[Math.floor(Math.random() * hexagramAdvices.length)];

  return {
    id: `FT-${Date.now().toString(36).toUpperCase()}`,
    luckTier: luckTemplate.tier,
    luckScore,
    title: `${rank} · 今日排位运势预言`,
    hextechBlessing: blessing,
    luckyTime,
    luckyLane: preferredLane === '全能位' ? selected[0].lane : preferredLane,
    recommendedHeroes,
    teammateAffinity,
    summary: quote,
    hexagramAdvice,
    timestamp: new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
  };
}
