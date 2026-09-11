import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/core/cast/cast_device_dialog.dart';
import 'package:ott/app/core/cast/cast_manager.dart';
import 'package:ott/app/core/cast/cast_models.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

/// Reusable Google Cast Action Button for FilmyTell.
/// Appears in video player controls and top bars on mobile & web senders.
/// Automatically hidden on Android TV and Fire TV layouts.
class CastButton extends StatelessWidget {
  final double size;
  final Color? color;
  final VoidCallback? onCustomTap;

  const CastButton({
    super.key,
    this.size = 24.0,
    this.color,
    this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    // Suppress Cast button on Android TV and Fire TV builds/devices
    if (!kIsWeb && ResponsiveWidget.isTv(context)) {
      return const SizedBox.shrink();
    }

    final castManager = CastManager.instance;

    return AnimatedBuilder(
      animation: castManager,
      builder: (context, _) {
        final state = castManager.state;
        final isConnected = castManager.connectedDevice != null;

        IconData iconData = Icons.cast;
        Color iconColor = color ?? Colors.white;

        if (state == CastPlayerState.connecting) {
          iconColor = const Color(0xFFE50914).withValues(alpha: 0.7);
        } else if (isConnected || state == CastPlayerState.playing || state == CastPlayerState.paused) {
          iconData = Icons.cast_connected;
          iconColor = const Color(0xFFE50914);
        }

        return IconButton(
          icon: Icon(iconData, size: size, color: iconColor),
          tooltip: isConnected ? 'Connected to ${castManager.connectedDevice?.name}' : 'Cast to device',
          onPressed: onCustomTap ?? () {
            if (isConnected) {
              CastDeviceDialog.show(context);
            } else {
              castManager.showCastDialog();
            }
          },
        );
      },
    );
  }
}
