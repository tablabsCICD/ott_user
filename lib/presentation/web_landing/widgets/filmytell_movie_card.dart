import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:ott/presentation/web_landing/utils/filmytell_theme.dart';
import 'package:ott/presentation/web_landing/widgets/filmytell_network_image.dart';

/// Reusable OTT Movie Card for Filmytell Trending and Latest Content carousels.
class FilmytellMovieCard extends StatefulWidget {
  const FilmytellMovieCard({
    super.key,
    required this.content,
    required this.width,
    required this.height,
    required this.onTap,
    this.rank,
  });

  final Content content;
  final double width;
  final double height;
  final int? rank;
  final VoidCallback onTap;

  @override
  State<FilmytellMovieCard> createState() => _FilmytellMovieCardState();
}

class _FilmytellMovieCardState extends State<FilmytellMovieCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final poster = _posterFor(widget.content);
    final hasRank = widget.rank != null;
    final isMobile = widget.width < 150;
    final rankOffset = hasRank
        ? (widget.rank! >= 10
            ? (isMobile ? 32.0 : 48.0)
            : (isMobile ? 22.0 : 34.0))
        : 0.0;
    final price = widget.content.price;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: widget.width + rankOffset,
            height: widget.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Poster Card (positioned with rankOffset so the number has space on the left)
                Positioned(
                  left: rankOffset,
                  top: 0,
                  width: widget.width,
                  height: widget.height,
                  child: Container(
                    width: widget.width,
                    height: widget.height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _hovered
                            ? Colors.white.withValues(alpha: 0.45)
                            : Colors.white.withValues(alpha: 0.12),
                        width: _hovered ? 1.4 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: _hovered ? 0.80 : 0.60),
                          blurRadius: _hovered ? 24 : 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FilmytellNetworkImage(
                            imageUrl: poster,
                            imageUrls: widget.content.posterUrlList,
                            width: widget.width,
                            height: widget.height,
                            fit: BoxFit.fill,
                          ),
                          // Subtle bottom dark gradient
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 60,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.80),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Rental Price Pill if present
                          if (price != null)
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: _RentCardButton(
                                label:
                                    '${lang.rent} Rs ${price.toStringAsFixed(0)}',
                                onTap: widget.onTap,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Exact Netflix Rank Numeral (layered ON TOP, elevated slightly above bottom)
                if (hasRank)
                  Positioned(
                    left: 0,
                    bottom: isMobile ? 8.0 : 12.0,
                    child: IgnorePointer(
                      child: _NetflixRankNumeral(
                        rank: widget.rank!,
                        height: widget.height,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _posterFor(Content content) {
    final candidates = FilmytellNetworkImage.sanitizeAndPrioritizeUrls(
      content.posterUrlList ?? const <String>[],
    );
    if (candidates.isNotEmpty) return candidates.first;
    return null;
  }
}

class _RentCardButton extends StatelessWidget {
  const _RentCardButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
          decoration: BoxDecoration(
            color: FilmytellTheme.primary.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_offer_rounded,
                color: Colors.white,
                size: 11,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Exact Netflix-style rank numeral with crisp silver/white stroke, black fill, and poster overlap.
class _NetflixRankNumeral extends StatelessWidget {
  const _NetflixRankNumeral({
    required this.rank,
    required this.height,
  });

  final int rank;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDoubleDigit = rank >= 10;
    // Scaled to compact ~40% of poster card height for clean readability
    final fontSize = height * 0.40;
    final strokeWidth = (fontSize * 0.052).clamp(2.5, 3.8);
    final text = '$rank';

    final textStyle = GoogleFonts.montserrat(
      fontSize: fontSize,
      height: 0.90,
      fontWeight: FontWeight.w900,
      letterSpacing: isDoubleDigit ? -fontSize * 0.08 : -fontSize * 0.02,
    );

    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        // 1. Deep black shadow for sharp contrast over any underlying poster image
        Text(
          text,
          style: textStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth + 7.0
              ..strokeJoin = StrokeJoin.round
              ..strokeCap = StrokeCap.round
              ..color = Colors.black.withValues(alpha: 0.90)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
          ),
        ),
        // 2. Pure black backing border
        Text(
          text,
          style: textStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth + 3.0
              ..strokeJoin = StrokeJoin.round
              ..strokeCap = StrokeCap.round
              ..color = Colors.black,
          ),
        ),
        // 3. Crisp bright Netflix silver-white outline stroke
        Text(
          text,
          style: textStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..strokeCap = StrokeCap.round
              ..color = const Color(0xFFF0F0F0),
          ),
        ),
        // 4. Solid black body fill to overlay cleanly over the poster
        Text(
          text,
          style: textStyle.copyWith(
            color: const Color(0xFF000000),
          ),
        ),
      ],
    );
  }
}
