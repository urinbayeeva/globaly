import '../../../../core/services/backend_api.dart';
import '../../domain/city_cost.dart';

abstract class CostDataSource {
  Future<List<CityCost>> cities({
    required String country,
    required String flag,
  });
}

class GeminiCostDataSource implements CostDataSource {
  GeminiCostDataSource(this._api);

  final BackendApi _api;

  bool get isConfigured => _api.isConfigured;

  @override
  Future<List<CityCost>> cities({
    required String country,
    required String flag,
  }) async {
    final Map<String, dynamic> json = await _api.post(
      '/v1/cost-of-living',
      <String, dynamic>{'country': country},
    );
    final List<dynamic> items =
        (json['items'] as List<dynamic>?) ?? <dynamic>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> j) => _toCityCost(j, country, flag))
        .where((CityCost c) => c.city.isNotEmpty && c.total > 0)
        .toList();
  }

  CityCost _toCityCost(Map<String, dynamic> j, String country, String flag) =>
      CityCost(
        city: _str(j['city']),
        country: country,
        flag: flag,
        rentMonthly: _int(j['rentMonthly']),
        foodMonthly: _int(j['foodMonthly']),
        transportMonthly: _int(j['transportMonthly']),
        miscMonthly: _int(j['miscMonthly']),
      );

  static String _str(Object? v) => v is String ? v.trim() : '';
  static int _int(Object? v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
}
