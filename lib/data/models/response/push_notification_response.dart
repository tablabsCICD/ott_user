class PushNotificationResponse {
  PushNotificationResponse({
    this.success,
    this.message,
    this.data,
    this.statusCode,
  });

  final bool? success;
  final String? message;
  final PushNotificationPageData? data;
  final int? statusCode;

  factory PushNotificationResponse.fromJson(Map<String, dynamic> json) {
    return PushNotificationResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      statusCode: _asInt(json['statusCode']),
      data: json['data'] is Map<String, dynamic>
          ? PushNotificationPageData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class PushNotificationPageData {
  PushNotificationPageData({
    required this.content,
    this.pageNumber,
    this.pageSize,
    this.totalPages,
    this.totalElements,
    this.last,
    this.first,
  });

  final List<PushNotificationItem> content;
  final int? pageNumber;
  final int? pageSize;
  final int? totalPages;
  final int? totalElements;
  final bool? last;
  final bool? first;

  factory PushNotificationPageData.fromJson(Map<String, dynamic> json) {
    return PushNotificationPageData(
      content: (json['content'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(PushNotificationItem.fromJson)
              .toList() ??
          [],
      pageNumber: _asInt(json['number'] ?? json['pageNumber']),
      pageSize: _asInt(json['size'] ?? json['pageSize']),
      totalPages: _asInt(json['totalPages']),
      totalElements: _asInt(json['totalElements']),
      last: json['last'] as bool?,
      first: json['first'] as bool?,
    );
  }
}

class PushNotificationItem {
  PushNotificationItem({
    this.id,
    this.notificationTitle,
    this.messageDescription,
    this.emailSubject,
    this.attachmentUrl,
    this.mediaHouseId,
    this.priority,
    this.recipientType,
    this.notificationType,
    this.totalRecipients,
    this.successCount,
    this.failedCount,
    this.deliveryStatus,
    this.sentBy,
    this.recipientId,
    this.sentDateTime,
    this.createdDate,
    this.openedAt,
    this.readAt,
    required this.attachments,
  });

  final int? id;
  final String? notificationTitle;
  final String? messageDescription;
  final String? emailSubject;
  final String? attachmentUrl;
  final int? mediaHouseId;
  final String? priority;
  final String? recipientType;
  final String? notificationType;
  final int? totalRecipients;
  final int? successCount;
  final int? failedCount;
  final String? deliveryStatus;
  final String? sentBy;
  final int? recipientId;
  final String? sentDateTime;
  final String? createdDate;
  final String? openedAt;
  final String? readAt;
  final List<PushNotificationAttachment> attachments;

  String get title => _clean(notificationTitle) ?? 'Notification';
  String get body => _clean(messageDescription) ?? 'No message available';
  String? get displayDate => _clean(sentDateTime) ?? _clean(createdDate);

  factory PushNotificationItem.fromJson(Map<String, dynamic> json) {
    return PushNotificationItem(
      id: _asInt(json['id']),
      notificationTitle: json['notificationTitle']?.toString(),
      messageDescription: json['messageDescription']?.toString(),
      emailSubject: json['emailSubject']?.toString(),
      attachmentUrl: json['attachmentUrl']?.toString(),
      mediaHouseId: _asInt(json['mediaHouseId']),
      priority: json['priority']?.toString(),
      recipientType: json['recipientType']?.toString(),
      notificationType: json['notificationType']?.toString(),
      totalRecipients: _asInt(json['totalRecipients']),
      successCount: _asInt(json['successCount']),
      failedCount: _asInt(json['failedCount']),
      deliveryStatus: json['deliveryStatus']?.toString(),
      sentBy: json['sentBy']?.toString(),
      recipientId: _asInt(json['recipientId']),
      sentDateTime: json['sentDateTime']?.toString(),
      createdDate: json['createdDate']?.toString(),
      openedAt: json['openedAt']?.toString(),
      readAt: json['readAt']?.toString(),
      attachments: (json['attachments'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(PushNotificationAttachment.fromJson)
              .toList() ??
          [],
    );
  }
}

class PushNotificationAttachment {
  PushNotificationAttachment({
    this.id,
    this.fileName,
    this.fileUrl,
    this.fileSize,
    this.fileType,
    this.createdDate,
  });

  final int? id;
  final String? fileName;
  final String? fileUrl;
  final int? fileSize;
  final String? fileType;
  final String? createdDate;

  factory PushNotificationAttachment.fromJson(Map<String, dynamic> json) {
    return PushNotificationAttachment(
      id: _asInt(json['id']),
      fileName: json['fileName']?.toString(),
      fileUrl: json['fileUrl']?.toString(),
      fileSize: _asInt(json['fileSize']),
      fileType: json['fileType']?.toString(),
      createdDate: json['createdDate']?.toString(),
    );
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? _clean(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}
