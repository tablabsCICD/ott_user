import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class FontDemoPage extends StatelessWidget {
  const FontDemoPage({super.key});

  static const demoText = "Now Streaming · Watch Anytime · Filmytell";

  @override
  Widget build(BuildContext context) {
    final isTv = ResponsiveWidget.isAndroidTv(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        // Android TV: compact bar for the 540 px canvas.
        toolbarHeight: isTv ? 48 : null,
        titleTextStyle: isTv
            ? const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              )
            : null,
        title: const Text("OTT Font Preview"),
      ),
      // Android TV: Up/Down on the remote scroll this text-only page
      // (pass-through on every other platform).
      body: OttTvKeyScroll(
        child: _buildList(isTv),
      ),
    );
  }

  Widget _buildList(bool isTv) {
    return ListView(
      padding: EdgeInsets.all(isTv ? 16 : 20),
      children: [
        /// CORE OTT FONTS
        _section("Core OTT Fonts"),
        _tile(isTv, "Inter", GoogleFonts.inter()),
        _tile(isTv, "Montserrat", GoogleFonts.montserrat()),
        _tile(isTv, "Poppins", GoogleFonts.poppins()),

        /// MODERN & PREMIUM
        _section("Modern & Premium"),
        _tile(isTv, "Manrope", GoogleFonts.manrope()),
        _tile(isTv, "Outfit", GoogleFonts.outfit()),
        _tile(isTv, "Urbanist", GoogleFonts.urbanist()),
        _tile(isTv, "DM Sans", GoogleFonts.dmSans()),

        /// CINEMATIC & TECH
        _section("Cinematic & Tech"),
        _tile(isTv, "Space Grotesk", GoogleFonts.spaceGrotesk()),
        _tile(isTv, "Rubik", GoogleFonts.rubik()),

        /// MULTILINGUAL & SAFE
        _section("Multilingual & Safe"),
        _tile(isTv, "Noto Sans", GoogleFonts.notoSans()),
        _tile(isTv, "Source Sans 3", GoogleFonts.sourceSans3()),
      ],
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _tile(bool isTv, String name, TextStyle style) {
    return Container(
      margin: EdgeInsets.only(bottom: isTv ? 10 : 16),
      padding: EdgeInsets.all(isTv ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: style.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            demoText,
            style: style.copyWith(
              fontSize: isTv ? 16 : 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
