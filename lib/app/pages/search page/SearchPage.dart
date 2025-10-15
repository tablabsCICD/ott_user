import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/movie%20details%20page/MovieDetailsPage.dart';
import 'package:ott/app/provider/ThemeProvider.dart';
import 'package:ott/app/provider/videoProvider.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/app/widgets/shimmer%20loader/search_shimmer.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/repositories/demo.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      Provider.of<VideoProvider>(context, listen: false).searchContent();
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    final selectedThemeData = themeProvider.getTheme;
    final lang = AppLocalizations.of(context)!;

    final movies = featuredContent["movies"];
    final genreSet = {
      for (var movie in movies)
        ...List<String>.from([
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
          'Crime'
        ])
    };
    final languageSet = {
      for (var movie in movies) movie['language'].toString()
    };

    return Consumer<VideoProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: selectedThemeData.scaffoldBackgroundColor,
          appBar: AppBar(
            toolbarHeight: 80,
            backgroundColor: ResponsiveWidget.isDesktop(context)
                ? selectedThemeData.scaffoldBackgroundColor
                : selectedThemeData.primaryColor,
            forceMaterialTransparency:
                ResponsiveWidget.isDesktop(context) ? true : false,
            title: Row(
              children: [
                ResponsiveWidget.isMobile(context)
                    ? Padding(
                        padding: EdgeInsets.only(
                            top: 1,
                            bottom: 1,
                            left: ResponsiveWidget.isTablet(context) ? 30 : 5),
                        child: SizedBox(
                          width: 40,
                          child: Image.asset(ImageConstant.logo2),
                        ),
                      )
                    : SizedBox(),
                const Spacer(),
                SizedBox(
                  width: ResponsiveWidget.isDesktop(context)
                      ? 500
                      : ResponsiveWidget.isTablet(context)
                          ? 400
                          : 250,
                  child: CustomTextField(
                    controller: provider.searchContentController,
                    hintText: lang.searchContent,
                    prefixIcon: const Icon(Icons.search),
                    textInputType: TextInputType.text,
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                      color: selectedThemeData.cardColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(22)),
                  child: Row(
                    children: [
                      ResponsiveWidget.isMobile(context)
                          ? SizedBox()
                          : Padding(
                              padding: EdgeInsets.only(
                                left: 10,
                              ),
                              child: Text(
                                lang.filter,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      PopupMenuButton(
                        color: selectedThemeData.cardColor,
                        tooltip: lang.filter,
                        icon:
                            const Icon(Icons.filter_list, color: Colors.white),
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
                                      dropdownColor:
                                          selectedThemeData.cardColor,
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
                                          .map((genre) =>
                                              DropdownMenuItem<String>(
                                                value: genre,
                                                child: Text(genre),
                                              ))
                                          .toList(),
                                    ),
                                    Text(lang.language),
                                    DropdownButton<String>(
                                      dropdownColor:
                                          selectedThemeData.cardColor,
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
                                          .map((language) =>
                                              DropdownMenuItem<String>(
                                                value: language,
                                                child: Text(language),
                                              ))
                                          .toList(),
                                    ),
                                    Text(lang.minimumRating),
                                    DropdownButton<double>(
                                      dropdownColor:
                                          selectedThemeData.cardColor,
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
                                          .map((rating) =>
                                              DropdownMenuItem<double>(
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
                                            color:
                                                selectedThemeData.primaryColor,
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
              ],
            ),
          ),
          // Inside _SearchPageState's build method where `body:` is assigned:
          body: isLoading
              ? SearchShimmer()
              : provider.filteredContentList.isEmpty
                  ? Center(
                      child: Text(
                        lang.noContentFound,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    )
                  : ResponsiveWidget.isMobile(context)
                      ? ListView.builder(
                          itemCount: provider.filteredContentList.length,
                          itemBuilder: (context, index) {
                            final movie = provider.filteredContentList[index];
                            return SearchMovieCard(movie: movie);
                          },
                        )
                      : CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.all(8.0),
                              sliver: SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final movie =
                                        provider.filteredContentList[index];
                                    return SearchMovieCard(movie: movie);
                                  },
                                  childCount:
                                      provider.filteredContentList.length,
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
}

class SearchMovieCard extends StatelessWidget {
  final Content movie;

  const SearchMovieCard({
    super.key,
    required this.movie,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    final theme = themeProvider.getTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailsPage(movieId: movie.id!),
              ),
            );
          },
          child: Card(
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
                  ClipRRect(
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
                                size: 100,
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
                            maxLines: 1,
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
                                  TextSpan(
                                    text: (movie.directorList != null &&
                                            movie.directorList!.isNotEmpty)
                                        ? movie.directorList!.join(', ')
                                        : 'N/A',
                                  )
                                ]),
                          ),
                          const SizedBox(height: 1),
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
                                    text: 'Cast: ',
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: (movie.castList != null &&
                                            movie.castList!.isNotEmpty)
                                        ? movie.castList!.join(', ')
                                        : 'N/A',
                                  )
                                ]),
                          ),
                          const SizedBox(height: 1),
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
          ),
        );
      },
    );
  }
}
