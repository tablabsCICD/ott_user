import 'dart:convert';

import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/data/models/response/getWalletAmount.dart';
import 'package:ott/data/models/response/walletHistory.dart';
import 'package:ott/data/models/response/withdrawAmountResponse.dart';
import 'package:ott/data/models/user.dart';

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

    final response =
        await _apiHelper.getApi(ApiConstant.walletHistory(user!.id!));
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

  Future<Map<String, Object>> refreshWalletSnapshot() async {
    try {
      final balanceResponse = await getBalance();
      WalletHistory? historyResponse;
      Object? historyError;

      try {
        historyResponse = await getTransactionHistory();
      } catch (error) {
        historyError = error;

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

      return {
        'success': false,
        'message': error.toString(),
      };
    }
  }
}
