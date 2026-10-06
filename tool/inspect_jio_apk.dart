import 'dart:io';
import 'package:archive/archive_io.dart';

void main() {
  final apkFile = File('build/app/outputs/flutter-apk/app-jio-release.apk');
  if (!apkFile.existsSync()) {
    print('APK NOT FOUND: ${apkFile.path}');
    return;
  }

  print('=== APK INSPECTION: ${apkFile.path} ===');
  print('Size in bytes: ${apkFile.lengthSync()} (${(apkFile.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB)');

  final bytes = apkFile.readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  print('Total files in APK archive: ${archive.length}');

  final adMatches = <String>[];
  final payMatches = <String>[];

  for (final file in archive) {
    final name = file.name.toLowerCase();
    if (name.contains('googleads') ||
        name.contains('admob') ||
        name.contains('ironsource') ||
        name.contains('unityads') ||
        name.contains('applovin')) {
      adMatches.add(file.name);
    }
    if (name.contains('razorpay') ||
        name.contains('payu') ||
        name.contains('cashfree') ||
        name.contains('paytm')) {
      payMatches.add(file.name);
    }
  }

  print('Ad SDK entries found: ${adMatches.length}');
  if (adMatches.isNotEmpty) {
    for (final match in adMatches.take(5)) {
      print('  - $match');
    }
  }

  print('Pay SDK entries found: ${payMatches.length}');
  if (payMatches.isNotEmpty) {
    for (final match in payMatches.take(5)) {
      print('  - $match');
    }
  }

  print('=== JIO RELEASE APK INSPECTION COMPLETE ===');
}
