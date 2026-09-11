import 'package:flutter/material.dart';
import 'package:ott/app/core/cast/cast_manager.dart';

class CastDeviceDialog extends StatefulWidget {
  const CastDeviceDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const CastDeviceDialog(),
    );
  }

  @override
  State<CastDeviceDialog> createState() => _CastDeviceDialogState();
}

class _CastDeviceDialogState extends State<CastDeviceDialog> {
  final CastManager _castManager = CastManager.instance;

  @override
  void initState() {
    super.initState();
    _castManager.startDiscovery();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _castManager,
      builder: (context, _) {
        final devices = _castManager.devices;
        final connectedDevice = _castManager.connectedDevice;
        final isDiscovering = _castManager.isDiscovering;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF161616),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: Colors.white12, width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cast, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        connectedDevice != null ? 'Connected to Cast' : 'Cast to Device',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (isDiscovering)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                      onPressed: () => _castManager.startDiscovery(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),

              // Connected Device Info
              if (connectedDevice != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE50914).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tv, color: Color(0xFFE50914), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connectedDevice.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const Text(
                              'Connected & Streaming',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          await _castManager.disconnect();
                          if (mounted) navigator.pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE50914),
                        ),
                        child: const Text('Disconnect'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Discovered Devices List
              if (devices.isEmpty && connectedDevice == null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.cast_connected,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isDiscovering
                              ? 'Searching for nearby Google Cast devices...'
                              : 'No Google Cast devices found on your Wi-Fi.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ensure your phone and Chromecast/Google TV are on the same network.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white30, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (devices.isNotEmpty) ...[
                const Text(
                  'Available Devices',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final isSelected = device.id == connectedDevice?.id;

                    return ListTile(
                      tileColor: isSelected ? const Color(0xFF282828) : const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      leading: Icon(
                        Icons.tv,
                        color: isSelected ? const Color(0xFFE50914) : Colors.white70,
                      ),
                      title: Text(
                        device.name,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      subtitle: device.modelName != null
                          ? Text(device.modelName!, style: const TextStyle(color: Colors.white38, fontSize: 12))
                          : null,
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Color(0xFFE50914), size: 20)
                          : const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
                      onTap: () async {
                        if (!isSelected) {
                          final navigator = Navigator.of(context);
                          final success = await _castManager.connect(device);
                          if (success && mounted) {
                            navigator.pop();
                          }
                        }
                      },
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
