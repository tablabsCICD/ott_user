import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/core/services/QRService.dart';
import 'package:ott/data/models/content.dart';

class PreparedMovieShareData {
  const PreparedMovieShareData({
    required this.movie,
    required this.contentType,
    required this.deepLink,
    required this.qrLink,
    required this.qrCode,
    required this.message,
  });

  final Content movie;
  final DeepLinkContentType contentType;
  final Uri deepLink;
  final Uri qrLink;
  final GeneratedQrCode qrCode;
  final String message;
}

class ShareService {
  ShareService._();

  static final ShareService instance = ShareService._();

  Future<PreparedMovieShareData> prepareContentShare(
    Content movie, {
    required DeepLinkContentType contentType,
  }) async {
    final contentId = movie.id;
    if (contentId == null || contentId <= 0) {
      throw ArgumentError('Movie id is required to share this content.');
    }

    final shareLink = DeepLinkService.instance.buildAppLink(
      type: contentType,
      id: contentId,
    );
    final qrLink = shareLink;
    final qrCode = await QRService.instance.generatePng(
      data: qrLink.toString(),
      fileName: '${contentType.name}_${contentId}_qr.png',
      foregroundColor: Color(0xFFFFFFFF),
      backgroundColor: const Color(0xFF111111),
    );

    return PreparedMovieShareData(
      movie: movie,
      contentType: contentType,
      deepLink: shareLink,
      qrLink: qrLink,
      qrCode: qrCode,
      message: _buildShareMessage(
        movie: movie,
        contentType: contentType,
        deepLink: shareLink,
      ),
    );
  }

  Future<void> shareMovieLink(PreparedMovieShareData data) {
    return SharePlus.instance.share(
      ShareParams(
        text: data.message,
        subject: data.movie.title ?? 'Movie',
      ),
    );
  }

  Future<void> shareQrImage(PreparedMovieShareData data) {
    final qrFile = XFile.fromData(
      data.qrCode.bytes,
      mimeType: 'image/png',
      name: '${data.contentType.name}_${data.movie.id}_qr.png',
    );
    return SharePlus.instance.share(
      ShareParams(
        text: data.message,
        subject: '${data.movie.title ?? 'Movie'} QR',
        files: <XFile>[qrFile],
      ),
    );
  }

  Future<String> downloadQrImage(PreparedMovieShareData data) async {
    if (kIsWeb) {
      final blob = html.Blob(<Object>[data.qrCode.bytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..download = '${data.contentType.name}_${data.movie.id}_qr.png'
        ..click();
      html.Url.revokeObjectUrl(url);
      return 'browser download started';
    }

    final directory = await getApplicationDocumentsDirectory();
    final filePath =
        '${directory.path}${Platform.pathSeparator}${data.contentType.name}_${data.movie.id}_qr.png';
    final file = File(filePath);
    await file.writeAsBytes(data.qrCode.bytes, flush: true);
    return file.path;
  }

  String _buildShareMessage({
    required Content movie,
    required DeepLinkContentType contentType,
    required Uri deepLink,
  }) {
    final contentLabel = _contentLabel(contentType);
    final buffer = StringBuffer()
      ..writeln(movie.title ?? contentLabel)
      ..writeln()
      ..writeln(movie.description?.trim().isNotEmpty == true
          ? movie.description!.trim()
          : 'Open this $contentLabel in the Filmytell app.')
      ..writeln()
      ..writeln('Watch now:')
      ..writeln(deepLink.toString());

    buffer
      ..writeln()
      ..writeln('Play Store:')
      ..writeln(DeepLinkService.playStoreUrl);

    return buffer.toString().trim();
  }

  String _contentLabel(DeepLinkContentType contentType) {
    switch (contentType) {
      case DeepLinkContentType.movie:
        return 'movie';
      case DeepLinkContentType.shortFilm:
        return 'short film';
      case DeepLinkContentType.series:
        return 'series';
      case DeepLinkContentType.short:
        return 'short';
      case DeepLinkContentType.gift:
        return 'gift';
    }
  }
}
