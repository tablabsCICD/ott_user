import 'dart:convert';

import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/utils/app_l10n.dart';
import 'package:ott/app/core/utils/mini_series_api_log.dart';
import 'package:ott/data/models/mini_series_commerce_models.dart';

/// Mini series gifting and one-time full purchase.
///
/// Contract sources (the server's /v2/api-docs types every body/response as
/// a generic object, so field names come from live dev-server responses):
/// - `GET  api/mini-series/{id}/full-purchase-details`: response verified,
///   mapped by [MiniSeriesPurchaseQuote.fromFullPurchaseDetails].
/// - `POST api/mini-series/{id}/purchase-full`: path id + optional
///   `Idempotency-Key` header + optional body (per Swagger). Sent with no
///   body, so no request field is assumed. Response read only through the
///   standard `{success, message, data}` envelope.
/// - `GET  api/mini-series/{id}/gift-details`: `giftUnitPrice`, `minQuantity`,
///   `maxQuantity` (confirmed backend contract).
/// - `POST api/mini-series/gift/purchase`: body `{miniSeriesId, quantity,
///   paymentMethod: "WALLET"}` (all required) + optional `Idempotency-Key`;
///   data `{transactionId, totalAmount, expiryDate, gifts[{giftCode, status,
///   expiryDate}], idempotentReplay}` (confirmed backend contract).
class MiniSeriesCommerceService {
  MiniSeriesCommerceService({ApiHelper? apiHelper})
      : _apiHelper = apiHelper ?? ApiHelper();

  final ApiHelper _apiHelper;
  bool _requestInFlight = false;

  bool get isBusy => _requestInFlight;

  Future<MiniSeriesPurchaseQuote> fetchQuote(
    int shortId, {
    required bool forGift,
    String title = '',
  }) async {
    final url = forGift
        ? ApiConstant.miniSeriesGiftDetails(shortId)
        : ApiConstant.miniSeriesFullPurchaseDetails(shortId);
    final response = await _get(
      forGift
          ? MiniSeriesApiLog.giftDetails
          : MiniSeriesApiLog.fullPurchaseDetails,
      url,
    );
    if (response == null) {
      throw Exception(appL10n().msgSomethingWentWrongTryAgain);
    }
    final body = _decode(response.body.toString());
    final statusCode = response.statusCode as int;
    if (statusCode != 200 || body['success'] != true) {
      throw Exception(
        _message(body) ?? appL10n().msgServerErrorTryLater(statusCode),
      );
    }
    final data = body['data'];
    if (data is! Map) throw Exception(appL10n().msgNoDataReturned);
    final map = Map<String, dynamic>.from(data);
    return forGift
        ? MiniSeriesPurchaseQuote.fromGiftDetails(map,
            shortId: shortId, title: title)
        : MiniSeriesPurchaseQuote.fromFullPurchaseDetails(map);
  }

  /// `POST api/mini-series/{id}/purchase-full` with the `Idempotency-Key`
  /// header and no body. The backend recomputes the price and deducts the
  /// wallet; success is only `HTTP 2xx` **and** `success: true`.
  Future<MiniSeriesCommerceResult> purchaseFull({
    required int shortId,
    required double expectedAmount,
    required String idempotencyKey,
  }) async {
    if (_requestInFlight) {
      return MiniSeriesCommerceResult.failure(appL10n().msgPurchaseInProgress);
    }
    _requestInFlight = true;
    const apiName = MiniSeriesApiLog.fullPurchase;
    final url = ApiConstant.miniSeriesPurchaseFull(shortId);
    final extraHeaders = {'Idempotency-Key': idempotencyKey};
    final stopwatch = Stopwatch()..start();
    try {
      MiniSeriesApiLog.request(
        apiName: apiName,
        method: 'POST',
        url: url,
        headers: {
          ...await _apiHelper.headersForDiagnostics(),
          ...extraHeaders,
        },
      );
      MiniSeriesApiLog.note(apiName,
          'MINI SERIES ID: $shortId | DISPLAYED TOTAL: ${expectedAmount.toStringAsFixed(2)} | PAYMENT METHOD: WALLET');
      final response = await _apiHelper.postApiWithHeaders(
        url,
        extraHeaders: extraHeaders,
      );
      final statusCode = response.statusCode as int;
      final rawBody = response.body.toString();
      MiniSeriesApiLog.response(
        apiName: apiName,
        url: url,
        statusCode: statusCode,
        body: rawBody,
        headers: Map<String, String>.from(response.headers as Map),
        elapsed: stopwatch.elapsed,
      );
      return _result(rawBody, statusCode);
    } catch (error, stackTrace) {
      MiniSeriesApiLog.exception(
        apiName: apiName,
        url: url,
        error: error,
        stackTrace: stackTrace,
        elapsed: stopwatch.elapsed,
      );
      return MiniSeriesCommerceResult.failure(
          appL10n().msgSomethingWentWrongTryAgain);
    } finally {
      _requestInFlight = false;
    }
  }

