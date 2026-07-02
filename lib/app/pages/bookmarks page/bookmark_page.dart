import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/pages/bookmarks page/component/bookmark_card.dart';
import 'package:ott/app/provider/bookmarkProvider.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';

enum BookmarkFilter { movies, series, shorts }

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: !(kIsWeb || ResponsiveWidget.isTv(context)),
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
                      if (width >= 1400) {
                        crossAxisCount = 6;
                      } else if (width >= 1100) {
                        crossAxisCount = 5;
                      } else if (width >= 800) {
                        crossAxisCount = 4;
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 24,
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
                    if (width >= 1400) {
                      crossAxisCount = 4;
                    } else if (width >= 1100) {
                      crossAxisCount = 3;
                    } else if (width >= 800) {
                      crossAxisCount = 2;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 24,
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
            .where((item) => (item.type ?? '').toLowerCase() == 'movie')
            .toList();
      case BookmarkFilter.series:
        return bookmarks
            .where((item) => (item.type ?? '').toLowerCase() == 'series')
            .toList();
      case BookmarkFilter.shorts:
        return [];
    }
  }

  Widget _segmentedToggle(ThemeData theme) {
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

    void selectSegment() => setState(() => selectedFilter = value);

    return Expanded(
      child: OttTvFocus(
        onTap: selectSegment,
        borderRadius: 30,
        scale: 1.02,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: selected ? theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : theme.canvasColor,
              fontWeight: FontWeight.w600,
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
            size: 60,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: theme.canvasColor,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
