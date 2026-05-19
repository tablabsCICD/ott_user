import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/data/models/request/saveRatingAndReview.dart';
import 'package:ott/data/models/response/getRatingsAndReview.dart';
import 'package:ott/data/models/response/saveRatingAndReview.dart';
import 'dart:convert';

import '../../data/models/content.dart';
import '../../data/models/request/getAllVideoResponse.dart';
import '../../data/models/user.dart';
import '../core/constant/api_constant.dart';
import '../core/network/api_helper.dart';
import '../core/utils/sharepreferences.dart';
import 'baseProvider.dart';

class VideoProvider extends BaseProvider {
  VideoProvider() : super('Ideal') {
    searchContentController.text = '';
    searchContentController.addListener(_onSearchChanged);
  }

  TextEditingController searchContentController = TextEditingController();
  TextEditingController reviewController = TextEditingController();
  double rating = 0;

  Timer? _debounce;

  // Debounced search listener
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchContent();
    });
  }

  final List<Content> _contentList = [];
  List<Content> _filteredContentList = [];
  List<Content> _upcomingContentList = [];
  final Content _content = Content();
  final Content _selectedContent = Content();

  List<Content> get contentList => _contentList;

  List<Content> get filteredContentList => _filteredContentList;

  List<Content> get upcomingContentList => _upcomingContentList;

  Content get content => _content;

  Content get selectedContent => _selectedContent;

  String? selectedGenre;
  String? selectedLanguage;
  double? selectedRating;

  // Search all content
  Future<void> searchContent() async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    String apiUrl =
        ApiConstant.searchContent(user!.id!, searchContentController.text);
    ApiHelper apiHelper = ApiHelper();
    try {
      var response = await apiHelper.getApi(apiUrl);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        GetAllVideoResponse searchResponse =
            GetAllVideoResponse.fromJson(responseBody);
        if (searchResponse.success == true) {
          if (searchResponse.data!.contentList != null) {
            _filteredContentList.clear();
            _filteredContentList = searchResponse.data!.contentList!;
            notifyListeners();
          } else {
            debugPrint("empty list: ${searchResponse.message}");
          }
        } else {
          debugPrint("Error: ${searchResponse.message}");
        }
      } else if (response.statusCode == 404) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        GetAllVideoResponse searchResponse =
            GetAllVideoResponse.fromJson(responseBody);
        if (searchResponse.success == false) {
          _filteredContentList.clear();
          notifyListeners();
        }
      } else {
        throw Exception(
            'Failed to fetch content. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
    }
  }

  // Search all content
  Future<void> filterAndSortContent(
      String lang, String genre, double rating) async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    String apiUrl =
        ApiConstant.filterAndSortContent(user!.id, lang, genre, rating);
    ApiHelper apiHelper = ApiHelper();
    try {
      var response = await apiHelper.getApi(apiUrl);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        GetAllVideoResponse searchResponse =
            GetAllVideoResponse.fromJson(responseBody);
        if (searchResponse.success == true) {
          if (searchResponse.data != null) {
            _filteredContentList.clear();
            _filteredContentList = searchResponse.data!.contentList!;
            notifyListeners();
          } else {
            debugPrint("empty list: ${searchResponse.message}");
            _filteredContentList.clear();
          }
          notifyListeners();
        } else {
          _filteredContentList.clear();
          debugPrint("Error: ${searchResponse.message}");
        }
        notifyListeners();
      } else if (response.statusCode == 404) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        GetAllVideoResponse searchResponse =
            GetAllVideoResponse.fromJson(responseBody);
        if (searchResponse.success == false) {
          _filteredContentList.clear();
          notifyListeners();
        }
      } else {
        throw Exception(
            'Failed to fetch content. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
    }
  }

  @override
  void dispose() {
    searchContentController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> upcomingContent() async {
    String apiUrl = ApiConstant.getUpcomingVideo;
    ApiHelper apiHelper = ApiHelper();
    try {
      var response = await apiHelper.getApi(apiUrl);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        GetAllVideoResponse searchResponse =
            GetAllVideoResponse.fromJson(responseBody);
        if (searchResponse.success == true) {
          if (searchResponse.data != null) {
            _upcomingContentList.clear();
            _upcomingContentList = searchResponse.data!.contentList!;

            notifyListeners();
          } else {
            debugPrint("empty list: ${searchResponse.message}");
          }
        } else {
          debugPrint("Error: ${searchResponse.message}");
        }
      } else {
        throw Exception(
            'Failed to fetch content. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
      throw Exception('An error occurred while fetching content.');
    }
  }

  Future<void> userPurchasedContent() async {
    String apiUrl = ApiConstant.getUpcomingVideo;
    ApiHelper apiHelper = ApiHelper();
    try {
      var response = await apiHelper.getApi(apiUrl);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        GetAllVideoResponse searchResponse =
            GetAllVideoResponse.fromJson(responseBody);
        if (searchResponse.success == true) {
          if (searchResponse.data != null) {
            _upcomingContentList.clear();
            _upcomingContentList = searchResponse.data!.contentList!;

            notifyListeners();
          } else {
            debugPrint("empty list: ${searchResponse.message}");
          }
        } else {
          debugPrint("Error: ${searchResponse.message}");
        }
      } else {
        throw Exception(
            'Failed to fetch content. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
      throw Exception('An error occurred while fetching content.');
    }
  }

  getFilteredMovies() {
    _filteredContentList = _contentList.where((movie) {
      final title = movie.title.toString().toLowerCase();
      final director = movie.directorList.toString().toLowerCase();
      final cast = (movie.castList as List).join(" ").toLowerCase();
      final genres = List<String>.from(movie.genreList ?? []);
      final language = movie.languageList.toString();
      final rating = movie.ratingCount?.toDouble() ?? 0.0;

      return (searchContentController.text.isEmpty ||
              title.contains(searchContentController.text) ||
              director.contains(searchContentController.text) ||
              cast.contains(searchContentController.text)) &&
          (selectedGenre == null || genres.contains(selectedGenre)) &&
          (selectedLanguage == null || language == selectedLanguage) &&
          (selectedRating == null || rating >= selectedRating!);
    }).toList();

    notifyListeners();
  }

  void applyFilter(String? genre, String? language, double? rating) {
    selectedGenre = genre;
    selectedLanguage = language;
    selectedRating = rating;
    filterAndSortContent(
        selectedLanguage ?? '', selectedGenre ?? '', selectedRating ?? 0.0);
    notifyListeners();
  }

  void clearFilters() {
    selectedGenre = null;
    selectedLanguage = null;
    selectedRating = null;
    searchContentController.text = '';
    searchContent();
    notifyListeners();
  }

  final List<Review> _reviewList = [];
  List<Review> get reviewList => _reviewList;

  Future<Map<String, Object>> saveRatingReview(int contentId) async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    DateTime now = DateTime.now().toUtc(); // Get current time in UTC
    String formattedDate = now.toIso8601String();
    String apiUrl = ApiConstant.saveRatingAndReview;
    SaveRatingsAndReview saveRatingsAndReview = SaveRatingsAndReview();
    saveRatingsAndReview.title = reviewController.text;
    saveRatingsAndReview.rating = rating;
    saveRatingsAndReview.userId = user!.id!;
    saveRatingsAndReview.comment = reviewController.text;
    saveRatingsAndReview.contentId = contentId;
    saveRatingsAndReview.reviewId = 0;
    saveRatingsAndReview.createdAt = formattedDate;

    ApiHelper apiHelper = ApiHelper();

    try {
      var response = await apiHelper.postApiWithBody(
          apiUrl, saveRatingsAndReview.toJson());
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        SaveRatingsAndReviewResponse saveRatingsAndReviewResponse =
            SaveRatingsAndReviewResponse.fromJson(responseBody);
        if (saveRatingsAndReviewResponse.success == true) {
          if (saveRatingsAndReviewResponse.data != null) {
            _reviewList.add(saveRatingsAndReviewResponse.data!.user!);
            notifyListeners();
            return {
              'success': true,
              'message': saveRatingsAndReviewResponse.message!
            };
          } else {
            debugPrint("Empty data: ${saveRatingsAndReviewResponse.message}");
            return {
              'success': false,
              'message':
                  saveRatingsAndReviewResponse.message ?? 'No data returned'
            };
          }
        } else {
          debugPrint("Error: ${saveRatingsAndReviewResponse.message}");
          return {
            'success': false,
            'message':
                saveRatingsAndReviewResponse.message ?? 'Error in response'
          };
        }
      } else {
        return {'failure': true, 'message': 'Something went wrong!'};
        // throw Exception('Failed to add user. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': 'An error occurred while adding user: $error'
      };
    }
  }

  Future<Map<String, Object>> getRatingReview(int contentId) async {
    String apiUrl = ApiConstant.getRatingAndReviewByContentId(contentId);

    ApiHelper apiHelper = ApiHelper();

    try {
      var response = await apiHelper.getApi(apiUrl);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        GetRatingsAndReview getRatingsAndReview =
            GetRatingsAndReview.fromJson(responseBody);
        if (getRatingsAndReview.success == true) {
          if (getRatingsAndReview.data != null) {
            _reviewList.clear();
            _reviewList
                .addAll(getRatingsAndReview.data!.reviewRating!.reviews!);
            notifyListeners();
            return {'success': true, 'message': getRatingsAndReview.message!};
          } else {
            debugPrint("Empty data: ${getRatingsAndReview.message}");
            return {
              'success': false,
              'message': getRatingsAndReview.message ?? 'No data returned'
            };
          }
        } else {
          debugPrint("Error: ${getRatingsAndReview.message}");
          return {
            'success': false,
            'message': getRatingsAndReview.message ?? 'Error in response'
          };
        }
      } else if (response.statusCode == 500) {
        _reviewList.clear();
        Map<String, dynamic> responseBody = json.decode(response.body);
        GetRatingsAndReview getRatingsAndReview =
            GetRatingsAndReview.fromJson(responseBody);
        //CustomToast.show("Error: ${getRatingsAndReview.message}",isSuccess:false);
        return {
          'success': false,
          'message': getRatingsAndReview.message ?? 'Error in response'
        };
      } else {
        return {'failure': true, 'message': 'Something went wrong!'};
      }
    } catch (error) {
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': 'An error occurred while adding user: $error'
      };
    }
  }
}
