import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/constant/prefrense_constant.dart';
import 'package:ott/app/core/services/device_identity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryDeviceIdStore implements DeviceIdStore {
  String? value;
  int writes = 0;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
    writes++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('creates a UUID once and reuses it', () async {
    SharedPreferences.setMockInitialValues({});
    final store = MemoryDeviceIdStore();
    const uuid = '2f44b286-0ca9-4f9f-8b29-a777e02ea198';
    final service = DeviceIdentityService(
      store: store,
      idGenerator: () => uuid,
      platformInfoLoader: () async => {
        'deviceName': 'Test phone',
        'osVersion': 'Android 15',
      },
    );

    final first = await service.getIdentity();
    final second = await service.getIdentity();

    expect(first.deviceId, uuid);
    expect(second.deviceId, uuid);
    expect(store.value, uuid);
    expect(store.writes, 1);
  });

  test('migrates the authenticated session device ID into secure storage',
      () async {
    const sessionDeviceId = 'ft-1720000000000-AbCdEf123456';
    SharedPreferences.setMockInitialValues({
      SharedPreferencesConstant.sessionDeviceId: sessionDeviceId,
    });
    final store = MemoryDeviceIdStore()
      ..value = '2f44b286-0ca9-4f9f-8b29-a777e02ea198';
    final service = DeviceIdentityService(
      store: store,
      platformInfoLoader: () async => {
        'deviceName': 'Test phone',
        'osVersion': 'Android 15',
      },
    );

    final identity = await service.getIdentity();

    expect(identity.deviceId, sessionDeviceId);
    expect(store.value, sessionDeviceId);
  });

  test('recovers the current authenticated user device ID when needed',
      () async {
    const userDeviceId = 'ft-1720000000001-UserDevice123';
    SharedPreferences.setMockInitialValues({
      SharedPreferencesConstant.currentUser:
          '{"id":1,"deviceId":"$userDeviceId"}',
    });
    final store = MemoryDeviceIdStore();
    final service = DeviceIdentityService(
      store: store,
      platformInfoLoader: () async => {
        'deviceName': 'Test phone',
        'osVersion': 'Android 15',
      },
    );

    final identity = await service.getIdentity();

    expect(identity.deviceId, userDeviceId);
    expect(store.value, userDeviceId);
  });

  test('saved authenticated user device ID replaces a stale session ID',
      () async {
    const staleSessionDeviceId = 'ft-1720000000000-StaleDevice123';
    const userDeviceId = 'ft-1720000000001-BackendUser123';
    SharedPreferences.setMockInitialValues({
      SharedPreferencesConstant.sessionDeviceId: staleSessionDeviceId,
      SharedPreferencesConstant.currentUser:
          '{"id":1,"deviceId":"$userDeviceId"}',
    });
    final store = MemoryDeviceIdStore()
      ..value = '2f44b286-0ca9-4f9f-8b29-a777e02ea198';
    final service = DeviceIdentityService(
      store: store,
      platformInfoLoader: () async => {
        'deviceName': 'Test phone',
        'osVersion': 'Android 15',
      },
    );

    final identity = await service.getIdentity();
    final preferences = await SharedPreferences.getInstance();

    expect(identity.deviceId, userDeviceId);
    expect(store.value, userDeviceId);
    expect(
      preferences.getString(SharedPreferencesConstant.sessionDeviceId),
      userDeviceId,
    );
  });
}
