import '../content.dart';

class PurchaseHistoryResponse {
  PurchaseHistoryResponse({
    this.message,
    this.statusCode,
    this.success,
    this.data = const <PurchaseHistoryItem>[],
  });

  final String? message;
  final int? statusCode;
  final bool? success;
  final List<PurchaseHistoryItem> data;

  factory PurchaseHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final rawList = rawData is List
        ? rawData
        : rawData is Map<String, dynamic> && rawData['items'] is List
            ? rawData['items'] as List
            : <dynamic>[];

    return PurchaseHistoryResponse(
      message: json['message']?.toString(),
      statusCode: json['statusCode'] is int
          ? json['statusCode'] as int
          : int.tryParse('${json['statusCode']}'),
      success: json['success'] == true,
      data: rawList
          .whereType<Map>()
          .map((item) => PurchaseHistoryItem.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }
}

class PurchaseHistoryItem {
  PurchaseHistoryItem({
    this.id,
    this.userId,
    this.amount,
    this.purchaseDate,
    this.content,
    this.invoiceNumber,
    this.invoiceId,
    this.invoiceUrl,
    this.paymentMethod,
    this.rentalDuration,
    this.contentType,
    this.itemTitle,
  });

  final int? id;
  final int? userId;
  final double? amount;
  final DateTime? purchaseDate;
  final Content? content;
  final String? invoiceNumber;
  final String? invoiceId;
  final String? invoiceUrl;
  final String? paymentMethod;
  final String? rentalDuration;
  final String? contentType;
  final String? itemTitle;

  factory PurchaseHistoryItem.fromJson(Map<String, dynamic> json) {
    final contentJson = json['content'] ?? json['movie'] ?? json['item'];
    final invoiceJson = json['invoice'];

    return PurchaseHistoryItem(
      id: _asInt(json['id']),
      userId: _asInt(json['userId']),
      amount: _asDouble(json['amount'] ?? json['price']),
      purchaseDate: _asDateTime(
        json['purchaseDate'] ?? json['date'] ?? json['createdDate'],
      ),
      content: contentJson is Map<String, dynamic>
          ? Content.fromJson(contentJson)
          : contentJson is Map
              ? Content.fromJson(Map<String, dynamic>.from(contentJson))
              : null,
      invoiceNumber: invoiceJson is Map<String, dynamic>
          ? invoiceJson['invoiceNumber']?.toString()
          : invoiceJson is Map
              ? invoiceJson['invoiceNumber']?.toString()
              : json['invoiceNumber']?.toString(),
      invoiceId: invoiceJson is Map<String, dynamic>
          ? invoiceJson['invoiceId']?.toString()
          : invoiceJson is Map
              ? invoiceJson['invoiceId']?.toString()
              : json['invoiceId']?.toString(),
      invoiceUrl: invoiceJson is Map<String, dynamic>
          ? invoiceJson['invoiceUrl']?.toString()
          : invoiceJson is Map
              ? invoiceJson['invoiceUrl']?.toString()
              : json['invoiceUrl']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      rentalDuration: json['rentalDuration']?.toString(),
      contentType: json['contentType']?.toString() ??
          (contentJson is Map ? contentJson['type']?.toString() : null),
      itemTitle: json['itemTitle']?.toString(),
    );
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is String && value.isNotEmpty) {
    final numeric = int.tryParse(value);
    if (numeric != null) {
      return DateTime.fromMillisecondsSinceEpoch(numeric);
    }
    return DateTime.tryParse(value);
  }
  return null;
}
