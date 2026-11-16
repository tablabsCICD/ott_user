import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/utils/content_type.dart';
import 'package:ott/app/core/utils/release_date_formatter.dart';
import 'package:ott/app/pages/movie%20details%20page/MovieDetailsPage.dart';
import 'package:ott/app/pages/series%20details%20page/seriesdetailspage.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/provider/videoProvider.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/app/widgets/filmytell_poster_image.dart';
import 'package:ott/app/widgets/shimmer%20loader/search_shimmer.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
import 'package:ott/data/models/cast_member.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/repositories/demo.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool isLoading = true;
  final FocusNode _searchFocusNode = FocusNode(debugLabel: 'search-field');
  final FocusNode _tvFilterFocusNode = FocusNode(debugLabel: 'search-filter');

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Provider.of<VideoProvider>(context, listen: false).searchContent();
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _tvFilterFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    final selectedThemeData = themeProvider.getTheme;
    final lang = AppLocalizations.of(context)!;

    final movies = featuredContent["movies"] as List<dynamic>? ?? [];
    final genreSet = <String>{
      'Action',
      'Drama',
      'Comedy',
      'Thriller',
      'Horror',
      'Romance',
      'Sci-Fi',
      'Fantasy',
      'Mystery',
      'Documentary',
      'Animation',
      'Adventure',
      'Musical',
      'Historical',
      'Crime',
    };
    final languageSet = {
      for (var movie in movies)
        if (movie is Map && movie['language'] != null)
          movie['language'].toString()
    };

    return Consumer<VideoProvider>(
      builder: (context, provider, child) {
        if (ResponsiveWidget.isAndroidTv(context)) {
          return _buildAndroidTv(
            context,
            provider,
            genreSet,
            languageSet,
            selectedThemeData,
            lang,
          );
        }
        return Scaffold(
          backgroundColor: selectedThemeData.scaffoldBackgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading:
                !(kIsWeb || ResponsiveWidget.isTv(context)),
            toolbarHeight: 80,
            backgroundColor: ResponsiveWidget.isDesktop(context)
                ? selectedThemeData.scaffoldBackgroundColor
                : selectedThemeData.primaryColor,
            forceMaterialTransparency:
                ResponsiveWidget.isDesktop(context) ? true : false,
            title: SizedBox(
              width: ResponsiveWidget.isDesktop(context)
                  ? 500
                  : ResponsiveWidget.isTablet(context)
                      ? 400
                      : double.infinity,
              child: CustomTextField(
                controller: provider.searchContentController,
                focusNode: _searchFocusNode,
                autofocus: ResponsiveWidget.isTv(context),
                hintText: lang.searchContent,
                prefixIcon: const Icon(Icons.search),
                textInputType: TextInputType.text,
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => provider.searchContent(),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ResponsiveWidget.isTabletOrTv(context)
                    ? OttTvFocus(
                        borderRadius: 22,
                        scale: 1.05,
                        semanticLabel: lang.filter,
                        onTap: () => _showTvFilterDialog(
                          context,
                          provider,
                          genreSet,
                          languageSet,
                          selectedThemeData,
                          lang,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => _showTvFilterDialog(
                            context,
                            provider,
                            genreSet,
                            languageSet,
                            selectedThemeData,
                            lang,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selectedThemeData.cardColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  lang.filter,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.filter_list,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: selectedThemeData.cardColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            ResponsiveWidget.isMobile(context)
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Text(
                                      lang.filter,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                            PopupMenuButton(
                              color: selectedThemeData.cardColor,
                              tooltip: lang.filter,
                              icon: const Icon(Icons.filter_list, color: Colors.white),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: StatefulBuilder(
                                    builder: (context, setState) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lang.filterOptions,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: selectedThemeData.primaryColor,
                                            ),
                                          ),
                                          const Divider(),
                                          Text(lang.genre),
                                          DropdownButton<String>(
                                            dropdownColor: selectedThemeData.cardColor,
                                            isExpanded: true,
                                            value: provider.selectedGenre,
                                            hint: Text(lang.selectGenre),
                                            onChanged: (value) {
                                              setState(() {
                                                provider.selectedGenre = value;
                                              });
                                              provider.applyFilter(
                                                value,
                                                provider.selectedLanguage,
                                                provider.selectedRating,
                                              );
                                            },
                                            items: genreSet
                                                .map((genre) => DropdownMenuItem<String>(
                                                      value: genre,
                                                      child: Text(genre),
                                                    ))
                                                .toList(),
                                          ),
                                          Text(lang.language),
                                          DropdownButton<String>(
                                            dropdownColor: selectedThemeData.cardColor,
                                            isExpanded: true,
                                            value: provider.selectedLanguage,
                                            hint: Text(lang.selectLanguage),
                                            onChanged: (value) {
                                              setState(() {
                                                provider.selectedLanguage = value;
                                              });
                                              provider.applyFilter(
                                                provider.selectedGenre,
                                                value,
                                                provider.selectedRating,
                                              );
                                            },
                                            items: languageSet
                                                .map((language) => DropdownMenuItem<String>(
                                                      value: language,
                                                      child: Text(language),
                                                    ))
                                                .toList(),
                                          ),
                                          Text(lang.minimumRating),
                                          DropdownButton<double>(
                                            dropdownColor: selectedThemeData.cardColor,
                                            isExpanded: true,
                                            value: provider.selectedRating,
                                            hint: Text(lang.selectRating),
                                            onChanged: (value) {
                                              setState(() {
                                                provider.selectedRating = value;
                                              });
                                              provider.applyFilter(
                                                provider.selectedGenre,
                                                provider.selectedLanguage,
                                                value,
                                              );
                                            },
                                            items: [3.0, 4.0, 4.5, 5.0]
                                                .map((rating) => DropdownMenuItem<double>(
                                                      value: rating,
                                                      child: Text("$rating+"),
                                                    ))
                                                .toList(),
                                          ),
                                          const SizedBox(height: 10),
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                provider.clearFilters();
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                lang.clearFilter,
                                                style: TextStyle(
                                                  color: selectedThemeData.primaryColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          body: isLoading
              ? const SearchShimmer()
              : ResponsiveWidget.isMobile(context)
                  ? provider.filteredContentList.isEmpty
                      ? Center(
                          child: Text(
                            lang.noContentFound,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        )
                      : ListView.builder(
                          itemCount: provider.filteredContentList.length,
                          itemBuilder: (context, index) {
                            final movie = provider.filteredContentList[index];
                            return SearchMovieCard(movie: movie);
                          },
                        )
                  : CustomScrollView(
                      slivers: [
                        _buildSearchSuggestionsSliver(
                          context,
                          provider,
                          genreSet,
                          languageSet,
                        ),
                        if (provider.filteredContentList.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                lang.noContentFound,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.all(8.0),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final movie =
                                      provider.filteredContentList[index];
                                  return SearchMovieCard(movie: movie);
                                },
                                childCount: provider.filteredContentList.length,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent:
                                    ResponsiveWidget.isDesktop(context)
                                        ? 500
                                        : 550,
                                mainAxisSpacing: 5,
                                crossAxisSpacing: 8,
                                childAspectRatio: 7 / 3,
                              ),
                            ),
                          ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildSearchSuggestionsSliver(
    BuildContext context,
    VideoProvider provider,
    Set<String> genres,
    Set<String> languages,
  ) {
    final query = provider.searchContentController.text.trim().toLowerCase();
    final suggestions = query.isEmpty
        ? <String>[
            ...genres.take(8),
            ...languages.take(4),
          ]
        : provider.filteredContentList
            .map((item) => item.title?.trim() ?? '')
            .where((title) => title.isNotEmpty)
            .take(12)
            .toList();

    if (suggestions.isEmpty) return const SliverToBoxAdapter();

    final theme = Theme.of(context);
    // Android TV: compact pill row aligned to the page gutter.
    final isAndroidTv = ResponsiveWidget.isAndroidTv(context);
    return SliverToBoxAdapter(
      child: SizedBox(
        height: isAndroidTv ? 44 : 58,
        child: ListView.separated(
          padding: isAndroidTv
              ? const EdgeInsets.symmetric(
                  horizontal: TvDesign.pageGutter,
                  vertical: 8,
                )
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => SizedBox(width: isAndroidTv ? 8 : 10),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            if (isAndroidTv) {
              return OttTvFocus(
                borderRadius: 14,
                scale: 1.05,
                semanticLabel: suggestion,
                onTap: () => _applySuggestion(provider, suggestion),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.canvasColor.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Text(
                    suggestion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.canvasColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }
            return OttTvFocus(
              borderRadius: 18,
              scale: 1.06,
              semanticLabel: suggestion,
              onTap: () => _applySuggestion(provider, suggestion),
              child: Chip(
                backgroundColor: theme.cardColor,
                side: BorderSide(color: theme.primaryColor.withOpacity(0.45)),
                label: Text(
                  suggestion,
                  style: TextStyle(
                    color: theme.canvasColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Puts a suggestion in the search box and runs the search (shared by the
  /// mobile/tablet chips and the Android TV pills).
  void _applySuggestion(VideoProvider provider, String suggestion) {
    provider.searchContentController.text = suggestion;
    provider.searchContentController.selection =
        TextSelection.collapsed(offset: suggestion.length);
    provider.searchContent();
  }

  // ===========================================================================
  // ANDROID TV LAYOUT
  // ===========================================================================

  /// Android TV: fixed header (title, search box, filter) above a scrolling
  /// area with the suggestion pills and a two-column grid of result cards.
  /// Uses the same controller, search, filter dialog and cards as the other
  /// layouts — only the presentation differs.
  Widget _buildAndroidTv(
    BuildContext context,
    VideoProvider provider,
    Set<String> genreSet,
    Set<String> languageSet,
    ThemeData theme,
    AppLocalizations lang,
  ) {
    final results = provider.filteredContentList;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TvDesign.pageGutter,
                12,
                TvDesign.pageGutter,
                0,
              ),
              child: _buildTvHeader(
                context,
                provider,
                genreSet,
                languageSet,
                theme,
                lang,
              ),
            ),
            Expanded(
              child: isLoading
                  ? const SearchShimmer()
                  : CustomScrollView(
                      slivers: [
                        _buildSearchSuggestionsSliver(
                          context,
                          provider,
                          genreSet,
                          languageSet,
                        ),
                        if (results.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                lang.noContentFound,
                                style: TextStyle(
                                  color: theme.canvasColor
                                      .withValues(alpha: 0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              TvDesign.pageGutter,
                              8,
                              TvDesign.pageGutter,
                              TvDesign.pageGutter,
                            ),
                            // Compact 16:9 landscape tiles, four per row
                            // (aligned columns, so Down lands in the next
                            // row).
                            sliver: SliverLayoutBuilder(
                              builder: (context, constraints) {
                                const columns = 4;
                                const gap = 12.0;
                                final tileWidth = (constraints.crossAxisExtent -
                                        gap * (columns - 1)) /
                                    columns;
                                return SliverGrid(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) =>
                                        SearchMovieCard(movie: results[index]),
                                    childCount: results.length,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisSpacing: gap + 4,
                                    crossAxisSpacing: gap,
                                    mainAxisExtent:
                                        tileWidth * 9 / 16 + _tvTileTextHeight,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTvHeader(
    BuildContext context,
    VideoProvider provider,
    Set<String> genreSet,
    Set<String> languageSet,
    ThemeData theme,
    AppLocalizations lang,
  ) {
    final activeFilters = [
      provider.selectedGenre,
      provider.selectedLanguage,
      provider.selectedRating,
    ].where((value) => value != null).length;

    void openFilters() => _showTvFilterDialog(
          context,
          provider,
          genreSet,
          languageSet,
          theme,
          lang,
        );

    final inputTheme = theme.copyWith(
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );

    return Row(
      children: [
        Text(lang.search, style: TvDesign.pageTitle(theme)),
        const SizedBox(width: 20),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              // Right at the end of the text moves on to Filter (a text
              // field otherwise keeps Left/Right for the caret).
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: (node, event) {
                  if (event is! KeyDownEvent ||
                      event.logicalKey != LogicalKeyboardKey.arrowRight ||
                      !_searchFocusNode.hasFocus) {
                    return KeyEventResult.ignored;
                  }
                  final value = provider.searchContentController.value;
                  final atEnd = !value.selection.isValid ||
                      (value.selection.isCollapsed &&
                          value.selection.baseOffset >= value.text.length);
                  if (!atEnd) return KeyEventResult.ignored;
                  _tvFilterFocusNode.requestFocus();
                  return KeyEventResult.handled;
                },
                child: Theme(
                  data: inputTheme,
                  child: CustomTextField(
                    controller: provider.searchContentController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    hintText: lang.searchContent,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    textInputType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (_) => provider.searchContent(),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OttTvFocus(
          focusNode: _tvFilterFocusNode,
          borderRadius: 18,
          scale: 1.05,
          semanticLabel: lang.filter,
          onTap: openFilters,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: activeFilters > 0 ? theme.primaryColor : theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.canvasColor.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_list,
                  size: 16,
                  color: activeFilters > 0 ? Colors.white : theme.canvasColor,
                ),
                const SizedBox(width: 6),
                Text(
                  activeFilters > 0
                      ? '${lang.filter} ($activeFilters)'
                      : lang.filter,
                  style: TextStyle(
                    color:
                        activeFilters > 0 ? Colors.white : theme.canvasColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showTvFilterDialog(
    BuildContext context,
    VideoProvider provider,
    Set<String> genreSet,
    Set<String> languageSet,
    ThemeData selectedThemeData,
    AppLocalizations lang,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: selectedThemeData.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.filterOptions,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selectedThemeData.primaryColor,
                    ),
                  ),
                  OttTvFocus(
                    borderRadius: 12,
                    scale: 1.05,
                    semanticLabel: "Close filters",
                    onTap: () => Navigator.pop(dialogContext),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.genre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: genreSet.map((genre) {
                          final isSelected = provider.selectedGenre == genre;
                          return OttTvFocus(
                            borderRadius: 16,
                            scale: 1.04,
                            semanticLabel: genre,
                            onTap: () {
                              setDialogState(() {
                                provider.selectedGenre =
                                    isSelected ? null : genre;
                              });
                              provider.applyFilter(
                                provider.selectedGenre,
                                provider.selectedLanguage,
                                provider.selectedRating,
                              );
                            },
                            child: FilterChip(
                              selected: isSelected,
                              label: Text(genre),
                              selectedColor: selectedThemeData.primaryColor,
                              onSelected: (_) {
                                setDialogState(() {
                                  provider.selectedGenre =
                                      isSelected ? null : genre;
                                });
                                provider.applyFilter(
                                  provider.selectedGenre,
                                  provider.selectedLanguage,
                                  provider.selectedRating,
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang.language,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: languageSet.map((language) {
                          final isSelected =
                              provider.selectedLanguage == language;
                          return OttTvFocus(
                            borderRadius: 16,
                            scale: 1.04,
                            semanticLabel: language,
                            onTap: () {
                              setDialogState(() {
                                provider.selectedLanguage =
                                    isSelected ? null : language;
                              });
                              provider.applyFilter(
                                provider.selectedGenre,
                                provider.selectedLanguage,
                                provider.selectedRating,
                              );
                            },
                            child: FilterChip(
                              selected: isSelected,
                              label: Text(language),
                              selectedColor: selectedThemeData.primaryColor,
                              onSelected: (_) {
                                setDialogState(() {
                                  provider.selectedLanguage =
                                      isSelected ? null : language;
                                });
                                provider.applyFilter(
                                  provider.selectedGenre,
                                  provider.selectedLanguage,
                                  provider.selectedRating,
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang.minimumRating,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [3.0, 4.0, 4.5, 5.0].map((rating) {
                          final isSelected =
                              provider.selectedRating == rating;
                          return OttTvFocus(
                            borderRadius: 16,
                            scale: 1.04,
                            semanticLabel: "$rating+ rating",
                            onTap: () {
                              setDialogState(() {
                                provider.selectedRating =
                                    isSelected ? null : rating;
                              });
                              provider.applyFilter(
                                provider.selectedGenre,
                                provider.selectedLanguage,
                                provider.selectedRating,
                              );
                            },
                            child: FilterChip(
                              selected: isSelected,
                              label: Text("$rating+"),
                              selectedColor: selectedThemeData.primaryColor,
                              onSelected: (_) {
                                setDialogState(() {
                                  provider.selectedRating =
                                      isSelected ? null : rating;
                                });
                                provider.applyFilter(
                                  provider.selectedGenre,
                                  provider.selectedLanguage,
                                  provider.selectedRating,
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                OttTvFocus(
                  borderRadius: 10,
                  scale: 1.05,
                  semanticLabel: lang.clearFilter,
                  onTap: () {
                    provider.clearFilters();
                    setDialogState(() {});
                  },
                  child: TextButton(
                    onPressed: () {
                      provider.clearFilters();
                      setDialogState(() {});
                    },
                    child: Text(
                      lang.clearFilter,
                      style:
                          TextStyle(color: selectedThemeData.primaryColor),
                    ),
                  ),
                ),
                OttTvFocus(
                  borderRadius: 10,
                  scale: 1.05,
                  semanticLabel: "Done",
                  onTap: () => Navigator.pop(dialogContext),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedThemeData.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text("Done"),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Android TV: height of the text block under a search tile's 16:9 image.
/// (Sized for three lines incl. taller Devanagari glyphs.)
const double _tvTileTextHeight = 70;

class SearchMovieCard extends StatefulWidget {
  final Content movie;

  const SearchMovieCard({
    super.key,
    required this.movie,
  });

  @override
  State<SearchMovieCard> createState() => _SearchMovieCardState();
}

class _SearchMovieCardState extends State<SearchMovieCard> {
  bool _isLoadingCast = false;
  List<CastMember> _apiCastAndCrew = [];

  Content get movie => widget.movie;

  @override
  void initState() {
    super.initState();
    _loadCastAndCrew();
  }

  @override
  void didUpdateWidget(covariant SearchMovieCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movie.id != widget.movie.id) {
      _loadCastAndCrew();
    }
  }

  Future<void> _loadCastAndCrew() async {
    final contentId = widget.movie.id;
    if (contentId == null) return;

    setState(() {
      _isLoadingCast = true;
      _apiCastAndCrew = [];
    });

    try {
      final response =
          await ApiHelper().getApi(ApiConstant.getCastByContentId(contentId));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final responseData =
            responseBody is Map<String, dynamic> ? responseBody['data'] : null;
        final castData =
            responseData is Map<String, dynamic> ? responseData['cast'] : null;

        setState(() {
          _apiCastAndCrew = castData is! List
              ? []
              : castData
                  .whereType<Map<String, dynamic>>()
                  .map(CastMember.fromJson)
                  .toList();
        });
      }
    } catch (error) {
      debugPrint('Search cast fetch error: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoadingCast = false);
      }
    }
  }

  List<CastMember> get _castList {
    final apiCast = _apiCastAndCrew.where(_isCastMember).toList();
    if (apiCast.isNotEmpty) return apiCast;

    return (movie.castList ?? const [])
        .where((name) => name.trim().isNotEmpty)
        .map((name) => CastMember(name: name.trim(), role: 'Cast'))
        .toList();
  }

  List<CastMember> get _crewList {
    final apiCrew =
        _apiCastAndCrew.where((member) => !_isCastMember(member)).toList();
    if (apiCrew.isNotEmpty) return apiCrew;

    return (movie.directorList ?? const [])
        .where((name) => name.trim().isNotEmpty)
        .map((name) => CastMember(name: name.trim(), role: 'Director'))
        .toList();
  }

  bool _isCastMember(CastMember member) {
    final role = member.role?.toLowerCase().trim() ?? '';
    if (role.isEmpty) return true;

    const castRoles = {
      'actor',
      'actress',
      'cast',
      'lead actor',
      'lead actress',
      'supporting actor',
      'supporting actress',
      'artist',
      'character',
    };

    return castRoles.any(role.contains);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    final theme = themeProvider.getTheme;

    if (ResponsiveWidget.isAndroidTv(context)) {
      return _buildTvCard(context, theme);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        void openDetails() => _openDetails(context);

        final card = Card(
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  height: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FilmytellPosterImage(
                      posterUrl: movie.posterUrlList != null &&
                              movie.posterUrlList!.isNotEmpty
                          ? movie.posterUrlList![0]
                          : null,
                      width: 100,
                      height: 140,
                      fallbackIconSize: 30,
                      fallbackIcon: Icons.movie,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          TextSpan(
                              style: TextStyle(
                                color: theme.canvasColor.withOpacity(0.7),
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: ' ${movie.ratings ?? '-'}',
                                  style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontWeight: FontWeight.w600),
                                ),
                                TextSpan(
                                  text: ' | ',
                                  style: TextStyle(
                                    color: theme.canvasColor.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: (movie.genreList != null &&
                                          movie.genreList!.isNotEmpty)
                                      ? movie.genreList!.join(', ')
                                      : 'N/A',
                                )
                              ]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          movie.title ?? 'No Title',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.canvasColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text.rich(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          TextSpan(
                              style: TextStyle(
                                color: theme.canvasColor.withOpacity(0.7),
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Director: ',
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: _memberNames(_crewList))
                              ]),
                        ),
                        const SizedBox(height: 1),
                        Text.rich(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          TextSpan(
                              style: TextStyle(
                                color: theme.canvasColor.withOpacity(0.7),
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Cast: ',
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: _memberNames(_castList))
                              ]),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          TextSpan(
                              style: TextStyle(
                                color: theme.canvasColor.withOpacity(0.7),
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: formatReleaseDate(movie.releaseDate),
                                  style: TextStyle(
                                    color: theme.canvasColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: ' | ',
                                  style: TextStyle(
                                    color: theme.canvasColor.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: movie.description ?? '',
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: 12,
                                    color: theme.canvasColor.withOpacity(0.7),
                                  ),
                                )
                              ]),
                        ),
                        const SizedBox(height: 4),
                        _buildPeopleSection(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (ResponsiveWidget.isMobile(context)) {
          return GestureDetector(onTap: openDetails, child: card);
        }

        return OttTvFocus(
          onTap: openDetails,
          borderRadius: 12,
          scale: 1.025,
          child: card,
        );
      },
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentType.isMovieLike(movie.type)
            ? MovieDetailsPage(
                movieId: movie.id!,
                contentType: movie.type,
              )
            : SeriesDetailsPage(
                seriesId: movie.id!,
                content: movie,
              ),
      ),
    );
  }

  /// Android TV: the same horizontal card (the grid keeps its 7:3 size) with
  /// a 16:9 cover image on the left and compact, ellipsized details.
  Widget _buildTvCard(BuildContext context, ThemeData theme) {
    final muted = theme.canvasColor.withValues(alpha: 0.68);
    final bodyStyle = TextStyle(color: muted, fontSize: 10.5, height: 1.3);
    final labelStyle = TextStyle(
      color: theme.primaryColor,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
    final posterUrl =
        movie.posterUrlList != null && movie.posterUrlList!.isNotEmpty
            ? movie.posterUrlList![0]
            : null;

    return OttTvFocus(
      onTap: () => _openDetails(context),
      borderRadius: TvDesign.cardRadius,
      scale: TvDesign.cardFocusScale,
      semanticLabel: movie.title,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(TvDesign.cardRadius),
          border: Border.all(
            color: theme.canvasColor.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: TvDesign.imageAspectRatio,
              child: FilmytellPosterImage(
                posterUrl: posterUrl,
                fit: BoxFit.cover,
                fallbackIconSize: 28,
                fallbackIcon: Icons.movie,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      movie.title ?? 'No Title',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.canvasColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      TextSpan(
                        style: TvDesign.caption(theme),
                        children: [
                          TextSpan(
                            text: '★ ${movie.ratings ?? '-'}',
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: '  |  '),
                          TextSpan(
                            text: (movie.genreList != null &&
                                    movie.genreList!.isNotEmpty)
                                ? movie.genreList!.join(', ')
                                : 'N/A',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text.rich(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      TextSpan(
                        style: bodyStyle,
                        children: [
                          TextSpan(text: 'Dir: ', style: labelStyle),
                          TextSpan(text: _memberNames(_crewList)),
                          TextSpan(text: '   Cast: ', style: labelStyle),
                          TextSpan(text: _memberNames(_castList)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _memberNames(List<CastMember> members) {
    final names = members
        .map((member) => member.name?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    return names.isEmpty ? 'N/A' : names.join(', ');
  }

  Widget _buildPeopleSection(BuildContext context) {
    final cast = _castList;
    final crew = _crewList;

    if (_isLoadingCast && cast.isEmpty && crew.isEmpty) {
      return const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (cast.isEmpty && crew.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cast.isNotEmpty) _buildPeopleChips(context, 'Cast', cast),
        if (cast.isNotEmpty && crew.isNotEmpty) const SizedBox(height: 4),
        if (crew.isNotEmpty) _buildPeopleChips(context, 'Crew', crew),
      ],
    );
  }

  Widget _buildPeopleChips(
    BuildContext context,
    String label,
    List<CastMember> members,
  ) {
    final theme = Theme.of(context);
    final visibleMembers = members.take(4).toList();
    // Android TV: slimmer chip row so the card keeps its size.
    final isAndroidTv = ResponsiveWidget.isAndroidTv(context);

    return SizedBox(
      height: isAndroidTv ? 22 : 28,
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: isAndroidTv ? 10.5 : 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleMembers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                return _buildPersonChip(context, visibleMembers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonChip(BuildContext context, CastMember member) {
    final theme = Theme.of(context);
    final name = member.name?.trim() ?? 'N/A';
    final role = member.role?.trim() ?? '';
    final isAndroidTv = ResponsiveWidget.isAndroidTv(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: isAndroidTv
          ? const EdgeInsets.symmetric(horizontal: 7, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.canvasColor.withOpacity(0.12)),
      ),
      child: Text(
        role.isEmpty ? name : '$name ($role)',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: theme.canvasColor.withOpacity(0.78),
          fontSize: isAndroidTv ? 10 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
