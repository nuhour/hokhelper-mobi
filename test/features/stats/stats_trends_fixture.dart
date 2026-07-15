import 'package:hok_helper_mobile/src/features/stats/domain/stats_trends.dart';

StatsTrendTable sampleStatsTrendTable({
  String dimension = 'hero_rank',
  String view = 'base',
}) {
  return StatsTrendTable.fromJson({
    'dimension': dimension,
    'baseline': 'peak_1000',
    'view': view,
    'columns': const [
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
    'rows': const [
      {
        'hero': {'id': 199, 'heroId': '199', 'name': 'Lam', 'position': '3'},
        'wr': 56.1,
        'pick_rate': 18.4,
        'bp_rate': 71.0,
        'avg_kills': 8.2,
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
        'hero': {'id': 166, 'heroId': '166', 'name': 'Yaria', 'position': '4'},
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
    'synergy_list': const [],
    'counter_list': const [],
  });
}
