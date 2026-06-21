import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/shorts.dart';
import 'package:ott/data/models/user.dart';
import 'baseProvider.dart';

class BookmarkProvider extends BaseProvider {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // 🎬 Movie Bookmarks
  List<Content> _bookmarks = [];
  List<Content> get bookmarksList => _bookmarks;

  // 🎞 Shorts Bookmarks
  List<ShortModel> _shortBookmarks = [];
  List<ShortModel> get shortBookmarksList => _shortBookmarks;

  final ApiHelper _apiHelper = ApiHelper();

  /* -------------------- ADD BOOKMARK MOVIE (POST) -------------------- */
  Future<bool> addBookmark(int contentId) async {
    try {
      final user = await _getUser();
      if (user == null) return false;

      final url = ApiConstant.addBookmark(user.id, contentId);
      log("AddBookmark (POST) => $url");

      final response = await _apiHelper.postApi(url);
      final body = jsonDecode(response.body);

      return body['isSuccess'] == true;
    } catch (e) {
      log("AddBookmark error => $e");
      return false;
    }
  }

  /* -------------------- ADD BOOKMARK SHORTS (POST) -------------------- */
  Future<bool> addBookmarkShort(int shortId) async {
    try {
      final user = await _getUser();
      if (user == null) return false;

      final url = ApiConstant.addBookmarkShort(user.id, shortId);
      log("AddBookmarkShort (POST) => $url");

      final response = await _apiHelper.postApi(url);
      final body = jsonDecode(response.body);

      return body['success'] == true;
    } catch (e) {
      log("AddBookmarkShort error => $e");
      return false;
    }
  }

  /* -------------------- REMOVE BOOKMARK MOVIE (DELETE) -------------------- */
  Future<bool> removeBookmark(int contentId) async {
    try {
      final user = await _getUser();
      if (user == null) return false;

      final url = ApiConstant.removeBookmark(user.id, contentId);
      log("RemoveBookmark (DELETE) => $url");

      final response = await _apiHelper.deleteApi(url);
      final body = jsonDecode(response.body);

      return body['isSuccess'] == true;
    } catch (e) {
      log("RemoveBookmark error => $e");
      return false;
    }
  }

  /* -------------------- REMOVE BOOKMARK SHORT (DELETE) -------------------- */
  Future<bool> removeBookmarkShort(int shortId) async {
    try {
      final user = await _getUser();
      if (user == null) return false;

      final url = ApiConstant.removeBookmarkShort(user.id, shortId);
      log("RemoveBookmarkShort (DELETE) => $url");

      final response = await _apiHelper.deleteApi(url);
      final body = jsonDecode(response.body);

      return body['success'] == true;
    } catch (e) {
      log("RemoveBookmarkShort error => $e");
      return false;
    }
  }

  /* -------------------- IS BOOKMARKED MOVIE (GET) -------------------- */
  Future<bool> isBookmarked(int contentId) async {
    try {
      final user = await _getUser();
      if (user == null) return false;

      final url = ApiConstant.isBookmarked(user.id, contentId);
      log("IsBookmarked (GET) => $url");

      final response = await _apiHelper.getApi(url);
      final body = jsonDecode(response.body);

      if (body['success'] == true) {
        return body['data']?['isBookmarked'] ?? false;
      }
    } catch (e) {
      log("IsBookmarked error => $e");
    }
    return false;
  }

  /* -------------------- IS BOOKMARKED SHORT (GET) -------------------- */
  Future<bool> isBookmarkedShort(int shortId) async {
    try {
      final user = await _getUser();
      if (user == null) return false;

      final url = ApiConstant.isBookmarkedShort(user.id, shortId);
      log("IsBookmarked (GET) => $url");

      final response = await _apiHelper.getApi(url);
      final body = jsonDecode(response.body);

      if (body['success'] == true) {
        return body['data']?['isBookmarked'] ?? false;
      }
    } catch (e) {
      log("IsBookmarked error => $e");
    }
    return false;
  }

