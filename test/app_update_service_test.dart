import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/services/app_update_service.dart';

class _FakeApiHelper extends ApiHelper {
  _FakeApiHelper(this.response);

  final http.Response response;

  @override
  Future<http.Response> getApi(String url) async => response;
}

AppUpdateService _service(String body, {int statusCode = 200}) {
  return AppUpdateService(
    apiHelper: _FakeApiHelper(http.Response(body, statusCode)),
    currentVersion: '1.0.16',
  );
}

void main() {
  group('AppUpdateService version ordering', () {
    final cases = <String, bool>{
      '1.0.15': false,
      '1.0.16': false,
      '1.0.16+99': false,
      'v1.0.16': false,
      '1.0.16-beta.1': false,
      '1.0.17': true,
      '1.1.0': true,
      '2.0': true,
      'not-a-version': false,
    };

    for (final entry in cases.entries) {
      test('${entry.key} update available is ${entry.value}', () async {
        final info =
            await _service('{"version":"${entry.key}"}').getUpdateInfo();

        expect(info.latestVersion, entry.key);
        expect(info.isUpdateAvailable, entry.value);
      });
    }

    test('reads a nested appVersion response', () async {
      final info = await _service(
        '{"data":{"appVersion":"1.0.17"}}',
      ).getUpdateInfo();

      expect(info.latestVersion, '1.0.17');
      expect(info.isUpdateAvailable, isTrue);
    });

    test('fails closed when the endpoint fails', () async {
      final info = await _service(
        '{"version":"9.0.0"}',
        statusCode: 500,
      ).getUpdateInfo();

      expect(info.latestVersion, isEmpty);
      expect(info.isUpdateAvailable, isFalse);
    });
  });
}
