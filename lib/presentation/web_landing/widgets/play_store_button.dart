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

    return Semantics(
      button: true,
      label: 'Get it on Google Play',
      child: MouseRegion(
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
      ),
    );
  }
}

class AppStoreButton extends StatefulWidget {
  const AppStoreButton({
    super.key,
    required this.appStoreUrl,
    this.appName,
  });

  final String appStoreUrl;
  final String? appName;

  @override
  State<AppStoreButton> createState() => _AppStoreButtonState();
}

class _AppStoreButtonState extends State<AppStoreButton> {
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

  Future<void> _openAppStore() async {
    final rawUrl = widget.appStoreUrl.trim();
    if (rawUrl.isEmpty) {
      if (!mounted) return;
      CustomToast.show(
        context,
        'Apple App Store link coming soon.',
        isSuccess: false,
      );
      return;
    }

    final uri = Uri.parse(rawUrl);
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
        ? 'DOWNLOAD ON THE'
        : 'GET ${widget.appName!.toUpperCase()} ON';

    return Semantics(
      button: true,
      label: 'Download on Apple App Store',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHovered(true),
        onExit: (_) {
          _setHovered(false);
          _setPressed(false);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openAppStore,
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
                  const _AppleMark(),
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
                          'Apple App Store',
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
      ),
    );
  }
}

class AmazonFireTvButton extends StatefulWidget {
  const AmazonFireTvButton({
    super.key,
    required this.amazonUrl,
    this.appName,
  });

  final String amazonUrl;
  final String? appName;

  @override
  State<AmazonFireTvButton> createState() => _AmazonFireTvButtonState();
}

class _AmazonFireTvButtonState extends State<AmazonFireTvButton> {
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

  Future<void> _openAmazonStore() async {
    final uri = Uri.parse(widget.amazonUrl);
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
        ? 'AVAILABLE ON'
        : 'GET ${widget.appName!.toUpperCase()} ON';

    return Semantics(
      button: true,
      label: 'Available on Amazon Fire TV',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHovered(true),
        onExit: (_) {
          _setHovered(false);
          _setPressed(false);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openAmazonStore,
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
                  const _AmazonFireTvMark(),
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
                          'Amazon Fire TV',
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
      ),
    );
  }
}

class JioStoreButton extends StatefulWidget {
  const JioStoreButton({
    super.key,
    this.jioStoreUrl,
    this.appName,
  });

  final String? jioStoreUrl;
  final String? appName;

  @override
  State<JioStoreButton> createState() => _JioStoreButtonState();
}

class _JioStoreButtonState extends State<JioStoreButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _hasUrl =>
      widget.jioStoreUrl != null && widget.jioStoreUrl!.trim().isNotEmpty;

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() => _hovered = value);
  }

  void _setPressed(bool value) {
    if (!mounted) return;
    setState(() => _pressed = value);
  }

  Future<void> _handleTap() async {
    if (!_hasUrl) {
      if (!mounted) return;
      CustomToast.show(
        context,
        'JioStore app is coming soon!',
        isSuccess: true,
      );
      return;
    }

    final uri = Uri.parse(widget.jioStoreUrl!.trim());
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
    final subtitle = _hasUrl
        ? (widget.appName == null
            ? 'AVAILABLE ON'
            : 'GET ${widget.appName!.toUpperCase()} ON')
        : 'COMING SOON';

    return Semantics(
      button: true,
      label: _hasUrl ? 'Available on JioStore' : 'JioStore - Coming Soon',
      child: MouseRegion(
        cursor: _hasUrl ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => _setHovered(true),
        onExit: (_) {
          _setHovered(false);
          _setPressed(false);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
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
                  const _JioStoreMark(),
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
                            color: _hasUrl
                                ? Colors.white.withOpacity(0.78)
                                : theme.primaryColor.withOpacity(0.95),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'JioStore',
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

class _AppleMark extends StatelessWidget {
  const _AppleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 25,
      child: Center(
        child: Icon(
          Icons.apple,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _AmazonFireTvMark extends StatelessWidget {
  const _AmazonFireTvMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 25),
      painter: _AmazonFireTvMarkPainter(),
    );
  }
}

class _AmazonFireTvMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Outer TV frame / screen
    final tvRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 2, size.width, size.height - 8),
      const Radius.circular(3),
    );

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawRRect(tvRect, borderPaint);

    // Stand base
    final standPath = Path()
      ..moveTo(size.width * 0.35, size.height - 6)
      ..lineTo(size.width * 0.35, size.height - 2)
      ..lineTo(size.width * 0.65, size.height - 2)
      ..lineTo(size.width * 0.65, size.height - 6);
    canvas.drawPath(
      standPath,
      Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    // Fire flame / play gradient glyph in center
    final flamePath = Path()
      ..moveTo(size.width * 0.36, size.height * 0.28)
      ..lineTo(size.width * 0.70, size.height * 0.44)
      ..lineTo(size.width * 0.36, size.height * 0.60)
      ..close();

    final flameShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFF9900), // Amazon Orange
        Color(0xFFFF5722), // Fire TV Deep Orange
      ],
    ).createShader(Offset.zero & size);

    canvas.drawPath(flamePath, Paint()..shader = flameShader);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _JioStoreMark extends StatelessWidget {
  const _JioStoreMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 25),
      painter: _JioStoreMarkPainter(),
    );
  }
}

class _JioStoreMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Jio vibrant blue circle
    final circleShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0078FF),
        Color(0xFF0A2885),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, Paint()..shader = circleShader);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Text "Jio" inside circle
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Jio',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
