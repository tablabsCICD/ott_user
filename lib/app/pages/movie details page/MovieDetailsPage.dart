import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/movie%20details%20page/component/AutoScrollingPosters.dart';
import 'package:ott/app/pages/DisplayTrailer.dart';
import 'package:ott/app/pages/wallet%20page/BillingPage.dart';
import 'package:ott/app/pages/movie%20details%20page/component/actionButtonWidget.dart';
import 'package:ott/app/provider/ThemeProvider.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/videoProvider.dart';
import 'package:ott/app/widgets/StarRatingWidget.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/response/getContentResponse.dart';
import 'package:ott/data/repositories/demo.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../widgets/show_toast.dart';
import '../watchlist page/playMoviePage.dart';
import 'component/displayStar.dart';
import 'component/starRating.dart';

class MovieDetailsPage extends StatefulWidget {
  final int movieId;
  const MovieDetailsPage({super.key, required this.movieId});

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> _fetchData() async {
    await Provider.of<DashboardProvider>(context, listen: false)
        .getContentById(widget.movieId);
    await Provider.of<VideoProvider>(context, listen: false)
        .getRatingReview(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    var selectedThemeData =
        Provider.of<ThemeProvider>(context, listen: true).getTheme;

    Content? movieContent =
        Provider.of<DashboardProvider>(context, listen: true).content;

    if (movieContent == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Movie Details'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),
        body: const Center(
          child: Text('Movie not found.'),
        ),
      );
    }

    final controller = YoutubePlayerController(
      initialVideoId:
          YoutubePlayer.convertUrlToId(movieContent.trailerUrl ?? '') ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: true,
      ),
    );

