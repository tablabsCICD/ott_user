import 'package:flutter/material.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class InAppPrivacyPolicyPage extends StatelessWidget {
  const InAppPrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isTv = ResponsiveWidget.isTv(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13131A),
        elevation: 0,
        leading: OttTvFocus(
          autofocus: isTv,
          onTap: () => Navigator.of(context).maybePop(),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTv ? 22 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTv ? 48.0 : 20.0,
            vertical: 24.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filmytell Privacy Policy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTv ? 26 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: September 2026',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: isTv ? 14 : 12,
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                isTv,
                '1. Introduction',
                'Filmytell ("we", "our", or "us") is dedicated to protecting your privacy. This Privacy Policy outlines how your personal information is collected, used, and protected when you use the Filmytell OTT platform across mobile, web, and Smart TV / Set-Top Box applications.',
              ),
              _buildSection(
                isTv,
                '2. Information We Collect',
                '• Account & Authentication Data: Mobile number, name, email address (if provided), and authentication session credentials.\n'
                '• Device & Technical Information: Device model, operating system version, screen resolution, unique installation identifier, and network connectivity state.\n'
                '• Playback & Usage Statistics: Watch history, continue-watching progress, video player bitrate, playback errors, and content interactions for optimal streaming performance.',
              ),
              _buildSection(
                isTv,
                '3. How We Use Your Information',
                '• To authenticate and authorize your streaming access and entitlement privileges.\n'
                '• To resume your playback progress across all your connected devices.\n'
                '• To securely process purchases, subscription rentals, and digital wallet transactions.\n'
                '• To diagnose video streaming issues, mitigate piracy, and optimize CDN delivery.',
              ),
              _buildSection(
                isTv,
                '4. Data Protection & Security',
                'We implement industry-standard cryptographic protocols (TLS 1.3, encrypted local storage, signed URL verification) to safeguard your data. Filmytell does not sell, rent, or trade your personal data to third parties.',
              ),
              _buildSection(
                isTv,
                '5. Storage & Device Privacy on Set-Top Boxes',
                'On TV and Set-Top Box platforms (including JioSTB), Filmytell stores only necessary application configuration, playback bookmarks, and temporary cache data. We periodically verify available storage and respect system disk thresholds.',
              ),
              _buildSection(
                isTv,
                '6. Your Rights & Account Controls',
                'You may view and edit your account details, manage your active device sessions, or request account deletion directly from the Profile & Settings menu within the application.',
              ),
              _buildSection(
                isTv,
                '7. Contact & Support',
                'If you have any questions regarding this Privacy Policy or data protection, contact our support team at support@filmytell.com or visit https://filmytell.com.',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(bool isTv, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFFF28C28),
              fontSize: isTv ? 18 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isTv ? 15 : 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