  /// `POST api/mini-series/gift/purchase` with the confirmed body
  /// `{miniSeriesId, quantity, paymentMethod: "WALLET"}` and an
  /// `Idempotency-Key`. The backend computes `giftUnitPrice × quantity` and
  /// deducts the wallet. Success is only HTTP 2xx **and** `success: true`.
  Future<MiniSeriesCommerceResult> purchaseGift({
    required int shortId,
    required int giftCount,
    required double expectedTotal,
    required String idempotencyKey,
  }) async {
    if (_requestInFlight) {
      return MiniSeriesCommerceResult.failure(appL10n().msgPurchaseInProgress);
    }
    _requestInFlight = true;
    const apiName = MiniSeriesApiLog.giftPurchase;
    final url = ApiConstant.miniSeriesGiftPurchase;
    final body = <String, dynamic>{
      'miniSeriesId': shortId,
      'quantity': giftCount,
      'paymentMethod': 'WALLET',
    };
    final extraHeaders = {'Idempotency-Key': idempotencyKey};
    final stopwatch = Stopwatch()..start();
    try {
      MiniSeriesApiLog.request(
        apiName: apiName,
        method: 'POST',
        url: url,
        headers: {
          ...await _apiHelper.headersForDiagnostics(),
          ...extraHeaders,
        },
        body: body,
      );
      MiniSeriesApiLog.note(apiName,
          'MINI SERIES ID: $shortId | QUANTITY: $giftCount | DISPLAYED TOTAL: ${expectedTotal.toStringAsFixed(2)} | PAYMENT METHOD: WALLET');
      final response = await _apiHelper.postApiWithHeaders(
        url,
        extraHeaders: extraHeaders,
        data: body,
      );
      final statusCode = response.statusCode as int;
      final rawBody = response.body.toString();
      MiniSeriesApiLog.response(
        apiName: apiName,
        url: url,
        statusCode: statusCode,
        body: rawBody,
        headers: Map<String, String>.from(response.headers as Map),
        elapsed: stopwatch.elapsed,
        requestBody: body,
      );
      return _result(rawBody, statusCode);
    } catch (error, stackTrace) {
      MiniSeriesApiLog.exception(
        apiName: apiName,
        url: url,
        error: error,
        stackTrace: stackTrace,
        elapsed: stopwatch.elapsed,
        requestBody: body,
      );
      // No response: the outcome is uncertain (statusCode stays null), so the
      // caller keeps the same Idempotency-Key for a retry.
      return MiniSeriesCommerceResult.failure(
          appL10n().msgSomethingWentWrongTryAgain);
    } finally {
      _requestInFlight = false;
    }
  }

  /// `POST api/mini-series/gift/claim` with Swagger
  /// `MiniSeriesGiftClaimRequest {giftCode}`. The recipient comes from the
  /// JWT. Errors: 400 missing code, 403 own gift, 404 unknown code,
  /// 409 already claimed / unavailable, 410 expired.
  Future<MiniSeriesCommerceResult> claimGift(String giftCode) async {
    if (_requestInFlight) {
      return MiniSeriesCommerceResult.failure(appL10n().msgPurchaseInProgress);
    }
    _requestInFlight = true;
    const apiName = MiniSeriesApiLog.giftClaim;
    final url = ApiConstant.miniSeriesGiftClaim;
    final body = <String, dynamic>{'giftCode': giftCode};
    final stopwatch = Stopwatch()..start();
    try {
      MiniSeriesApiLog.request(
        apiName: apiName,
        method: 'POST',
        url: url,
        headers: await _apiHelper.headersForDiagnostics(),
        body: body,
      );
      final response = await _apiHelper.postApiWithBody(url, body);
      final statusCode = response.statusCode as int;
      final rawBody = response.body.toString();
      MiniSeriesApiLog.response(
        apiName: apiName,
        url: url,
        statusCode: statusCode,
        body: rawBody,
        headers: Map<String, String>.from(response.headers as Map),
        elapsed: stopwatch.elapsed,
        requestBody: body,
      );
      return _result(rawBody, statusCode);
    } catch (error, stackTrace) {
      MiniSeriesApiLog.exception(
        apiName: apiName,
        url: url,
        error: error,
        stackTrace: stackTrace,
        elapsed: stopwatch.elapsed,
        requestBody: body,
      );
      return MiniSeriesCommerceResult.failure(
          appL10n().msgSomethingWentWrongTryAgain);
    } finally {
      _requestInFlight = false;
    }
  }

