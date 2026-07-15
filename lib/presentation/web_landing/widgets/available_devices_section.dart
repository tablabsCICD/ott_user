import 'package:flutter/material.dart';
import 'package:ott/l10n/app_localizations.dart';

class AvailableDevicesSection extends StatelessWidget {
  const AvailableDevicesSection({
    super.key,
    required this.onStartWatching,
    required this.onExplorePlans,
  });

  final VoidCallback onStartWatching;
  final VoidCallback onExplorePlans;

  static const _devices = [
    _DeviceItem(Icons.phone_android_rounded, 'Android'),
    _DeviceItem(Icons.tablet_android_rounded, 'Tablet'),
    _DeviceItem(Icons.tv_rounded, 'Android TV'),
    _DeviceItem(Icons.connected_tv_rounded, 'Smart TV'),
    _DeviceItem(Icons.desktop_windows_rounded, 'Web'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 10, 56, 46),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0B0B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.10),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 980;
            final title = compact
                ? const _StripTitle()
                : const Expanded(
                    flex: 4,
                    child: _StripTitle(),
                  );
            final devices = Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: compact ? WrapAlignment.start : WrapAlignment.center,
              children: [
                for (final device in _devices)
                  _DeviceBadge(
                    icon: device.icon,
                    label: device.label,
                  ),
              ],
            );
            final deviceWrap = compact
                ? devices
                : Expanded(
                    flex: 6,
                    child: devices,
                  );

            final content = [
              title,
              SizedBox(width: compact ? 0 : 24, height: compact ? 18 : 0),
              deviceWrap,
              SizedBox(width: compact ? 0 : 24, height: compact ? 18 : 0),
              _StartButton(
                color: theme.primaryColor,
                onTap: onStartWatching,
              ),
            ];

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: content,
              );
            }

            return Row(
              children: content,
            );
          },
        ),
      ),
    );
  }
}

class _StripTitle extends StatelessWidget {
  const _StripTitle();

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          lang.watchAnywhere,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          lang.availableDevicesDescription,
          style: TextStyle(
            color: Colors.white.withOpacity(0.58),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DeviceBadge extends StatelessWidget {
  const _DeviceBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.primaryColor, size: 17),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatefulWidget {
  const _StartButton({
    required this.color,
    required this.onTap,
  });

  final Color color;
  final VoidCallback onTap;

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_hovered ? 0.38 : 0.18),
                blurRadius: _hovered ? 22 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            lang.startWatching,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceItem {
  const _DeviceItem(this.icon, this.label);

  final IconData icon;
  final String label;
}
