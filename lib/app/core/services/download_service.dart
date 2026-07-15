import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class DownloadResult {
  const DownloadResult({
    required this.success,
    required this.filePath,
    required this.totalBytes,
    this.message,
  });

  final bool success;
  final String filePath;
  final int totalBytes;
  final String? message;
}

class DownloadService {
  DownloadService._();

  static final DownloadService instance = DownloadService._();
  static const MethodChannel _storageChannel =
      MethodChannel('com.filmytell.ott/storage');
  static const int _minimumFreeBytesAfterDownload = 100 * 1024 * 1024;

  Future<int?> availableStorageBytes() async {
    try {
      final bytes = await _storageChannel.invokeMethod<int>('availableBytes');
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<DownloadResult> downloadFile({
    required Uri uri,
    required File destination,
    required void Function(double progress) onProgress,
  }) async {
    await destination.parent.create(recursive: true);

    final partial = File('${destination.path}.part');
    final existingBytes = await partial.exists() ? await partial.length() : 0;

    final contentLength = await _remoteContentLength(uri);
    if (contentLength != null) {
      final availableBytes = await availableStorageBytes();
      final remainingBytes = contentLength - existingBytes;
      if (availableBytes != null &&
          availableBytes < remainingBytes + _minimumFreeBytesAfterDownload) {
        return DownloadResult(
          success: false,
          filePath: destination.path,
          totalBytes: contentLength,
          message: 'Not enough storage available for this download.',
        );
      }
    }

    final client = http.Client();
    IOSink? sink;

    try {
      final request = http.Request('GET', uri);
      if (existingBytes > 0) {
        request.headers['Range'] = 'bytes=$existingBytes-';
      }

      final response = await client.send(request);
      if (response.statusCode == 416) {
        try {
          await partial.delete();
        } catch (_) {}
        return downloadFile(
          uri: uri,
          destination: destination,
          onProgress: onProgress,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Download failed with status ${response.statusCode}');
      }

      final canResume = existingBytes > 0 && response.statusCode == 206;
      final startBytes = canResume ? existingBytes : 0;
      if (existingBytes > 0 && !canResume) {
        try {
          await partial.delete();
        } catch (_) {}
      }

      sink = partial.openWrite(mode: canResume ? FileMode.append : FileMode.write);
      final totalBytes = _resolveTotalBytes(
        response: response,
        alreadyReceived: startBytes,
        fallback: contentLength,
      );
      var receivedBytes = startBytes;

      if (totalBytes > 0) {
        onProgress((receivedBytes / totalBytes).clamp(0, 1).toDouble());
      }

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress((receivedBytes / totalBytes).clamp(0, 1).toDouble());
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (await destination.exists()) {
        await destination.delete();
      }
      await partial.rename(destination.path);
      onProgress(1);

      return DownloadResult(
        success: true,
        filePath: destination.path,
        totalBytes: totalBytes > 0 ? totalBytes : receivedBytes,
      );
    } catch (error) {
      try {
        await sink?.close();
      } catch (_) {}

      return DownloadResult(
        success: false,
        filePath: destination.path,
        totalBytes: contentLength ?? 0,
        message: 'Failed to download movie: $error',
      );
    } finally {
      client.close();
    }
  }

  Future<int?> _remoteContentLength(Uri uri) async {
    final client = http.Client();
    try {
      final response = await client.head(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 400) return null;
      final value = response.headers['content-length'];
      if (value == null) return null;
      return int.tryParse(value);
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  int _resolveTotalBytes({
    required http.StreamedResponse response,
    required int alreadyReceived,
    required int? fallback,
  }) {
    final contentRange = response.headers['content-range'];
    if (contentRange != null) {
      final total = int.tryParse(contentRange.split('/').last);
      if (total != null) return total;
    }

    final contentLength = response.contentLength;
    if (contentLength != null && contentLength > 0) {
      return alreadyReceived + contentLength;
    }

    return fallback ?? 0;
  }
}
