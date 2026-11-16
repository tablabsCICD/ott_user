import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/pages/bookmarks page/component/bookmark_card.dart';
import 'package:ott/app/provider/bookmarkProvider.dart';
import 'package:ott/app/core/utils/content_type.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';

enum BookmarkFilter { movies, series, shorts, shortFilms }

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  BookmarkFilter selectedFilter = BookmarkFilter.movies;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BookmarkProvider>().getUserBookmarks();
      context.read<BookmarkProvider>().getUserBookmarkShort();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Android TV: no red app bar (the remote's Back key closes the page); the
    // title sits in a compact header row with the filter toggle.
    final isAndroidTv = ResponsiveWidget.isAndroidTv(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isAndroidTv
          ? null
          : AppBar(
        title: const Text(
          "My Bookmarks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
                child: CircularProgressIndicator(
              color: theme.primaryColor,
            ));
          }

          final allBookmarks = provider.bookmarksList;
          final allShortBookmarks = provider.shortBookmarksList;
          final bool hasAnyBookmarks =
              allBookmarks.isNotEmpty || allShortBookmarks.isNotEmpty;

          if (!hasAnyBookmarks) {
            return _emptyState(theme, message: "No bookmarks added");
          }

          if (selectedFilter == BookmarkFilter.shorts) {
            if (allShortBookmarks.isEmpty) {
              return _emptyState(
                theme,
                message: "No bookmarks found",
              );
            }

            return Column(
              children: [
                _segmentedToggle(theme),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;

                      int crossAxisCount = 2;
                      if (isAndroidTv) {
                        crossAxisCount = 6;
                      } else if (width >= 1400) {
                        crossAxisCount = 6;
                      } else if (width >= 1100) {
                        crossAxisCount = 5;
                      } else if (width >= 800) {
                        crossAxisCount = 4;
                      }

                      return GridView.builder(
                        padding: isAndroidTv
                            ? _tvGridPadding
                            : const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: isAndroidTv ? 14 : 20,
                          mainAxisSpacing: isAndroidTv ? 16 : 24,
                          childAspectRatio: 9 / 16,
                        ),
                        itemCount: allShortBookmarks.length,
                        itemBuilder: (context, index) {
                          final short = allShortBookmarks[index];
                          return ShortBookmarkPosterCard(short: short);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }

          final filteredBookmarks = _filterBookmarks(allBookmarks);
          if (filteredBookmarks.isEmpty) {
            return _emptyState(
              theme,
              message: "No bookmarks found",
            );
          }

          return Column(
            children: [
              _segmentedToggle(theme),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    int crossAxisCount = 1;
                    if (isAndroidTv) {
                      crossAxisCount = 4;
                    } else if (width >= 1400) {
                      crossAxisCount = 4;
                    } else if (width >= 1100) {
                      crossAxisCount = 3;
                    } else if (width >= 800) {
                      crossAxisCount = 2;
                    }

                    return GridView.builder(
                      padding: isAndroidTv
                          ? _tvGridPadding
                          : const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: isAndroidTv ? 14 : 20,
                        mainAxisSpacing: isAndroidTv ? 16 : 24,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: filteredBookmarks.length,
                      itemBuilder: (context, index) {
                        final movie = filteredBookmarks[index];
                        return BookmarkPosterCard(movie: movie);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Content> _filterBookmarks(List<Content> bookmarks) {
    switch (selectedFilter) {
      case BookmarkFilter.movies:
        return bookmarks
            .where(
                (item) => ContentType.normalize(item.type) == ContentType.movie)
            .toList();
      case BookmarkFilter.series:
        return bookmarks
            .where((item) => (item.type ?? '').toLowerCase() == 'series')
            .toList();
      case BookmarkFilter.shorts:
        return [];
      case BookmarkFilter.shortFilms:
        return bookmarks
            .where((item) =>
                ContentType.normalize(item.type) == ContentType.shortFilm)
            .toList();
    }
  }

  static const EdgeInsets _tvGridPadding = EdgeInsets.fromLTRB(
    TvDesign.pageGutter,
    10,
    TvDesign.pageGutter,
    TvDesign.pageGutter,
  );

  Widget _segmentedToggle(ThemeData theme) {
    if (ResponsiveWidget.isAndroidTv(context)) {
      // Android TV: page title on the left, compact segmented toggle right.
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TvDesign.pageGutter,
            14,
            TvDesign.pageGutter,
            8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "My Bookmarks",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TvDesign.pageTitle(theme),
                ),
              ),
              Container(
                height: 32,
                width: 400,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.canvasColor.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    _segment(theme, BookmarkFilter.movies, "Movies"),
                    _segment(theme, BookmarkFilter.series, "Series"),
                    _segment(theme, BookmarkFilter.shorts, "Mini Series"),
                    _segment(theme, BookmarkFilter.shortFilms, "Short Film"),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 40,
        width: ResponsiveWidget.isMobile(context) ? double.infinity : 520,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            _segment(theme, BookmarkFilter.movies, "Movies"),
            _segment(theme, BookmarkFilter.series, "Series"),
            _segment(theme, BookmarkFilter.shorts, "Mini Series"),
            _segment(theme, BookmarkFilter.shortFilms, "Short Film"),
          ],
        ),
      ),
    );
  }

  Widget _segment(
    ThemeData theme,
    BookmarkFilter value,
    String label,
  ) {
    final selected = selectedFilter == value;
    final isAndroidTv = ResponsiveWidget.isAndroidTv(context);
    final double radius = isAndroidTv ? 16 : 30;

    void selectSegment() => setState(() => selectedFilter = value);

    return Expanded(
      child: OttTvFocus(
        onTap: selectSegment,
        borderRadius: radius,
        scale: 1.02,
        semanticLabel: label,
        // Android TV: start on the active segment.
        autofocus: isAndroidTv && selected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: selected ? theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: isAndroidTv ? 1 : null,
            overflow: isAndroidTv ? TextOverflow.ellipsis : null,
            style: TextStyle(
              color: selected ? Colors.white : theme.canvasColor,
              fontWeight: FontWeight.w600,
              fontSize: isAndroidTv ? 12 : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme, {required String message}) {
    return Center(
      child: Column(
        children: [
          _segmentedToggle(theme),
          const Spacer(),
          Icon(
            Icons.bookmark_border,
            color: theme.canvasColor,
            size: ResponsiveWidget.isAndroidTv(context) ? 44 : 60,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: theme.canvasColor,
              fontSize: ResponsiveWidget.isAndroidTv(context) ? 13 : null,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
