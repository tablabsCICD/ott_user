import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/constant/image_constant.dart';

class AboutFilmytellDialog {
  static void show(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 90,
                    width: 90,
                    child: ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(100),
                      child: Image.asset(
                        ImageConstant.logo,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🎬 App Name
                  Text(
                    "Filmytell",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.canvasColor,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 🏷 Tagline
                  Text(
                    "Your stories. Your screen.",
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.canvasColor.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 📄 Description
                  Text(
                    "Filmytell is a premium OTT platform bringing you movies, series, and exclusive content across multiple languages. Enjoy seamless streaming, smart recommendations, and a cinematic experience across all your devices.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: theme.canvasColor.withOpacity(0.85),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _infoRow(theme, "Version", AppConstant.appVersion),
                  _infoRow(theme, "Platform", "Android • iOS • Web"),
                  _infoRow(theme, "Developed by", "Filmytell Team"),

                  const SizedBox(height: 20),

                  // ✅ Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: theme.canvasColor.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.canvasColor,
            ),
          ),
        ],
      ),
    );
  }
}
