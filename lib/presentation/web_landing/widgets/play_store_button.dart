import 'package:flutter/material.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class PlayStoreButton extends StatefulWidget {
  const PlayStoreButton({
    super.key,
    required this.playStoreUrl,
    this.appName,
  });

  final String playStoreUrl;
  final String? appName;

  @override
  State<PlayStoreButton> createState() => _PlayStoreButtonState();
}

class _PlayStoreButtonState extends State<PlayStoreButton> {
  bool _hovered = false;
  bool _pressed = false;

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() => _hovered = value);
  }

  void _setPressed(bool value) {
    if (!mounted) return;
    setState(() => _pressed = value);
  }

  Future<void> _openPlayStore() async {
    final uri = Uri.parse(widget.playStoreUrl);
    var opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

    if (!opened) {
      opened = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
    }

    if (!mounted || opened) return;
    CustomToast.show(
      context,
      AppLocalizations.of(context)!.unableOpenLink,
      isSuccess: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = widget.appName == null
        ? 'GET IT ON'
        : 'GET ${widget.appName!.toUpperCase()} ON';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) {
        _setHovered(false);
        _setPressed(false);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openPlayStore,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : (_hovered ? 1.025 : 1),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            constraints: const BoxConstraints(minHeight: 54, maxWidth: 230),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            decoration: BoxDecoration(
              color: _hovered ? const Color(0xFF151515) : Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hovered
                    ? theme.primaryColor.withOpacity(0.52)
                    : Colors.white.withOpacity(0.20),
              ),
              boxShadow: [
                if (_hovered)
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _GooglePlayMark(),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Google Play',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GooglePlayMark extends StatelessWidget {
  const _GooglePlayMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 25),
      painter: _GooglePlayMarkPainter(),
    );
  }
}

class _GooglePlayMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();

    final shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF00F5A0),
        Color(0xFF00D9F5),
        Color(0xFFFFD15C),
        Color(0xFFFF4F6D),
      ],
      stops: [0.0, 0.46, 0.68, 1.0],
    ).createShader(Offset.zero & size);

    canvas.drawPath(path, Paint()..shader = shader);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.42),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
