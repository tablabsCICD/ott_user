import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ott/app/provider/session_device_provider.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/data/models/session_device.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<SessionDeviceProvider>().fetchDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveWidget.isMobile(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.canvasColor,
        title: const Text('Device Management'),
      ),
      body: Consumer<SessionDeviceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.devices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.devices.isEmpty) {
            return _StateMessage(
              icon: Icons.error_outline,
              title: provider.errorMessage!,
              actionLabel: 'Retry',
              onAction: provider.fetchDevices,
            );
          }

          if (provider.devices.isEmpty) {
            return _StateMessage(
              icon: Icons.devices_other,
              title: 'No active devices found.',
              actionLabel: 'Refresh',
              onAction: provider.fetchDevices,
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchDevices,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 48,
                vertical: 24,
              ),
              itemCount: provider.devices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final device = provider.devices[index];
                return _DeviceCard(device: device);
              },
            ),
          );
        },
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final SessionDevice device;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveWidget.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.primaryColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isMobile ? 42 : 54,
                height: isMobile ? 42 : 54,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForType(device.deviceType),
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            device.deviceName,
                            style: TextStyle(
                              color: theme.canvasColor,
                              fontSize: isMobile ? 16 : 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _TypeBadge(type: device.deviceType),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (device.isCurrent)
                      Text(
                        'Current device',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 10),
                    _MetaLine(label: 'Login', value: device.loginTime),
                    _MetaLine(
                      label: 'Last access',
                      value: device.lastAccessTime,
                    ),
                    _MetaLine(label: 'App version', value: device.appVersion),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OttTvFocus(
              borderRadius: 10,
              onTap: device.isCurrent
                  ? null
                  : () => _logoutDevice(context, device.id),
              child: ElevatedButton.icon(
                onPressed: device.isCurrent
                    ? null
                    : () => _logoutDevice(context, device.id),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout Device'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logoutDevice(BuildContext context, String id) async {
    final provider = context.read<SessionDeviceProvider>();
    final success = await provider.logoutDevice(id);
    if (!context.mounted) return;
    CustomToast.show(
      context,
      success ? 'Device logged out successfully.' : provider.errorMessage ?? '',
      isSuccess: success,
    );
  }

  IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'TV':
        return Icons.tv;
      case 'WEB':
        return Icons.desktop_windows;
      default:
        return Icons.smartphone;
    }
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          color: theme.primaryColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: theme.canvasColor.withOpacity(0.72),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.primaryColor, size: 48),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.canvasColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
