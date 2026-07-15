import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class FloatingWhatsAppButton extends StatefulWidget {
  const FloatingWhatsAppButton({super.key});

  static final Uri supportUri = Uri.parse('https://wa.me/919075919666');

  @override
  State<FloatingWhatsAppButton> createState() => _FloatingWhatsAppButtonState();
}

class _FloatingWhatsAppButtonState extends State<FloatingWhatsAppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _offsetAnimation;
  bool _hovering = false;

  void _setHovering(bool value) {
    if (!mounted) return;
    setState(() => _hovering = value);
  }

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _offsetAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -5).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -5, end: 0).chain(
          CurveTween(curve: Curves.easeInCubic),
        ),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 64),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    final opened = await launchUrl(
      FloatingWhatsAppButton.supportUri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

    if (!opened) {
      await launchUrl(
        FloatingWhatsAppButton.supportUri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showBadge = width >= 640;
    final lang = AppLocalizations.of(context)!;

    return SafeArea(
      minimum: EdgeInsets.only(
        right: width < 640 ? 14 : 24,
        bottom: width < 640 ? 18 : 24,
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Tooltip(
          message: lang.chatWithUsWhatsapp,
          waitDuration: const Duration(milliseconds: 250),
          child: Semantics(
            button: true,
            label: lang.chatWithUsWhatsapp,
            child: AnimatedBuilder(
              animation: _offsetAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _offsetAnimation.value),
                  child: child,
                );
              },
              child: MouseRegion(
                onEnter: (_) => _setHovering(true),
                onExit: (_) => _setHovering(false),
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _openWhatsApp,
                  child: AnimatedScale(
                    scale: _hovering ? 1.07 : 1,
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showBadge) ...[
                          AnimatedOpacity(
                            opacity: _hovering ? 1 : 0.92,
                            duration: const Duration(milliseconds: 160),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.22),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Text(
                                lang.needHelp,
                                style: const TextStyle(
                                  color: Color(0xFF075E54),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Container(
                          width: width < 640 ? 54 : 60,
                          height: width < 640 ? 54 : 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF25D366).withOpacity(
                                  _hovering ? 0.46 : 0.32,
                                ),
                                blurRadius: _hovering ? 24 : 18,
                                offset: const Offset(0, 9),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/icons/whatsapp.svg',
                            width: width < 640 ? 52 : 58,
                            height: width < 640 ? 52 : 58,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
