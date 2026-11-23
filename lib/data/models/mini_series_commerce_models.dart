// Models for the PROPOSED mini series gift / full purchase contract.
// See docs/mini_series_gift_and_full_purchase_backend.md.

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}') ?? 0;
}

int? _asIntOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}');
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

class MiniSeriesQuotePart {
  const MiniSeriesQuotePart({
    required this.partId,
    required this.partNumber,
    required this.price,
    required this.free,
    required this.owned,
    required this.purchasable,
  });

  final int? partId;
  final int partNumber;
  final double price;
  final bool free;
  final bool owned;
  final bool purchasable;

  factory MiniSeriesQuotePart.fromJson(Map<String, dynamic> json) =>
      MiniSeriesQuotePart(
        partId: _asIntOrNull(json['partId']),
        partNumber: _asIntOrNull(json['partNumber']) ?? 0,
        price: _asDouble(json['price']),
        free: json['free'] == true,
        owned: json['owned'] == true,
        purchasable: json['purchasable'] == true,
      );
}

/// Backend-computed prices for one mini series and one user.
class MiniSeriesPurchaseQuote {
  const MiniSeriesPurchaseQuote({
    required this.shortId,
    required this.title,
    required this.currency,
    required this.totalParts,
    required this.purchasablePartCount,
    required this.ownedPartCount,
    required this.freePartCount,
    required this.parts,
    required this.fullPurchasePrice,
    required this.fullPurchaseAvailable,
    required this.alreadyOwnsAll,
    required this.giftAvailable,
    required this.giftPrice,
    required this.minGiftCount,
    required this.maxGiftCount,
  });

  final int shortId;
  final String title;
  final String currency;
  final int totalParts;
  final int purchasablePartCount;
  final int ownedPartCount;
  final int freePartCount;
  final List<MiniSeriesQuotePart> parts;
  final double fullPurchasePrice;
  final bool fullPurchaseAvailable;
  final bool alreadyOwnsAll;
  final bool giftAvailable;
  final double giftPrice;
  final int minGiftCount;

  /// Null means the backend sets no upper limit.
  final int? maxGiftCount;

  /// Sum of the purchasable parts' prices. Shown as a cross-check against the
  /// backend's [fullPurchasePrice], which is always the amount charged.
  double get purchasablePartsSum => parts
      .where((part) => part.purchasable)
      .fold(0.0, (sum, part) => sum + part.price);

  /// Maps the real `data` of `GET api/mini-series/{id}/full-purchase-details`
  /// (verified from a live dev-server response):
  /// `{ miniSeriesId, title, totalParts, eligibleParts, alreadyOwnedParts,
  ///    currency, partPriceBreakdown: [{partId, partNumber, price, owned,
  ///    eligible}], totalAmount, purchaseAvailable }`.
  /// That response has no gift price, so gift fields are left unavailable.
  factory MiniSeriesPurchaseQuote.fromFullPurchaseDetails(
      Map<String, dynamic> json) {
    final parts = (json['partPriceBreakdown'] as List? ?? const []).map((e) {
      final m = _asMap(e);
      final owned = m['owned'] == true;
      final eligible = m['eligible'] == true;
      final price = _asDouble(m['price']);
      return MiniSeriesQuotePart(
        partId: _asIntOrNull(m['partId']),
        partNumber: _asIntOrNull(m['partNumber']) ?? 0,
        price: price,
        // The breakdown has no free flag: a part that is neither owned nor
        // eligible is shown as free only when its price is zero.
        free: !owned && !eligible && price <= 0,
        owned: owned,
        purchasable: eligible,
      );
    }).toList(growable: false);
    final totalParts = _asIntOrNull(json['totalParts']) ?? parts.length;
    final eligible = _asIntOrNull(json['eligibleParts']) ??
        parts.where((p) => p.purchasable).length;
    final owned = _asIntOrNull(json['alreadyOwnedParts']) ??
        parts.where((p) => p.owned).length;
    return MiniSeriesPurchaseQuote(
      shortId: _asIntOrNull(json['miniSeriesId']) ?? 0,
      title: json['title']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'INR',
      totalParts: totalParts,
      purchasablePartCount: eligible,
      ownedPartCount: owned,
      freePartCount: parts.where((p) => p.free).length,
      parts: parts,
      fullPurchasePrice: _asDouble(json['totalAmount']),
      fullPurchaseAvailable: json['purchaseAvailable'] == true,
      alreadyOwnsAll: eligible == 0 && totalParts > 0 && owned >= totalParts,
      giftAvailable: false,
      giftPrice: 0,
      minGiftCount: 1,
      maxGiftCount: null,
    );
  }

