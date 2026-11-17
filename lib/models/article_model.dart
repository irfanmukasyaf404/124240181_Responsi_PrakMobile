import 'package:intl/intl.dart';

class ArticleModel {
  final int id;
  final String title;
  final String url;
  final String imageUrl;
  final String newsSite;
  final String summary;
  final String publishedAt;
  final String authors;

  ArticleModel({
    required this.id,
    required this.title,
    required this.url,
    required this.imageUrl,
    required this.newsSite,
    required this.summary,
    required this.publishedAt,
    required this.authors,
  });

  // Factory constructor from Spaceflight News API JSON
  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    // Parse authors list
    String parsedAuthors = '';
    if (json['authors'] != null && json['authors'] is List) {
      final list = json['authors'] as List;
      final names = list
          .map((a) {
            if (a is Map && a['name'] != null) {
              return a['name'].toString();
            }
            return '';
          })
          .where((name) => name.isNotEmpty)
          .toList();
      parsedAuthors = names.join(', ');
    }
    if (parsedAuthors.isEmpty) {
      parsedAuthors = json['news_site']?.toString() ?? 'Unknown Author';
    }

    return ArticleModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? 'No Title',
      url: json['url']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      newsSite: json['news_site']?.toString() ?? 'Unknown Source',
      summary: json['summary']?.toString() ?? 'No Summary Available',
      publishedAt: json['published_at']?.toString() ?? '',
      authors: parsedAuthors,
    );
  }

  // Factory constructor from SQLite database map
  factory ArticleModel.fromMap(Map<String, dynamic> map) {
    return ArticleModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      title: map['title']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      newsSite: map['news_site']?.toString() ?? '',
      summary: map['summary']?.toString() ?? '',
      publishedAt: map['published_at']?.toString() ?? '',
      authors: map['authors']?.toString() ?? '',
    );
  }

  // Convert ArticleModel to Map for SQLite storage
  Map<String, dynamic> toMap({String? username}) {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'url': url,
      'image_url': imageUrl,
      'news_site': newsSite,
      'summary': summary,
      'published_at': publishedAt,
      'authors': authors,
    };
    if (username != null) {
      map['username'] = username;
    }
    return map;
  }

  // Helper to format publication date
  String get formattedPublishedDate {
    if (publishedAt.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(publishedAt).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    } catch (_) {
      return publishedAt;
    }
  }
}
