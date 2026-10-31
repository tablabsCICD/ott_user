import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/presentation/web_landing/designs/common/landing_action_handler.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Ecosystem download showcase with QR Code instant mobile scan & store links.
class MarketingAppEcosystemSection extends StatelessWidget {
  const MarketingAppEcosystemSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);
    final isDark = colors.isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final paddingHorizontal = isMobile ? 20.0 : 64.0;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: 36,
      ),
      padding: EdgeInsets.all(isMobile ? 24 : 44),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.surface,
            colors.surfaceElevated,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.primaryAccent.withOpacity(isDark ? 0.3 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetails(context, colors, isMobile: true),
                const SizedBox(height: 32),
                Center(child: _buildQrCode(context, colors)),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 6,
                  child: _buildDetails(context, colors, isMobile: false),
                ),
                const SizedBox(width: 48),
                Expanded(
                  flex: 4,
                  child: Center(child: _buildQrCode(context, colors)),
                ),
              ],
            ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    LandingThemeColors colors, {
    required bool isMobile,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.primaryAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'DOWNLOAD & WATCH EVERYWHERE',
            style: TextStyle(
              color: colors.primaryAccent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Take Filmytell With You On Any Screen',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: isMobile ? 22 : 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Install the official Filmytell app on your Android phone, iPhone, iPad, Android TV, and Amazon Fire Stick for the smoothest 4K playback and offline downloads.',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: isMobile ? 13 : 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),

        // App Store Buttons
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _EcosystemStoreBtn(
              label: 'Google Play',
              sublabel: 'GET IT ON',
              icon: Icons.android_rounded,
              onTap: () => LandingActionHandler.openExternal(
                context,
                AppConstant.playStoreLink,
              ),
            ),
            _EcosystemStoreBtn(
              label: 'App Store',
              sublabel: 'DOWNLOAD ON THE',
              icon: Icons.apple_rounded,
              onTap: () => LandingActionHandler.openExternal(
                context,
                AppConstant.appStoreLink,
              ),
            ),
            _EcosystemStoreBtn(
              label: 'Amazon Fire TV',
              sublabel: 'AVAILABLE ON',
              icon: Icons.tv_rounded,
              onTap: () => LandingActionHandler.openExternal(
                context,
                AppConstant.amazonFireTvLink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQrCode(BuildContext context, LandingThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(colors.isDark ? 0.35 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: AppConstant.playStoreLink,
              version: QrVersions.auto,
              size: 140.0,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Scan to Download App',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Point your phone camera to install',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EcosystemStoreBtn extends StatefulWidget {
  const _EcosystemStoreBtn({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_EcosystemStoreBtn> createState() => _EcosystemStoreBtnState();
}

class _EcosystemStoreBtnState extends State<_EcosystemStoreBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? colors.primaryAccent.withOpacity(0.15)
                : colors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? colors.primaryAccent : colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 26,
                color: _hovered ? colors.primaryAccent : colors.textPrimary,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.sublabel,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: _hovered ? colors.primaryAccent : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
