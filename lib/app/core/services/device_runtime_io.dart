import 'dart:io' as io;

import 'device_runtime_stub.dart';
export 'device_runtime_stub.dart' show DeviceRuntimeInfo;

DeviceRuntimeInfo readDeviceRuntimeInfo() {
  final os = io.Platform.operatingSystem;
  final version = io.Platform.operatingSystemVersion;
  final normalizedOs = os.isEmpty ? 'Unknown' : os;
  final model = switch (normalizedOs.toLowerCase()) {
    'android' => 'Android Device',
    'ios' => 'iPhone',
    'macos' => 'Mac',
    'windows' => 'Windows PC',
    'linux' => 'Linux Device',
    _ => 'Device',
  };

  return DeviceRuntimeInfo(
    isWeb: false,
    os: version.isEmpty ? normalizedOs : version,
    model: model,
    manufacturer: normalizedOs,
    browser: '',
    userAgent: '',
  );
}