  /// Maps Swagger `MiniSeriesGiftDetails` (`GET api/mini-series/{id}/gift-details`):
  /// `miniSeriesId, title, currency, giftAvailable, giftUnitPrice (nullable),
  /// minQuantity, maxQuantity, giftValidityDays, paidParts`.
  factory MiniSeriesPurchaseQuote.fromGiftDetails(
    Map<String, dynamic> json, {
    required int shortId,
    required String title,
  }) {
    final unitPrice = _asDouble(json['giftUnitPrice']);
    final min = _asIntOrNull(json['minQuantity']) ?? 1;
    final backendTitle = json['title']?.toString() ?? '';
    return MiniSeriesPurchaseQuote(
      shortId: _asIntOrNull(json['miniSeriesId']) ?? shortId,
      title: backendTitle.isNotEmpty ? backendTitle : title,
      currency: json['currency']?.toString() ?? 'INR',
      totalParts: 0,
      purchasablePartCount: 0,
      ownedPartCount: 0,
      freePartCount: 0,
      parts: const [],
      fullPurchasePrice: 0,
      fullPurchaseAvailable: false,
      alreadyOwnsAll: false,
      // Backend flag is authoritative; a null/zero price is never giftable.
      giftAvailable: json['giftAvailable'] == true && unitPrice > 0,
      giftPrice: unitPrice,
      minGiftCount: min < 1 ? 1 : min,
      maxGiftCount: _asIntOrNull(json['maxQuantity']),
    );
  }

  factory MiniSeriesPurchaseQuote.fromJson(Map<String, dynamic> json) {
    final parts = (json['parts'] as List? ?? const [])
        .map((e) => MiniSeriesQuotePart.fromJson(_asMap(e)))
        .toList(growable: false);
    return MiniSeriesPurchaseQuote(
      shortId: _asIntOrNull(json['shortId']) ?? 0,
      title: json['title']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'INR',
      totalParts: _asIntOrNull(json['totalParts']) ?? parts.length,
      purchasablePartCount: _asIntOrNull(json['purchasablePartCount']) ??
          parts.where((p) => p.purchasable).length,
      ownedPartCount: _asIntOrNull(json['ownedPartCount']) ??
          parts.where((p) => p.owned).length,
      freePartCount: _asIntOrNull(json['freePartCount']) ??
          parts.where((p) => p.free).length,
      parts: parts,
      fullPurchasePrice: _asDouble(json['fullPurchasePrice']),
      fullPurchaseAvailable: json['fullPurchaseAvailable'] == true,
      alreadyOwnsAll: json['alreadyOwnsAll'] == true,
      giftAvailable: json['giftAvailable'] == true,
      giftPrice: _asDouble(json['giftPrice']),
      minGiftCount: _asIntOrNull(json['minGiftCount']) ?? 1,
      maxGiftCount: _asIntOrNull(json['maxGiftCount']),
    );
  }
}

