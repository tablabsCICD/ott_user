import 'package:flutter/material.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class InAppTermsConditionsPage extends StatelessWidget {
  const InAppTermsConditionsPage({super.key});

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
          'Terms & Conditions',
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
                'Filmytell Terms of Service',
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
                '1. Acceptance of Terms',
                'By accessing or using the Filmytell platform across web, mobile, and Smart TV / Set-Top Box applications, you agree to be bound by these Terms and Conditions. If you do not agree to all terms, please discontinue use of the service.',
              ),
              _buildSection(
                isTv,
                '2. User Accounts & Security',
                '• You are responsible for safeguarding your login credentials and authenticating via your registered phone number.\n'
                '• Each account is authorized for personal, non-commercial entertainment use.\n'
                '• Filmytell reserves the right to suspend or terminate accounts suspected of unauthorized redistribution, account sharing, or fraudulent activity.',
              ),
              _buildSection(
                isTv,
                '3. Content Licensing & Intellectual Property',
                'All media content, including movies, series, shorts, trailers, posters, graphics, and trademarks available on Filmytell, are protected by intellectual property and copyright laws. You are granted a personal, revocable, non-exclusive license to stream content through the official Filmytell application.',
              ),
              _buildSection(
                isTv,
                '4. Prohibited Activities & Anti-Piracy',
                '• Re-broadcasting, screen capturing, ripping, reverse engineering, or redistributing streamed content is strictly prohibited.\n'
                '• Filmytell employs dynamic watermarking and digital rights protection to prevent unauthorized copying.\n'
                '• Any attempt to circumvent digital rights management (DRM) or tamper with media tokens will result in immediate termination of access and potential legal action.',
              ),
              _buildSection(
                isTv,
                '5. Purchases, Subscriptions & Wallet',
                '• Content purchases, rentals, or wallet recharges completed through Filmytell are governed by the pricing displayed at the time of purchase.\n'
                '• Digital content rentals grant streaming rights for the specified entitlement window.\n'
                '• All payments are processed through secure payment gateways.',
              ),
              _buildSection(
                isTv,
                '6. Set-Top Box & TV Operation',
                'When accessing Filmytell through certified Set-Top Box platforms (including JioSTB), the app is designed for remote-control navigation. Filmytell adheres to platform guidelines concerning device memory, background resource utilization, and storage management.',
              ),
              _buildSection(
                isTv,
                '7. Limitation of Liability',
                'Filmytell provides streaming services on an "as is" and "as available" basis. While we strive for continuous, uninterrupted high-definition streaming, we are not liable for network latency, ISP throttling, or device hardware constraints beyond our reasonable control.',
              ),
              _buildSection(
                isTv,
                '8. Contact & Inquiries',
                'For questions or concerns regarding these Terms and Conditions, please reach out to our legal and support team at legal@filmytell.com or support@filmytell.com.',
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
