import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import 'bookmark_screen.dart';
import 'detail_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ArticleModel> _articles = [];
  List<String> _newsSites = ['Semua'];
  String _selectedNewsSite = 'Semua';

  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadNewsSites(),
      _loadArticles(),
    ]);
  }

  Future<void> _loadNewsSites() async {
    try {
      final sites = await ApiService.fetchNewsSites();
      if (mounted) {
        setState(() {
          _newsSites = ['Semua', ...sites];
        });
      }
    } catch (_) {
      // Handled silently with fallback in ApiService
    }
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final articles = await ApiService.fetchArticles(
        newsSite: _selectedNewsSite == 'Semua' ? null : _selectedNewsSite,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        limit: 30, // Minimal 10 berita, kita muat 30 untuk kelengkapan
      );

      if (mounted) {
        setState(() {
          _articles = articles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _onFilterChanged(String site) {
    if (_selectedNewsSite == site) return;
    setState(() {
      _selectedNewsSite = site;
    });
    _loadArticles();
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Logout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: TextStyle(color: Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await DatabaseHelper.instance.clearSession();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SpaceNews Explorer',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF38BDF8),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.person_pin, size: 18, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  widget.username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Bookmark Button (Required by prompt)
          IconButton(
            icon: const Icon(Icons.bookmark_rounded, color: Colors.amber, size: 26),
            tooltip: 'Halaman Bookmark',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookmarkScreen(username: widget.username),
                ),
              );
            },
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 22),
            tooltip: 'Keluar',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header Container
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(
                bottom: BorderSide(color: Color(0xFF334155), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Cari topik luar angkasa...',
                            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8), size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _loadArticles();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) => _loadArticles(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                        tooltip: 'Cari',
                        onPressed: _loadArticles,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // News Site Filter Label & Chips
                Row(
                  children: [
                    const Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    const Text(
                      'Filter Sumber Berita:',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedNewsSite != 'Semua')
                      GestureDetector(
                        onTap: () => _onFilterChanged('Semua'),
                        child: const Text(
                          'Reset Filter',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Horizontal Filter Chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _newsSites.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final site = _newsSites[index];
                      final isSelected = _selectedNewsSite == site;

                      return ChoiceChip(
                        label: Text(site),
                        selected: isSelected,
                        onSelected: (_) => _onFilterChanged(site),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF0F172A) : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        selectedColor: const Color(0xFF38BDF8),
                        backgroundColor: const Color(0xFF0F172A),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main Article List / Status Area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF38BDF8)),
                        SizedBox(height: 16),
                        Text(
                          'Memuat berita luar angkasa...',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.redAccent),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadArticles,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Coba Lagi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF38BDF8),
                                  foregroundColor: const Color(0xFF0F172A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _articles.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.article_outlined, size: 56, color: Color(0xFF64748B)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Tidak ada berita ditemukan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Coba ubah kata kunci pencarian atau filter sumber berita.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      _onFilterChanged('Semua');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E293B),
                                      foregroundColor: const Color(0xFF38BDF8),
                                      side: const BorderSide(color: Color(0xFF38BDF8)),
                                    ),
                                    child: const Text('Reset Pencarian'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadArticles,
                            color: const Color(0xFF38BDF8),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _articles.length,
                              itemBuilder: (context, index) {
                                final article = _articles[index];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  color: const Color(0xFF1E293B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(
                                      color: Color(0xFF334155),
                                      width: 1,
                                    ),
                                  ),
                                  elevation: 3,
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DetailScreen(
                                            article: article,
                                            username: widget.username,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 1. Gambar Berita
                                        if (article.imageUrl.isNotEmpty)
                                          Image.network(
                                            article.imageUrl,
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                height: 180,
                                                color: const Color(0xFF0F172A),
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                            loadingProgress.expectedTotalBytes!
                                                        : null,
                                                    strokeWidth: 2,
                                                    color: const Color(0xFF38BDF8),
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) =>
                                                Container(
                                              height: 180,
                                              color: const Color(0xFF0F172A),
                                              child: const Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.image_not_supported_outlined,
                                                      size: 40,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                    SizedBox(height: 6),
                                                    Text(
                                                      'Gambar tidak tersedia',
                                                      style: TextStyle(
                                                        color: Color(0xFF64748B),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            height: 160,
                                            color: const Color(0xFF0F172A),
                                            child: const Center(
                                              child: Icon(
                                                Icons.satellite_alt_rounded,
                                                size: 48,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ),

                                        Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Row: News Site & Published Date
                                              Row(
                                                children: [
                                                  // 3. Sumber Berita (News Site)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(
                                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                                                        width: 0.8,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      article.newsSite,
                                                      style: const TextStyle(
                                                        color: Color(0xFF38BDF8),
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // 4. Tanggal Publikasi
                                                  Expanded(
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        const Icon(
                                                          Icons.schedule_rounded,
                                                          size: 13,
                                                          color: Color(0xFF94A3B8),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Flexible(
                                                          child: Text(
                                                            article.formattedPublishedDate,
                                                            style: const TextStyle(
                                                              color: Color(0xFF94A3B8),
                                                              fontSize: 11,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),

                                              // 2. Judul Berita
                                              Text(
                                                article.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1.3,
                                                ),
                                              ),
                                              const SizedBox(height: 8),

                                              // Ringkasan singkat
                                              Text(
                                                article.summary,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 13,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
