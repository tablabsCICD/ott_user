import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/constant/prefrense_constant.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/core/services/referral_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Content Deep Link Generation and Parsing for All 4 Types', () {
    final deepLinkService = DeepLinkService.instance;

    test('Movie link generation and parsing (installed app & direct link)', () {
      final uri = deepLinkService.buildAppLink(
        type: DeepLinkContentType.movie,
        id: 101,
      );
      expect(uri.toString(), 'https://filmytell.com/movie/101');

      final parsed = deepLinkService.parseTarget(uri);
      expect(parsed, isNotNull);
      expect(parsed!.type, DeepLinkContentType.movie);
      expect(parsed.id, 101);

      // App scheme
      final schemeUri = deepLinkService.buildDeepLink(
        type: DeepLinkContentType.movie,
        id: 101,
      );
      expect(schemeUri.toString(), 'myapp://movie/101');
      final parsedScheme = deepLinkService.parseTarget(schemeUri);
      expect(parsedScheme, isNotNull);
      expect(parsedScheme!.type, DeepLinkContentType.movie);
      expect(parsedScheme.id, 101);
    });

    test('Series link generation and parsing', () {
      final uri = deepLinkService.buildAppLink(
        type: DeepLinkContentType.series,
        id: 202,
      );
      expect(uri.toString(), 'https://filmytell.com/series/202');

      final parsed = deepLinkService.parseTarget(uri);
      expect(parsed, isNotNull);
      expect(parsed!.type, DeepLinkContentType.series);
      expect(parsed.id, 202);

      // App scheme
      final schemeUri = deepLinkService.buildDeepLink(
        type: DeepLinkContentType.series,
        id: 202,
      );
      expect(schemeUri.toString(), 'myapp://series/202');
      final parsedScheme = deepLinkService.parseTarget(schemeUri);
      expect(parsedScheme, isNotNull);
      expect(parsedScheme!.type, DeepLinkContentType.series);
      expect(parsedScheme.id, 202);
    });

    test('Miniseries link generation and parsing', () {
      final uri = deepLinkService.buildAppLink(
        type: DeepLinkContentType.miniSeries,
        id: 303,
      );
      expect(uri.toString(), 'https://filmytell.com/miniseries/303');

      final parsed = deepLinkService.parseTarget(uri);
      expect(parsed, isNotNull);
      expect(parsed!.type, DeepLinkContentType.miniSeries);
      expect(parsed.id, 303);

      // App scheme
      final schemeUri = deepLinkService.buildDeepLink(
        type: DeepLinkContentType.miniSeries,
        id: 303,
      );
      expect(schemeUri.toString(), 'myapp://miniseries/303');
      final parsedScheme = deepLinkService.parseTarget(schemeUri);
      expect(parsedScheme, isNotNull);
      expect(parsedScheme!.type, DeepLinkContentType.miniSeries);
      expect(parsedScheme.id, 303);
    });

    test('Short Film link generation and parsing', () {
      final uri = deepLinkService.buildAppLink(
        type: DeepLinkContentType.shortFilm,
        id: 404,
      );
      expect(uri.toString(), 'https://filmytell.com/short-film/404');

      final parsed = deepLinkService.parseTarget(uri);
      expect(parsed, isNotNull);
      expect(parsed!.type, DeepLinkContentType.shortFilm);
      expect(parsed.id, 404);

      // App scheme
      final schemeUri = deepLinkService.buildDeepLink(
        type: DeepLinkContentType.shortFilm,
        id: 404,
      );
      expect(schemeUri.toString(), 'myapp://short-film/404');
      final parsedScheme = deepLinkService.parseTarget(schemeUri);
      expect(parsedScheme, isNotNull);
      expect(parsedScheme!.type, DeepLinkContentType.shortFilm);
      expect(parsedScheme.id, 404);
    });
  });

  group('Deferred Content Recovery: Android Play Store Install Referrer Payloads', () {
    final deepLinkService = DeepLinkService.instance;

    test('recovers Movie from Android referrer query string', () {
      const referrer = 'content_type=movie&content_id=101&url=https%3A%2F%2Ffilmytell.com%2Fmovie%2F101';
      final target = deepLinkService.extractTargetFromString(referrer);
      expect(target, isNotNull);
      expect(target!.type, DeepLinkContentType.movie);
      expect(target.id, 101);
    });

    test('recovers Series from Android referrer query string', () {
      const referrer = 'content_type=series&content_id=202&url=https%3A%2F%2Ffilmytell.com%2Fseries%2F202';
      final target = deepLinkService.extractTargetFromString(referrer);
      expect(target, isNotNull);
      expect(target!.type, DeepLinkContentType.series);
      expect(target.id, 202);
    });

    test('recovers Miniseries from Android referrer query string', () {
      const referrer = 'content_type=miniseries&content_id=303&url=https%3A%2F%2Ffilmytell.com%2Fminiseries%2F303';
      final target = deepLinkService.extractTargetFromString(referrer);
      expect(target, isNotNull);
      expect(target!.type, DeepLinkContentType.miniSeries);
      expect(target.id, 303);
    });

    test('recovers Short Film from Android referrer query string', () {
      const referrer = 'content_type=short-film&content_id=404&url=https%3A%2F%2Ffilmytell.com%2Fshort-film%2F404';
      final target = deepLinkService.extractTargetFromString(referrer);
      expect(target, isNotNull);
      expect(target!.type, DeepLinkContentType.shortFilm);
      expect(target.id, 404);
    });

    test('recovers content from nested referrer parameter', () {
      const referrer = 'utm_source=meta_ads&referrer=content_type%3Dmovie%26content_id%3D555';
      final target = deepLinkService.extractTargetFromString(referrer);
      expect(target, isNotNull);
      expect(target!.type, DeepLinkContentType.movie);
      expect(target.id, 555);
    });

    test('recovers content and referral code simultaneously from compound referrer', () {
      const referrer = 'content_type=movie&content_id=101&referralCode=FILMY-XX-60E7';
      final target = deepLinkService.extractTargetFromString(referrer);
      expect(target, isNotNull);
      expect(target!.type, DeepLinkContentType.movie);
      expect(target.id, 101);

      // Verify referral service also extracts referral code from same referrer
      final refCode = ReferralService.extractCodeFromString(referrer);
      expect(refCode, 'FILMY-XX-60E7');
    });
  });

  group('Deferred Content Recovery: iOS Clipboard', () {
    final deepLinkService = DeepLinkService.instance;

    test('recovers Movie from clipboard URL on iOS', () {
      const clipboardText = 'https://filmytell.com/movie/101';
      final target = deepLinkService.extractTargetFromString(clipboardText);
      expect(target, isNotNull);
      expect(target!.type, DeepLinkContentType.movie);
      expect(target.id, 101);
    });

    test('recovers Series from clipboard URL on iOS', () {
      const clipboardText = 'https://filmytell.com/series/202';
      final target = deepLinkService.extractTargetFromString(clipboardText);
      expect(target, isNotNull);
      expect(target!.type, DeepLinkContentType.series);
      expect(target.id, 202);
    });

    test('recovers Miniseries from clipboard URL on iOS', () {
      const clipboardText = 'https://filmytell.com/miniseries/303';
      final target = deepLinkService.extractTargetFromString(clipboardText);
      expect(target, isNotNull);
      expect(target!.type, DeepLinkContentType.miniSeries);
      expect(target.id, 303);
    });

    test('recovers Short Film from clipboard URL on iOS', () {
      const clipboardText = 'https://filmytell.com/short-film/404';
      final target = deepLinkService.extractTargetFromString(clipboardText);
      expect(target, isNotNull);
      expect(target!.type, DeepLinkContentType.shortFilm);
      expect(target.id, 404);
    });
  });

  group('Scenario C: Unauthenticated vs Authenticated Preservation and Consumption', () {
    final deepLinkService = DeepLinkService.instance;

    test('preserves pending content deep link when user is not logged in', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(SharedPreferencesConstant.isUserLoggedIn, false);

      const movieTarget = DeepLinkTarget(
        type: DeepLinkContentType.movie,
        id: 777,
      );
      await deepLinkService.savePendingDeepLinkTarget(movieTarget);

      // Attempt to consume while not logged in
      await deepLinkService.consumePendingNavigation();

      // Verify target was NOT deleted or wiped
      final stillPending = await deepLinkService.getPendingDeepLinkTarget();
      expect(stillPending, isNotNull);
      expect(stillPending!.type, DeepLinkContentType.movie);
      expect(stillPending.id, 777);
      expect(deepLinkService.pendingTarget, equals(movieTarget));
    });

    test('preserves Series, Miniseries, and Short Film targets while unauthenticated', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(SharedPreferencesConstant.isUserLoggedIn, false);

      // Series
      const seriesTarget = DeepLinkTarget(type: DeepLinkContentType.series, id: 888);
      await deepLinkService.savePendingDeepLinkTarget(seriesTarget);
      await deepLinkService.consumePendingNavigation();
      expect((await deepLinkService.getPendingDeepLinkTarget())?.id, 888);

      // Miniseries
      const miniTarget = DeepLinkTarget(type: DeepLinkContentType.miniSeries, id: 999);
      await deepLinkService.savePendingDeepLinkTarget(miniTarget);
      await deepLinkService.consumePendingNavigation();
      expect((await deepLinkService.getPendingDeepLinkTarget())?.id, 999);

      // Short Film
      const shortFilmTarget = DeepLinkTarget(type: DeepLinkContentType.shortFilm, id: 111);
      await deepLinkService.savePendingDeepLinkTarget(shortFilmTarget);
      await deepLinkService.consumePendingNavigation();
      expect((await deepLinkService.getPendingDeepLinkTarget())?.id, 111);
    });
  });

  group('Non-Regression Protection: Gift and Referral Flows', () {
    final deepLinkService = DeepLinkService.instance;

    test('Gift link parsing and persistence remains untouched', () async {
      final giftUri = Uri.parse('https://filmytell.com/gift/GF000843A767720E');
      final target = deepLinkService.parseTarget(giftUri);
      expect(target, isNotNull);
      expect(target!.type, DeepLinkContentType.gift);
      expect(target.couponCode, 'GF000843A767720E');

      final giftFromReferrer = deepLinkService.extractTargetFromString(
        'gift_code=GF000843A767720E&utm_source=share',
      );
      expect(giftFromReferrer?.couponCode, 'GF000843A767720E');
    });

    test('Referral link parsing and persistence remains untouched', () async {
      final refUri = Uri.parse('https://filmytell.com/register?referralCode=FILMY-XX-60E7');
      final target = deepLinkService.parseTarget(refUri);
      expect(target, isNotNull);
      expect(target!.type, DeepLinkContentType.register);
      expect(target.referralCode, 'FILMY-XX-60E7');

      final refFromReferrer = deepLinkService.extractTargetFromString(
        'referralCode=FILMY-XX-60E7&utm_medium=invite',
      );
      expect(refFromReferrer?.referralCode, 'FILMY-XX-60E7');
    });
  });
}