/// Backend dates are epoch **milliseconds**; converted to local time.
DateTime? epochMillisToLocal(dynamic value) {
  int? millis;
  if (value is num) millis = value.toInt();
  if (value is String) millis = int.tryParse(value.trim());
  if (millis == null || millis <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
}

/// One single-use code from `gifts[]` of the gift purchase response.
class MiniSeriesGiftCode {
  const MiniSeriesGiftCode({
    required this.giftCode,
    required this.status,
    required this.expiryDate,
  });

  final String giftCode;
  final String status;
  final DateTime? expiryDate;

  factory MiniSeriesGiftCode.fromJson(Map<String, dynamic> json) =>
      MiniSeriesGiftCode(
        giftCode: json['giftCode']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        expiryDate: epochMillisToLocal(json['expiryDate']),
      );
}

/// `data` of `POST api/mini-series/gift/purchase`: `transactionId`,
/// `totalAmount`, `expiryDate`, `gifts[]` and, for a replayed idempotent
/// request, `idempotentReplay: true` (confirmed contract).
class MiniSeriesGiftPurchaseResult {
  const MiniSeriesGiftPurchaseResult({
    required this.transactionId,
    required this.totalAmount,
    required this.expiryDate,
    required this.gifts,
    required this.idempotentReplay,
  });

  final String transactionId;
  final double totalAmount;
  final DateTime? expiryDate;
  final List<MiniSeriesGiftCode> gifts;
  final bool idempotentReplay;

  factory MiniSeriesGiftPurchaseResult.fromJson(
    Map<String, dynamic> data, {
    Map<String, dynamic> envelope = const {},
  }) =>
      MiniSeriesGiftPurchaseResult(
        transactionId: data['transactionId']?.toString() ?? '',
        totalAmount: _asDouble(data['totalAmount']),
        expiryDate: epochMillisToLocal(data['expiryDate']),
        gifts: (data['gifts'] as List? ?? const [])
            .map((e) => MiniSeriesGiftCode.fromJson(_asMap(e)))
            .where((g) => g.giftCode.isNotEmpty)
            .toList(growable: false),
        idempotentReplay: data['idempotentReplay'] == true ||
            envelope['idempotentReplay'] == true,
      );
}

/// Outcome of a full purchase or gift request.
class MiniSeriesCommerceResult {
  const MiniSeriesCommerceResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.data = const {},
    this.statusCode,
    this.envelope = const {},
  });

  final bool success;
  final String message;
  final String? errorCode;
  final Map<String, dynamic> data;

  /// HTTP status; null when no response arrived (network failure/timeout).
  /// A null status means the outcome is uncertain, so a retry must reuse the
  /// same idempotency key.
  final int? statusCode;

  /// Whole decoded response body.
  final Map<String, dynamic> envelope;

  bool get isNetworkFailure => statusCode == null;

  /// Swagger `MiniSeriesInsufficientBalanceData` on HTTP 400:
  /// `data: {requiredAmount, availableBalance}`.
  bool get hasInsufficientBalanceData =>
      statusCode == 400 &&
      data.containsKey('requiredAmount') &&
      data.containsKey('availableBalance');
  double? get requiredAmount =>
      data['requiredAmount'] == null ? null : _asDouble(data['requiredAmount']);
  double? get availableBalance => data['availableBalance'] == null
      ? null
      : _asDouble(data['availableBalance']);

  bool get isInsufficientBalance => errorCode == 'INSUFFICIENT_BALANCE';
  bool get isPriceChanged => errorCode == 'PRICE_CHANGED';
  bool get isAlreadyOwned => errorCode == 'ALREADY_OWNED';

  double? get newBalance =>
      data['newBalance'] == null ? null : _asDouble(data['newBalance']);

  factory MiniSeriesCommerceResult.fromJson(
    Map<String, dynamic> json, {
    required String fallbackMessage,
    int? statusCode,
  }) {
    final message = json['message']?.toString().trim() ?? '';
    return MiniSeriesCommerceResult(
      success: json['success'] == true,
      message: message.isEmpty ? fallbackMessage : message,
      errorCode: json['errorCode']?.toString(),
      data: _asMap(json['data']),
      statusCode: statusCode,
      envelope: json,
    );
  }

  factory MiniSeriesCommerceResult.failure(String message,
          {String? errorCode}) =>
      MiniSeriesCommerceResult(
        success: false,
        message: message,
        errorCode: errorCode,
      );
}

/// Swagger `MiniSeriesGiftHistoryItem` (sender, `GET gift/history`) and
/// `MiniSeriesGiftReceivedItem` (recipient, `GET gift/received`). Dates are
/// epoch milliseconds. Fields missing from one schema stay null.
class MiniSeriesGiftHistoryEntry {
  const MiniSeriesGiftHistoryEntry({
    required this.giftId,
    required this.giftCode,
    required this.giftStatus,
    required this.miniSeriesId,
    required this.miniSeriesTitle,
    required this.poster,
    required this.transactionId,
    required this.giftPrice,
    required this.purchaseDate,
    required this.claimDate,
    required this.expiryDate,
    this.senderName,
    this.giftExpiryDate,
    this.accessValidUntil,
  });

