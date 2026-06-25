class ApiConstant {
  static const String baseUrl = "https://filmytell.in/ott/";

  /*  static const String baseUrl =
      "http://ec2-13-201-5-93.ap-south-1.compute.amazonaws.com:8080/ott/";
 */
  static String login = "${baseUrl}auth/session/login";
  static String twoStepLogin = "${baseUrl}auth/two-step/login";
  static String twoStepVerifyOtp = "${baseUrl}auth/two-step/verify-otp";
  static String legacyLogin = "${baseUrl}user/email/login2";
  static String sessionLogout = "${baseUrl}auth/session/logout";
  static String activeDevices = "${baseUrl}auth/session/devices";
  static String forceLogoutDevice(sessionRecordId) =>
      "${baseUrl}auth/session/devices/$sessionRecordId/logout";
  static String validatePlaybackSecurity =
      "${baseUrl}api/playback/security/validate";
  static String playbackPiracyEvent = "${baseUrl}api/playback/security/event";
  static String registration = '${baseUrl}user/RegisterUser';

  //otp login
  static String sendOTP(mobileNum) =>
      "${baseUrl}userNew/SendOTPOnMobileWithRegistration?mobileNumber=$mobileNum";
  static String verifyOTP({
    required mobileNum,
    required otp,
    required deviceId,
    required deviceName,
    required deviceType,
    required appVersion,
    deviceMetadata,
    deviceToken,
  }) {
    final query = <String, String>{
      'username': mobileNum.toString(),
      'mobileNumber': mobileNum.toString(),
      'otp': otp.toString(),
      'deviceId': deviceId.toString(),
      'deviceName': deviceName.toString(),
      'deviceType': deviceType.toString(),
      'appVersion': appVersion.toString(),
      if (deviceMetadata != null && deviceMetadata.toString().trim().isNotEmpty)
        'deviceMetadata': deviceMetadata.toString(),
      if (deviceToken != null && deviceToken.toString().trim().isNotEmpty)
        'deviceToken': deviceToken.toString(),
    };

    return Uri.parse("${baseUrl}userNew/VerifyOtpJWT")
        .replace(queryParameters: query)
        .toString();
  }

  static String getDashboardData =
      "${baseUrl}api/forUser/filter/content-list/type3?";
  static String getNewDashboardData = "${baseUrl}api/user/dashboard/filter/";

// increase views api
  static String addViewForMovie(movieId, userId) =>
      "${baseUrl}api/forUser/movie/$movieId/view?userId=$userId";
  static String addViewForEpisode(episodeId, userId) =>
      "${baseUrl}api/forUser/episode/$episodeId/view?userId=$userId";

  //update user
  static String editUserById(id) => "${baseUrl}userNew/updateUserBy/$id";
  static String getUserById(id) => "${baseUrl}user/getUser/$id";
  static String deleteUserById(id) => "${baseUrl}user/deleteUserBy/$id";

  // content
  static String getVideoById(id, userId) =>
      "${baseUrl}api/ContentList/getContentByIdAndUserId?id=$id&userId=$userId";
  static String getCastByContentId(contentId) =>
      "${baseUrl}api/Cast/getByContentId?contentId=$contentId";
  static String getCastByContentIdAndSeasonId(contentId, seasonId) =>
      "${baseUrl}api/Cast/getByContentIdAndSeasonId?contentId=$contentId&seasonId=$seasonId";
  static String getUpcomingVideo =
      "${baseUrl}api/foruser/upcomingmovie?isFeatured=true";
  static String searchContent(id, char) =>
      "${baseUrl}api/forUser/user/Content/getByAnyKey?userId=$id&keyword=$char";
  static String filterAndSortContent(id, lang, genre, rating) =>
      "${baseUrl}api/forUser/foruser/search/lag/gen/rating?userId=$id&language=$lang&genre=$genre&minRating=$rating";
  static String getTopTrendingContentLast7Days(userId) =>
      "${baseUrl}api/forUser/user/Content/TopTen?userId=$userId";
  static String publicTopTenContent =
      "${baseUrl}api/forUser/public/Content/TopTen";
  static String publicLatestContent({
    int page = 0,
    int size = 10,
    String? type,
  }) {
    final query = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if ((type ?? '').trim().isNotEmpty) 'type': type!.trim(),
    };
    return Uri.parse("${baseUrl}api/forUser/public/Content/Latest")
        .replace(queryParameters: query)
        .toString();
  }

  static String uploadImg = "${baseUrl}api/other/upload-file";

  // get all languges
  static String fetchLang = "${baseUrl}api/Languages/getAll";
  static String fetchGroupedLang = "${baseUrl}api/all/withGrouping";
  static String getLatestVersion = "${baseUrl}api/GetLatestVersionIos";
  static String legalDocumentUrls = "${baseUrl}api/legal/document-urls";

  static String addMoneyToWallet = "${baseUrl}add-amount";
  static String createWalletOrder(double amount, int userId) {
    final normalizedAmount =
        amount == amount.truncateToDouble() ? amount.toInt() : amount;
    return "${baseUrl}api/razorpay/create-order?amount=$normalizedAmount&customerId=$userId";
  }

  static String verifyWalletPayment = "${baseUrl}api/razorpay/verify-payment";
  static String withdrawMoneyFromWallet(userId, amount, contentId) =>
      "${baseUrl}deduct?userId=$userId&amount=$amount&contentId=$contentId";
  static String getWalletBalanceByUserId(userId) =>
      "${baseUrl}wallet/balance/$userId";
  static String walletHistory(userId) =>
      "${baseUrl}api/walletHistory/user/%7BuserId%7D?userId=$userId";

  static String saveRatingAndReview = "${baseUrl}api/saveRatingAndRewiew";
  static String deleteRatingAndReview(id) =>
      "${baseUrl}api/deleteRatingAndRewiewBy/$id";
  static String getRatingAndReviewByContentId(contentId) =>
      "${baseUrl}api/content/$contentId";
  static String userPushNotifications(userId, pageNo, pageSize) =>
      "${baseUrl}api/notifications/user/$userId/push?pageNo=$pageNo&pageSize=$pageSize";

  static String sendEmail = "${baseUrl}api/email/send";

  static String raiseTicket = "${baseUrl}api/TicketRaised/add";
  static String deleteTicket(id) =>
      "${baseUrl}api/TicketRaised/deleteTicketRaisedBy/$id";
  static String getRaisedTicketByUserId(userId) =>
      "${baseUrl}api/TicketRaised/user/$userId";

  static String saveUserContent = "${baseUrl}api/save";
  static String getUserContent(
    id, {
    bool isGifted = false,
    bool isExpired = false,
  }) =>
      "${baseUrl}api/filter/remainingDays/$id?isGifted=$isGifted&isExpired=$isExpired";
  static String purchaseHistory(userId, fromDate, toDate, selectedType) {
    final type = selectedType?.toString().trim() ?? '';
    final typeQuery =
        type.isEmpty || type.toLowerCase() == 'all' ? '' : '&type=$type';
    return "${baseUrl}api/purchase-history?userId=$userId&fromDate=$fromDate&toDate=$toDate$typeQuery";
  }

  static String saveViewHistory = "${baseUrl}api/saveOrUpdate";

