import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/data/models/response/addWalletResponse.dart';
import 'package:ott/data/models/response/getWalletAmount.dart';
import 'package:ott/data/models/response/walletHistory.dart';
import 'package:ott/data/models/response/withdrawAmountResponse.dart';
import 'package:ott/data/models/user.dart';

import '../core/network/api_helper.dart';
import '../core/services/WalletService.dart';
import '../core/utils/sharepreferences.dart';

class WalletProvider extends ChangeNotifier {
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
      _transactionHistory =
          List<Transactions>.from(result['transactions'] as List<Transactions>);
      _filteredTransactionHistory = List<Transactions>.from(_transactionHistory);
      notifyListeners();
      return {
        'success': true,
        'message': 'Wallet refreshed successfully.',
      };
    }

    return {
      'success': false,
      'message': result['message']?.toString() ?? 'Failed to refresh wallet',
    };
  }

  Future<Map<String, Object>> onPaymentVerified() async {
    if (_isAddingBalance) {
      return {
        'success': false,
        'message': 'Recharge already in progress. Please wait.'
      };
    }

    _isAddingBalance = true;
    notifyListeners();

    try {
      final result = await refreshWalletData();
      return result;
    } finally {
      _isAddingBalance = false;
      notifyListeners();
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
    print(apiUrl);
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    Map<String, dynamic> mapData = {"amount": amount, "userId": user!.id};
    ApiHelper apiHelper = ApiHelper();

    try {
      var response = await apiHelper.postApiWithBody(apiUrl, mapData);
      print(response);
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
        // throw Exception('Failed to add user. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': 'An error occurred while adding user: $error'
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

      _walletBalance = withdrawAmountresponse.data?.newBalance ?? _walletBalance;
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
        'message': error.toString(),
      };
    } finally {
      _isDeductingBalance = false;
      notifyListeners();
    }
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
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': 'An error occurred while adding user: $error'
      };
    }
  }

  Future<Map<String, Object>> getBalance() async {
    try {
      final addUserResponse = await _walletService.getBalance();
      if (addUserResponse.success == true) {
        if (addUserResponse.data != null) {
          _wallet = addUserResponse.data!;
          _walletBalance = addUserResponse.data!.balance!;
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
    } catch (error) {
      _walletBalance = 0.0;
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': 'An error occurred while adding user: $error'
      };
    }
  }

  void resetTransactionFilters() {
    _filteredTransactionHistory.clear();
    _filteredTransactionHistory = List.from(_transactionHistory);
    notifyListeners();
  }
}
