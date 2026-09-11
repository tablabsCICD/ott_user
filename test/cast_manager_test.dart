import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/cast/cast_constants.dart';
import 'package:ott/app/core/cast/cast_manager.dart';
import 'package:ott/app/core/cast/cast_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google Cast Configuration & Models', () {
    test('CastConfig uses default Custom Receiver Application ID 0C452C93', () {
      expect(CastConfig.appId, equals('0C452C93'));
      expect(CastConfig.isCustomReceiver, isTrue);
      expect(CastConstants.castAppId, equals('0C452C93'));
      expect(CastConstants.castNamespace, equals('urn:x-cast:com.filmytell.ott.cast'));
    });

    test('CastDevice copyWith and equality work correctly', () {
      const device1 = CastDevice(
        id: 'chromecast-living-room',
        name: 'Living Room Google TV',
        host: '192.168.1.50',
      );

      final device2 = device1.copyWith(isConnected: true);
      expect(device2.isConnected, isTrue);
      expect(device2.id, equals(device1.id));
      expect(device2.host, equals(device1.host));
      expect(device1 == device2, isTrue);
    });

    test('CastMediaMetadata toJson correctly serializes playback details without exposing JWT', () {
      const metadata = CastMediaMetadata(
        contentId: 42,
        title: 'Test Movie',
        subtitle: 'FilmyTell Original',
        posterUrl: 'https://filmytell.com/poster.jpg',
        mediaUrl: 'https://cdn.filmytell.com/movie.m3u8?Policy=xyz',
        initialPosition: Duration(minutes: 5, seconds: 30),
        duration: Duration(hours: 2),
        isSeries: false,
        watermarkText: 'USER#9876',
      );

      final json = metadata.toJson();
      expect(json['contentId'], equals(42));
      expect(json['title'], equals('Test Movie'));
      expect(json['subtitle'], equals('FilmyTell Original'));
      expect(json['initialPositionSeconds'], equals(330));
      expect(json['durationSeconds'], equals(7200));
      expect(json['watermarkText'], equals('USER#9876'));
      expect(json.containsKey('authToken'), isFalse);
    });
  });

  group('CastManager Lifecycle & Initial State', () {
    late CastManager castManager;

    setUp(() {
      castManager = CastManager.instance;
    });

    test('Initial state is disconnected', () {
      expect(castManager.state, equals(CastPlayerState.disconnected));
      expect(castManager.connectedDevice, isNull);
      expect(castManager.isCasting, isFalse);
      expect(castManager.position, equals(Duration.zero));
    });

    test('Adding and removing devices updates device list', () {
      const device = CastDevice(
        id: 'bedroom-cast',
        name: 'Bedroom Google TV',
        host: '192.168.1.60',
      );

      castManager.addOrUpdateDevice(device);
      expect(castManager.devices.contains(device), isTrue);

      castManager.removeDevice(device.id);
      expect(castManager.devices.contains(device), isFalse);
    });
  });
}
