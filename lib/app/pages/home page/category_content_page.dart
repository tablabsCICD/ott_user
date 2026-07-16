import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/route/route_observer.dart';
import 'package:ott/app/widgets/movieCard.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class CategoryContentPage extends StatefulWidget {
  final String categoryTitle;
  final List<Content> contents;

  const CategoryContentPage({
    super.key,
    required this.categoryTitle,
    required this.contents,
  });

  @override
  State<CategoryContentPage> createState() => _CategoryContentPageState();
}

class _CategoryContentPageState extends State<CategoryContentPage>
    with RouteAware, WidgetsBindingObserver {
  static const double _autoPlayVisibilityThreshold = 0.70;
  static const double _cardHeight = 270;
  static const double _gap = 8;

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int?> _activeIndex = ValueNotifier<int?>(null);
  late List<Content> _contents;
  bool _isPageActive = true;
  PageRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _contents = List<Content>.from(widget.contents);
    _scrollController.addListener(_updateActiveIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateActiveIndex();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      if (_route != null) {
        routeObserver.unsubscribe(this);
      }
      _route = route;
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _isPageActive = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateActiveIndex();
    });
  }

  @override
  void didPushNext() {
    _isPageActive = false;
    _clearAutoPlay('navigating away from category');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _isPageActive = false;
      _clearAutoPlay('app lifecycle $state');
    } else if (state == AppLifecycleState.resumed) {
      _isPageActive = ModalRoute.of(context)?.isCurrent ?? true;
      if (_isPageActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateActiveIndex();
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant CategoryContentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contents != widget.contents) {
      _contents = List<Content>.from(widget.contents);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateActiveIndex();
      });
    }
  }

  void _updateActiveIndex() {
    if (!_isPageActive) {
      _clearAutoPlay('page inactive');
      return;
    }

    if (!_scrollController.hasClients || _contents.isEmpty) {
      if (_activeIndex.value != null) {
        _activeIndex.value = null;
      }
      return;
    }

    final viewport = _scrollController.position.viewportDimension;
    if (viewport <= 0) return;

    final rowExtent = _cardHeight + _gap;
    final viewStart = _scrollController.offset;
    final viewEnd = viewStart + viewport;
    final firstCandidate = math.max(0, (viewStart / rowExtent).floor());
    final lastCandidate = math.min(
      _contents.length - 1,
      math.max(firstCandidate, ((viewEnd - 0.001) / rowExtent).floor()),
    );
    final isAtEnd =
        _scrollController.position.maxScrollExtent - _scrollController.offset <=
            1.0;

    int? bestIndex;
    double bestVisibility = 0;
    for (int candidate = firstCandidate;
        candidate <= lastCandidate;
        candidate++) {
      if (!(_contents[candidate].trailerUrl?.trim().isNotEmpty ?? false)) {
        continue;
      }

      final itemStart = candidate * rowExtent;
      final itemEnd = itemStart + _cardHeight;
      final overlap =
          math.min(viewEnd, itemEnd) - math.max(viewStart, itemStart);
      final visibility = (overlap / _cardHeight).clamp(0.0, 1.0).toDouble();
      if (visibility < _autoPlayVisibilityThreshold) continue;

      if (bestIndex == null ||
          visibility > bestVisibility ||
          (visibility == bestVisibility && candidate > bestIndex)) {
        bestVisibility = visibility;
        bestIndex = candidate;
      }
    }

    if (bestIndex == null && isAtEnd) {
      final lastPlayableIndex = _lastPlayableIndex();
      if (lastPlayableIndex != null) {
        final itemStart = lastPlayableIndex * rowExtent;
        final itemEnd = itemStart + _cardHeight;
        final overlap =
            math.min(viewEnd, itemEnd) - math.max(viewStart, itemStart);
        final visibility = (overlap / _cardHeight).clamp(0.0, 1.0).toDouble();
        if (visibility >= _autoPlayVisibilityThreshold) {
          bestIndex = lastPlayableIndex;
        }
      }
    }

    if (_activeIndex.value != bestIndex) {
      _activeIndex.value = bestIndex;
    }
  }

  int? _lastPlayableIndex() {
    for (int index = _contents.length - 1; index >= 0; index--) {
      if (_contents[index].trailerUrl?.trim().isNotEmpty ?? false) {
        return index;
      }
    }
    return null;
  }

  void _clearAutoPlay(String reason) {
    if (_activeIndex.value != null) {
      _activeIndex.value = null;
    }
    MovieCard.stopActiveTrailerPreview(reason);
  }

  void _replaceContent(Content updatedContent) {
    final contentId = updatedContent.id;
    if (contentId == null || !mounted) return;

    final index = _contents.indexWhere((content) => content.id == contentId);
    if (index == -1) return;

    setState(() {
      _contents[index] = updatedContent;
    });
    _updateActiveIndex();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clearAutoPlay('category disposed');
    routeObserver.unsubscribe(this);
    _scrollController.dispose();
    _activeIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: !(kIsWeb || ResponsiveWidget.isTv(context)),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          widget.categoryTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _contents.isEmpty
          ? const Center(
              child: Text('No content available'),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = ResponsiveWidget.isDesktop(context);
                  final isTablet = ResponsiveWidget.isTablet(context);
                  final isMobile = ResponsiveWidget.isMobile(context);
                  final horizontalPadding = isDesktop
                      ? 18.0
                      : ResponsiveWidget.isTablet(context)
                          ? 14.0
                          : 10.0;
                  final availableWidth =
                      constraints.maxWidth - (horizontalPadding * 2);

                  /*   final header = Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primaryColor.withValues(alpha: 0.12),
                          theme.cardColor,
                        ],
                      ),
                      border: Border.all(
                        color: theme.canvasColor.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.categoryTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.canvasColor,
                                  fontSize: isMobile ? 17 : 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Browse the full collection',
                                style: TextStyle(
                                  color:
                                      theme.canvasColor.withValues(alpha: 0.64),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
             */

                  if (isMobile) {
                    final cardWidth = availableWidth.toDouble();

                    return Column(
                      children: [
                        /*  Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            8,
                            horizontalPadding,
                            10,
                          ),
                          child: header,
                        ), */
                        Expanded(
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              0,
                              horizontalPadding,
                              16,
                            ),
                            itemCount: _contents.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: _gap),
                            itemBuilder: (context, index) {
                              final content = _contents[index];
                              return SizedBox(
                                width: cardWidth,
                                height: _cardHeight,
                                child: MovieCard(
                                  movie: content,
                                  index: index,
                                  activeIndexListenable: _activeIndex,
                                  cardWidth: cardWidth,
                                  cardMargin: 0,
                                  onContentUpdated: _replaceContent,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  final targetCardWidth = isDesktop ? 312.0 : 296.0;
                  int crossAxisCount =
                      ((availableWidth + _gap) / (targetCardWidth + _gap))
                          .floor();
                  if (crossAxisCount < 1) crossAxisCount = 1;
                  if (isTablet && crossAxisCount > 3) crossAxisCount = 3;
                  if (isDesktop && crossAxisCount > 4) crossAxisCount = 4;

                  final cardWidth =
                      (availableWidth - ((crossAxisCount - 1) * _gap)) /
                          crossAxisCount;

                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      /*  SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          8,
                          horizontalPadding,
                          10,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: header,
                        ),
                      ), */
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          18,
                        ),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final content = _contents[index];
                              return SizedBox(
                                height: _cardHeight,
                                child: MovieCard(
                                  movie: content,
                                  cardWidth: cardWidth,
                                  cardMargin: 0,
                                  onContentUpdated: _replaceContent,
                                ),
                              );
                            },
                            childCount: _contents.length,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: _gap,
                            crossAxisSpacing: _gap,
                            mainAxisExtent: _cardHeight,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
