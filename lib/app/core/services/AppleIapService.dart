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
  verification,
}

class AppleIapUserMessage {
  const AppleIapUserMessage({
    required this.type,
    required this.title,
    required this.message,
    this.requestedAmount,
    this.creditedAmount,
    this.deductionAmount,
    this.deductionPercentage,
    this.deductionReason,
    this.operatingSystem,
    this.paymentGateway,
    this.settlementType,
  });

  final AppleIapDialogType type;
  final String title;
  final String message;
  final double? requestedAmount;
  final double? creditedAmount;
  final double? deductionAmount;
  final double? deductionPercentage;
  final String? deductionReason;
  final String? operatingSystem;
  final String? paymentGateway;
  final String? settlementType;
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
  final Set<String> _verificationInProgress = {};

  bool _isAvailable = false;
  bool _isLoadingProducts = false;
  bool _isPurchasing = false;
  bool _isVerifying = false;
  bool _isRestoring = false;
  bool _initialized = false;
  String? _activeProductId;
  String? _errorMessage;
  AppleIapUserMessage? _pendingMessage;

  bool get isAvailable => _isAvailable;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isPurchasing => _isPurchasing;
  bool get isVerifying => _isVerifying;
  bool get isRestoring => _isRestoring;
  bool get isBusy =>
      _isLoadingProducts || _isPurchasing || _isVerifying || _isRestoring;
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

    if (_initialized) return;
    _initialized = true;

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

      // StoreKit returns only products available for sale to this storefront.
      // Never synthesize purchasable products from locally configured amounts.
      _products = response.productDetails
          .where((product) => productIds.contains(product.id))
          .toList()
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
    if (!_isAvailable || !_products.any((item) => item.id == product.id)) {
      _setMessage(
        AppleIapDialogType.unavailable,
        'Products unavailable',
        'Apple purchases are not available on this device right now.',
      );
      return;
    }

    if (isBusy) return;

    _isPurchasing = true;
    _activeProductId = product.id;
    _errorMessage = null;
    notifyListeners();

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      final launched = await _iap.buyConsumable(purchaseParam: purchaseParam);
      if (!launched) {
        _isPurchasing = false;
        _activeProductId = null;
        _setMessage(
          AppleIapDialogType.failed,
          'Purchase could not start',
          'Apple could not start this purchase. Please try again.',
        );
      }
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

