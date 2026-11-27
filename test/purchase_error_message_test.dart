// Purchase failures show the backend's readable reason (e.g. coupon expired)
// instead of a generic "Purchase failed"; technical text stays generic.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ott/app/core/constant/prefrense_constant.dart';
import 'package:ott/app/provider/purchaseContentProvider.dart';
import 'package:ott/data/models/content.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final movie = Content(id: 11, title: 'Movie', price: 40);

  setUp(() {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesConstant.currentUser: jsonEncode({'id': 42}),
      SharedPreferencesConstant.authToken: 'test-token',
    });
  });

  Future<Map<String, Object>> purchase(http.Client client) =>
      http.runWithClient(
        () => PurchaseContentProvider()
            .saveUserContent(movie, couponCode: 'diwali90'),
        () => client,
      );

  MockClient reply(int status, Object body) =>
      MockClient((_) async => http.Response(jsonEncode(body), status));

  test('readable backend reason is shown (non-200)', () async {
    final result = await purchase(reply(400, {
      'success': false,
      'message': 'Coupon DIWALI90 has expired.',
    }));
    expect(result['success'], isFalse);
    expect(result['message'], 'Coupon DIWALI90 has expired.');
  });

  test('readable backend reason is shown (200 with success=false)', () async {
    final result = await purchase(reply(200, {
      'success': false,
      'message': 'Insufficient wallet balance',
    }));
    expect(result['message'], 'Insufficient wallet balance');
  });

  test('missing message falls back to the generic text', () async {
    final result = await purchase(reply(500, {'success': false}));
    expect(result['message'], 'Purchase failed. Please try again.');
  });

  test('technical / stack-trace text stays generic', () async {
    final result = await purchase(reply(500, {
      'success': false,
      'message': 'java.lang.NullPointerException: Cannot invoke "Coupon.getId()"',
    }));
    expect(result['message'], 'Purchase failed. Please try again.');
  });

  test('server transaction errors keep their existing message', () async {
    final result = await purchase(reply(500, {
      'success': false,
      'message': 'No EntityManager with actual transaction available',
    }));
    expect(result['message'],
        'Purchase could not be completed. Please try again in a moment.');
  });

  test('network failure stays generic', () async {
    final result = await purchase(
        MockClient((_) async => throw const SocketException('down')));
    expect(result['message'], 'Purchase failed. Please try again.');
  });

  test('request body still carries the coupon (unchanged)', () async {
    late Map<String, dynamic> sent;
    await purchase(MockClient((request) async {
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({'success': false, 'message': 'x y'}), 400);
    }));
    expect(sent['couponCode'], 'DIWALI90');
    expect(sent['movieId'], 11);
    expect(sent['price'], 40);
  });
}
