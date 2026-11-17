import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/article_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Storage keys for Web / Fallback persistence
  static const String _keyWebUsers = 'local_db_users';
  static const String _keyWebBookmarks = 'local_db_bookmarks';

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDB('spacenews_explorer.db');
      return _database;
    } catch (_) {
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Table for registered users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // Table for saved bookmarks per user
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER NOT NULL,
        username TEXT NOT NULL,
        title TEXT NOT NULL,
        url TEXT,
        image_url TEXT,
        news_site TEXT,
        summary TEXT,
        published_at TEXT,
        authors TEXT,
        PRIMARY KEY (id, username)
      )
    ''');
  }

  // ==================== USER AUTHENTICATION ====================

  /// Register a new user. Returns true on success, false if username already exists.
  Future<bool> registerUser(UserModel user) async {
    if (kIsWeb) {
      return await _registerUserWeb(user);
    }

    try {
      final db = await database;
      if (db == null) return await _registerUserWeb(user);

      final id = await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return id > 0;
    } catch (_) {
      return await _registerUserWeb(user);
    }
  }

  /// Check if username is already registered
  Future<bool> isUsernameTaken(String username) async {
    final cleanUsername = username.toLowerCase().trim();

    if (kIsWeb) {
      return await _isUsernameTakenWeb(cleanUsername);
    }

    try {
      final db = await database;
      if (db == null) return await _isUsernameTakenWeb(cleanUsername);

      final result = await db.query(
        'users',
        where: 'LOWER(username) = ?',
        whereArgs: [cleanUsername],
      );
      return result.isNotEmpty;
    } catch (_) {
      return await _isUsernameTakenWeb(cleanUsername);
    }
  }

  /// Validate login credentials. Returns UserModel if credentials match, else null.
  Future<UserModel?> loginUser(String username, String password) async {
    final cleanUsername = username.toLowerCase().trim();

    if (kIsWeb) {
      return await _loginUserWeb(cleanUsername, password);
    }

    try {
      final db = await database;
      if (db == null) return await _loginUserWeb(cleanUsername, password);

      final result = await db.query(
        'users',
        where: 'LOWER(username) = ? AND password = ?',
        whereArgs: [cleanUsername, password],
      );

      if (result.isNotEmpty) {
        return UserModel.fromMap(result.first);
      }
      return null;
    } catch (_) {
      return await _loginUserWeb(cleanUsername, password);
    }
  }

  // ==================== BOOKMARK OPERATIONS ====================

  /// Add an article to bookmarks for a specific user
  Future<bool> addBookmark(ArticleModel article, String username) async {
    if (kIsWeb) {
      return await _addBookmarkWeb(article, username);
    }

    try {
      final db = await database;
      if (db == null) return await _addBookmarkWeb(article, username);

      final row = article.toMap(username: username);
      final id = await db.insert(
        'bookmarks',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id > 0;
    } catch (_) {
      return await _addBookmarkWeb(article, username);
    }
  }

  /// Remove an article from bookmarks for a specific user
  Future<bool> removeBookmark(int articleId, String username) async {
    if (kIsWeb) {
      return await _removeBookmarkWeb(articleId, username);
    }

    try {
      final db = await database;
      if (db == null) return await _removeBookmarkWeb(articleId, username);

      final rows = await db.delete(
        'bookmarks',
        where: 'id = ? AND username = ?',
        whereArgs: [articleId, username],
      );
      return rows > 0;
    } catch (_) {
      return await _removeBookmarkWeb(articleId, username);
    }
  }

  /// Check if an article is bookmarked by a user
  Future<bool> isBookmarked(int articleId, String username) async {
    if (kIsWeb) {
      return await _isBookmarkedWeb(articleId, username);
    }

    try {
      final db = await database;
      if (db == null) return await _isBookmarkedWeb(articleId, username);

      final result = await db.query(
        'bookmarks',
        where: 'id = ? AND username = ?',
        whereArgs: [articleId, username],
      );
      return result.isNotEmpty;
    } catch (_) {
      return await _isBookmarkedWeb(articleId, username);
    }
  }

  /// Get all bookmarks for a specific user
  Future<List<ArticleModel>> getBookmarks(String username) async {
    if (kIsWeb) {
      return await _getBookmarksWeb(username);
    }

    try {
      final db = await database;
      if (db == null) return await _getBookmarksWeb(username);

      final result = await db.query(
        'bookmarks',
        where: 'username = ?',
        whereArgs: [username],
        orderBy: 'published_at DESC',
      );

      return result.map((map) => ArticleModel.fromMap(map)).toList();
    } catch (_) {
      return await _getBookmarksWeb(username);
    }
  }

  // ==================== WEB & FALLBACK PERSISTENCE (LocalStorage / SharedPreferences) ====================

  Future<List<Map<String, dynamic>>> _getWebUsersList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyWebUsers);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveWebUsersList(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWebUsers, json.encode(list));
  }

  Future<bool> _registerUserWeb(UserModel user) async {
    final list = await _getWebUsersList();
    final cleanUsername = user.username.toLowerCase().trim();
    if (list.any((u) => (u['username'] as String? ?? '').toLowerCase().trim() == cleanUsername)) {
      return false; // Already taken
    }
    list.add(user.toMap());
    await _saveWebUsersList(list);
    return true;
  }

  Future<bool> _isUsernameTakenWeb(String cleanUsername) async {
    final list = await _getWebUsersList();
    return list.any((u) => (u['username'] as String? ?? '').toLowerCase().trim() == cleanUsername);
  }

  Future<UserModel?> _loginUserWeb(String cleanUsername, String password) async {
    final list = await _getWebUsersList();
    for (final item in list) {
      final uName = (item['username'] as String? ?? '').toLowerCase().trim();
      final uPass = item['password'] as String? ?? '';
      if (uName == cleanUsername && uPass == password) {
        return UserModel.fromMap(item);
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _getWebBookmarksList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyWebBookmarks);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveWebBookmarksList(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWebBookmarks, json.encode(list));
  }

  Future<bool> _addBookmarkWeb(ArticleModel article, String username) async {
    final list = await _getWebBookmarksList();
    list.removeWhere((item) => item['id'] == article.id && item['username'] == username);
    list.add(article.toMap(username: username));
    await _saveWebBookmarksList(list);
    return true;
  }

  Future<bool> _removeBookmarkWeb(int articleId, String username) async {
    final list = await _getWebBookmarksList();
    final initialLen = list.length;
    list.removeWhere((item) => item['id'] == articleId && item['username'] == username);
    await _saveWebBookmarksList(list);
    return list.length < initialLen;
  }

  Future<bool> _isBookmarkedWeb(int articleId, String username) async {
    final list = await _getWebBookmarksList();
    return list.any((item) => item['id'] == articleId && item['username'] == username);
  }

  Future<List<ArticleModel>> _getBookmarksWeb(String username) async {
    final list = await _getWebBookmarksList();
    final userItems = list.where((item) => item['username'] == username).toList();
    return userItems.map((map) => ArticleModel.fromMap(map)).toList();
  }

  // ==================== SESSION MANAGEMENT (SharedPreferences) ====================

  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUsername = 'logged_in_username';

  Future<void> saveSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUsername, username);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<String?> getSessionUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUsername);
  }
}
