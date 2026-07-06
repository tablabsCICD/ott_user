// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ott/app/core/services/WalletService.dart';

class AppleWalletPackage {
  const AppleWalletPackage({
    required this.walletAmount,
    required this.productId,
    required this.title,
  });

  final int walletAmount;
  final String productId;
  final String title;
}

enum AppleIapDialogType {
  success,
  failed,
  cancelled,
  network,
  unavailable,
  pending,
  restored,
}

class AppleIapUserMessage {
  const AppleIapUserMessage({
    required this.type,
    required this.title,
    required this.message,
  });

  final AppleIapDialogType type;
  final String title;
  final String message;
}

class AppleIapService extends ChangeNotifier {
  AppleIapService({
    InAppPurchase? inAppPurchase,
    WalletService? walletService,
  })  : _iap = inAppPurchase ?? InAppPurchase.instance,
        _walletService = walletService ?? WalletService();

  static const List<AppleWalletPackage> packages = [
    AppleWalletPackage(
      walletAmount: 99,
      productId: 'com.filmytell.wallet.99',
      title: 'Filmytell Wallet \u20B999',
    ),
    AppleWalletPackage(
      walletAmount: 199,
      productId: 'com.filmytell.wallet.199',
      title: 'Filmytell Wallet \u20B9199',
    ),
    AppleWalletPackage(
      walletAmount: 499,
      productId: 'com.filmytell.wallet.499',
      title: 'Filmytell Wallet \u20B9499',
    ),
    AppleWalletPackage(
      walletAmount: 999,
      productId: 'com.filmytell.wallet.999',
      title: 'Filmytell Wallet \u20B9999',
    ),
  ];

  static const Set<String> productIds = {
    'com.filmytell.wallet.99',
    'com.filmytell.wallet.199',
    'com.filmytell.wallet.499',
    'com.filmytell.wallet.999',
  };

  final InAppPurchase _iap;
  final WalletService _walletService;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  List<ProductDetails> _products = [];
  Set<String> _notFoundProductIds = {};
  final Set<String> _creditedPurchaseKeys = {};

  bool _isAvailable = false;
  bool _isLoadingProducts = false;
  bool _isPurchasing = false;
  String? _activeProductId;
  String? _errorMessage;
  AppleIapUserMessage? _pendingMessage;

  bool get isAvailable => _isAvailable;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isPurchasing => _isPurchasing;
  String? get activeProductId => _activeProductId;
  String? get errorMessage => _errorMessage;
  AppleIapUserMessage? get pendingMessage => _pendingMessage;
  List<ProductDetails> get products => List.unmodifiable(_products);
  Set<String> get notFoundProductIds => Set.unmodifiable(_notFoundProductIds);