    return isLoading
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : Scaffold(
            backgroundColor: selectedThemeData.scaffoldBackgroundColor,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              forceMaterialTransparency: true,
              title: ResponsiveWidget.isDesktop(context)
                  ? const Text('')
                  : Text(
                      Provider.of<DashboardProvider>(context).content.title ??
                          "",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: selectedThemeData.primaryColor,
                      ),
                    ),
              backgroundColor: Colors.transparent,
              centerTitle: true,
              elevation: 0,
            ),
            body: Consumer<DashboardProvider>(
              builder: (context, provider, child) {
                final content = provider.content;

                if (content == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ResponsiveWidget.isDesktop(context)
                    ? _buildDesktopView(content, selectedThemeData, controller)
                    : _buildMobileView(content, selectedThemeData, controller);
              },
            ),
          );
  }

  Widget _buildDesktopView(Content content, ThemeData selectedThemeData,
      YoutubePlayerController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackground(
          content.posterUrlList != null && content.posterUrlList!.isNotEmpty
              ? content.posterUrlList![0]
              : null,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 10,
                              right: 10,
                              top: 6,
                              bottom: 6,
                            ),
                            child: Text(
                              content.title ?? "",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: selectedThemeData.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StarRatingWidget(
                          rating: content.ratings ?? 0.0,
                          starSize: 20,
                          textSize: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${content.ratingCount ?? '0'} reviews)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const Spacer(),
                        _ageRating(content.ageRating ?? ""),
                      ],
                    ),
                    const SizedBox(height: 10),
                    (content.posterUrlList != null &&
                            content.posterUrlList!.isNotEmpty)
                        ? Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  width: 300,
                                  child: AutoScrollingPosters(
                                    imageUrls: [
                                      if (content.posterUrlList != null &&
                                          content.posterUrlList!.isNotEmpty)
                                        content.posterUrlList!.length > 0
                                            ? content.posterUrlList![0]
                                            : "",
                                      if (content.posterUrlList!.length > 1)
                                        content.posterUrlList![1],
                                      if (content.posterUrlList!.length > 2)
                                        content.posterUrlList![2],
                                    ],
                                    height: 300,
                                    aspectRatio: 2 / 3,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SizedBox.shrink(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildButtons(context, content),
                        _buildGifting(context, content),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "  ${content.description ?? 'N/A'}",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailsSection(context, content),
                    const SizedBox(height: 16),
                    content.isRental == true
                        ? _buildRatingReviewSection(context, content)
                        : SizedBox.shrink(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        height: 400,
                        child: TrailerPage(
                          trailerUrl: content.trailerUrl,
                          isTrailerUrl: true,
                          content: content,
                        ),
                      ),
                    ],
                  ),
                ))
          ],
        ),
      ],
    );
  }

  Widget _buildMobileView(Content content, ThemeData selectedThemeData,
      YoutubePlayerController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackground(content.posterUrlList![0]),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 100),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StarRatingWidget(
                    rating: content.ratings ?? 0.0,
                    starSize: 20,
                    textSize: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${content.ratingCount ?? '0'} reviews)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  Spacer(),
                  _ageRating(content.ageRating ?? ""),
                ],
              ),
              SizedBox(height: 10),
              (content.posterUrlList != null &&
                      content.posterUrlList!.isNotEmpty)
                  ? Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            width: 300,
                            child: AutoScrollingPosters(
                              imageUrls: [
                                if (content.posterUrlList != null &&
                                    content.posterUrlList!.isNotEmpty)
                                  content.posterUrlList!.length > 0
                                      ? content.posterUrlList![0]
                                      : "",
                                if (content.posterUrlList!.length > 1)
                                  content.posterUrlList![1],
                                if (content.posterUrlList!.length > 2)
                                  content.posterUrlList![2],
                              ],
                              height: 300,
                              aspectRatio: 2 / 3,
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox.shrink(),
              const SizedBox(height: 16),
              _buildButtons(context, content),
              const SizedBox(height: 8),
              _buildGifting(context, content),
              const SizedBox(height: 16),
              Text(
                "  ${content.description ?? 'N/A'}",
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailsSection(context, content),
              const SizedBox(height: 16),
              content.isRental == true
                  ? _buildRatingReviewSection(context, content)
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackground(String? imageUrl) {
    return imageUrl != null && imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.grey),
          )
        : Container(color: Colors.black);
  }

  Widget _ageRating(String? ageRating) {
    return ageRating != null && ageRating.isNotEmpty
        ? Tooltip(
            preferBelow: false,
            showDuration: const Duration(seconds: 2),
            waitDuration: const Duration(seconds: 1),
            message: ageRating == 'U'
                ? 'Universal Age'
                : ageRating == 'U/A'
                    ? 'Parental Guidance'
                    : 'Adults Only',
            child: Image.asset(
              height: 40,
              width: 60,
              ageRating == 'U'
                  ? ImageConstant.ageUniversal
                  : ageRating == 'U/A'
                      ? ImageConstant.ageParentalGuidance
                      : ImageConstant.ageAdultsOnly,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.grey),
            ),
          )
        : Container(color: Colors.black);
  }

  Widget _buildGifting(BuildContext context, Content movie) {
    final theme = Theme.of(context);
    final TextEditingController _countController = TextEditingController();

    return Center(
      child: ActionButtonWidget(
        label: 'Gift This Movie',
        icon: LucideIcons.gift,
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return Dialog(
                backgroundColor: theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: ResponsiveWidget.isMobile(context)
                        ? double.infinity
                        : 400,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 1,
                          left: 1,
                          right: 1,
                          bottom: 1,
                          child: Icon(
                            LucideIcons.gift,
                            size: 200,
                            color: theme.canvasColor.withOpacity(0.1),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Icon(LucideIcons.gift,
                                    color: theme.primaryColor, size: 28),
                                const SizedBox(width: 10),
                                Text(
                                  "Gift This Movie",
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Description
                            Text(
                              "Enter how many people you’d like to gift this movie to.",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.canvasColor,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Input field
                            CustomTextField(
                              backgroundColor: theme.scaffoldBackgroundColor,
                              isDigits: true,
                              controller: _countController,
                              hintText: "Number of recipients",
                              textInputType: TextInputType.number,
                            ),
                            const SizedBox(height: 24),

                            // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(color: theme.canvasColor),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: () {
                                    final count =
                                        int.tryParse(_countController.text);
                                    if (count == null || count <= 0) {
                                      CustomToast.show(
                                          context, 'Please enter valid number',
                                          isSuccess: false);
                                      return;
                                    }

                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BillingPage(
                                          movie: movie,
                                          giftCount: count,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Continue",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildButtons(BuildContext context, Content movie) {
    final lang = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ResponsiveWidget.isDesktop(context)
            ? SizedBox()
            : ActionButtonWidget(
                label: lang.watchTrailer,
                icon: Icons.play_circle_fill,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrailerPage(
                        trailerUrl: movie.trailerUrl ?? '',
                        isTrailerUrl: true,
                        content: movie,
                      ),
                    ),
                  );
                },
              ),
        const SizedBox(width: 20),
        movie.isRental == false
            ? ActionButtonWidget(
                label: '${lang.rent} ₹${movie.price}',
                icon: Icons.movie,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return _buildConfirmationBox(context, movie);
                    },
                  );
                },
              )
            : ActionButtonWidget(
                label: movie.type!.toLowerCase() == "movie"
                    ? lang.watchMovie
                    : lang.watchSeries,
                icon: Icons.play_circle_fill,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayMoviePage(
                        movieId: movie.id!,
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildConfirmationBox(BuildContext context, Content movie) {
    var selectedThemeData =
        Provider.of<ThemeProvider>(context, listen: true).getTheme;
    final lang = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: selectedThemeData.cardColor,
      title: Center(
        child: Text(
          movie.title ?? "",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color:
                selectedThemeData.primaryColor, // Apply text color from theme
          ),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${lang.price}: ₹${movie.price ?? 0.0}',
            style: TextStyle(
              fontSize: 14,
              color: selectedThemeData.secondaryHeaderColor, // Theme text color
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${lang.rentDuration}: ${movie.rentlDuration ?? ''}',
            style: TextStyle(
              fontSize: 14,
              color: selectedThemeData.secondaryHeaderColor, // Theme text color
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Do you want to rent this ${movie.type}?',
            style: TextStyle(
              fontSize: 14,
              color: selectedThemeData.primaryColor, // Theme text color
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: selectedThemeData.cardColor,
            foregroundColor: selectedThemeData.canvasColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text(lang.cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: selectedThemeData.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BillingPage(
                  movie: movie,
                ),
              ),
            );
          },
          child: Text("Continue"),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context, Content movie) {
    final lang = AppLocalizations.of(context)!;
    TextStyle titleStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );
    TextStyle contentStyle = const TextStyle(
      color: Colors.white70,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(),
        },
        border: TableBorder.symmetric(
          inside: BorderSide(color: Colors.white12, width: 0.5),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          _buildTableRow(
              lang.director,
              (movie.directorList != null && movie.directorList!.isNotEmpty)
                  ? movie.directorList!.first
                  : 'Unknown',
              titleStyle,
              contentStyle),
          _buildTableRow(
              lang.cast,
              (movie.castList != null && movie.castList!.isNotEmpty)
                  ? movie.castList!.join(', ')
                  : 'N/A',
              titleStyle,
              contentStyle),
          _buildTableRow(
              lang.genres,
              (movie.genreList != null && movie.genreList!.isNotEmpty)
                  ? movie.genreList!.join(', ')
                  : 'N/A',
              titleStyle,
              contentStyle),
          _buildTableRow(lang.runtime, movie.runtime?.toString() ?? 'N/A',
              titleStyle, contentStyle),
          _buildTableRow(lang.price, movie.price?.toString() ?? 'N/A',
              titleStyle, contentStyle),
          _buildTableRow(
              lang.rentDuration,
              movie.rentlDuration?.toString() ?? 'N/A',
              titleStyle,
              contentStyle),
          _buildTableRow(
              lang.mediaHouse,
              movie.mediaHouseName?.toString() ?? 'N/A',
              titleStyle,
              contentStyle),
          _buildTableRow(lang.releaseDate, movie.releaseDate ?? 'N/A',
              titleStyle, contentStyle),
          _buildTableRow(lang.languages, (movie.languageList ?? []).join(', '),
              titleStyle, contentStyle),
          _buildTableRow(lang.rating, '${movie.ratings ?? 0.0} ⭐', titleStyle,
              contentStyle),
          _buildTableRow(
              lang.audioFormat,
              (movie.audioFormatList ?? []).join(', '),
              titleStyle,
              contentStyle),
          _buildTableRow(
              lang.subtitle,
              (movie.subtitleLanguageList ?? []).join(', '),
              titleStyle,
              contentStyle),
          _buildTableRow(lang.ageRating, movie.ageRating ?? 'N/A', titleStyle,
              contentStyle),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String title, String content, TextStyle titleStyle,
      TextStyle contentStyle) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text('$title:', style: titleStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text(content, style: contentStyle),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        '$title:  $content',
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  _buildRatingReviewSection(BuildContext context, Content content) {
    var selectedThemeData =
        Provider.of<ThemeProvider>(context, listen: true).getTheme;
    return Consumer<VideoProvider>(
      builder: (context, provider, child) => Column(
        children: [
          Text(
            "Rate your experience with ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          StarRating(
            rating: provider.rating,
            onRatingChanged: (rating) =>
                setState(() => provider.rating = rating),
          ),
          SizedBox(
            height: 7,
          ),
          Container(
            height: 90,
            margin: EdgeInsets.all(10.0),
            padding: EdgeInsets.only(bottom: 16.0),
            child: TextField(
              maxLines: 9,
              controller: provider.reviewController,
              decoration: InputDecoration(
                hintText: "Your Feedback!",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            height: 7,
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedThemeData.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () async {
              if (provider.reviewController.text.isNotEmpty) {
                if (provider.rating == 0) {
                  CustomToast.show(context, "Please select rating..",
                      isSuccess: false);
                } else {
                  var result = await provider.saveRatingReview(content.id!);
                  if (result['success'] == false) {
                    CustomToast.show(
                        context, "something went wrong to submit review",
                        isSuccess: false);
                  } else {
                    CustomToast.show(context, 'review submitted successfully',
                        isSuccess: true);

                    await provider.getRatingReview(content.id!);
                  }
                }
              } else {
                CustomToast.show(context, "Please give some comments",
                    isSuccess: false);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text("Submit Review"),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              getChatList(),
            ],
          ),
        ],
      ),
    );
  }

  getChatList() {
    return Consumer<VideoProvider>(
      builder: (context, provider, child) => Expanded(
        child: ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: provider.reviewList.length,
            itemBuilder: (BuildContext context, int index) {
              DateTime date = DateTime.now();
              if (provider.reviewList[index].createdAt != null) {
                date = DateTime.fromMillisecondsSinceEpoch(
                    provider.reviewList[index].createdAt!);
              }
              String formattedDate =
                  DateFormat('yyyy-MM-dd HH:mm:ss').format(date);

              return Container(
                margin: EdgeInsets.symmetric(vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: CircleAvatar(
                            backgroundImage:
                                provider.reviewList[index].userProfile != null
                                    ? NetworkImage(
                                        provider.reviewList[index].userProfile!)
                                    : null,
                            radius: 50,
                            child:
                                provider.reviewList[index].userProfile == null
                                    ? Icon(Icons.person, size: 25)
                                    : null,
                          ),
                        ),
                        SizedBox(
                          width: 15,
                        ),
                        Text(provider.reviewList[index].username ?? 'NA',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15))
                      ],
                    ),
                    Row(
                      children: [
                        StarDisplay(
                            value: provider.reviewList[index].rating ?? 5),
                        SizedBox(
                          width: 10,
                        ),
                        Text(formattedDate,
                            style: TextStyle(
                                fontWeight: FontWeight.normal, fontSize: 12))
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(provider.reviewList[index].title.toString(),
                        style: TextStyle(
                            fontWeight: FontWeight.normal, fontSize: 12)),
                    SizedBox(
                      height: 10,
                    ),
                    Divider(
                      thickness: 2,
                    )
                  ],
                ),
              );
            }),
      ),
    );
  }
}
