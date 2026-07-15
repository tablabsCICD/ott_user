import 'package:universal_html/html.dart' as html;

import 'device_runtime_stub.dart';
export 'device_runtime_stub.dart' show DeviceRuntimeInfo;

DeviceRuntimeInfo readDeviceRuntimeInfo() {
  final navigator = html.window.navigator;
  final userAgent = navigator.userAgent;
  final browser = _browserName(userAgent);

  return DeviceRuntimeInfo(
    isWeb: true,
    os: navigator.platform!,
    model: '$browser Browser',
    manufacturer: browser,
    browser: browser,
    userAgent: userAgent,
  );
}

String _browserName(String userAgent) {
  final value = userAgent.toLowerCase();
  if (value.contains('edg/')) return 'Edge';
  if (value.contains('opr/') || value.contains('opera')) return 'Opera';
  if (value.contains('firefox')) return 'Firefox';
  if (value.contains('safari') && !value.contains('chrome')) return 'Safari';
  if (value.contains('chrome') || value.contains('chromium')) return 'Chrome';
  return 'Web';
}
