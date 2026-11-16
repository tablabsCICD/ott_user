import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';

class MadiooPage extends StatefulWidget {
  const MadiooPage({super.key, this.useParentScroll = false});

  final bool useParentScroll;

  @override
  State<MadiooPage> createState() => _MadiooPageState();
}

class _MadiooPageState extends State<MadiooPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final int barCount = 5;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 🎵 Animated sound bars
  Widget _buildWaveBars(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(barCount, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double value = sin((_controller.value * 2 * pi) + index);
            double height = 10 + (value.abs() * 30);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Android TV: sized for the 540 px canvas with the shared TV gutter and
    // some room above, so the message sits under the tabs, not against them.
    final tv = ResponsiveWidget.isAndroidTv(context);
    return Padding(
      padding: tv
          ? const EdgeInsets.fromLTRB(
              TvDesign.pageGutter, 48, TvDesign.pageGutter, 24)
          : const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
        /// 📻 Radio Icon with glow
          /*  Container(
            padding: const EdgeInsets.all(20),
            child: Hero(
              tag: "logo",
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {},
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    ImageConstant.madiooLogo,
                    width: 75,
                    height: 75,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
 */
          /// 🎧 Title
          Text(
            "Madioo is Coming Soon",
            textAlign: tv ? TextAlign.center : null,
            style: GoogleFonts.poppins(
              fontSize: tv ? 20 : 22,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          /// 📄 Subtitle
          Text(
            "Streaming Hindi songs...\nYour vibe, anytime 🎶",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: tv ? 13 : 14,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
          SizedBox(height: tv ? 36 : 60),

          /// 🎵 Animated Wave Bars
          _buildWaveBars(theme.primaryColor),
        ],
      ),
    );
  }
}
