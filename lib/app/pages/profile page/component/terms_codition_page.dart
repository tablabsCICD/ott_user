import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontDemoPage extends StatelessWidget {
  const FontDemoPage({super.key});

  static const demoText = "Now Streaming · Watch Anytime · Filmytell";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("OTT Font Preview"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          /// CORE OTT FONTS
          _section("Core OTT Fonts"),
          _tile("Inter", GoogleFonts.inter()),
          _tile("Montserrat", GoogleFonts.montserrat()),
          _tile("Poppins", GoogleFonts.poppins()),

          /// MODERN & PREMIUM
          _section("Modern & Premium"),
          _tile("Manrope", GoogleFonts.manrope()),
          _tile("Outfit", GoogleFonts.outfit()),
          _tile("Urbanist", GoogleFonts.urbanist()),
          _tile("DM Sans", GoogleFonts.dmSans()),

          /// CINEMATIC & TECH
          _section("Cinematic & Tech"),
          _tile("Space Grotesk", GoogleFonts.spaceGrotesk()),
          _tile("Rubik", GoogleFonts.rubik()),

          /// MULTILINGUAL & SAFE
          _section("Multilingual & Safe"),
          _tile("Noto Sans", GoogleFonts.notoSans()),
          _tile("Source Sans 3", GoogleFonts.sourceSans3()),
        ],
      ),
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

  Widget _tile(String name, TextStyle style) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
              fontSize: 20,
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
