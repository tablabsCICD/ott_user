import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/pages/movie%20details%20page/MovieDetailsPage.dart';
import 'package:ott/app/pages/series%20details%20page/seriesdetailspage.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/provider/videoProvider.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/app/widgets/shimmer%20loader/search_shimmer.dart';
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
  final FocusNode _searchFocusNode =
      FocusNode(debugLabel: 'search-field');

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
              ? SearchShimmer()
              : ResponsiveWidget.isMobile(context)
                  ? provider.filteredContentList.isEmpty
                      ? Center(
                          child: Text(
                            lang.noContentFound,
                            style: TextStyle(
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
                                style: TextStyle(
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
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 58,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return OttTvFocus(
              borderRadius: 18,
              scale: 1.06,
              semanticLabel: suggestion,
              onTap: () {
                provider.searchContentController.text = suggestion;
                provider.searchContentController.selection =
                    TextSelection.collapsed(offset: suggestion.length);
                provider.searchContent();
              },
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

    return LayoutBuilder(
      builder: (context, constraints) {
        void openDetails() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => movie.type!.toLowerCase() == 'movie'
                  ? MovieDetailsPage(
                      movieId: movie.id!,
                    )
                  : SeriesDetailsPage(
                      seriesId: movie.id!,
                      content: movie,
                    ),
            ),
          );
        }

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
                    child: movie.posterUrlList != null &&
                            movie.posterUrlList!.isNotEmpty
                        ? Image.network(
                            movie.posterUrlList![0],
                            width: 100,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.broken_image,
                                size: 30,
                                color: Colors.grey),
                          )
                        : Container(
                            width: 100,
                            height: 140,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.movie,
                              size: 60,
                              color: Colors.grey[600],
                            ),
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
                                  style: TextStyle(
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
                                  text: movie.releaseDate ?? '',
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

  String _memberNames(List<CastMember> members) {
    final names = members
        .map((member) => member.name?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    return names.isEmpty ? 'N/A' : names.join(', ');
  }
}
