import 'package:hok_helper_mobile/src/features/stats/domain/stats_trends.dart';

StatsTrendTable sampleStatsTrendTable({
  String dimension = 'hero_rank',
  String view = 'base',
  List<Object?>? columns,
  List<Object?>? rows,
}) {
  return StatsTrendTable.fromJson({
    'dimension': dimension,
    'baseline': 'peak_1000',
    'view': view,
    'columns':
        columns ??
        const [
          {'id': 'hero', 'label': 'Hero', 'type': 'hero', 'sortable': true},
          {
            'id': 'wr',
            'label': 'Win Rate',
            'type': 'percent',
            'sortable': true,
            'group': 'Core',
          },
          {
            'id': 'pick_rate',
            'label': 'Pick Rate',
            'type': 'percent',
            'sortable': true,
            'group': 'Core',
          },
          {
            'id': 'avg_kills',
            'label': 'Kills',
            'type': 'number',
            'sortable': true,
            'group': 'KDA',
          },
          {'id': 'trend_smoothed', 'label': 'Trend', 'type': 'sparkline'},
        ],
    'rows':
        rows ??
        const [
          {
            'hero': {
              'id': 199,
              'heroId': '199',
              'name': 'Lam',
              'position': '3',
            },
            'wr': 56.1,
            'pick_rate': 18.4,
            'avg_kills': 8.2,
            'best_skill': {'id': 80115, 'name': 'Flash'},
            'best_equip': [
              {'id': 12211, 'name': 'Venomous Staff'},
            ],
            'trend_smoothed': [52.0, 54.0, 53.0, 56.1],
            'core_trend_points': [
              {
                'snapshot_date': '2026-07-14',
                'wr': 53.0,
                'pick_rate': 17.9,
                'ban_rate': 12.0,
                'bp_rate': 29.9,
              },
              {
                'snapshot_date': '2026-07-15',
                'wr': 56.1,
                'pick_rate': 18.4,
                'ban_rate': 13.0,
                'bp_rate': 31.4,
              },
            ],
          },
          {
            'hero': {
              'id': 166,
              'heroId': '166',
              'name': 'Yaria',
              'position': '4',
            },
            'wr': 60.2,
            'pick_rate': 11.5,
            'avg_kills': 2.4,
            'trend_smoothed': [58.0, 57.0, 59.0, 60.2],
          },
        ],
    'available_views': const [
      {'id': 'base', 'label': 'Base'},
      {'id': 'prep', 'label': 'Preparation'},
    ],
    'available_baselines': const ['all', 'peak_base', 'top_rank', 'peak_1000'],
    'available_window_days': const [1, 7, 30, 999],
    'available_filters': const {
      'region': ['36', '156', '360', '826', '840'],
    },
    'meta': const {
      'sample_size': 2,
      'data_range': '2026-07-15',
      'patch_version': 'S15',
      'latest_snapshot_date': '2026-07-15',
      'available_snapshot_dates': ['2026-07-14', '2026-07-15'],
    },
  });
}

