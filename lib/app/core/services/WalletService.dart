import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/data/models/response/getWalletAmount.dart';
import 'package:ott/data/models/response/walletHistory.dart';
import 'package:ott/data/models/response/withdrawAmountResponse.dart';
import 'package:ott/data/models/user.dart';

class AppleIapWalletVerificationResult {
  const AppleIapWalletVerificationResult({
    required this.success,
    required this.message,
    this.walletBalance,
    this.creditedAmount,
  });

  final bool success;
  final String message;
  final double? walletBalance;
  final double? creditedAmount;
}

class WalletService {
  WalletService({
    ApiHelper? apiHelper,
    LocalSharePreferences? preferences,
  })  : _apiHelper = apiHelper ?? ApiHelper(),
        _preferences =
            preferences ?? LocalSharePreferences.localSharePreferences;

  final ApiHelper _apiHelper;
  final LocalSharePreferences _preferences;

  Future<User?> _getUser() => _preferences.getUser();

  Future<GetWalletAmountResponse> getBalance() async {
    final user = await _getUser();
    if (user?.id == null) {
      throw Exception('User not found');
    }

    final response = await _apiHelper
        .getApi(ApiConstant.getWalletBalanceByUserId(user!.id!));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch wallet balance');
    }

    return GetWalletAmountResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<WalletHistory> getTransactionHistory() async {
    final user = await _getUser();
    if (user?.id == null) {
      throw Exception('User not found');
    }

    var response =
        await _apiHelper.getApi(ApiConstant.walletHistory(user!.id!));
    if (response.statusCode != 200) {
      response = await _apiHelper.getApi(ApiConstant.walletHistoryV2(user.id!));
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch wallet history');
    }

    return WalletHistory.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<WithdrawAmountresponse> deductAmount({
    required double amount,
    required contentId,
  }) async {
    final user = await _getUser();
    if (user?.id == null) {
      throw Exception('User not found');
    }

    final response = await _apiHelper.postApi(
      ApiConstant.withdrawMoneyFromWallet(user!.id!, amount, contentId),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to deduct wallet amount');
    }

    final parsed = WithdrawAmountresponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    if (parsed.success != true) {
      throw Exception(parsed.message ?? 'Wallet deduction failed');
    }

    return parsed;
  }

  Future<AppleIapWalletVerificationResult> verifyAppleIapPurchase({
    required String productId,
    required String transactionId,
    required int walletAmount,
    required String receiptData,
  }) async {
    final user = await _getUser();
    if (user?.id == null) {
      throw Exception('User not found');
    }

    final response = await _apiHelper.postApiWithBody(
      ApiConstant.verifyAppleIapPurchase,
      {
        'userId': user!.id,
        'platform': 'IOS',
        'product_id': productId,
        'transaction_id': transactionId,
        'wallet_amount': walletAmount,
        'receipt_data': receiptData,
      },
    ).timeout(const Duration(seconds: 30));

    final responseBody = jsonDecode(response.body);
    final body = responseBody is Map<String, dynamic>
        ? responseBody
        : <String, dynamic>{};

    if (response.statusCode != 200) {
      throw Exception(
        body['message']?.toString() ?? 'Apple purchase verification failed',
      );
    }

    final success = body['success'] == true;
    final result = AppleIapWalletVerificationResult(
      success: success,
      message: body['message']?.toString() ??
          (success
              ? 'Wallet credited successfully'
              : 'Apple purchase verification failed'),
      walletBalance: _asDouble(
        body['walletBalance'] ??
            body['balance'] ??
            (body['data'] is Map<String, dynamic>
                ? (body['data'] as Map<String, dynamic>)['balance']
                : null),
      ),
      creditedAmount: _asDouble(body['creditedAmount'] ?? walletAmount),
    );

    if (!result.success) {
      throw Exception(result.message);
    }

    return result;
  }

  Future<Map<String, Object>> refreshWalletSnapshot() async {
    try {
      final balanceResponse = await getBalance();
      WalletHistory? historyResponse;
      Object? historyError;

      try {
        historyResponse = await getTransactionHistory();
      } catch (error) {
        historyError = error;
        debugPrint('Wallet history refresh error: $error');
      }

      return {
        'success': true,
        'wallet': balanceResponse.data ?? Wallet(),
        'balance': balanceResponse.data?.balance ?? 0.0,
        'transactions': historyResponse?.data ?? <Transactions>[],
        'historyUpdated': historyError == null,
        'message': historyError == null
            ? 'Wallet refreshed successfully.'
            : 'Wallet balance updated. Transaction history will refresh shortly.',
      };
    } catch (error) {
      debugPrint('Wallet refresh error: $error');
      return {
        'success': false,
        'message': error.toString(),
      };
    }
  }
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
