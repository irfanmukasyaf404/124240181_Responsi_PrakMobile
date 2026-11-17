import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';

class ApiService {
  static const String baseUrl = 'https://api.spaceflightnewsapi.net/v4';

  /// Fetch articles with optional news_site filter and search query
  static Future<List<ArticleModel>> fetchArticles({
    String? newsSite,
    String? search,
    int limit = 25,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };

    if (newsSite != null && newsSite.isNotEmpty && newsSite != 'All' && newsSite != 'Semua') {
      queryParams['news_site'] = newsSite;
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl/articles/').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> results = data['results'] ?? [];
        return results.map((item) => ArticleModel.fromJson(item)).toList();
      } else {
        throw Exception('Gagal memuat berita (HTTP ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server SpaceNews: $e');
    }
  }

  /// Fetch available news sites from the info endpoint
  static Future<List<String>> fetchNewsSites() async {
    final uri = Uri.parse('$baseUrl/info/');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        if (data['news_sites'] != null && data['news_sites'] is List) {
          final sites = List<String>.from(data['news_sites']);
          sites.sort();
          return sites;
        }
      }
    } catch (_) {
      // Fallback in case of timeout or offline
    }

    // Default fallback news sites
    return [
      'NASA',
      'SpaceNews',
      'Space.com',
      'NASASpaceflight',
      'SpaceX',
      'ESA',
      'Arstechnica',
      'European Spaceflight',
      'The Space Review',
    ];
  }
}
