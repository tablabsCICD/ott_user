import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/provider/onboarding_tour_provider.dart';
import 'package:ott/app/widgets/ott_tv_app_shell.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';

class FeatureTourTarget extends StatefulWidget {
  const FeatureTourTarget({
    super.key,
    required this.id,
    required this.child,
  });

  final FeatureTourStepId id;
  final Widget child;

  @override
  State<FeatureTourTarget> createState() => _FeatureTourTargetState();
}

class _FeatureTourTargetState extends State<FeatureTourTarget> {
  OnboardingTourProvider? _tourProvider;
  int _lastRefreshRevision = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tourProvider = context.read<OnboardingTourProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishRect());
  }

  @override
  void didUpdateWidget(covariant FeatureTourTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishRect());
  }

  @override
  void dispose() {
    _tourProvider?.unregisterTarget(widget.id);
    super.dispose();
  }

  void _publishRect() {
    if (!mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final origin = renderObject.localToGlobal(Offset.zero);
    final rect = origin & renderObject.size;
    _tourProvider?.registerTarget(widget.id, rect);
  }

  @override
  Widget build(BuildContext context) {
    final refreshRevision = context.select<OnboardingTourProvider, int>(
      (provider) => provider.targetRefreshRevision,
    );
    if (_lastRefreshRevision != refreshRevision) {
      _lastRefreshRevision = refreshRevision;
      WidgetsBinding.instance.addPostFrameCallback((_) => _publishRect());
    }

    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) {
        context.read<OnboardingTourProvider>().trackFeatureClicked(widget.id);
      },
      child: widget.child,
    );
  }
}

class FeatureTourOverlay extends StatelessWidget {
  const FeatureTourOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingTourProvider>(
      builder: (context, tour, _) {
        if (!tour.isActive) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final step = tour.currentStep;
        final screenSize = MediaQuery.of(context).size;
        final isTv = ResponsiveWidget.isTv(context);
        final rect = tour.rectFor(step.id);
        final spotlight = rect?.inflate(isTv ? 14 : 10);
        final horizontalMargin = isTv ? 48.0 : 16.0;
        final tooltipWidth = math.min(
          screenSize.width - horizontalMargin * 2,
          isTv ? 560.0 : 360.0,
        );
        final tooltipTop = _tooltipTop(
          screenSize: screenSize,
          spotlight: spotlight,
          isTv: isTv,
        );
        final tooltipLeft = ((spotlight?.center.dx ?? screenSize.width / 2) -
                tooltipWidth / 2)
            .clamp(
              horizontalMargin,
              screenSize.width - tooltipWidth - horizontalMargin,
            )
            .toDouble();

        return Semantics(
          label: '${step.title}. ${step.description}',
          liveRegion: true,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: CustomPaint(
                    painter: _SpotlightPainter(
                      spotlight: spotlight,
                      overlayColor: Colors.black.withOpacity(0.74),
                      borderColor: theme.primaryColor,
                    ),
                  ),
                ),
              ),
              if (spotlight != null)
                Positioned.fromRect(
                  rect: spotlight,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: theme.primaryColor.withOpacity(0.95),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.32),
                            blurRadius: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: tooltipTop,
                left: tooltipLeft,
                width: tooltipWidth,
                child: _TourCard(
                  step: step,
                  index: tour.currentIndex,
                  count: tour.activeSteps.length,
                  onNext: tour.next,
                  onSkip: tour.skip,
                  isTv: isTv,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _tooltipTop({
    required Size screenSize,
    required Rect? spotlight,
    required bool isTv,
  }) {
    final cardHeight = isTv ? 280.0 : 230.0;
    final edgeMargin = isTv ? 48.0 : 16.0;
    if (spotlight == null) {
      return (screenSize.height - cardHeight) / 2;
    }

    final below = spotlight.bottom + 18;
    if (below + cardHeight <= screenSize.height - edgeMargin) return below;

    final above = spotlight.top - cardHeight - 18;
    if (above >= edgeMargin) return above;

    return (screenSize.height - cardHeight - edgeMargin)
        .clamp(edgeMargin, screenSize.height)
        .toDouble();
  }
}

class _TourCard extends StatefulWidget {
  const _TourCard({
    required this.step,
    required this.index,
    required this.count,
    required this.onNext,
    required this.onSkip,
    required this.isTv,
  });

  final FeatureTourStep step;
  final int index;
  final int count;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final bool isTv;

  @override
  State<_TourCard> createState() => _TourCardState();
}

class _TourCardState extends State<_TourCard> {
  final FocusNode _keyboardFocusNode =
      FocusNode(debugLabel: 'feature-tour-keyboard');
  final FocusNode _skipFocusNode = FocusNode(debugLabel: 'feature-tour-skip');
  final FocusNode _nextFocusNode = FocusNode(debugLabel: 'feature-tour-next');

  @override
  void initState() {
    super.initState();
    _requestInitialFocus();
  }

  @override
  void didUpdateWidget(covariant _TourCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index || oldWidget.isTv != widget.isTv) {
      _requestInitialFocus();
    }
  }

  void _requestInitialFocus() {
    if (!widget.isTv) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nextFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _skipFocusNode.dispose();
    _nextFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleTvKey(FocusNode node, KeyEvent event) {
    if (!widget.isTv || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (OttTvRemoteKey.left.contains(key) ||
        OttTvRemoteKey.up.contains(key)) {
      _skipFocusNode.requestFocus();
      return KeyEventResult.handled;
    }
    if (OttTvRemoteKey.right.contains(key) ||
        OttTvRemoteKey.down.contains(key)) {
      _nextFocusNode.requestFocus();
      return KeyEventResult.handled;
    }
    if (OttTvRemoteKey.activate.contains(key)) {
      if (_skipFocusNode.hasFocus) {
        widget.onSkip();
      } else {
        widget.onNext();
      }
      return KeyEventResult.handled;
    }
    if (OttTvRemoteKey.back.contains(key)) {
      widget.onSkip();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = widget.index == widget.count - 1;
    final padding = widget.isTv ? 28.0 : 18.0;

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: widget.isTv,
      onKeyEvent: _handleTvKey,
      child: FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.step.title,
                      style: TextStyle(
                        color: theme.canvasColor,
                        fontSize: widget.isTv ? 26 : 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.index + 1}/${widget.count}',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.step.description,
                style: TextStyle(
                  color: theme.canvasColor.withOpacity(0.76),
                  fontSize: widget.isTv ? 18 : 14,
                  height: 1.42,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  TextButton(
                    focusNode: _skipFocusNode,
                    onPressed: widget.onSkip,
                    child: Text(
                      'Skip',
                      style: TextStyle(color: theme.canvasColor),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    focusNode: _nextFocusNode,
                    autofocus: widget.isTv,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                    ),
                    onPressed: widget.onNext,
                    child: Text(isLast ? 'Done' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({
    required this.spotlight,
    required this.overlayColor,
    required this.borderColor,
  });

  final Rect? spotlight;
  final Color overlayColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final fullPath = Path()..addRect(Offset.zero & size);
    if (spotlight == null) {
      canvas.drawPath(fullPath, Paint()..color = overlayColor);
      return;
    }

    final spotlightPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          spotlight!,
          const Radius.circular(18),
        ),
      );
    final path = Path.combine(
      PathOperation.difference,
      fullPath,
      spotlightPath,
    );
    canvas.drawPath(path, Paint()..color = overlayColor);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.spotlight != spotlight ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.borderColor != borderColor;
  }
}
