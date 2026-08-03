import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ott/app/core/services/download_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ott/data/models/content.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'baseProvider.dart';

enum OfflineDownloadStatus { idle, downloading, completed, failed }

class OfflineDownloadMetadata {
  const OfflineDownloadMetadata({
    required this.mediaId,
    required this.title,
    required this.thumbnail,
    required this.filePath,
    required this.downloadDate,
    required this.status,
    this.errorMessage,
  });

  final int mediaId;
  final String title;
  final String thumbnail;
  final String filePath;
  final DateTime downloadDate;
  final OfflineDownloadStatus status;
  final String? errorMessage;

  factory OfflineDownloadMetadata.fromJson(Map<String, dynamic> json) {
    return OfflineDownloadMetadata(
      mediaId: _asInt(json['mediaId']) ?? 0,
      title: json['title']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      filePath: json['filePath']?.toString() ?? '',
      downloadDate: DateTime.tryParse(json['downloadDate']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: OfflineDownloadStatus.values.firstWhere(
        (status) => status.name == json['status']?.toString(),
        orElse: () => OfflineDownloadStatus.idle,
      ),
      errorMessage: json['errorMessage']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'mediaId': mediaId,
        'title': title,
        'thumbnail': thumbnail,
        'filePath': filePath,
        'downloadDate': downloadDate.toIso8601String(),
        'status': status.name,
        'errorMessage': errorMessage,
      };

  OfflineDownloadMetadata copyWith({
    String? filePath,
    DateTime? downloadDate,
    OfflineDownloadStatus? status,
    String? errorMessage,
  }) {
    return OfflineDownloadMetadata(
      mediaId: mediaId,
      title: title,
      thumbnail: thumbnail,
      filePath: filePath ?? this.filePath,
      downloadDate: downloadDate ?? this.downloadDate,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

class OfflineDownloadProvider extends BaseProvider {
  static const String _downloadedContentPrefsKey = 'offline_downloaded_movies';
  static const String _downloadMetadataPrefsKey = 'offline_download_metadata';
  final Map<int, double> _downloadProgress = {};
  final Map<int, OfflineDownloadMetadata> _downloadMetadata = {};
  final Set<int> _downloadedContentIds = <int>{};
  final Set<int> _downloadingContentIds = <int>{};
  final List<Content> _downloadedContents = <Content>[];
  bool _hasLoadedCache = false;

  double progressFor(int contentId) => _downloadProgress[contentId] ?? 0;
  bool isDownloading(int contentId) =>
      _downloadingContentIds.contains(contentId);
  bool isDownloaded(int contentId) => _downloadedContentIds.contains(contentId);
  bool hasFailed(int contentId) =>
      statusFor(contentId) == OfflineDownloadStatus.failed;
  OfflineDownloadStatus statusFor(int contentId) {
    if (_downloadingContentIds.contains(contentId)) {
      return OfflineDownloadStatus.downloading;
    }
    if (_downloadedContentIds.contains(contentId)) {
      return OfflineDownloadStatus.completed;
    }
    return _downloadMetadata[contentId]?.status ?? OfflineDownloadStatus.idle;
  }

  OfflineDownloadMetadata? metadataFor(int contentId) =>
      _downloadMetadata[contentId];

  List<Content> get downloadedContents =>
      List.unmodifiable(_downloadedContents);

  void clear() {
    _downloadProgress.clear();
    _downloadMetadata.clear();
    _downloadingContentIds.clear();
    _downloadedContentIds.clear();
    _downloadedContents.clear();
    _hasLoadedCache = false;
    notifyListeners();
  }

  Future<void> loadDownloadedContents() async {
    if (_hasLoadedCache) return;

    final prefs = await SharedPreferences.getInstance();
    final rawList =
        prefs.getStringList(_downloadedContentPrefsKey) ?? <String>[];
    final rawMetadata =
        prefs.getStringList(_downloadMetadataPrefsKey) ?? <String>[];

    _downloadedContentIds.clear();
    _downloadedContents.clear();
    _downloadMetadata.clear();

    for (final raw in rawMetadata) {
      try {
        final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
        final metadata = OfflineDownloadMetadata.fromJson(jsonMap);
        if (metadata.mediaId > 0) {
          _downloadMetadata[metadata.mediaId] = metadata;
        }
      } catch (_) {}
    }

    for (final raw in rawList) {
      try {
        final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
        final content = Content.fromJson(jsonMap);
        final contentId = content.id;
        if (contentId == null) continue;

        if (kIsWeb) {
          _downloadedContentIds.add(contentId);
          _downloadedContents.add(content);
          _downloadMetadata[contentId] = _metadataForContent(
            content,
            status: OfflineDownloadStatus.completed,
          );
          continue;
        }

        final file = await _existingLocalFileForContent(content);
        if (await file.exists()) {
          _downloadedContentIds.add(contentId);
          _downloadedContents.add(content);
          _downloadMetadata[contentId] = _metadataForContent(
            content,
            filePath: file.path,
            status: OfflineDownloadStatus.completed,
          );
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

    final file = await _existingLocalFileForContent(content);
    final exists = await file.exists();

    if (exists) {
      _downloadedContentIds.add(contentId);
      _upsertDownloadedContent(content);
      _downloadMetadata[contentId] = _metadataForContent(
        content,
        filePath: file.path,
        status: OfflineDownloadStatus.completed,
      );
    } else {
      _downloadedContentIds.remove(contentId);
      _downloadedContents.removeWhere((item) => item.id == contentId);
      final existing = _downloadMetadata[contentId];
      if (existing?.status == OfflineDownloadStatus.completed) {
        _downloadMetadata.remove(contentId);
      }
    }
    await _persistDownloadedContents();
    notifyListeners();
  }

  Future<String?> getOfflinePath(Content content) async {
    await loadDownloadedContents();
    final contentId = content.id;
    if (contentId == null || kIsWeb) return null;

    final file = await _existingLocalFileForContent(content);
    if (await file.exists()) {
      _downloadedContentIds.add(contentId);
      _downloadMetadata[contentId] = _metadataForContent(
        content,
        filePath: file.path,
        status: OfflineDownloadStatus.completed,
      );
      return file.path;
    }

    _downloadedContentIds.remove(contentId);
    return null;
  }

  Future<Map<String, Object>> downloadContent(
    Content content, {
    String? sourceUrl,
  }) async {
    await loadDownloadedContents();
    final contentId = content.id;
    final videoUrl = sourceUrl?.trim().isNotEmpty == true
        ? sourceUrl!.trim()
        : content.contentUrl?.trim() ?? '';

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

    final file = await _existingLocalFileForContent(content);
    if (await file.exists()) {
      _downloadedContentIds.add(contentId);
      _upsertDownloadedContent(content);
      _downloadMetadata[contentId] = _metadataForContent(
        content,
        filePath: file.path,
        status: OfflineDownloadStatus.completed,
      );
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
    _downloadMetadata[contentId] = _metadataForContent(
      content,
      status: OfflineDownloadStatus.downloading,
    );
    notifyListeners();

    try {
      final uri = Uri.parse(videoUrl);
      final result = await DownloadService.instance.downloadFile(
        uri: uri,
        destination: file,
        onProgress: (progress) {
          _downloadProgress[contentId] = progress;
          notifyListeners();
        },
      );

      if (!result.success) {
        _downloadMetadata[contentId] = _metadataForContent(
          content,
          filePath: file.path,
          status: OfflineDownloadStatus.failed,
          errorMessage: result.message,
        );
        await _persistDownloadedContents();
        notifyListeners();
        return {
          'success': false,
          'message': result.message ?? 'Failed to download movie.',
        };
      }

      _downloadedContentIds.add(contentId);
      _upsertDownloadedContent(content);
      _downloadProgress[contentId] = 1;
      _downloadMetadata[contentId] = _metadataForContent(
        content,
        filePath: result.filePath,
        status: OfflineDownloadStatus.completed,
      );
      await _persistDownloadedContents();
      notifyListeners();

      return {
        'success': true,
        'message': 'Movie downloaded for offline playback.',
        'path': result.filePath,
      };
    } catch (error) {
      _downloadMetadata[contentId] = _metadataForContent(
        content,
        filePath: file.path,
        status: OfflineDownloadStatus.failed,
        errorMessage: error.toString(),
      );
      await _persistDownloadedContents();
      return {
        'success': false,
        'message': 'Failed to download movie: $error',
      };
    } finally {
      _downloadingContentIds.remove(contentId);
      if (_downloadMetadata[contentId]?.status !=
          OfflineDownloadStatus.completed) {
        _downloadProgress[contentId] = 0;
      } else {
        _downloadProgress.remove(contentId);
      }
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
    if (_downloadingContentIds.contains(contentId)) {
      return {
        'success': false,
        'message': 'Download is still in progress.',
      };
    }
    if (kIsWeb) {
      _downloadedContentIds.remove(contentId);
      _downloadedContents.removeWhere((item) => item.id == contentId);
      _downloadProgress.remove(contentId);
      _downloadMetadata.remove(contentId);
      await _persistDownloadedContents();
      notifyListeners();
      return {
        'success': true,
        'message': 'Download removed from app list.',
      };
    }

    final file = await _existingLocalFileForContent(content);
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Failed to remove offline copy: $error',
      };
    }

    final partial = File('${file.path}.part');
    try {
      if (await partial.exists()) {
        await partial.delete();
      }
    } catch (_) {}

    _downloadedContentIds.remove(contentId);
    _downloadedContents.removeWhere((item) => item.id == contentId);
    _downloadProgress.remove(contentId);
    _downloadMetadata.remove(contentId);
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

  Future<File> _existingLocalFileForContent(Content content) async {
    final contentId = content.id;
    final metadataPath =
        contentId == null ? null : _downloadMetadata[contentId]?.filePath;
    if (metadataPath != null && metadataPath.trim().isNotEmpty) {
      final metadataFile = File(metadataPath);
      if (await metadataFile.exists()) {
        return metadataFile;
      }
    }

    return _localFileForContent(content);
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
      _downloadMetadata[contentId] = _metadataForContent(
        content,
        status: OfflineDownloadStatus.completed,
      );
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
      _downloadMetadata[contentId] = _metadataForContent(
        content,
        status: OfflineDownloadStatus.completed,
      );
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

    final index =
        _downloadedContents.indexWhere((item) => item.id == contentId);
    if (index >= 0) {
      _downloadedContents[index] = content;
    } else {
      _downloadedContents.add(content);
    }
  }

  OfflineDownloadMetadata _metadataForContent(
    Content content, {
    String? filePath,
    required OfflineDownloadStatus status,
    String? errorMessage,
  }) {
    final contentId = content.id ?? 0;
    final existing = _downloadMetadata[contentId];
    final posters = content.posterUrlList ?? const <String>[];

    return OfflineDownloadMetadata(
      mediaId: contentId,
      title: content.title?.trim().isNotEmpty == true
          ? content.title!.trim()
          : 'Untitled',
      thumbnail: posters.isNotEmpty ? posters.first : '',
      filePath: filePath ?? existing?.filePath ?? '',
      downloadDate: status == OfflineDownloadStatus.completed
          ? DateTime.now()
          : existing?.downloadDate ?? DateTime.now(),
      status: status,
      errorMessage: errorMessage,
    );
  }

  Future<void> _persistDownloadedContents() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _downloadedContents
        .map((content) => jsonEncode(content.toJson()))
        .toList();
    await prefs.setStringList(_downloadedContentPrefsKey, encoded);

    final metadata = _downloadMetadata.values
        .where((item) => item.status != OfflineDownloadStatus.idle)
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await prefs.setStringList(_downloadMetadataPrefsKey, metadata);
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
