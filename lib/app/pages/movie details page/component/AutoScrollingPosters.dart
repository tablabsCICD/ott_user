import 'dart:async';
import 'package:flutter/material.dart';

class AutoScrollingPosters extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final double aspectRatio;
  final Duration scrollDuration;

  const AutoScrollingPosters({
    super.key,
    required this.imageUrls,
    this.height = 300,
    this.aspectRatio = 2 / 3,
    this.scrollDuration = const Duration(seconds: 3),
  });

  @override
  _AutoScrollingPostersState createState() => _AutoScrollingPostersState();
}

class _AutoScrollingPostersState extends State<AutoScrollingPosters> {
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pageController = PageController(viewportFraction: _getViewportFraction());
  }

  double _getViewportFraction() {
    return MediaQuery.of(context).size.width > 600 ? 0.5 : 0.8;
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.scrollDuration, (timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.toInt() + 1;
        if (nextPage >= widget.imageUrls.length) {
          _pageController.jumpToPage(0);
        } else {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _pauseAutoScroll() {
    _timer?.cancel();
  }

  void _resumeAutoScroll() {
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _pauseAutoScroll(),
      onExit: (_) => _resumeAutoScroll(),
      child: GestureDetector(
        onTapDown: (_) => _pauseAutoScroll(),
        onTapUp: (_) => _resumeAutoScroll(),
        child: SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
                  }
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.imageUrls[index % widget.imageUrls.length],
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.2),
                                Colors.black.withOpacity(0.7)
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
