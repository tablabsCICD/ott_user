import 'package:flutter/material.dart';

class BaseProvider extends ChangeNotifier {
  String appState = "Ideal";
  bool _disposed = false;

  BaseProvider([this.appState = "Ideal"]);

  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
