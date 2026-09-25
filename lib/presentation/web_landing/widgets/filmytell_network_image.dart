import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/presentation/web_landing/utils/filmytell_theme.dart';

/// Reusable, CORS-safe, multi-candidate Network Image Loader for Filmytell Web.
class FilmytellNetworkImage extends StatefulWidget {
  const FilmytellNetworkImage({
    super.key,
    this.imageUrl,
    this.imageUrls,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.fallbackIcon = Icons.movie_outlined,
    this.showShimmer = true,
  });

  final String? imageUrl;
  final List<String>? imageUrls;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final IconData fallbackIcon;
  final bool showShimmer;

  /// Sanitizes any raw image URL (handles relative paths, protocol upgrades, whitespace).
  static String? sanitizeUrl(String? raw) {
    if (raw == null) return null;
    var url = raw.trim();
    if (url.isEmpty) return null;

    // Fix schema-relative URLs
    if (url.startsWith('//')) {
      url = 'https:$url';
    } else if (url.startsWith('http://')) {
      url = 'https://${url.substring(7)}';
    } else if (!url.startsWith('https://')) {
      final base = ApiConstant.baseUrl.endsWith('/')
          ? ApiConstant.baseUrl.substring(0, ApiConstant.baseUrl.length - 1)
          : ApiConstant.baseUrl;

      if (url.startsWith('/')) {
        url = '$base$url';
      } else {
        url = '$base/$url';
      }
    }

    return Uri.tryParse(url)?.toString() ?? Uri.encodeFull(url);
  }

  /// Extracts and prioritizes valid candidate URLs.
  /// Prioritizes working S3 / direct HTTPS storage domains.
  static List<String> sanitizeAndPrioritizeUrls(List<String?> rawUrls) {
    final results = <String>[];
    for (final raw in rawUrls) {
      final sanitized = sanitizeUrl(raw);
      if (sanitized != null && sanitized.isNotEmpty && !results.contains(sanitized)) {
        results.add(sanitized);
      }
    }

    // Sort to prioritize direct AWS S3 / Filmytell endpoints that pass SSL handshakes
    results.sort((a, b) {
      final aIsS3 = a.contains('amazonaws.com') || a.contains('filmytell.com');
      final bIsS3 = b.contains('amazonaws.com') || b.contains('filmytell.com');
      if (aIsS3 && !bIsS3) return -1;
      if (!aIsS3 && bIsS3) return 1;
      return 0;
    });

    return results;
  }

  @override
  State<FilmytellNetworkImage> createState() => _FilmytellNetworkImageState();
}

class _FilmytellNetworkImageState extends State<FilmytellNetworkImage> {
  late List<String> _candidates;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _resolveCandidates();
  }

  @override
  void didUpdateWidget(covariant FilmytellNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageUrls != widget.imageUrls) {
      _resolveCandidates();
    }
  }

  void _resolveCandidates() {
    final rawList = <String?>[
      if (widget.imageUrl != null) widget.imageUrl,
      if (widget.imageUrls != null) ...widget.imageUrls!,
    ];
    _candidates = FilmytellNetworkImage.sanitizeAndPrioritizeUrls(rawList);
    _currentIndex = 0;
  }

  void _handleError() {
    if (_currentIndex + 1 < _candidates.length) {
      if (mounted) {
        setState(() {
          _currentIndex++;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_candidates.isEmpty || _currentIndex >= _candidates.length) {
      return _buildFallback();
    }

    final activeUrl = _candidates[_currentIndex];

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Image.network(
        activeUrl,
        key: ValueKey(activeUrl),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        filterQuality: FilterQuality.medium,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return widget.showShimmer ? _buildShimmer() : _buildFallback();
        },
        errorBuilder: (context, error, stackTrace) {
          // If more candidates exist, trigger fallback transition
          if (_currentIndex + 1 < _candidates.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _handleError());
            return widget.showShimmer ? _buildShimmer() : _buildFallback();
          }
          return _buildFallback();
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return _ShimmerBox(
      width: widget.width,
      height: widget.height,
      borderRadius: widget.borderRadius,
    );
  }

  Widget _buildFallback() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: FilmytellTheme.surfaceDark,
        borderRadius: widget.borderRadius,
        border: Border.all(color: FilmytellTheme.borderSubtle),
      ),
      child: Center(
        child: Icon(
          widget.fallbackIcon,
          color: FilmytellTheme.textSubtle,
          size: (widget.height != null && widget.height! < 120) ? 20 : 28,
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    this.width,
    this.height,
    required this.borderRadius,
  });

  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [
                  (_controller.value - 0.3).clamp(0.0, 1.0),
                  _controller.value.clamp(0.0, 1.0),
                  (_controller.value + 0.3).clamp(0.0, 1.0),
                ],
                colors: const [
                  Color(0xFF121216),
                  Color(0xFF1F1F26),
                  Color(0xFF121216),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
