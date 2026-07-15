class DeviceRuntimeInfo {
  const DeviceRuntimeInfo({
    required this.isWeb,
    required this.os,
    required this.model,
    required this.manufacturer,
    required this.browser,
    required this.userAgent,
  });

  final bool isWeb;
  final String os;
  final String model;
  final String manufacturer;
  final String browser;
  final String userAgent;
}

DeviceRuntimeInfo readDeviceRuntimeInfo() {
  return const DeviceRuntimeInfo(
    isWeb: false,
    os: 'Unknown',
    model: 'Unknown Device',
    manufacturer: 'Unknown',
    browser: '',
    userAgent: '',
  );
}
