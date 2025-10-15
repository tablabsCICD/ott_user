import 'package:flutter/material.dart';

class FullScreenProvider extends ChangeNotifier {
  bool _isFullScreen = false; // Initial value

  bool get isFullScreen => _isFullScreen;

  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen; // Toggle the boolean value
    notifyListeners(); // Notify listeners about the change
  }

  void setFullScreen(bool value) {
    _isFullScreen = value; // Set the value explicitly
    notifyListeners(); // Notify listeners about the change
  }
}