  ProductDetails? productFor(String productId) {
    for (final product in _products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      _isAvailable = false;
      _errorMessage = 'Apple wallet packages are available only on iOS.';
      notifyListeners();
      return;
    }

    _purchaseSubscription ??= _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _isPurchasing = false;
        _activeProductId = null;
        _setMessage(
          AppleIapDialogType.failed,
          'Purchase failed',
          'Unable to process purchase updates. Please try again.',
        );
      },
    );

    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

    _isLoadingProducts = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        _products = [];
        _setMessage(
          AppleIapDialogType.unavailable,
          'Products unavailable',
          'Apple purchases are not available on this device right now.',
          notify: false,
        );
        return;
      }

      final ProductDetailsResponse response =
          await _iap.queryProductDetails(productIds);
      if (response.error != null) {
        _products = [];
        _errorMessage = response.error!.message;
        _setMessage(
          AppleIapDialogType.unavailable,
          'Products unavailable',
          response.error!.message,
          notify: false,
        );
        return;
      }

      _products = List<ProductDetails>.from(response.productDetails)
        ..sort((a, b) => _walletAmountFor(a.id).compareTo(
              _walletAmountFor(b.id),
            ));
      _notFoundProductIds = Set<String>.from(response.notFoundIDs);

      if (_products.isEmpty) {
        _setMessage(
          AppleIapDialogType.unavailable,
          'Products unavailable',
          'Wallet credit packages are not configured for this Apple ID yet.',
          notify: false,
        );
      }
    } catch (error) {
      _errorMessage = error.toString();
      _setMessage(
        AppleIapDialogType.network,
        'Network error',
        'Unable to load wallet packages. Please check your connection.',
        notify: false,
      );
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  Future<void> buyProduct(ProductDetails product) async {
    if (!_isAvailable) {
      _setMessage(
        AppleIapDialogType.unavailable,
        'Products unavailable',
        'Apple purchases are not available on this device right now.',
      );
      return;
    }

    _isPurchasing = true;
    _activeProductId = product.id;
    _errorMessage = null;
    notifyListeners();

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyConsumable(purchaseParam: purchaseParam);
    } catch (error) {
      _isPurchasing = false;
      _activeProductId = null;
      _setMessage(
        AppleIapDialogType.failed,
        'Purchase failed',
        'Unable to start Apple purchase. Please try again.',
      );
    }
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _isPurchasing = true;
          _activeProductId = purchase.productID;
          _setMessage(
            AppleIapDialogType.pending,
            'Purchase pending',
            'Apple is processing your wallet credit purchase.',
          );
          break;
        case PurchaseStatus.purchased:
          await _verifyPurchase(purchase);
          break;
        case PurchaseStatus.error:
          _isPurchasing = false;
          _activeProductId = null;
          final isCancelled = purchase.error?.code == 'purchase_cancelled' ||
              purchase.error?.code == 'storekit_duplicate_product_object';
          _setMessage(
            isCancelled
                ? AppleIapDialogType.cancelled
                : AppleIapDialogType.failed,
            isCancelled ? 'Purchase cancelled' : 'Purchase failed',
            purchase.error?.message ??
                (isCancelled
                    ? 'Your purchase was cancelled.'
                    : 'Apple could not complete the purchase.'),
          );
          break;
        case PurchaseStatus.restored:
          await _verifyPurchase(purchase);
          break;
        case PurchaseStatus.canceled:
          _isPurchasing = false;
          _activeProductId = null;
          _setMessage(
            AppleIapDialogType.cancelled,
            'Purchase cancelled',
            'Your purchase was cancelled.',
          );
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _completePurchase(purchase);
      }
    }
  }

  Future<void> _completePurchase(PurchaseDetails purchase) async {
    try {
      await _iap.completePurchase(purchase);
    } catch (error) {
      debugPrint('Apple IAP completePurchase failed: $error');
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    final walletAmount = _walletAmountFor(purchase.productID);
    if (walletAmount <= 0) {
      _isPurchasing = false;
      _activeProductId = null;
      _setMessage(
        AppleIapDialogType.unavailable,
        'Invalid product',
        'This Apple wallet product is not available.',
      );
      return;
    }

    final purchaseId =
        purchase.purchaseID ?? purchase.verificationData.localVerificationData;
    final purchaseKey = purchaseId.isNotEmpty
        ? purchaseId
        : purchase.verificationData.serverVerificationData;

    if (_creditedPurchaseKeys.contains(purchaseKey)) {
      _isPurchasing = false;
      _activeProductId = null;
      notifyListeners();
      return;
    }

    try {
      // Apple IAP only collects payment. The backend verifies Apple purchase
      // data before crediting the Filmytell wallet.
      final result = await _walletService.verifyAppleIapPurchase(
        productId: purchase.productID,
        transactionId: purchaseId,
        walletAmount: walletAmount,
        receiptData: purchase.verificationData.serverVerificationData,
      );
      _creditedPurchaseKeys.add(purchaseKey);
      _isPurchasing = false;
      _activeProductId = null;
      final creditedAmount = result.creditedAmount ?? walletAmount.toDouble();
      _setMessage(
        AppleIapDialogType.success,
        'Wallet recharged',
        '\u20B9${creditedAmount.toStringAsFixed(0)} has been added to your wallet.',
      );
    } catch (error) {
      _isPurchasing = false;
      _activeProductId = null;
      _setMessage(
        AppleIapDialogType.network,
        'Wallet credit failed',
        'Payment succeeded, but wallet credit failed. Please contact support.',
      );
    }
  }

  void consumeMessage() {
    _pendingMessage = null;
  }

  int _walletAmountFor(String productId) {
    for (final package in packages) {
      if (package.productId == productId) return package.walletAmount;
    }
    return 0;
  }

  void _setMessage(
    AppleIapDialogType type,
    String title,
    String message, {
    bool notify = true,
  }) {
    _pendingMessage = AppleIapUserMessage(
      type: type,
      title: title,
      message: message,
    );
    _errorMessage = type == AppleIapDialogType.success ||
            type == AppleIapDialogType.pending ||
            type == AppleIapDialogType.restored
        ? null
        : message;
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
