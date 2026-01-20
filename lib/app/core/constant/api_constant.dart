class ApiConstant {
  static const String baseUrl =
      "http://ec2-13-201-5-93.ap-south-1.compute.amazonaws.com:8080/ott/";

  static String login = "${baseUrl}user/email/login2";
  static String registration = '${baseUrl}user/RegisterUser';

  //otp login

  static String sendOTP(mobileNum) =>
      "${baseUrl}userNew/SendOTPOnMobileWithRegistration?mobileNumber=$mobileNum";
  static String verifyOTP(mobileNum, otp) =>
      "${baseUrl}userNew/VerifyOtpJWT?mobileNumber=$mobileNum&otp=$otp";

  static String getDashboardData =
      "${baseUrl}api/forUser/filter/content-list/type3?";

  //update user
  static String editUserById = "${baseUrl}userNew/updateUserBy/%7Bid%7D";
  static String getUserById(id) => "${baseUrl}user/getUser/$id";
  static String deleteUserById(id) => "${baseUrl}user/deleteUserBy/$id";

  // content
  static String getVideoById(id, userId) =>
      "${baseUrl}api/ContentList/getContentByIdAndUserId?id=$id&userId=$userId";
  static String getUpcomingVideo =
      "${baseUrl}api/foruser/upcomingmovie?isFeatured=true";
  static String searchContent(id, char) =>
      "${baseUrl}api/forUser/user/Content/getByAnyKey?userId=$id&keyword=$char";
  static String filterAndSortContent(id, lang, genre, rating) =>
      "${baseUrl}api/forUser/foruser/search/lag/gen/rating?userId=$id&language=$lang&genre=$genre&minRating=$rating";
  static String getTopTrendingContentLast7Days(userId) =>
      "${baseUrl}api/forUser/Content/TopTen?userId=$userId";

  static String uploadImg = "${baseUrl}api/saveImage/new";
  static String fetchLang = "${baseUrl}api/Languages/getAll";

  static String addMoneyToWallet = "${baseUrl}add-amount";
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

  static String raiseTicket = "${baseUrl}api/TicketRaised/add";
  static String deleteTicket(id) =>
      "${baseUrl}api/tickets/deleteTicketRaisedBy/$id";
  static String getRaisedTicketByUserId(userId) =>
      "${baseUrl}api/TicketRaised/user/$userId";

  static String saveUserContent = "${baseUrl}api/save";
  static String getUserContent(id) => "${baseUrl}api/filter/remainingDays/$id";

  static String saveViewHistory = "${baseUrl}api/saveOrUpdate";

//gifting
  static String saveUserGift = "${baseUrl}api/saveMovieGiftMaster";

  static String getByGiftOwner(giftOwnerId) =>
      "${baseUrl}api/getByGiftOwner?giftOwnerId=$giftOwnerId";

  static String getByGiftMasterId(giftMasterId) =>
      "${baseUrl}api/getByGiftMasterId?giftMasterId=$giftMasterId";

  static String useGiftByCoupon(userId, couponCode) =>
      "${baseUrl}api/useGiftByCoupon?couponCode=$couponCode&userId=$userId";

  //shorts
  static String shortsMaster = "${baseUrl}api/shortsMaster";
  static String shortsDetails(id, userId) =>
      "${baseUrl}api/shortsMaster/$id?userId=$userId";

  //series
  static String seriesDetails(seriesId) => "${baseUrl}series/$seriesId/details";
}
