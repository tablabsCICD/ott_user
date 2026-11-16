import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ott/app/pages/profile%20page/component/profile_detail_shell.dart';
import 'package:ott/app/provider/session_device_provider.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
import 'package:ott/data/models/anti_piracy_models.dart';
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

    // Android TV: compact header + device list sized for the 540 px canvas.
    if (ResponsiveWidget.isAndroidTv(context)) return _buildTv(theme);

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

  Widget _buildTv(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<SessionDeviceProvider>(
        builder: (context, provider, child) {
          final hasDevices = provider.devices.isNotEmpty;
          // Initial focus: the first device that can be removed, otherwise
          // the Refresh button (pull-to-refresh is not possible on a remote).
          final firstRemovable =
              provider.devices.indexWhere((device) => !device.current);

          Widget body;
          if (provider.isLoading && !hasDevices) {
            body = Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.primaryColor,
                ),
              ),
            );
          } else if (provider.errorMessage != null && !hasDevices) {
            body = _StateMessage(
              icon: Icons.error_outline,
              title: provider.errorMessage!,
              actionLabel: 'Retry',
              onAction: provider.fetchDevices,
            );
          } else if (!hasDevices) {
            body = _StateMessage(
              icon: Icons.devices_other,
              title: 'No active devices found.',
              actionLabel: 'Refresh',
              onAction: provider.fetchDevices,
            );
          } else {
            body = Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 720 + TvDesign.pageGutter * 2,
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    TvDesign.pageGutter,
                    2,
                    TvDesign.pageGutter,
                    20,
                  ),
                  itemCount: provider.devices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _DeviceCard(
                    device: provider.devices[index],
                    autofocus: index == firstRemovable,
                  ),
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TvDetailHeader(
                title: 'Device Management',
                subtitle: hasDevices
                    ? '${provider.devices.length} active '
                        '${provider.devices.length == 1 ? 'device' : 'devices'}'
                    : null,
                trailing: [
                  if (hasDevices)
                    TvCompactButton(
                      label: 'Refresh',
                      icon: Icons.refresh_rounded,
                      primary: false,
                      autofocus: firstRemovable < 0,
                      loading: provider.isLoading,
                      onPressed: provider.fetchDevices,
                    ),
                ],
              ),
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, this.autofocus = false});

  final DeviceBinding device;

  /// Android TV only: initial focus on this card's Remove button.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveWidget.isMobile(context);
    if (ResponsiveWidget.isAndroidTv(context)) return _buildTv(context, theme);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.18)),
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
                  color: theme.primaryColor.withValues(alpha: 0.14),
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
                    if (device.current)
                      Text(
                        'Current device',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 10),
                    _MetaLine(label: 'OS', value: device.osVersion),
                    _MetaLine(
                      label: 'Authorization',
                      value: device.blocked
                          ? 'Blocked'
                          : device.authorized
                              ? 'Authorized'
                              : 'Unknown',
                    ),
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
              onTap: device.current
                  ? null
                  : () => _confirmRemoveDevice(context, device.deviceId),
              child: ElevatedButton.icon(
                onPressed: device.current
                    ? null
                    : () => _confirmRemoveDevice(context, device.deviceId),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remove Device'),
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

  /// Android TV: one compact row per device (icon, details, Remove).
  Widget _buildTv(BuildContext context, ThemeData theme) {
    final authorization = device.blocked
        ? 'Blocked'
        : device.authorized
            ? 'Authorized'
            : 'Unknown';

    return TvPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconForType(device.deviceType),
              color: theme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.deviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.canvasColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TypeBadge(type: device.deviceType),
                    if (device.current) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Current device',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'OS: ${device.osVersion}   ·   Authorization: $authorization',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TvDesign.caption(theme),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TvCompactButton(
            label: 'Remove Device',
            icon: Icons.delete_outline,
            autofocus: autofocus,
            onPressed: device.current
                ? null
                : () => _confirmRemoveDevice(context, device.deviceId),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveDevice(
    BuildContext context,
    String deviceId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove device?'),
        content: const Text(
          'This device will no longer be authorized for protected playback.',
        ),
        actions: [
          TextButton(
            // Android TV: start on the safe choice.
            autofocus: ResponsiveWidget.isAndroidTv(dialogContext),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final provider = context.read<SessionDeviceProvider>();
    final success = await provider.removeDevice(deviceId);
    if (!context.mounted) return;
    CustomToast.show(
      context,
      success ? 'Device removed successfully.' : provider.errorMessage ?? '',
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
    final isTv = ResponsiveWidget.isAndroidTv(context);
    return Container(
      padding: isTv
          ? const EdgeInsets.symmetric(horizontal: 7, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          color: theme.primaryColor,
          fontWeight: FontWeight.w800,
          fontSize: isTv ? 9.5 : 12,
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
          color: theme.canvasColor.withValues(alpha: 0.72),
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
    if (ResponsiveWidget.isAndroidTv(context)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(TvDesign.pageGutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: theme.primaryColor, size: 36),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.canvasColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              TvCompactButton(
                label: actionLabel,
                autofocus: true,
                onPressed: onAction,
              ),
            ],
          ),
        ),
      );
    }
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
