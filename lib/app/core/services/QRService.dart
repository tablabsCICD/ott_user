import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GeneratedQrCode {
  const GeneratedQrCode({
    required this.data,
    required this.bytes,
  });

  final String data;
  final Uint8List bytes;
}

class QRService {
  QRService._();

  static final QRService instance = QRService._();

  Future<GeneratedQrCode> generatePng({
    required String data,
    required String fileName,
    double size = 1080,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
  }) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: foregroundColor,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: foregroundColor,
      ),
      color: foregroundColor,
      emptyColor: backgroundColor,
    );

    final byteData = await painter.toImageData(
      size,
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw StateError('QR image generation returned no image data.');
    }

    final bytes = byteData.buffer.asUint8List();
    return GeneratedQrCode(
      data: data,
      bytes: bytes,
    );
  }
}
