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
      final response = await _apiHelper.getApi(
        ApiConstant.purchaseHistory(
            user!.id!, formattedFromDate, formattedToDate, selectedType),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final parsed = PurchaseHistoryResponse.fromJson(body);
        _items = parsed.data;
        return {
          'success': true,
          'message': parsed.message ?? appL10n().msgPurchaseHistoryLoaded,
        };
      }

      _items = <PurchaseHistoryItem>[];
      _error = appL10n().msgFailedToLoadPurchaseHistory;
      return {'success': false, 'message': _error!};
    } catch (error) {
      _items = <PurchaseHistoryItem>[];
      _error = appL10n().msgFailedToLoadPurchaseHistory;
      return {'success': false, 'message': _error!};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isValidDateRange(DateTime fromDate, DateTime toDate) {
    return DateUtils.dateOnly(fromDate).isBefore(DateUtils.dateOnly(toDate));
  }
}