  Future<void> restorePurchases() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS || isBusy) {
      return;
    }

    _isRestoring = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Consumables are not generally restorable from purchase history, but
      // StoreKit will redeliver unfinished transactions. Those transactions
      // are reverified by the purchase stream before they are completed.
      await _iap.restorePurchases();
      _setMessage(
        AppleIapDialogType.pending,
        'Purchases checked',
        'Any unfinished Apple purchases will be verified automatically.',
        notify: false,
      );
    } catch (error) {
      _setMessage(
        AppleIapDialogType.network,
        'Restore failed',
        'Unable to check Apple purchases. Please check your connection and try again.',
        notify: false,
      );
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      var shouldComplete = false;
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
          shouldComplete = await _verifyPurchase(purchase);
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
          shouldComplete = true;
          break;
        case PurchaseStatus.restored:
          shouldComplete = await _verifyPurchase(purchase, restored: true);
          break;
        case PurchaseStatus.canceled:
          _isPurchasing = false;
          _activeProductId = null;
          _setMessage(
            AppleIapDialogType.cancelled,
            'Purchase cancelled',
            'Your purchase was cancelled.',
          );
          shouldComplete = true;
          break;
      }

      // A successful backend verification is the only condition that permits
      // completing a paid transaction. Failed verification stays unfinished
      // so StoreKit can redeliver it for a later retry.
      if (shouldComplete && purchase.pendingCompletePurchase) {
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

  Future<bool> _verifyPurchase(
    PurchaseDetails purchase, {
    bool restored = false,
  }) async {
    final walletAmount = _walletAmountFor(purchase.productID);
    if (walletAmount <= 0) {
      _isPurchasing = false;
      _activeProductId = null;
      _setMessage(
        AppleIapDialogType.unavailable,
        'Invalid product',
        'This Apple wallet product is not available.',
      );
      return false;
    }

    final purchaseId = purchase.purchaseID?.trim() ?? '';
    final receiptData = purchase.verificationData.serverVerificationData.trim();
    final purchaseKey = purchaseId.isNotEmpty ? purchaseId : receiptData;

    if (purchaseId.isEmpty || receiptData.isEmpty) {
      _isPurchasing = false;
      _activeProductId = null;
      _setMessage(
        AppleIapDialogType.failed,
        'Invalid receipt',
        'Apple returned incomplete purchase data. The wallet was not credited.',
      );
      return false;
    }

    if (_creditedPurchaseKeys.contains(purchaseKey)) {
      _isPurchasing = false;
      _activeProductId = null;
      notifyListeners();
      return true;
    }
    if (!_verificationInProgress.add(purchaseKey)) return false;

    _isVerifying = true;
    _setMessage(
      AppleIapDialogType.verification,
      'Verifying purchase',
      'Your Apple purchase is being verified securely.',
    );
    try {
      // Apple IAP only collects payment. The backend verifies Apple purchase
      // data before crediting the Filmytell wallet.
      final result = await _walletService.verifyAppleIapPurchase(
        productId: purchase.productID,
        transactionId: purchaseId,
        walletAmount: walletAmount,
        receiptData: receiptData,
      );
      _creditedPurchaseKeys.add(purchaseKey);
      _isPurchasing = false;
      _activeProductId = null;
      final creditedAmount = result.creditedAmount ?? walletAmount.toDouble();
      _setMessage(
        restored ? AppleIapDialogType.restored : AppleIapDialogType.success,
        restored ? 'Purchase Restored' : 'Wallet Recharge Successful',
        '\u20B9${creditedAmount.toStringAsFixed(2)} has been added to your wallet.',
        requestedAmount: result.requestedAmount ?? walletAmount.toDouble(),
        creditedAmount: creditedAmount,
        deductionAmount: result.deductionAmount,
        deductionPercentage: result.deductionPercentage,
        deductionReason: result.deductionReason,
        operatingSystem: result.operatingSystem,
        paymentGateway: result.paymentGateway,
        settlementType: result.settlementType,
      );
      return true;
    } catch (error) {
      _isPurchasing = false;
      _activeProductId = null;
      final isNetworkFailure = error is TimeoutException;
      _setMessage(
        isNetworkFailure
            ? AppleIapDialogType.network
            : AppleIapDialogType.failed,
        'Verification failed',
        isNetworkFailure
            ? 'The verification service could not be reached. The wallet was not credited. Use Restore Purchases to retry.'
            : 'Apple could not validate this receipt. The wallet was not credited. Please contact support if the purchase appears in your Apple history.',
      );
      return false;
    } finally {
      _verificationInProgress.remove(purchaseKey);
      _isVerifying = false;
      notifyListeners();
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
    double? requestedAmount,
    double? creditedAmount,
    double? deductionAmount,
    double? deductionPercentage,
    String? deductionReason,
    String? operatingSystem,
    String? paymentGateway,
    String? settlementType,
  }) {
    _pendingMessage = AppleIapUserMessage(
      type: type,
      title: title,
      message: message,
      requestedAmount: requestedAmount,
      creditedAmount: creditedAmount,
      deductionAmount: deductionAmount,
      deductionPercentage: deductionPercentage,
      deductionReason: deductionReason,
      operatingSystem: operatingSystem,
      paymentGateway: paymentGateway,
      settlementType: settlementType,
    );
    _errorMessage = type == AppleIapDialogType.success ||
            type == AppleIapDialogType.pending ||
            type == AppleIapDialogType.restored ||
            type == AppleIapDialogType.verification
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
