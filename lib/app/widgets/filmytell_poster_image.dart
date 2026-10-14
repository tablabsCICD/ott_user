import 'package:flutter/material.dart';

/// Reusable Movie Poster Renderer for Filmytell.
///
/// Solves the portrait-poster-in-landscape-card cropping problem across mobile,
/// tablet, desktop web, Android TV, and Google TV:
///
/// 1. Uses [BoxFit.contain] in the foreground so the ENTIRE movie poster
///    (actor faces, top movie title logos, billing block, and credits) is 100%
///    visible with zero cropping, stretching, or aspect-ratio distortion.
/// 2. Uses an ambient [BoxFit.cover] layer in the background to seamlessly fill
///    the available card space with the poster's native color palette, avoiding
///    awkward empty gutters or blank black voids.
/// 3. Employs a lightweight darkened scrim overlay (`Colors.black.withValues(alpha: ambientOpacity)`)
///    between the layers. This gives high contrast to the foreground poster while
///    delivering 60fps scrolling on TV devices without heavy GPU shader overhead.
class FilmytellPosterImage extends StatelessWidget {
  final String? posterUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius? borderRadius;
  final double ambientOpacity;
  final double fallbackIconSize;
  final IconData fallbackIcon;
  final Color? fallbackColor;
  final Color? backgroundColor;

  const FilmytellPosterImage({
    super.key,
    required this.posterUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.ambientOpacity = 0.72,
    this.fallbackIconSize = 48,
    this.fallbackIcon = Icons.broken_image,
    this.fallbackColor,
    this.backgroundColor,
  });

  /// Sanitizes raw URL strings to prevent malformed URL exceptions.
  static String? sanitizeUrl(String? raw) {
    if (raw == null) return null;
    var url = raw.trim();
    if (url.isEmpty) return null;
    if (url.startsWith('//')) {
      url = 'https:$url';
    } else if (url.startsWith('http://')) {
      url = 'https://${url.substring(7)}';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = sanitizeUrl(posterUrl);
    final theme = Theme.of(context);
    final iconColor =
        fallbackColor ?? theme.canvasColor.withValues(alpha: 0.3);

    Widget content;

    if (cleanUrl == null || cleanUrl.isEmpty) {
      content = Container(
        color: backgroundColor ?? Colors.black26,
        alignment: Alignment.center,
        child: Icon(
          fallbackIcon,
          color: iconColor,
          size: fallbackIconSize,
        ),
      );
    } else {
      content = Stack(
        fit: StackFit.expand,
        alignment: alignment,
        children: [
          // 1. Ambient Background Layer:
          // Fills the card boundaries completely using BoxFit.cover.
          Image.network(
            cleanUrl,
            fit: BoxFit.cover,
            alignment: alignment,
            filterQuality: FilterQuality.low,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),

          // 2. Ambient Dimming Scrim:
          // Smoothly dims background colors for maximum foreground contrast.
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: ambientOpacity),
            ),
          ),

          // 3. Foreground Uncropped Poster:
          // Uses BoxFit.contain to guarantee 100% complete poster visibility.
          Image.network(
            cleanUrl,
            fit: fit,
            alignment: alignment,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => Center(
              child: Icon(
                fallbackIcon,
                color: iconColor,
                size: fallbackIconSize,
              ),
            ),
          ),
        ],
      );
    }

    if (borderRadius != null) {
      content = ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    if (width != null || height != null) {
      content = SizedBox(
        width: width,
        height: height,
        child: content,
      );
    }

    return content;
  }
}
