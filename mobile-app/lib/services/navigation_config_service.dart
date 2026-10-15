import 'package:flutter/foundation.dart';

import 'api_client.dart';
import '../utils/json_parsing.dart';

class NavigationItemConfig {
  const NavigationItemConfig({
    required this.key,
    this.visible = true,
    this.order = 0,
  });

  final String key;
  final bool visible;
  final int order;

  factory NavigationItemConfig.fromJson(Map<String, dynamic> json) {
    return NavigationItemConfig(
      key: (json['key'] ?? '').toString(),
      visible: json['visible'] != false,
      order: jsonInt(json['order']) ?? 0,
    );
  }
}

class NavigationConfigService {
  NavigationConfigService._();

  static Future<NavigationConfig>? _inFlight;

  static const defaultItems = <NavigationItemConfig>[
    NavigationItemConfig(key: 'today', order: 0),
    NavigationItemConfig(key: 'learn', order: 1),
    NavigationItemConfig(key: 'practice', order: 2),
    NavigationItemConfig(key: 'progress', order: 3),
    NavigationItemConfig(key: 'me', order: 4),
  ];

  static const defaultHomeSections = <NavigationItemConfig>[
    NavigationItemConfig(key: 'hero', order: 0),
    NavigationItemConfig(key: 'banners', order: 1),
    NavigationItemConfig(key: 'stats', order: 2),
    NavigationItemConfig(key: 'shortcuts', order: 3),
    NavigationItemConfig(key: 'attention', order: 4),
    NavigationItemConfig(key: 'todo', order: 5),
    NavigationItemConfig(key: 'jumpBackIn', order: 6),
    NavigationItemConfig(key: 'comingUp', order: 7),
    NavigationItemConfig(key: 'subjects', order: 8),
  ];

  static const defaultConfig = NavigationConfig(
    items: defaultItems,
    homeSections: defaultHomeSections,
  );

  static Future<NavigationConfig> fetchConfig() async {
    final existing = _inFlight;
    if (existing != null) return existing;
    final request = _fetchConfig();
    _inFlight = request;
    try {
      return await request;
    } catch (error) {
      return defaultConfig;
    } finally {
      if (identical(_inFlight, request)) _inFlight = null;
    }
  }

  static Future<NavigationConfig> _fetchConfig() async {
    try {
      final body = await ApiClient.get('/api/navigation');
      if (body is! Map) return defaultConfig;

      final items = _parseItems(
        body['items'],
        defaultItems,
        requiredKey: 'today',
      );
      final homeSections = _parseItems(
        body['homeSections'],
        defaultHomeSections,
        allowEmpty: true,
      );
      return NavigationConfig(items: items, homeSections: homeSections);
    } catch (error) {
      debugPrint('Navigation config unavailable: $error');
      return defaultConfig;
    }
  }

  static Future<List<NavigationItemConfig>> fetch() async {
    return (await fetchConfig()).items;
  }

  static List<NavigationItemConfig> _parseItems(
    dynamic raw,
    List<NavigationItemConfig> fallback, {
    String? requiredKey,
    bool allowEmpty = false,
  }) {
    if (raw is! List) return fallback;
    if (raw.isEmpty) return fallback;
    final allowed = fallback.map((item) => item.key).toSet();
    final defaultOrder = {
      for (var index = 0; index < fallback.length; index++)
        fallback[index].key: index,
    };
    final seen = <String>{};
    final items =
        raw
            .whereType<Map>()
            .map(
              (item) => NavigationItemConfig.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where(
              (item) =>
                  allowed.contains(item.key) &&
                  item.visible &&
                  seen.add(item.key),
            )
            .toList()
          ..sort((a, b) {
            final order = a.order.compareTo(b.order);
            return order == 0
                ? (defaultOrder[a.key] ?? 999).compareTo(
                    defaultOrder[b.key] ?? 999,
                  )
                : order;
          });

    if (items.isEmpty) return allowEmpty ? items : fallback;
    if (requiredKey != null && !items.any((item) => item.key == requiredKey)) {
      items.insert(0, NavigationItemConfig(key: requiredKey, order: -1));
    }
    return items;
  }
}

class NavigationConfig {
  const NavigationConfig({required this.items, required this.homeSections});

  final List<NavigationItemConfig> items;
  final List<NavigationItemConfig> homeSections;
}