StatsTrendDetail sampleStatsTrendDetail() {
  return StatsTrendDetail.fromJson({
    'hero': const {'id': 199, 'heroId': '199', 'name': 'Lam'},
    'synergy_rank': 58.2,
    'counter_rank': 54.7,
    'power_trend_points': const [
      {
        'snapshot_date': '2026-07-14',
        'top1': 12000,
        'top10': 9000,
        'top50': 8000,
        'top100': 7000,
      },
      {
        'snapshot_date': '2026-07-15',
        'top1': 12100,
        'top10': 9100,
        'top50': 8100,
        'top100': 7100,
      },
    ],
    'playstyle_trend_series': const [],
    'equip_trend_series': const [],
    'hero_equip_stats': const [
      {
        'equip': {'id': 12211, 'name': 'Venomous Staff'},
        'quantity': 3790,
        'pick_rate': 70.24,
        'win_rate': 54.2,
        'most_common_slot': 3,
        'avg_slot': 2.6,
        'slot1_share': 8.4,
        'slot1_win_rate': 50.1,
        'slot2_share': 30.2,
        'slot2_win_rate': 53.3,
        'slot3_share': 61.4,
        'slot3_win_rate': 56.8,
      },
      // pick_rate 与 quantity 排序结果相反，用于钉住默认排序列。
      {
        'equip': {'id': 12345, 'name': 'Boots of Speed'},
        'quantity': 9999,
        'pick_rate': 45.1,
        'win_rate': 60.0,
        'most_common_slot': 1,
        'avg_slot': 1.2,
        'slot1_share': 100.0,
        'slot1_win_rate': 60.0,
      },
    ],
    'hero_skill_equip_stats': const [
      {
        'skill': {'id': 80115, 'name': 'Flash'},
        'equips': [
          {'id': 12211, 'name': 'Venomous Staff'},
        ],
        'match_count': 1200,
        'win_rate': 55.4,
      },
    ],
    'hero_master_builds': const [],
    'hero_skill_position_stats': const [],
    'hero_bp_stats': const {
      'blue_pick_share': 50.0,
      'blue_win_rate': 52.0,
      'red_pick_share': 50.0,
      'red_win_rate': 48.0,
    },
    'synergy_list': const [],
    'counter_list': const [],
  });
}

StatsTrendTable sampleEquipStatsTrendTable() {
  return sampleStatsTrendTable(
    dimension: 'equip_rank',
    view: 'main',
    columns: const [
      {'id': 'equip', 'label': 'Equipment', 'type': 'equip', 'sortable': true},
      {
        'id': 'win_rate',
        'label': 'Win Rate',
        'type': 'percent',
        'sortable': true,
      },
      {
        'id': 'pick_rate',
        'label': 'Pick Rate',
        'type': 'percent',
        'sortable': true,
      },
      {'id': 'trend_smoothed', 'label': 'Trend', 'type': 'sparkline'},
    ],
    rows: const [
      {
        'equip': {'id': 12211, 'name': 'Venomous Staff'},
        'win_rate': 54.2,
        'pick_rate': 70.24,
        'trend_smoothed': [52.0, 53.1, 54.2],
      },
    ],
  );
}

StatsTrendDetail sampleEquipStatsTrendDetail() {
  return StatsTrendDetail.fromJson({
    'equip': const {'id': 12211, 'name': 'Venomous Staff'},
    'trend_points': const [
      {'snapshot_date': '2026-07-14', 'win_rate': 53.4, 'pick_rate': 69.8},
      {'snapshot_date': '2026-07-15', 'win_rate': 54.2, 'pick_rate': 70.24},
    ],
    'hero_equip_stats': const [
      {
        'hero': {'id': 199, 'heroId': '199', 'name': 'Lam'},
        'quantity': 3790,
        'pick_rate': 70.24,
        'win_rate': 54.2,
        'most_common_slot': 3,
        'avg_slot': 2.6,
        'slot1_share': 8.4,
        'slot1_win_rate': 50.1,
        'slot2_share': 30.2,
        'slot2_win_rate': 53.3,
        'slot3_share': 61.4,
        'slot3_win_rate': 56.8,
      },
      // pick_rate 与 quantity 排序结果相反，用于钉住默认排序列。
      {
        'hero': {'id': 166, 'heroId': '166', 'name': 'Yaria'},
        'quantity': 9999,
        'pick_rate': 45.1,
        'win_rate': 60.0,
        'most_common_slot': 1,
        'avg_slot': 1.2,
        'slot1_share': 100.0,
        'slot1_win_rate': 60.0,
      },
    ],
  });
}

/// 31 行英雄数据：pick_rate 递减、Hero31 胜率最高，用于验证「先全量排序再截断」。
StatsTrendDetail sampleWideEquipStatsTrendDetail() {
  return StatsTrendDetail.fromJson({
    'equip': const {'id': 12211, 'name': 'Venomous Staff'},
    'trend_points': const [],
    'hero_equip_stats': [
      for (var index = 1; index <= 31; index++)
        {
          'hero': {'id': 1000 + index, 'name': 'Hero$index'},
          'quantity': index,
          'pick_rate': 100.0 - index,
          'win_rate': index == 31 ? 99.0 : 50.0,
        },
    ],
  });
}
