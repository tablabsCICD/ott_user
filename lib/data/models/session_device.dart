class SessionDevice {
  const SessionDevice({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.loginTime,
    required this.lastAccessTime,
    required this.appVersion,
    required this.isCurrent,
  });

  final String id;
  final String deviceName;
  final String deviceType;
  final String loginTime;
  final String lastAccessTime;
  final String appVersion;
  final bool isCurrent;

  factory SessionDevice.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ??
        json['sessionRecordId'] ??
        json['recordId'] ??
        json['session_record_id'];
    return SessionDevice(
      id: rawId == null ? '' : '$rawId',
      deviceName:
          '${json['deviceName'] ?? json['device_name'] ?? 'Unknown Device'}',
      deviceType: '${json['deviceType'] ?? json['device_type'] ?? 'MOBILE'}',
      loginTime: '${json['loginTime'] ?? json['login_time'] ?? '-'}',
      lastAccessTime:
          '${json['lastAccessTime'] ?? json['last_access_time'] ?? '-'}',
      appVersion: '${json['appVersion'] ?? json['app_version'] ?? '-'}',
      isCurrent: json['current'] == true ||
          json['isCurrent'] == true ||
          json['active'] == true,
    );
  }
}
