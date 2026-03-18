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
  static const double _gap = 12;

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
          : LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = ResponsiveWidget.isDesktop(context)
                    ? 20.0
                    : ResponsiveWidget.isTablet(context)
                        ? 16.0
                        : 8.0;

                if (ResponsiveWidget.isMobile(context)) {
                  return ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      10,
                      horizontalPadding,
                      20,
                    ),
                    itemCount: widget.contents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: _gap),
                    itemBuilder: (context, index) {
                      return Center(
                        child: SizedBox(
                          width: MovieCard.itemExtent,
                          height: _cardHeight,
                          child: MovieCard(
                            movie: widget.contents[index],
                            index: index,
                            activeIndexListenable: _activeIndex,
                          ),
                        ),
                      );
                    },
                  );
                }

                final usableWidth =
                    constraints.maxWidth - (horizontalPadding * 2);
                int maxColumns = (usableWidth / MovieCard.itemExtent).floor();
                if (maxColumns < 1) maxColumns = 1;

                final targetColumns =
                    ResponsiveWidget.isDesktop(context) ? 4 : 3;
                final crossAxisCount =
                    maxColumns > targetColumns ? targetColumns : maxColumns;

                return GridView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    10,
                    horizontalPadding,
                    20,
                  ),
                  itemCount: widget.contents.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: _gap,
                    crossAxisSpacing: _gap,
                    mainAxisExtent: _cardHeight,
                  ),
                  itemBuilder: (context, index) {
                    return Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: MovieCard.itemExtent,
                        height: _cardHeight,
                        child: MovieCard(
                          movie: widget.contents[index],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
