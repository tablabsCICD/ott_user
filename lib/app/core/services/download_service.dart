import 'dart:async';
import 'dart:convert';
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

  Future<DownloadResult> downloadHlsPackage({
    required Uri masterUri,
    required File destination,
    required void Function(double progress) onProgress,
    Map<String, String> headers = const {},
  }) async {
    final client = http.Client();
    final assetsDirectory = Directory('${destination.path}.assets');
    try {
      await destination.parent.create(recursive: true);
      if (await assetsDirectory.exists()) {
        await assetsDirectory.delete(recursive: true);
      }
      await assetsDirectory.create(recursive: true);

      final masterText = await _getText(client, masterUri, headers);
      final variantUri = _selectHlsVariant(masterText, masterUri);
      if (variantUri == null) {
        throw const FormatException('HLS master has no playable variant.');
      }

      final mediaText = await _getText(client, variantUri, headers);
      final resources = _hlsResources(mediaText, variantUri);
      if (resources.isEmpty) {
        throw const FormatException('HLS media playlist has no segments.');
      }

      var rewrittenMedia = mediaText;
      var receivedBytes = 0;
      for (var index = 0; index < resources.length; index++) {
        final resource = resources[index];
        final extension = _resourceExtension(resource.uri, resource.isKey);
        final fileName = resource.isKey
            ? 'key_$index$extension'
            : 'media_$index$extension';
        final localFile = File(
          '${assetsDirectory.path}${Platform.pathSeparator}$fileName',
        );
        receivedBytes += await _downloadResource(
          client,
          resource.uri,
          localFile,
          headers,
        );
        rewrittenMedia = rewrittenMedia.replaceAll(
          resource.originalReference,
          fileName,
        );
        onProgress((index + 1) / resources.length);
      }

      final mediaFile = File(
        '${assetsDirectory.path}${Platform.pathSeparator}media.m3u8',
      );
      await mediaFile.writeAsString(rewrittenMedia, flush: true);
      final relativeMediaPath =
          '${destination.uri.pathSegments.last}.assets/media.m3u8';
      await destination.writeAsString(
        '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1\n$relativeMediaPath\n',
        flush: true,
      );

      return DownloadResult(
        success: true,
        filePath: destination.path,
        totalBytes: receivedBytes,
      );
    } catch (error) {
      try {
        if (await destination.exists()) await destination.delete();
        if (await assetsDirectory.exists()) {
          await assetsDirectory.delete(recursive: true);
        }
      } catch (_) {}
      return DownloadResult(
        success: false,
        filePath: destination.path,
        totalBytes: 0,
        message: 'Failed to download HLS movie: $error',
      );
    } finally {
      client.close();
    }
  }

  Future<String> _getText(
    http.Client client,
    Uri uri,
    Map<String, String> headers,
  ) async {
    final response = await client.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Download failed with status ${response.statusCode}');
    }
    return response.body;
  }

  Uri? _selectHlsVariant(String playlist, Uri baseUri) {
    final lines = const LineSplitter().convert(playlist);
    Uri? selected;
    var bestBandwidth = -1;
    for (var index = 0; index < lines.length - 1; index++) {
      final line = lines[index].trim();
      if (!line.startsWith('#EXT-X-STREAM-INF:')) continue;
      final bandwidth = int.tryParse(
            RegExp(r'BANDWIDTH=(\d+)').firstMatch(line)?.group(1) ?? '',
          ) ??
          0;
      final reference = lines[index + 1].trim();
      if (reference.isEmpty || reference.startsWith('#')) continue;
      if (selected == null || bandwidth > bestBandwidth) {
        selected = _resolveHlsUri(baseUri, reference);
        bestBandwidth = bandwidth;
      }
    }
    if (selected != null) return selected;
    return playlist.contains('#EXTINF:') ? baseUri : null;
  }

  List<_HlsResource> _hlsResources(String playlist, Uri baseUri) {
    final resources = <_HlsResource>[];
    final attributePattern = RegExp(r'URI="([^"]+)"');
    for (final rawLine in const LineSplitter().convert(playlist)) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (!line.startsWith('#')) {
        resources.add(_HlsResource(
          originalReference: line,
          uri: _resolveHlsUri(baseUri, line),
        ));
        continue;
      }
      if (line.startsWith('#EXT-X-KEY:') ||
          line.startsWith('#EXT-X-MAP:')) {
        final match = attributePattern.firstMatch(line);
        final reference = match?.group(1);
        if (reference == null || reference.isEmpty) continue;
        resources.add(_HlsResource(
          originalReference: reference,
          uri: _resolveHlsUri(baseUri, reference),
          isKey: line.startsWith('#EXT-X-KEY:'),
        ));
      }
    }
    return resources;
  }

  Uri _resolveHlsUri(Uri baseUri, String reference) {
    final resolved = baseUri.resolve(reference);
    if (resolved.query.isNotEmpty || baseUri.query.isEmpty) return resolved;
    return resolved.replace(query: baseUri.query);
  }

  Future<int> _downloadResource(
    http.Client client,
    Uri uri,
    File destination,
    Map<String, String> headers,
  ) async {
    final request = http.Request('GET', uri)..headers.addAll(headers);
    final response = await client.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Download failed with status ${response.statusCode}');
    }
    final sink = destination.openWrite();
    var bytes = 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        bytes += chunk.length;
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    return bytes;
  }

  String _resourceExtension(Uri uri, bool isKey) {
    if (isKey) return '.key';
    final segment = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    final dot = segment.lastIndexOf('.');
    return dot > 0 ? segment.substring(dot) : '.bin';
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

class _HlsResource {
  const _HlsResource({
    required this.originalReference,
    required this.uri,
    this.isKey = false,
  });

  final String originalReference;
  final Uri uri;
  final bool isKey;
}