  final int? giftId;
  final String giftCode;

  /// AVAILABLE, CLAIMED or EXPIRED.
  final String giftStatus;
  final int? miniSeriesId;
  final String miniSeriesTitle;
  final String poster;
  final String transactionId;

  /// Sender history only.
  final double? giftPrice;

  /// Sender history only.
  final DateTime? purchaseDate;
  final DateTime? claimDate;

  /// Gift-code claim deadline (legacy field, kept for compatibility).
  final DateTime? expiryDate;

  /// Received only: sender's display name; null when unknown.
  final String? senderName;

  /// Received only: deadline until which the code could be claimed. Same
  /// value as [expiryDate]. NOT the recipient's access validity.
  final DateTime? giftExpiryDate;

  /// Recipient's access validity. Not returned by `gift/received` today
  /// (only by the claim response); null unless the backend adds it.
  final DateTime? accessValidUntil;

  /// Gift-code expiry: `giftExpiryDate`, falling back to `expiryDate`.
  DateTime? get codeExpiry => giftExpiryDate ?? expiryDate;

  /// Sender name, or null when missing/blank (UI shows a fallback).
  String? get displaySenderName {
    final name = senderName?.trim();
    return name == null || name.isEmpty ? null : name;
  }

  bool get isAvailable => giftStatus.toUpperCase() == 'AVAILABLE';
  bool get isClaimed => giftStatus.toUpperCase() == 'CLAIMED';

  factory MiniSeriesGiftHistoryEntry.fromJson(Map<String, dynamic> json) =>
      MiniSeriesGiftHistoryEntry(
        giftId: _asIntOrNull(json['giftId']),
        giftCode: json['giftCode']?.toString() ?? '',
        giftStatus: json['giftStatus']?.toString() ?? '',
        miniSeriesId: _asIntOrNull(json['miniSeriesId']),
        miniSeriesTitle: json['miniSeriesTitle']?.toString() ?? '',
        poster: json['poster']?.toString() ?? '',
        transactionId: json['transactionId']?.toString() ?? '',
        giftPrice:
            json['giftPrice'] == null ? null : _asDouble(json['giftPrice']),
        purchaseDate: epochMillisToLocal(json['purchaseDate']),
        claimDate: epochMillisToLocal(json['claimDate']),
        expiryDate: epochMillisToLocal(json['expiryDate']),
        senderName: json['senderName']?.toString(),
        giftExpiryDate: epochMillisToLocal(json['giftExpiryDate']),
        accessValidUntil: epochMillisToLocal(json['accessValidUntil']),
      );

  static List<MiniSeriesGiftHistoryEntry> listFrom(dynamic data) =>
      (data as List? ?? const [])
          .map((e) => MiniSeriesGiftHistoryEntry.fromJson(_asMap(e)))
          .toList(growable: false);
}

/// Swagger `MiniSeriesGiftClaimData` (`POST gift/claim`).
class MiniSeriesGiftClaimResult {
  const MiniSeriesGiftClaimResult({
    required this.miniSeriesId,
    required this.miniSeriesTitle,
    required this.accessGranted,
    required this.grantedParts,
    required this.accessValidUntil,
    required this.claimDate,
  });

  final int? miniSeriesId;
  final String miniSeriesTitle;
  final bool accessGranted;

  /// Parts newly unlocked (already owned parts and free previews skipped).
  final int grantedParts;
  final DateTime? accessValidUntil;
  final DateTime? claimDate;

  factory MiniSeriesGiftClaimResult.fromJson(Map<String, dynamic> json) =>
      MiniSeriesGiftClaimResult(
        miniSeriesId: _asIntOrNull(json['miniSeriesId']),
        miniSeriesTitle: json['miniSeriesTitle']?.toString() ?? '',
        accessGranted: json['accessGranted'] == true,
        grantedParts: _asIntOrNull(json['grantedParts']) ?? 0,
        accessValidUntil: epochMillisToLocal(json['accessValidUntil']),
        claimDate: epochMillisToLocal(json['claimDate']),
      );
}
