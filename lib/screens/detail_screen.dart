import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article_model.dart';
import '../services/database_helper.dart';

class DetailScreen extends StatefulWidget {
  final ArticleModel article;
  final String username;

  const DetailScreen({
    super.key,
    required this.article,
    required this.username,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isBookmarked = false;
  bool _isLoadingBookmark = true;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final status = await DatabaseHelper.instance.isBookmarked(
      widget.article.id,
      widget.username,
    );
    if (mounted) {
      setState(() {
        _isBookmarked = status;
        _isLoadingBookmark = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarked) {
      // Remove from bookmark
      final success = await DatabaseHelper.instance.removeBookmark(
        widget.article.id,
        widget.username,
      );
      if (!mounted) return;

      if (success) {
        setState(() => _isBookmarked = false);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berita dihapus dari bookmark'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Add to bookmark
      final success = await DatabaseHelper.instance.addBookmark(
        widget.article,
        widget.username,
      );
      if (!mounted) return;

      if (success) {
        setState(() => _isBookmarked = true);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berita berhasil ditambahkan ke bookmark'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openFullArticle() async {
    if (widget.article.url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link artikel tidak tersedia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uri = Uri.parse(widget.article.url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka browser untuk artikel ini'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error membuka link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Detail Berita',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isLoadingBookmark)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _isBookmarked ? Colors.amber : Colors.white,
                size: 28,
              ),
              tooltip: _isBookmarked ? 'Hapus Bookmark' : 'Tambah ke Bookmark',
              onPressed: _toggleBookmark,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Article Image
            if (widget.article.imageUrl.isNotEmpty)
              Image.network(
                widget.article.imageUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 250,
                    color: const Color(0xFF1E293B),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: const Color(0xFF1E293B),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 54, color: Color(0xFF64748B)),
                        SizedBox(height: 8),
                        Text('Gambar tidak dapat dimuat', style: TextStyle(color: Color(0xFF64748B))),
                      ],
                    ),
                  );
                },
              )
            else
              Container(
                height: 200,
                color: const Color(0xFF1E293B),
                child: const Center(
                  child: Icon(Icons.satellite_alt_rounded, size: 64, color: Color(0xFF64748B)),
                ),
              ),

            // Article Details Container
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges: News Site & Published Date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.source, size: 14, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 5),
                            Text(
                              widget.article.newsSite,
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.article.formattedPublishedDate,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.article.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Author
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Penulis: ${widget.article.authors.isNotEmpty ? widget.article.authors : widget.article.newsSite}',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Divider(color: Color(0xFF334155), thickness: 1),
                  const SizedBox(height: 16),

                  // Summary Section Title
                  const Text(
                    'Ringkasan Berita',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Summary Content
                  Text(
                    widget.article.summary.isNotEmpty
                        ? widget.article.summary
                        : 'Tidak ada ringkasan yang tersedia untuk berita ini.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFFE2E8F0),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Read Full Article Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openFullArticle,
                      icon: const Icon(Icons.open_in_new_rounded, size: 20),
                      label: const Text(
                        'Read Full Article',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