//gifting
  static String saveUserGift = "${baseUrl}api/saveMovieGiftMaster";

  static String getByGiftOwner(giftOwnerId) =>
      "${baseUrl}api/getByGiftOwner?giftOwnerId=$giftOwnerId";

  static String getByGiftMasterId(giftMasterId) =>
      "${baseUrl}api/getByGiftMasterId?giftMasterId=$giftMasterId";

  static String useGiftByCoupon(userId, couponCode) =>
      "${baseUrl}api/useGiftByCoupon?couponCode=${Uri.encodeComponent(couponCode.toString())}&userId=$userId";

  //shorts
  static String shortsMaster = "${baseUrl}api/shortsMaster";
  static String getLatestShortsByLang(lang, page) =>
      "${baseUrl}api/shortsMaster/latest?lang=${Uri.encodeComponent(lang.toString())}&page=$page&size=10";
  static String getTrendingShortsByLang(lang, page) =>
      "${baseUrl}api/shortsMaster/trending?lang=${Uri.encodeComponent(lang.toString())}&page=$page&size=10";
  static String getShortsByTypeLang(type, lang, page) =>
      type.toString().toLowerCase() == 'trending'
          ? getTrendingShortsByLang(lang, page)
          : getLatestShortsByLang(lang, page);
  static String shortsDetails(id, userId) =>
      "${baseUrl}api/shortsMaster/$id?userId=$userId";
  static String likeshort(partId, userId) =>
      "${baseUrl}api/shortsMaster/part/$partId/like?userId=$userId";
  static String unlikeshort(partId, userId) =>
      "${baseUrl}api/shortsMaster/part/$partId/unlike?userId=$userId";
  static String viewsShort(partId) =>
      "${baseUrl}api/shortsMaster/part/$partId/view";
  static String purchaseShort(partId, userId) =>
      "${baseUrl}api/shortsMaster/purchaseShort?partId=$partId&userId=$userId";

  //series
  static String seriesDetails(seriesId, userId) =>
      "${baseUrl}api/userSeries/$seriesId/user-details?userId=$userId";
  static String purchaseEpisode(episodeId, userId) =>
      '${baseUrl}series/purchase/episode?episodeId=$episodeId&userId=$userId';
  static String purchaseSeason(seasonId, userId) =>
      '${baseUrl}series/purchase/season?seasonId=$seasonId&userId=$userId';
  static String continueWatchedMoviesByUser(userId, type) =>
      "${baseUrl}continue-watching/user/$userId?contentType=$type";

  // bookmarks movie
  static String addBookmark(userId, contentId) =>
      "${baseUrl}bookmarks/add?userId=$userId&contentId=$contentId";
  static String removeBookmark(userId, contentId) =>
      "${baseUrl}bookmarks/remove?userId=$userId&contentId=$contentId";
  static String isBookmarked(userId, contentId) =>
      "${baseUrl}bookmarks/status?userId=$userId&contentId=$contentId";
  static String getUserBookmarks(userId) => "${baseUrl}bookmarks/user/$userId";

  // bookmarks movie
  static String addBookmarkShort(userId, shortId) =>
      "${baseUrl}short-bookmarks/add?userId=$userId&shortId=$shortId";
  static String removeBookmarkShort(userId, shortId) =>
      "${baseUrl}short-bookmarks/remove?userId=$userId&shortId=$shortId";
  static String isBookmarkedShort(userId, shortId) =>
      "${baseUrl}short-bookmarks/status?userId=$userId&shortId=$shortId";
  static String getUserBookmarkShort(userId) =>
      "${baseUrl}short-bookmarks/user/$userId";
}
