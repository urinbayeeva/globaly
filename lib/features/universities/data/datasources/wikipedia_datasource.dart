import 'package:dio/dio.dart';

import '../../../../core/utils/app_logger.dart';

class WikipediaSummary {
  WikipediaSummary({required this.extract, required this.imageUrl});
  final String extract;
  final String imageUrl;

  bool get isEmpty => extract.isEmpty && imageUrl.isEmpty;
}

abstract class WikipediaDataSource {
  Future<WikipediaSummary> summary(String title);
}

class WikipediaDataSourceImpl implements WikipediaDataSource {
  WikipediaDataSourceImpl(this._dio);
  final Dio _dio;

  static const String _base =
      'https://en.wikipedia.org/api/rest_v1/page/summary';

  @override
  Future<WikipediaSummary> summary(String title) async {
    final String slug = Uri.encodeComponent(title.replaceAll(' ', '_'));
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '$_base/$slug',
        options: Options(
          validateStatus: (int? code) => code != null && code < 500,
          receiveTimeout: const Duration(seconds: 8),
          headers: <String, String>{'accept': 'application/json'},
        ),
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final Map<String, dynamic> j = res.data as Map<String, dynamic>;
        final String extract = (j['extract'] as String?)?.trim() ?? '';
        final Map<String, dynamic>? thumb =
            j['originalimage'] as Map<String, dynamic>? ??
                j['thumbnail'] as Map<String, dynamic>?;
        final String image = (thumb?['source'] as String?) ?? '';
        return WikipediaSummary(extract: extract, imageUrl: image);
      }
      return WikipediaSummary(extract: '', imageUrl: '');
    } catch (e) {
      appLogger.w('📚 Wikipedia summary failed for "$title": $e');
      return WikipediaSummary(extract: '', imageUrl: '');
    }
  }
}
