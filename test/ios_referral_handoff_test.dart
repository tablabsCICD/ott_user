import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/constant/prefrense_constant.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/core/services/referral_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('iOS URL transport decodes once and leaves validation to backend', () {
    for (final code in ['FILMY-XX-60E7', 'ABC123', 'A', 'A+B&%25']) {
      final uri =
          Uri.https('filmytell.com', '/register', {'referralCode': code});
      expect(DeepLinkService.instance.parseTarget(uri)?.referralCode, code);
      final api = Uri.parse(ApiConstant.verifyOTP(
        mobileNum: '123',
        otp: '1234',
        deviceId: 'test',
        deviceName: 'test',
        deviceType: 'IOS',
        appVersion: '1',
        referralCode: code,
      ));
      expect(api.queryParameters['referralCode'], code);
    }
    for (final suffix in ['', '?referralCode=', '?referralCode=%20']) {
      final target = DeepLinkService.instance.parseTarget(
        Uri.parse('https://filmytell.com/register$suffix'),
      );
      expect(target?.type, DeepLinkContentType.register);
      expect(target?.referralCode, isNull);
    }
  });

  test('clipboard requires an explicit Filmytell HTTPS register URL', () {
    for (final text in [
      null,
      '',
      'shopping',
      'FILMY-XX-60E7',
      'https://example.com/register?referralCode=ABC',
      'https://filmytell.com/movie/6?referralCode=ABC',
      'https://filmytell.com/register?referralCode=',
      'https://filmytell.com/register?referralCode=%FF'
    ]) {
      expect(ReferralService.extractIOSClipboardReferral(text), isNull);
    }
    expect(
        ReferralService.extractIOSClipboardReferral(
            'https://filmytell.com/register?referralCode=FILMY-XX-60E7'),
        'FILMY-XX-60E7');
  });

  test('unknown links cannot store a referral or reuse a stale pending route',
      () async {
    await ReferralService.instance.saveReferralCode('ORIGINAL');
    expect(
        await DeepLinkService.instance.handleUri(
            Uri.parse('https://example.com/register?referralCode=OTHER'),
            source: 'initial_uri'),
        isFalse);
    expect(await ReferralService.instance.getPendingReferralCode(), 'ORIGINAL');
    final movie = DeepLinkService.instance
        .parseTarget(Uri.parse('https://filmytell.com/movie/6'));
    expect(movie?.type, DeepLinkContentType.movie);
    expect(movie?.id, 6);
  });

  test(
      'first-launch recovery is shared, persists, and cannot replay after consumption',
      () async {
    final clipboard = Completer<Object?>();
    var reads = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        reads++;
        return clipboard.future;
      }
      return null;
    });
    final service = ReferralService.instance;
    final splash = service.checkDeferredInstallReferrer();
    final login = service.checkDeferredInstallReferrer();
    clipboard.complete(
        {'text': 'https://filmytell.com/register?referralCode=FILMY-XX-60E7'});
    expect(await splash, 'FILMY-XX-60E7');
    expect(await login, 'FILMY-XX-60E7');
    expect(reads, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SharedPreferencesConstant.pendingReferralCode),
        'FILMY-XX-60E7');
    expect(
        prefs.getBool(
            SharedPreferencesConstant.hasCheckedDeferredInstallReferrer),
        isTrue);
    await service.clearReferralCode();
    expect(await service.checkDeferredInstallReferrer(), isNull);
    expect(reads, 1);
  });
}
