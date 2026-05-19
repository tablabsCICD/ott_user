import 'package:flutter/material.dart';
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

class _CategoryContentPageState extends State<CategoryContentPage> {
  static const double _cardHeight = 270;
  static const double _gap = 8;

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int?> _activeIndex = ValueNotifier<int?>(0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateActiveIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateActiveIndex();
      }
    });
  }

  void _updateActiveIndex() {
    if (!_scrollController.hasClients || widget.contents.isEmpty) {
      if (_activeIndex.value != null) {
        _activeIndex.value = null;
      }
      return;
    }

    final viewport = _scrollController.position.viewportDimension;
    if (viewport <= 0) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    if (maxScrollExtent - _scrollController.offset <= 1.0) {
      int lastIndex = widget.contents.length - 1;
      for (int i = widget.contents.length - 1; i >= 0; i--) {
        if (widget.contents[i].trailerUrl?.trim().isNotEmpty ?? false) {
          lastIndex = i;
          break;
        }
      }

      if (_activeIndex.value != lastIndex) {
        _activeIndex.value = lastIndex;
      }
      return;
    }

    final rowExtent = _cardHeight + _gap;
    final center = _scrollController.offset + (viewport / 2);
    int index = (center / rowExtent).floor();

    if (index < 0) index = 0;
    if (index >= widget.contents.length) {
      index = widget.contents.length - 1;
    }

    if (_activeIndex.value != index) {
      _activeIndex.value = index;
    }
  }

  @override
  void dispose() {
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
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          widget.categoryTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: widget.contents.isEmpty
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
                            itemCount: widget.contents.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: _gap),
                            itemBuilder: (context, index) {
                              return SizedBox(
                                width: cardWidth,
                                height: _cardHeight,
                                child: MovieCard(
                                  movie: widget.contents[index],
                                  index: index,
                                  activeIndexListenable: _activeIndex,
                                  cardWidth: cardWidth,
                                  cardMargin: 0,
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
                              return SizedBox(
                                height: _cardHeight,
                                child: MovieCard(
                                  movie: widget.contents[index],
                                  cardWidth: cardWidth,
                                  cardMargin: 0,
                                ),
                              );
                            },
                            childCount: widget.contents.length,
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
