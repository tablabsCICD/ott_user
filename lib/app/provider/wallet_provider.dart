import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/data/models/response/addWalletResponse.dart';
import 'package:ott/data/models/response/getWalletAmount.dart';
import 'package:ott/data/models/response/walletHistory.dart';
import 'package:ott/data/models/user.dart';

import '../core/network/api_helper.dart';
import '../core/services/WalletService.dart';
import '../core/utils/sharepreferences.dart';
import 'baseProvider.dart';

class WalletProvider extends BaseProvider {
  WalletProvider({
    WalletService? walletService,
  }) : _walletService = walletService ?? WalletService();

  final WalletService _walletService;
  double _walletBalance = 0.0;
  List<Transactions> _transactionHistory = [];

  double get walletBalance => _walletBalance;

  List<Transactions> get transactionHistory => _transactionHistory;

  bool _isAddingBalance = false;
  bool _isDeductingBalance = false;

  bool get isAddingBalance => _isAddingBalance;
  bool get isDeductingBalance => _isDeductingBalance;

  List<Transactions> _filteredTransactionHistory = [];

  List<Transactions> get filteredTransactionHistory =>
      _filteredTransactionHistory;

  TextEditingController amountController = TextEditingController();

  TextEditingController referController = TextEditingController();

  Future<Map<String, Object>> refreshWalletData() async {
    final result = await _walletService.refreshWalletSnapshot();
    if (result['success'] == true) {
      _wallet = result['wallet'] as Wallet;
      _walletBalance = (result['balance'] as num).toDouble();
      if (result['historyUpdated'] != false) {
        _transactionHistory = List<Transactions>.from(
            result['transactions'] as List<Transactions>);
        _filteredTransactionHistory =
            List<Transactions>.from(_transactionHistory);
      }
      notifyListeners();
      return {
        'success': true,
        'message':
            result['message']?.toString() ?? 'Wallet refreshed successfully.',
      };
    }

    return {
      'success': false,
      'message': result['message']?.toString() ?? 'Failed to refresh wallet',
    };
  }

  Future<Map<String, Object>> onPaymentVerified(
      {double? expectedAmount}) async {
    if (_isAddingBalance) {
      return {
        'success': false,
        'message': 'Recharge already in progress. Please wait.'
      };
    }

    _isAddingBalance = true;
    notifyListeners();

    try {
      final previousBalance = _walletBalance;
      final result = await refreshWalletData();
      if (result['success'] != true) {
        return result;
      }

      if (expectedAmount != null &&
          _walletBalance + 0.01 < previousBalance + expectedAmount) {
        await Future.delayed(const Duration(seconds: 2));
        final retryResult = await refreshWalletData();
        if (retryResult['success'] == true &&
            _walletBalance + 0.01 >= previousBalance + expectedAmount) {
          return {
            'success': true,
            'message': 'Wallet recharged successfully.',
          };
        }

        final fallbackResult = await _addBalanceAfterVerifiedPayment(
          expectedAmount,
        );
        if (fallbackResult['success'] == true) {
          await refreshWalletData();
          return {
            'success': true,
            'message': 'Wallet recharged successfully.',
          };
        }

        return {
          'success': false,
          'message': fallbackResult['message']?.toString() ??
              'Payment was verified, but the wallet balance has not updated yet. Please check again in a moment.',
        };
      }

      return {
        'success': true,
        'message': 'Wallet recharged successfully.',
      };
    } finally {
      _isAddingBalance = false;
      notifyListeners();
    }
  }

  Future<Map<String, Object>> _addBalanceAfterVerifiedPayment(
    double amount,
  ) async {
    try {
      final apiUrl = ApiConstant.addMoneyToWallet;
      final user = await LocalSharePreferences.localSharePreferences.getUser();
      if (user?.id == null) {
        return {
          'success': false,
          'message': 'Please log in again to update your wallet balance.',
        };
      }

      final response = await ApiHelper().postApiWithBody(
        apiUrl,
        {'amount': amount, 'userId': user!.id, "operatingSystem": "Android"},
      );

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message':
              'Payment was successful, but wallet credit failed. Please contact support.',
        };
      }

      final responseBody = json.decode(response.body);
      if (responseBody is! Map<String, dynamic>) {
        return {
          'success': false,
          'message':
              'Payment was successful, but wallet credit returned an invalid response.',
        };
      }

      final walletResponse = AddWalletAmountResponse.fromJson(responseBody);
      if (walletResponse.success != true) {
        return {
          'success': false,
          'message': walletResponse.message ??
              'Payment was successful, but wallet credit failed.',
        };
      }

      if (walletResponse.data?.balance != null) {
        _walletBalance = walletResponse.data!.balance!;
        await getTransactionHistory();
        notifyListeners();
      }

