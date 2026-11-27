import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/data/models/response/purchase_history_response.dart';
import 'baseProvider.dart';
import 'package:ott/app/core/utils/app_l10n.dart';

class PurchaseHistoryProvider extends BaseProvider {
  final ApiHelper _apiHelper = ApiHelper();

  bool _isLoading = false;
  String? _error;
  DateTime _selectedToDate = DateTime.now();
  DateTime _selectedFromDate =
      DateTime.now().subtract(const Duration(days: 30));

// Dropdown value
  String selectedType = "All";
  List<PurchaseHistoryItem> _items = <PurchaseHistoryItem>[];

  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedFromDate => _selectedFromDate;
  DateTime get selectedToDate => _selectedToDate;
  List<PurchaseHistoryItem> get items => List.unmodifiable(_items);

  Future<void> setDate(DateTime date, bool isFromDate) async {
    isFromDate ? _selectedFromDate = date : _selectedToDate = date;
    notifyListeners();
    await fetchPurchaseHistory();
  }

  Future<void> setSelectedType(String type) async {
    if (selectedType == type) return;
    selectedType = type;
    notifyListeners();
    await fetchPurchaseHistory();
  }

  Future<Map<String, Object>> fetchPurchaseHistory() async {
    if (!_isValidDateRange(_selectedFromDate, _selectedToDate)) {
      _isLoading = false;
      _items = <PurchaseHistoryItem>[];
      _error = appL10n().startDateBeforeEndDate;
      notifyListeners();
      return {'success': false, 'message': _error!};
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await LocalSharePreferences.localSharePreferences.getUser();
      if (user?.id == null) {
        _items = <PurchaseHistoryItem>[];
        _error = appL10n().msgUserNotFoundPeriod;
        return {'success': false, 'message': _error!};
      }

      final formattedFromDate =
          DateFormat('yyyy-MM-dd').format(_selectedFromDate);
      final formattedToDate = DateFormat('yyyy-MM-dd').format(_selectedToDate);
      final url = ApiConstant.purchaseHistory(
          user!.id!, formattedFromDate, formattedToDate, selectedType);
      final stopwatch = Stopwatch()..start();
      _log('[PURCHASE_HISTORY]', 'REQUEST GET $url');
      final response = await _apiHelper.getApi(url);
      _log('[PURCHASE_HISTORY]',
          'RESPONSE status=${response.statusCode} duration=${stopwatch.elapsedMilliseconds}ms');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _logResponseShape(body);
        final parsed = PurchaseHistoryResponse.fromJson(body);
        _items = parsed.data;
        _log('[PURCHASE_HISTORY]', 'PARSED ITEMS: ${_items.length}');
        return {
          'success': true,
          'message': parsed.message ?? appL10n().msgPurchaseHistoryLoaded,
        };
      }

      _items = <PurchaseHistoryItem>[];
      _error = appL10n().msgFailedToLoadPurchaseHistory;
      return {'success': false, 'message': _error!};
    } catch (error, stackTrace) {
      _log('[PURCHASE_HISTORY]',
          'EXCEPTION ${error.runtimeType}: $error\n${stackTrace.toString().split('\n').take(5).join('\n')}');
      _items = <PurchaseHistoryItem>[];
      _error = appL10n().msgFailedToLoadPurchaseHistory;
      return {'success': false, 'message': _error!};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _log(String tag, String message) {
    if (!kDebugMode) return;
    for (final line in message.split('\n')) {
      debugPrint('$tag $line', wrapWidth: 1024);
    }
  }

  /// Debug-only: the field NAMES (and value types) of each history item, so
  /// the real gift / sender / access-expiry fields can be identified without
  /// logging any values (no personal or payment data).
  void _logResponseShape(Map<String, dynamic> body) {
    if (!kDebugMode) return;
    final data = body['data'];
    final list = data is List
        ? data
        : (data is Map && data['items'] is List ? data['items'] as List : const []);
    _log('[PURCHASE_HISTORY]',
        'ENVELOPE KEYS: ${body.keys.toList()} | data type: ${data.runtimeType} | items: ${list.length}');
    String shape(Map m) => (m.keys.map((k) => '$k:${m[k].runtimeType}').toList()
          ..sort())
        .join(', ');
    final candidate =
        RegExp(r'gift|sender|from|expir|valid|access|dateto|enddate|remaining', caseSensitive: false);
    for (var i = 0; i < list.length && i < 30; i++) {
      final item = list[i];
      if (item is! Map) continue;
      _log('[PURCHASE_HISTORY]', 'ITEM[$i] FIELDS: ${shape(item)}');
      for (final nested in item.entries.where((e) => e.value is Map)) {
        _log('[PURCHASE_HISTORY]',
            'ITEM[$i].${nested.key} FIELDS: ${shape(nested.value as Map)}');
      }
      final giftKeys = item.keys.where((k) => candidate.hasMatch('$k')).toList();
      _log('[PURCHASE_HISTORY_GIFT_DETAILS]',
          'ITEM[$i] gift/sender-like fields: ${giftKeys.where((k) => RegExp(r'gift|sender|from', caseSensitive: false).hasMatch('$k')).toList()}');
      _log('[PURCHASE_HISTORY_EXPIRY]',
          'ITEM[$i] expiry/validity-like fields: ${giftKeys.where((k) => RegExp(r'expir|valid|access|dateto|enddate|remaining', caseSensitive: false).hasMatch('$k')).toList()}');
    }
  }

  bool _isValidDateRange(DateTime fromDate, DateTime toDate) {
    return DateUtils.dateOnly(fromDate).isBefore(DateUtils.dateOnly(toDate));
  }
}