  /// Sender: `GET api/mini-series/gift/history` (`MiniSeriesGiftHistoryItem[]`).
  Future<List<MiniSeriesGiftHistoryEntry>> fetchGiftHistory() =>
      _fetchGiftList(MiniSeriesApiLog.giftHistory, ApiConstant.miniSeriesGiftHistory);

  /// Recipient: `GET api/mini-series/gift/received` (`MiniSeriesGiftReceivedItem[]`).
  Future<List<MiniSeriesGiftHistoryEntry>> fetchGiftReceived() async {
    final items = await _fetchGiftList(
        MiniSeriesApiLog.giftReceived, ApiConstant.miniSeriesGiftReceived);
    _logReceivedItems(items);
    return items;
  }

  /// Debug-only parsing summary. No tokens, gift codes or full names.
  void _logReceivedItems(List<MiniSeriesGiftHistoryEntry> items) {
    MiniSeriesApiLog.note(MiniSeriesApiLog.giftReceived,
        'PARSED ITEMS: ${items.length}');
    for (final item in items) {
      final name = item.displaySenderName;
      MiniSeriesApiLog.note('MINI_SERIES_GIFT_SENDER',
          'giftId=${item.giftId} senderName=${name == null ? 'null/empty -> "A friend" fallback' : 'present (${name.substring(0, 1)}…)'}');
      MiniSeriesApiLog.note('MINI_SERIES_GIFT_EXPIRY',
          'giftId=${item.giftId} giftExpiryDate=${item.giftExpiryDate?.toIso8601String() ?? 'null'} '
          'expiryDate=${item.expiryDate?.toIso8601String() ?? 'null'} (epoch ms -> local; gift-code claim deadline)');
      MiniSeriesApiLog.note('MINI_SERIES_GIFT_ACCESS_VALIDITY',
          'giftId=${item.giftId} accessValidUntil=${item.accessValidUntil?.toIso8601String() ?? 'not in received response (not shown)'}');
    }
  }

  Future<List<MiniSeriesGiftHistoryEntry>> _fetchGiftList(
      String apiName, String url) async {
    final response = await _get(apiName, url);
    if (response == null) {
      throw Exception(appL10n().msgSomethingWentWrongTryAgain);
    }
    final statusCode = response.statusCode as int;
    final body = _decode(response.body.toString());
    if (statusCode != 200 || body['success'] != true) {
      throw Exception(
          _message(body) ?? appL10n().msgServerErrorTryLater(statusCode));
    }
    return MiniSeriesGiftHistoryEntry.listFrom(body['data']);
  }

  /// Success requires HTTP 2xx and `success: true`.
  MiniSeriesCommerceResult _result(String rawBody, int statusCode) {
    final result = MiniSeriesCommerceResult.fromJson(
      _decode(rawBody),
      fallbackMessage: appL10n().msgServerErrorTryLater(statusCode),
      statusCode: statusCode,
    );
    if ((statusCode < 200 || statusCode >= 300) && result.success) {
      return MiniSeriesCommerceResult(
        success: false,
        message: result.message,
        errorCode: result.errorCode,
        data: result.data,
        statusCode: statusCode,
        envelope: result.envelope,
      );
    }
    return result;
  }

  /// Logged GET. Returns the raw response, or null on a network exception.
  Future<dynamic> _get(String apiName, String url) async {
    final stopwatch = Stopwatch()..start();
    try {
      MiniSeriesApiLog.request(
        apiName: apiName,
        method: 'GET',
        url: url,
        headers: await _apiHelper.headersForDiagnostics(),
      );
      final response = await _apiHelper.getApi(url);
      MiniSeriesApiLog.response(
        apiName: apiName,
        url: url,
        statusCode: response.statusCode as int,
        body: response.body.toString(),
        headers: Map<String, String>.from(response.headers as Map),
        elapsed: stopwatch.elapsed,
      );
      return response;
    } catch (error, stackTrace) {
      MiniSeriesApiLog.exception(
        apiName: apiName,
        url: url,
        error: error,
        stackTrace: stackTrace,
        elapsed: stopwatch.elapsed,
      );
      return null;
    }
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return const {};
  }

  String? _message(Map<String, dynamic> body) {
    final message = body['message']?.toString().trim();
    return message == null || message.isEmpty ? null : message;
  }
}