  /* -------------------- GET USER BOOKMARKS MOVIE (GET) -------------------- */
  Future<void> getUserBookmarks() async {
    try {
      _setLoading(true);

      final user = await _getUser();
      if (user == null) return;

      final url = ApiConstant.getUserBookmarks(user.id);
      log("GetUserBookmarks URL => $url");

      final response = await _apiHelper.getApi(url);
      final body = jsonDecode(response.body);

      if (body['isSuccess'] == true) {
        final List list = body['data'] ?? [];
        _bookmarks = list.map((e) => Content.fromJson(e)).toList();
      } else {
        _errorMessage = body['message'];
      }
    } catch (e) {
      _errorMessage = e.toString();
      log("GetUserBookmarks error => $e");
    } finally {
      _setLoading(false);
    }
  }

  /* -------------------- GET USER BOOKMARKS SHORT (GET) -------------------- */
  Future<void> getUserBookmarkShort() async {
    try {
      _setLoading(true);

      final user = await _getUser();
      if (user == null) return;

      final url = ApiConstant.getUserBookmarkShort(user.id);
      log("GetUserBookmarks URL => $url");

      final response = await _apiHelper.getApi(url);
      final body = jsonDecode(response.body);

      if (body['success'] == true) {
        final List list = body['data'] ?? [];
        _shortBookmarks = list.map((e) => ShortModel.fromJson(e)).toList();
      } else {
        _errorMessage = body['message'];
      }
    } catch (e) {
      _errorMessage = e.toString();
      log("GetUserBookmarks error => $e");
    } finally {
      _setLoading(false);
    }
  }

  /* -------------------- TOGGLE BOOKMARK MOVIE (OPTIMISTIC) -------------------- */
  Future<void> toggleBookmark(Content movie) async {
    final int id = movie.id ?? 0;
    final bool wasBookmarked = isBookmarkedLocally(id);

    // ✅ Optimistic local update (ONLY place list mutates)
    if (wasBookmarked) {
      _bookmarks.removeWhere((e) => e.id == id);
    } else {
      _bookmarks.add(movie);
    }

    notifyListeners();

    // 🔄 Sync with server (NO list mutation here)
    try {
      if (wasBookmarked) {
        await removeBookmark(id);
      } else {
        await addBookmark(id);
      }
    } catch (e) {
      log("ToggleBookmark sync error => $e");
    }
  } /* -------------------- TOGGLE BOOKMARK SHORT (OPTIMISTIC) -------------------- */

  Future<void> toggleBookmarkShort(ShortModel short) async {
    final int id = short.id ?? 0;
    final bool wasBookmarked = isShortBookmarkedLocally(id);

    // ✅ Optimistic local update (ONLY place list mutates)
    if (wasBookmarked) {
      _shortBookmarks.removeWhere((e) => e.id == id);
    } else {
      _shortBookmarks.add(short);
    }

    notifyListeners();

    // 🔄 Sync with server (NO list mutation here)
    try {
      if (wasBookmarked) {
        await removeBookmarkShort(id);
      } else {
        await addBookmarkShort(id);
      }
    } catch (e) {
      log("ToggleBookmark sync error => $e");
    }
  }

  /* -------------------- HELPERS -------------------- */

  Future<User?> _getUser() async {
    final user = await LocalSharePreferences.localSharePreferences.getUser();
    if (user == null) {
      _errorMessage = "User not logged in";
    }
    return user;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  bool isBookmarkedLocally(int contentId) {
    return _bookmarks.any((c) => c.id == contentId);
  }

  bool isShortBookmarkedLocally(int shortId) {
    return _shortBookmarks.any((c) => c.id == shortId);
  }

  void clear() {
    _bookmarks.clear();
    _shortBookmarks.clear();
    notifyListeners();
  }
}
