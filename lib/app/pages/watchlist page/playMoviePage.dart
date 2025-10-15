import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/movie%20details%20page/component/AutoScrollingPosters.dart';
import 'package:ott/app/pages/DisplayTrailer.dart';
import 'package:ott/app/pages/wallet%20page/BillingPage.dart';
import 'package:ott/app/pages/movie%20details%20page/component/actionButtonWidget.dart';
import 'package:ott/app/provider/ThemeProvider.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/videoProvider.dart';
import 'package:ott/app/widgets/StarRatingWidget.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/response/getContentResponse.dart';
import 'package:ott/data/repositories/demo.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../widgets/show_toast.dart';
import '../movie details page/component/displayStar.dart';
import '../movie details page/component/starRating.dart';

class PlayMoviePage extends StatefulWidget {
  final int movieId;

  const PlayMoviePage({super.key, required this.movieId});

  @override
  State<PlayMoviePage> createState() => _PlayMoviePageState();
}

class _PlayMoviePageState extends State<PlayMoviePage> {
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
          YoutubePlayer.convertUrlToId(movieContent.contentUrl ?? '') ?? '',
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
              title: ResponsiveWidget.isDesktop(context)
                  ? const Text('')
                  : Text(
                      /* movieContent.title ?? */
                      'Movie Details',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
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
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
              height: 750,
              child: TrailerPage(
                trailerUrl: content.contentUrl ?? '',
                isTrailerUrl: false,
                content: content,
              )),
          Column(
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
              Text(
                content.description ?? 'N/A',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // _buildButtons(context, content),
              //   const SizedBox(height: 16),
              const SizedBox(height: 16),
              _buildDetailsSection(context, content),
              const SizedBox(height: 16),
              _buildRatingReviewSection(context, content),
            ],
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildMobileView(Content content, ThemeData selectedThemeData,
      YoutubePlayerController controller) {
    return Column(
      children: [
        SizedBox(
            height: 450,
            child: TrailerPage(
              trailerUrl: content.contentUrl ?? '',
              isTrailerUrl: false,
              content: content,
            )),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  content.description ?? 'N/A',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                //  _buildButtons(context, content),
                const SizedBox(height: 16),
                _buildDetailsSection(context, content),
                const SizedBox(height: 16),
                _buildRatingReviewSection(context, content),
              ],
            ),
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

  Widget _buildButtons(BuildContext context, Content movie) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ResponsiveWidget.isDesktop(context)
            ? SizedBox()
            : ActionButtonWidget(
                label: 'Watch Trailer',
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
        ActionButtonWidget(
          label: 'Rent ₹${movie.price}',
          icon: Icons.shopping_cart,
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return _buildConfirmationBox(context, movie);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildConfirmationBox(BuildContext context, Content movie) {
    var selectedThemeData =
        Provider.of<ThemeProvider>(context, listen: true).getTheme;
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
            'Price: ₹${movie.price ?? 0.0}',
            style: TextStyle(
              fontSize: 14,
              color: selectedThemeData.secondaryHeaderColor, // Theme text color
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Duration: ${movie.rentlDuration ?? ''}',
            style: TextStyle(
              fontSize: 14,
              color: selectedThemeData.secondaryHeaderColor, // Theme text color
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Do you want to rent this movie?',
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
          child: const Text("Cancel"),
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
          child: const Text("Continue"),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context, Content movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem(
            'Director',
            (movie.directorList != null && movie.directorList!.isNotEmpty)
                ? movie.directorList!.first
                : 'Unknown'),
        _buildDetailItem(
            'Cast',
            (movie.castList != null && movie.castList!.isNotEmpty)
                ? movie.castList!.join(', ')
                : 'N/A'),
        _buildDetailItem(
            'Genres',
            (movie.genreList != null && movie.genreList!.isNotEmpty)
                ? movie.genreList!.join(', ')
                : 'N/A'),
        _buildDetailItem('Runtime', movie.runtime!.toString()),
        _buildDetailItem('Release Date', movie.releaseDate ?? 'N/A'),
        _buildDetailItem('Languages', (movie.languageList ?? []).join(', ')),
        _buildDetailItem('Rating', '${movie.ratings ?? 0.0} ⭐'),
        _buildDetailItem(
            'Audio Formats', (movie.audioFormatList ?? []).join(', ')),
        _buildDetailItem(
            'Subtitle', (movie.subtitleLanguageList ?? []).join(', ')),
        _buildDetailItem('Age Rating', movie.ageRating ?? 'N/A'),
        //is_downloadable
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
                  CustomToast.show(context, "Please select rating",
                      isSuccess: false);
                } else {
                  var result = await provider.saveRatingReview(content.id!);
                  if (result['success'] == false) {
                    CustomToast.show(
                        context, "something went wrong to submit review",
                        isSuccess: false);
                  } else {
                    CustomToast.show(context, "'review submitted successfully'",
                        isSuccess: true);
                    await provider.getRatingReview(content.id!);
                  }
                }
              } else {
                CustomToast.show(context, 'Please give some comments',
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
              DateTime date = DateTime.fromMillisecondsSinceEpoch(
                  provider.reviewList[index].createdAt!);
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
