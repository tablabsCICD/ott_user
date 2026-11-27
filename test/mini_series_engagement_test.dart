// Mini Series engagement: like / unlike / view must carry the bearer token
// (the backend returns 401 without it), and every part keeps its own
// likes / isLiked / views from the detail response.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/constant/prefrense_constant.dart';
import 'package:ott/app/provider/shorts_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> requests;

  setUp(() {
    requests = [];
    SharedPreferences.setMockInitialValues({
      SharedPreferencesConstant.currentUser: jsonEncode({'id': 42}),
      SharedPreferencesConstant.authToken: 'test-token',
    });
  });

  Future<T> withServer<T>(
    Future<T> Function() body, {
    http.Response Function(http.Request request)? handler,
    Completer<void>? hold,
  }) {
    final client = MockClient((request) async {
      requests.add(request);
      if (hold != null) await hold.future;
      return handler?.call(request) ??
          http.Response(jsonEncode({'success': true}), 200);
    });
    return http.runWithClient(body, () => client);
  }

  group('like / unlike / view requests', () {
    test('like: POST part like URL with bearer token', () async {
      final ok =
          await withServer(() => ShortProvider().likeShortPart(partId: 123));
      expect(ok, isTrue);
      expect(requests.single.method, 'POST');
      expect(requests.single.url.toString(), ApiConstant.likeshort(123, 42));
      expect(requests.single.headers['Authorization'], 'Bearer test-token');
    });

    test('unlike: POST part unlike URL with bearer token', () async {
      final ok =
          await withServer(() => ShortProvider().unlikeShortPart(partId: 123));
      expect(ok, isTrue);
      expect(requests.single.url.toString(), ApiConstant.unlikeshort(123, 42));
      expect(requests.single.headers['Authorization'], 'Bearer test-token');
    });

    test('view: POST part view URL with bearer token', () async {
      final ok = await withServer(() => ShortProvider().addShortView(partId: 7));
      expect(ok, isTrue);
      expect(requests.single.url.toString(), ApiConstant.viewsShort(7));
      expect(requests.single.headers['Authorization'], 'Bearer test-token');
    });

    test('401 is reported as not applied', () async {
      final ok = await withServer(
        () => ShortProvider().likeShortPart(partId: 1),
        handler: (_) => http.Response(
            jsonEncode({'message': 'Unauthorized access. Please login again.'}),
            401),
      );
      expect(ok, isFalse);
    });

    test('repeated taps while a like is in flight send one request', () async {
      final hold = Completer<void>();
      final provider = ShortProvider();
      final results = await withServer(() async {
        final first = provider.likeShortPart(partId: 9);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        final second = provider.likeShortPart(partId: 9);
        hold.complete();
        return Future.wait([first, second]);
      }, hold: hold);
      expect(results, [isTrue, isFalse]);
      expect(requests, hasLength(1));
    });
  });

  test('detail: every part keeps its own likes / isLiked / views', () async {
    final provider = ShortProvider();
    await withServer(
      () => provider.fetchShortDetail(77, 42),
      handler: (_) => http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'id': 77,
            'title': 'Drama',
            'likeCount': 9,
            'viewCount': 120,
            'parts': [
              {'partId': 1, 'partNumber': 1, 'likes': 5, 'isLiked': true, 'views': 40},
              {'partId': 2, 'partNumber': 2, 'likes': 2, 'isLiked': false, 'views': 30},
              {'partId': 3, 'partNumber': 3, 'likes': 0, 'liked': false, 'views': 0},
            ],
          },
        }),
        200,
      ),
    );
    final detail = provider.shortDetail!;
    expect(requests.single.url.toString(), ApiConstant.shortsDetails(77, 42));
    expect(detail.likeCount, 9, reason: 'series-level count, separate field');
    expect(detail.viewCount, 120);
    expect([for (final p in detail.parts) p.likes], [5, 2, 0]);
    expect([for (final p in detail.parts) p.isLiked], [true, false, false]);
    expect([for (final p in detail.parts) p.views], [40, 30, 0]);
  });
}
