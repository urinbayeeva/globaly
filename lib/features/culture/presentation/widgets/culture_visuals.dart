import 'package:flutter/material.dart';

class CultureVisual {
  const CultureVisual({required this.colors, required this.icon});

  final List<Color> colors;
  final IconData icon;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      );
}

CultureVisual cultureVisual(String title, int index) {
  final String t = title.toLowerCase();
  if (_has(
    t,
    <String>[
      'dining',
      'food',
      'eat',
      'meal',
      'restaurant',
      'drink',
      'cuisine',
      'table',
    ],
  )) {
    return const CultureVisual(
      colors: <Color>[Color(0xFFF97316), Color(0xFFB91C1C)],
      icon: Icons.restaurant_rounded,
    );
  }
  if (_has(
    t,
    <String>[
      'convers',
      'talk',
      'languag',
      'greet',
      'communic',
      'social',
      'meeting',
    ],
  )) {
    return const CultureVisual(
      colors: <Color>[Color(0xFF3B82F6), Color(0xFF1E3A8A)],
      icon: Icons.chat_bubble_rounded,
    );
  }
  if (_has(
    t,
    <String>[
      'taboo',
      'avoid',
      'forbidden',
      'never',
      'offens',
      'sensitiv',
      'rude',
    ],
  )) {
    return const CultureVisual(
      colors: <Color>[Color(0xFF475569), Color(0xFF0B1220)],
      icon: Icons.report_rounded,
    );
  }
  if (_has(
    t,
    <String>[
      'public',
      'behav',
      'street',
      'transport',
      'queue',
      'space',
      'city',
    ],
  )) {
    return const CultureVisual(
      colors: <Color>[Color(0xFF14B8A6), Color(0xFF115E59)],
      icon: Icons.groups_rounded,
    );
  }
  if (_has(
    t,
    <String>['dress', 'cloth', 'wear', 'attire', 'outfit', 'appearance'],
  )) {
    return const CultureVisual(
      colors: <Color>[Color(0xFF8B5CF6), Color(0xFF4C1D95)],
      icon: Icons.checkroom_rounded,
    );
  }
  if (_has(
    t,
    <String>[
      'money',
      'tip',
      'pay',
      'bargain',
      'price',
      'cash',
      'shop',
      'market',
    ],
  )) {
    return const CultureVisual(
      colors: <Color>[Color(0xFF22C55E), Color(0xFF14532D)],
      icon: Icons.payments_rounded,
    );
  }
  if (_has(
    t,
    <String>[
      'religion',
      'temple',
      'worship',
      'mosque',
      'church',
      'pray',
      'sacred',
      'holy',
    ],
  )) {
    return const CultureVisual(
      colors: <Color>[Color(0xFF6366F1), Color(0xFF312E81)],
      icon: Icons.account_balance_rounded,
    );
  }
  const List<CultureVisual> fallback = <CultureVisual>[
    CultureVisual(
      colors: <Color>[Color(0xFF0EA5E9), Color(0xFF1E3A8A)],
      icon: Icons.public_rounded,
    ),
    CultureVisual(
      colors: <Color>[Color(0xFFEC4899), Color(0xFF831843)],
      icon: Icons.auto_awesome_rounded,
    ),
    CultureVisual(
      colors: <Color>[Color(0xFFF59E0B), Color(0xFF92400E)],
      icon: Icons.wb_sunny_rounded,
    ),
    CultureVisual(
      colors: <Color>[Color(0xFF14B8A6), Color(0xFF134E4A)],
      icon: Icons.map_rounded,
    ),
  ];
  return fallback[index % fallback.length];
}

bool _has(String source, List<String> keys) =>
    keys.any((String k) => source.contains(k));

String cultureImageUrl(String country, String title) {
  final String query = '$country $title'.trim();
  if (query.isEmpty) return '';
  return 'https://source.unsplash.com/800x1000/?${Uri.encodeComponent(query)}';
}
