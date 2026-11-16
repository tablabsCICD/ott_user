import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/pages/gifted%20movies%20page/GiftDetailsPage.dart';
import 'package:ott/app/pages/movie%20details%20page/MovieDetailsPage.dart';
import 'package:ott/app/provider/giftProvider.dart';
import 'package:ott/data/models/giftRecordModel.dart';
import 'package:ott/app/widgets/filmytell_poster_image.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class GiftedMoviesPage extends StatefulWidget {
  const GiftedMoviesPage({super.key});

  @override
  State<GiftedMoviesPage> createState() => _GiftedMoviesPageState();
}

class _GiftedMoviesPageState extends State<GiftedMoviesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<GiftProvider>(context, listen: false).fetchGiftHistory();
    });
  }

  String formatDate(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateFormat("dd MMM yyyy, hh:mm a").format(date);
  }

  void copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    CustomToast.show(context, "Copied: $text", isSuccess: true);
  }

  Future<void> shareGiftLink(
    String couponCode,
    String movieTitle,
  ) async {
    final giftLink = DeepLinkService.instance.buildGiftDeepLink(couponCode);
    final fallbackLink = DeepLinkService.instance.buildGiftAppLink(couponCode);
    final message = '''
You have received a Filmytell gift: $movieTitle

Claim gift:
$giftLink

Fallback link:
$fallbackLink

Gift code: $couponCode
''';

    await SharePlus.instance.share(
      ShareParams(
        text: message.trim(),
        subject: 'Filmytell movie gift',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveWidget.isAndroidTv(context)) return _buildTv(context);

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          "Gifted Movies",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.primaryColor,
        centerTitle: true,
      ),
      body: Consumer<GiftProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return const Center(child: Text("No gift history available."));
          }
          if (provider.giftRecords.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.movie_outlined,
                    size: 90,
                    color: theme.canvasColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "No gift history available.",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: provider.giftRecords.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildGiftCard(context, provider.giftRecords[index]);
            },
          );
        },
      ),
    );
  }

  /// One gift record as a [GiftCard] (shared by the mobile list and the
  /// Android TV grid, so both use the same callbacks).
  Widget _buildGiftCard(BuildContext context, GiftRecordModel record) {
    return GiftCard(
      title: record.movie?.title ?? "Movie #${record.movie}",
      date: record.createdDate == null
          ? "Date not available"
          : formatDate(record.createdDate!),
      totalGifted: record.totalGiftCount ?? 0,
      remainingGifted: record.remainingGiftCount ?? 0,
      moviePrice: record.movie?.price ?? 0,
      totalPaid: record.totalPaid ?? 0,
      couponCode: record.couponCode,
      posterUrl: record.movie?.posterUrlList?.isNotEmpty == true
          ? record.movie!.posterUrlList!.first
          : null,
      onTap: () {
        if (record.id == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GiftDetailsPage(giftMasterId: record.id!),
          ),
        );
      },
      onCopy: record.couponCode != null
          ? () => copyToClipboard(context, record.couponCode!)
          : null,
      onShare: record.couponCode != null
          ? () => shareGiftLink(
                record.couponCode!,
                record.movie?.title ?? "this movie",
              )
          : null,
      onMovieDetails: record.movie?.id == null
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailsPage(movieId: record.movie!.id!),
                ),
              );
            },
    );
  }

  // ---------------- Android TV ----------------

  /// Android TV: page title and a 2-column grid of compact gift cards
  /// (same states, texts and callbacks as the mobile list).
  Widget _buildTv(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.canvasColor.withValues(alpha: 0.62);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TvDesign.pageGutter,
                16,
                TvDesign.pageGutter,
                12,
              ),
              child: Text("Gifted Movies", style: TvDesign.pageTitle(theme)),
            ),
            Expanded(
              child: Consumer<GiftProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.errorMessage != null ||
                      provider.giftRecords.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.movie_outlined, size: 48, color: muted),
                          const SizedBox(height: 10),
                          Text(
                            "No gift history available.",
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      TvDesign.pageGutter,
                      4,
                      TvDesign.pageGutter,
                      TvDesign.pageGutter,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 12,
                      mainAxisExtent: GiftCard.tvHeight,
                    ),
                    itemCount: provider.giftRecords.length,
                    itemBuilder: (context, index) {
                      final card =
                          _buildGiftCard(context, provider.giftRecords[index]);
                      // Initial focus on the first gift.
                      return index == 0 ? _TvInitialFocus(child: card) : card;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GiftCard extends StatelessWidget {
  final String title;
  final String date;
  final int totalGifted;
  final int remainingGifted;
  final num moviePrice;
  final num totalPaid;
  final String? couponCode;
  final VoidCallback onTap;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onMovieDetails;

  /// Movie art, used by the Android TV layout only.
  final String? posterUrl;

  /// Card height in the Android TV grid.
  static const double tvHeight = 136;

  const GiftCard({
    super.key,
    required this.title,
    required this.date,
    required this.totalGifted,
    required this.remainingGifted,
    required this.moviePrice,
    required this.totalPaid,
    required this.onTap,
    this.couponCode,
    this.onCopy,
    this.onShare,
    this.onMovieDetails,
    this.posterUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveWidget.isAndroidTv(context)) return _buildTv(context);

    final theme = Theme.of(context);
    final showMovieDetailsButton =
        !ResponsiveWidget.isDesktop(context) && onMovieDetails != null;

    // TV: Down from the card selects Copy, Right moves to Share, OK runs the
    // selected action, Up returns to the card. (Inline buttons can't be
    // reached by the remote otherwise.)
    final tvActions = <VoidCallback>[
      if (couponCode != null && onCopy != null) onCopy!,
      if (couponCode != null && onShare != null) onShare!,
    ];
    final copyIndex = couponCode != null && onCopy != null ? 0 : -1;
    final shareIndex =
        couponCode != null && onShare != null ? tvActions.length - 1 : -1;

    return OttTvActionsCard(
      onTap: onTap,
      actions: tvActions,
      borderRadius: 16,
      semanticLabel: title,
      builder: (context, selectedAction) => Card(
        color: theme.cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.canvasColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(
                      color: theme.canvasColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Gift Info Chips
              Wrap(
                spacing: 5,
                runSpacing: 3,
                children: [
                  _infoChip(
                    context,
                    icon: LucideIcons.gift,
                    label1: 'Gifted: ',
                    label2: '$totalGifted',
                  ),
                  _infoChip(
                    context,
                    icon: Icons.inventory_2_outlined,
                    label1: 'Remaining: ',
                    label2: '$remainingGifted',
                  ),
                  _infoChip(
                    context,
                    icon: Icons.payment,
                    label1: 'Price: ',
                    label2: "₹${moviePrice.toStringAsFixed(2)}",
                  ),
                  _infoChip(
                    context,
                    icon: Icons.payments_outlined,
                    label1: 'Total Paid: ',
                    label2: '₹${totalPaid.toStringAsFixed(2)}',
                  ),
                ],
              ),

              // Coupon Code
              if (couponCode != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: theme.primaryColor.withOpacity(0.3), width: 1),
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          couponCode!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: theme.canvasColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onCopy != null)
                        OttTvActionHighlight(
                          selected: selectedAction == copyIndex,
                          borderRadius: 20,
                          child: IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            color: theme.primaryColor,
                            onPressed: onCopy,
                            tooltip: "Copy coupon code",
                          ),
                        ),
                      if (onShare != null)
                        OttTvActionHighlight(
                          selected: selectedAction == shareIndex,
                          borderRadius: 20,
                          child: IconButton(
                            icon: const Icon(Icons.share, size: 18),
                            color: theme.primaryColor,
                            onPressed: onShare,
                            tooltip: "Share gift link",
                          ),
                        ),
                    ],
                  ),
                ),
                if (onShare != null) ...[
                  const SizedBox(height: 8),
                  OttTvFocus(
                    borderRadius: 8,
                    scale: 1.02,
                    semanticLabel: "Share gift claim link",
                    onTap: onShare,
                    child: InkWell(
                      onTap: onShare,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.link,
                              size: 16,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Share gift claim link",
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              if (showMovieDetailsButton) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onMovieDetails,
                    icon: const Icon(Icons.movie_outlined, size: 18),
                    label: const Text('Movie details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      side: BorderSide(color: theme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Android TV gift card: 16:9 art, title, date, gift counts and amounts,
  /// coupon code. One focus stop: OK opens the gift details, Down selects
  /// the inline actions (Copy / Share link / Movie details), Left/Right move
  /// between them, Up returns to the card ([OttTvActionsCard]).
  Widget _buildTv(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.canvasColor.withValues(alpha: 0.62);

    final labels = <(String, IconData)>[];
    final actions = <VoidCallback>[];
    if (couponCode != null && onCopy != null) {
      labels.add(('Copy', Icons.copy));
      actions.add(onCopy!);
    }
    if (couponCode != null && onShare != null) {
      labels.add(('Share link', Icons.share));
      actions.add(onShare!);
    }
    if (onMovieDetails != null) {
      labels.add(('Details', Icons.movie_outlined));
      actions.add(onMovieDetails!);
    }

    Widget stat(String label, String value) => Text.rich(
          TextSpan(
            children: [
              TextSpan(text: label, style: TextStyle(color: muted)),
              TextSpan(
                text: value,
                style: TextStyle(
                  color: theme.canvasColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          style: const TextStyle(fontSize: 10.5),
          maxLines: 1,
        );

    return OttTvActionsCard(
      onTap: onTap,
      actions: actions,
      borderRadius: TvDesign.cardRadius,
      scale: 1.0,
      semanticLabel: title,
      builder: (context, selectedAction) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(TvDesign.cardRadius),
          border: Border.all(color: theme.canvasColor.withValues(alpha: 0.06)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
              child: SizedBox(
                width: 132,
                child: AspectRatio(
                  aspectRatio: TvDesign.imageAspectRatio,
                  child: FilmytellPosterImage(
                    posterUrl: posterUrl,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(6),
                    fallbackIcon: LucideIcons.gift,
                    fallbackIconSize: 24,
                    backgroundColor: theme.scaffoldBackgroundColor,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.canvasColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TvDesign.caption(theme),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        stat('Gifted: ', '$totalGifted'),
                        const SizedBox(width: 10),
                        stat('Remaining: ', '$remainingGifted'),
                      ],
                    ),
                    const SizedBox(height: 1),
                    // Scales down rather than clipping, so amounts stay
                    // fully visible.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          stat('Price: ',
                              "₹${moviePrice.toStringAsFixed(2)}"),
                          const SizedBox(width: 10),
                          stat('Total Paid: ',
                              '₹${totalPaid.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                    if (couponCode != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        couponCode!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                    if (labels.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                          children: [
                            for (var i = 0; i < labels.length; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              OttTvActionHighlight(
                                selected: selectedAction == i,
                                borderRadius: 6,
                                child: Container(
                                  height: 22,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: theme.canvasColor
                                          .withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        labels[i].$2,
                                        size: 11,
                                        color: theme.canvasColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        labels[i].$1,
                                        style: TextStyle(
                                          color: theme.canvasColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(
    BuildContext context, {
    required IconData icon,
    required String label1,
    required String label2,
  }) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 17, color: theme.primaryColor),
      label: Text.rich(
        TextSpan(
            style: TextStyle(
              color: theme.canvasColor,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: label1,
                style: TextStyle(
                  color: theme.canvasColor.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextSpan(text: label2),
            ]),
      ),
      backgroundColor: theme.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

/// Android TV: gives the first focusable control inside [child] focus once,
/// if nothing on the current route is focused yet (e.g. after being pushed).
/// Used because [OttTvActionsCard] has no `autofocus` parameter.
class _TvInitialFocus extends StatefulWidget {
  const _TvInitialFocus({required this.child});

  final Widget child;

  @override
  State<_TvInitialFocus> createState() => _TvInitialFocusState();
}

class _TvInitialFocusState extends State<_TvInitialFocus> {
  final FocusNode _node = FocusNode(
    debugLabel: 'gift-initial-focus',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (FocusScope.of(context).focusedChild != null) return;
      for (final node in _node.descendants) {
        if (node.canRequestFocus && !node.skipTraversal) {
          node.requestFocus();
          return;
        }
      }
    });
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      canRequestFocus: false,
      skipTraversal: true,
      child: widget.child,
    );
  }
}
