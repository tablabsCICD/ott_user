import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/services/wallet_platform.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/data/models/response/addWalletResponse.dart';
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
    this.requestedAmount,
    this.deductionAmount,
    this.deductionPercentage,
    this.deductionReason,
    this.operatingSystem,
    this.paymentGateway,
    this.settlementType,
    this.transactionId,
  });

  final bool success;
  final String message;
  final double? walletBalance;
  final double? creditedAmount;
  final double? requestedAmount;
  final double? deductionAmount;
  final double? deductionPercentage;
  final String? deductionReason;
  final String? operatingSystem;
  final String? paymentGateway;
  final String? settlementType;
  final String? transactionId;
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

  Future<AddWalletAmountResponse> addWalletAmount(double amount) async {
    final user = await _getUser();
    if (user?.id == null) {
      throw Exception('User not found');
    }

    final body = <String, dynamic>{
      'amount': amount,
      'userId': user!.id,
    };
    final operatingSystem = WalletPlatform.operatingSystem;
    if (operatingSystem != null) {
      body['operatingSystem'] = operatingSystem;
    }

    final response = await _apiHelper.postApiWithBody(
      ApiConstant.addMoneyToWallet,
      body,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add wallet amount');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Wallet credit returned an invalid response');
    }

    return AddWalletAmountResponse.fromJson(decoded);
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
        'productId': productId,
        'transactionId': transactionId,
        'walletAmount': walletAmount,
        'receiptData': receiptData,
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

    final success = body['success'] != false;
    final data = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : <String, dynamic>{};
    final creditedAmount =
        _asDouble(body['creditedAmount'] ?? data['creditedAmount']);
    final requestedAmount =
        _asDouble(body['requestedAmount'] ?? data['requestedAmount']) ??
            walletAmount.toDouble();
    final deductionAmount = _asDouble(
          body['deductionAmount'] ?? data['deductionAmount'],
        ) ??
        (creditedAmount == null ? null : requestedAmount - creditedAmount);
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
      creditedAmount: creditedAmount ?? walletAmount.toDouble(),
      requestedAmount: requestedAmount,
      deductionAmount: deductionAmount,
      deductionPercentage: _asDouble(
            body['deductionPercentage'] ?? data['deductionPercentage'],
          ) ??
          (deductionAmount == null || requestedAmount <= 0
              ? null
              : (deductionAmount / requestedAmount) * 100),
      deductionReason:
          (body['deductionReason'] ?? data['deductionReason'])?.toString() ??
              'iOS payment gateway charges',
      operatingSystem:
          (body['operatingSystem'] ?? data['operatingSystem'])?.toString() ??
              'IOS',
      paymentGateway:
          (body['paymentGateway'] ?? data['paymentGateway'])?.toString() ??
              'APPLE',
      settlementType:
          (body['settlementType'] ?? data['settlementType'])?.toString() ??
              'MONTHLY',
      transactionId:
          (body['transactionId'] ?? data['transactionId'] ?? transactionId)
              ?.toString(),
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
