import 'package:flutter/material.dart';

class GenresSection extends StatelessWidget {
  const GenresSection({
    super.key,
    required this.genres,
  });

  final List<String> genres;

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 8, 56, 62),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Genres',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3.2,
            ),
            itemCount: genres.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 18, end: 0),
                duration: Duration(milliseconds: 300 + index * 35),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, value),
                    child: Opacity(opacity: value == 0 ? 1 : 0.65, child: child),
                  );
                },
                child: _GenreCard(
                  label: genres[index],
                  color: theme.primaryColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GenreCard extends StatefulWidget {
  const _GenreCard({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  State<_GenreCard> createState() => _GenreCardState();
}

class _GenreCardState extends State<_GenreCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              widget.color.withOpacity(_hovered ? 0.72 : 0.48),
              Colors.white.withOpacity(_hovered ? 0.13 : 0.07),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(_hovered ? 0.22 : 0.10)),
          boxShadow: [
            if (_hovered)
              BoxShadow(
                color: widget.color.withOpacity(0.24),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
