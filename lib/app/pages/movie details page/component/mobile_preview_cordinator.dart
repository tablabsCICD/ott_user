import 'package:flutter/foundation.dart';

class MobilePreviewCoordinator {
  /// Holds the currently active movie id
  static final ValueNotifier<int?> activeMovieId =
  ValueNotifier<int?>(null);

  /// Request preview for a card
  static void requestPreview(int movieId) {
    activeMovieId.value = movieId;
  }

  /// Stop preview if this card is active
  static void stopPreview(int movieId) {
    if (activeMovieId.value == movieId) {
      activeMovieId.value = null;
    }
  }
}