      return {
        'success': true,
        'message': walletResponse.message ?? 'Wallet recharged successfully.',
      };
    } catch (error) {
      debugPrint('Wallet credit fallback error: $error');
      return {
        'success': false,
        'message':
            'Payment was successful, but wallet credit failed. Please contact support.',
      };
    }
  }

  Future<Map<String, Object>> addBalance(double amount) async {
    if (_isAddingBalance) {
      return {
        'success': false,
        'message': 'Recharge already in progress. Please wait.'
      };
    }

    _isAddingBalance = true;
    notifyListeners();

    String apiUrl = ApiConstant.addMoneyToWallet;
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    Map<String, dynamic> mapData = {
      "amount": amount,
      "userId": user!.id,
      "operatingSystem": "Android"
    };
    ApiHelper apiHelper = ApiHelper();

    try {
      var response = await apiHelper.postApiWithBody(apiUrl, mapData);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        AddWalletAmountResponse addUserResponse =
            AddWalletAmountResponse.fromJson(responseBody);

        if (addUserResponse.success == true) {
          if (addUserResponse.data != null) {
            _walletBalance = addUserResponse.data!.balance!;
            await getTransactionHistory();
            notifyListeners();
            return {'success': true, 'message': addUserResponse.message!};
          } else {
            debugPrint("Empty data: ${addUserResponse.message}");
            return {
              'success': false,
              'message': addUserResponse.message ?? 'No data returned'
            };
          }
        } else {
          debugPrint("Error: ${addUserResponse.message}");
          return {
            'success': false,
            'message': addUserResponse.message ?? 'Error in response'
          };
        }
      } else {
        return {'failure': true, 'message': 'Something went wrong!'};
      }
    } catch (error) {
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': 'An error occurred while adding balance: $error'
      };
    } finally {
      _isAddingBalance = false;
      notifyListeners();
    }
  }

  Future<Map<String, Object>> deductBalance(
      double amount, int contentId) async {
    if (_isDeductingBalance) {
      return {
        'success': false,
        'message': 'Payment already in progress. Please wait.'
      };
    }

    _isDeductingBalance = true;
    notifyListeners();

    try {
      final withdrawAmountresponse = await _walletService.deductAmount(
        amount: amount,
        contentId: contentId,
      );

      _walletBalance =
          withdrawAmountresponse.data?.newBalance ?? _walletBalance;
      await getTransactionHistory();
      notifyListeners();
      return {
        'success': true,
        'message': withdrawAmountresponse.message ?? 'Payment successful'
      };
    } catch (error) {
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': _cleanWalletError(error),
      };
    } finally {
      _isDeductingBalance = false;
      notifyListeners();
    }
  }

  String _cleanWalletError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    final normalized = message.toLowerCase();
    if (normalized.contains('transactionrequiredexception') ||
        normalized.contains('no entitymanager with actual transaction') ||
        normalized.contains("cannot reliably process 'remove' call") ||
        normalized.contains('nested exception is javax.persistence')) {
      return 'Wallet payment could not be completed. Please try again in a moment.';
    }
    if (message.trim().isEmpty) {
      return 'Wallet payment failed. Please try again.';
    }
    return message;
  }

  Wallet _wallet = Wallet();
  Wallet get wallet => _wallet;

  Future<Map<String, Object>> getTransactionHistory() async {
    try {
      final walletHistory = await _walletService.getTransactionHistory();
      _transactionHistory.clear();
      _filteredTransactionHistory.clear();
      if (walletHistory.success == true) {
        if (walletHistory.data != null) {
          _transactionHistory = walletHistory.data!;
          _filteredTransactionHistory.addAll(_transactionHistory);
          notifyListeners();
          return {'success': true, 'message': walletHistory.message!};
        } else {
          debugPrint("Empty data: ${walletHistory.message}");
          return {
            'success': false,
            'message': walletHistory.message ?? 'No data returned'
          };
        }
      } else {
        debugPrint("Error: ${walletHistory.message}");
        return {
          'success': false,
          'message': walletHistory.message ?? 'Error in response'
        };
      }
    } catch (error) {
      debugPrint("Wallet history error: $error");
      return {
        'success': false,
        'message': 'Failed to load transaction history: $error'
      };
    }
  }

  Future<Map<String, Object>> getBalance() async {
    try {
      final balanceResponse = await _walletService.getBalance();
      if (balanceResponse.success == true) {
        if (balanceResponse.data != null) {
          _wallet = balanceResponse.data!;
          _walletBalance = balanceResponse.data!.balance!;
          notifyListeners();
          return {'success': true, 'message': balanceResponse.message!};
        } else {
          debugPrint("Empty data: ${balanceResponse.message}");
          return {
            'success': false,
            'message': balanceResponse.message ?? 'No data returned'
          };
        }
      } else {
        debugPrint("Error: ${balanceResponse.message}");
        return {
          'success': false,
          'message': balanceResponse.message ?? 'Error in response'
        };
      }
    } catch (error) {
      _walletBalance = 0.0;
      debugPrint("Wallet balance error: $error");
      return {
        'success': false,
        'message': 'Failed to load wallet balance: $error'
      };
    }
  }

  void clear() {
    _walletBalance = 0.0;
    _wallet = Wallet();
    _transactionHistory.clear();
    _filteredTransactionHistory.clear();
    _isAddingBalance = false;
    _isDeductingBalance = false;
    amountController.clear();
    referController.clear();
    notifyListeners();
  }

  void resetTransactionFilters() {
    _filteredTransactionHistory.clear();
    _filteredTransactionHistory = List.from(_transactionHistory);
    notifyListeners();
  }
}
