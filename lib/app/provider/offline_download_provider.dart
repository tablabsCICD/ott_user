import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:ott/data/models/content.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineDownloadProvider extends ChangeNotifier {
  static const String _downloadedContentPrefsKey = 'offline_downloaded_movies';
  final Map<int, double> _downloadProgress = {};
  final Set<int> _downloadedContentIds = <int>{};
  final Set<int> _downloadingContentIds = <int>{};
  final List<Content> _downloadedContents = <Content>[];
  bool _hasLoadedCache = false;

  double progressFor(int contentId) => _downloadProgress[contentId] ?? 0;
  bool isDownloading(int contentId) =>
      _downloadingContentIds.contains(contentId);
  bool isDownloaded(int contentId) => _downloadedContentIds.contains(contentId);
  List<Content> get downloadedContents => List.unmodifiable(_downloadedContents);

  Future<void> loadDownloadedContents() async {
    if (_hasLoadedCache) return;

    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_downloadedContentPrefsKey) ?? <String>[];

    _downloadedContentIds.clear();
    _downloadedContents.clear();

    for (final raw in rawList) {
      try {
        final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
        final content = Content.fromJson(jsonMap);
        final contentId = content.id;
        if (contentId == null) continue;

        if (kIsWeb) {
          _downloadedContentIds.add(contentId);
          _downloadedContents.add(content);
          continue;
        }

        final file = await _localFileForContent(content);
        if (await file.exists()) {
          _downloadedContentIds.add(contentId);
          _downloadedContents.add(content);
        }
      } catch (_) {}
    }

    _hasLoadedCache = true;
    await _persistDownloadedContents();
    notifyListeners();
  }

  Future<void> refreshStatus(Content content) async {
    await loadDownloadedContents();
    final contentId = content.id;
    if (contentId == null) return;
    if (kIsWeb) {
      if (_downloadedContentIds.contains(contentId)) {
        _upsertDownloadedContent(content);
        await _persistDownloadedContents();
        notifyListeners();
      }
      return;
    }

    final file = await _localFileForContent(content);
    final exists = await file.exists();

    if (exists) {
      _downloadedContentIds.add(contentId);
      _upsertDownloadedContent(content);
    } else {
      _downloadedContentIds.remove(contentId);
      _downloadedContents.removeWhere((item) => item.id == contentId);
    }
    await _persistDownloadedContents();
    notifyListeners();
  }

  Future<String?> getOfflinePath(Content content) async {
    await loadDownloadedContents();
    final contentId = content.id;
    if (contentId == null || kIsWeb) return null;

    final file = await _localFileForContent(content);
    if (await file.exists()) {
      _downloadedContentIds.add(contentId);
      return file.path;
    }

    _downloadedContentIds.remove(contentId);
    return null;
  }

  Future<Map<String, Object>> downloadContent(Content content) async {
    await loadDownloadedContents();
    final contentId = content.id;
    final videoUrl = content.contentUrl?.trim() ?? '';

    if (contentId == null || videoUrl.isEmpty) {
      return {
        'success': false,
        'message': 'Video is not available for download.',
      };
    }
    if (_downloadingContentIds.contains(contentId)) {
      return {
        'success': false,
        'message': 'Download already in progress.',
      };
    }
    if (kIsWeb) {
      return _downloadForWeb(content, videoUrl);
    }

    final file = await _localFileForContent(content);
    if (await file.exists()) {
      _downloadedContentIds.add(contentId);
      _upsertDownloadedContent(content);
      await _persistDownloadedContents();
      notifyListeners();
      return {
        'success': true,
        'message': 'Movie is already downloaded.',
        'path': file.path,
      };
    }

    _downloadingContentIds.add(contentId);
    _downloadProgress[contentId] = 0;
    notifyListeners();

    final client = http.Client();
    IOSink? sink;

    try {
      final request = http.Request('GET', Uri.parse(videoUrl));
      final response = await client.send(request);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Download failed with status ${response.statusCode}',
        );
      }

      await file.parent.create(recursive: true);
      sink = file.openWrite();

      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        if (totalBytes > 0) {
          _downloadProgress[contentId] = receivedBytes / totalBytes;
          notifyListeners();
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      _downloadedContentIds.add(contentId);
      _upsertDownloadedContent(content);
      _downloadProgress[contentId] = 1;
      await _persistDownloadedContents();
      notifyListeners();

      return {
        'success': true,
        'message': 'Movie downloaded for offline playback.',
        'path': file.path,
      };
    } catch (error) {
      try {
        await sink?.close();
      } catch (_) {}

      if (await file.exists()) {
        await file.delete();
      }

      return {
        'success': false,
        'message': 'Failed to download movie: $error',
      };
    } finally {
      client.close();
      _downloadingContentIds.remove(contentId);
      _downloadProgress.remove(contentId);
      notifyListeners();
    }
  }

  Future<Map<String, Object>> deleteContent(Content content) async {
    await loadDownloadedContents();
    final contentId = content.id;
    if (contentId == null) {
      return {
        'success': false,
        'message': 'Offline copy was not found.',
      };
    }
    if (kIsWeb) {
      _downloadedContentIds.remove(contentId);
      _downloadedContents.removeWhere((item) => item.id == contentId);
      _downloadProgress.remove(contentId);
      await _persistDownloadedContents();
      notifyListeners();
      return {
        'success': true,
        'message': 'Download removed from app list.',
      };
    }

    final file = await _localFileForContent(content);
    if (await file.exists()) {
      await file.delete();
    }

    _downloadedContentIds.remove(contentId);
    _downloadedContents.removeWhere((item) => item.id == contentId);
    _downloadProgress.remove(contentId);
    await _persistDownloadedContents();
    notifyListeners();

    return {
      'success': true,
      'message': 'Offline copy removed.',
    };
  }

  Future<File> _localFileForContent(Content content) async {
    final directory = await getApplicationSupportDirectory();
    final extension = _guessFileExtension(content.contentUrl);
    final fileName = 'movie_${content.id}$extension';

    return File(
      '${directory.path}${Platform.pathSeparator}offline_media${Platform.pathSeparator}$fileName',
    );
  }

  String _guessFileExtension(String? url) {
    final uri = Uri.tryParse(url ?? '');
    final lastSegment =
        uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : '';
    final dotIndex = lastSegment.lastIndexOf('.');

    if (dotIndex > 0 && dotIndex < lastSegment.length - 1) {
      return lastSegment.substring(dotIndex);
    }
    return '.mp4';
  }

  Future<Map<String, Object>> _downloadForWeb(
    Content content,
    String videoUrl,
  ) async {
    final contentId = content.id!;
    if (_downloadedContentIds.contains(contentId)) {
      _upsertDownloadedContent(content);
      await _persistDownloadedContents();
      notifyListeners();
      return {
        'success': true,
        'message': 'Content is already added to downloads.',
      };
    }

    try {
      _downloadedContentIds.add(contentId);
      _upsertDownloadedContent(content);
      await _persistDownloadedContents();
      notifyListeners();

      return {
        'success': true,
        'message': 'Content added to downloads in app.',
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Failed to add content to web downloads: $error',
      };
    }
  }

  void _upsertDownloadedContent(Content content) {
    final contentId = content.id;
    if (contentId == null) return;

    final index = _downloadedContents.indexWhere((item) => item.id == contentId);
    if (index >= 0) {
      _downloadedContents[index] = content;
    } else {
      _downloadedContents.add(content);
    }
  }

  Future<void> _persistDownloadedContents() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _downloadedContents
        .map((content) => jsonEncode(content.toJson()))
        .toList();
    await prefs.setStringList(_downloadedContentPrefsKey, encoded);
  }
}
