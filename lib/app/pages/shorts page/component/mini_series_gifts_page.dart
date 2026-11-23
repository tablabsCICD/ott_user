import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ott/app/core/services/gift_deep_link_service.dart';
import 'package:ott/app/core/services/mini_series_commerce_service.dart';
import 'package:ott/app/widgets/filmytell_app_bar.dart';
import 'package:ott/app/widgets/gift_claim_dialog.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/data/models/mini_series_commerce_models.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

/// Mini Series gifts, in two clearly separated tabs (Received first):
/// - **Received Gifts**: gifts the user claimed (`GET gift/received`).
/// - **Sent Gifts**: single-use codes the user bought (`GET gift/history`).
///
/// Card styling follows the movie gift screen (GiftedMoviesPage.GiftCard).
class MiniSeriesGiftsPage extends StatefulWidget {
  const MiniSeriesGiftsPage({super.key, this.initialTab = 0});

  /// 0 = Received Gifts (default), 1 = Sent Gifts.
  final int initialTab;

  @override
  State<MiniSeriesGiftsPage> createState() => _MiniSeriesGiftsPageState();
}

class _MiniSeriesGiftsPageState extends State<MiniSeriesGiftsPage>
    with SingleTickerProviderStateMixin {
  final MiniSeriesCommerceService _service = MiniSeriesCommerceService();
  late final TabController _tabController;
  late Future<List<MiniSeriesGiftHistoryEntry>> _sent;
  late Future<List<MiniSeriesGiftHistoryEntry>> _received;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    // One request per tab on open; each tab reloads only itself afterwards.
    _sent = _service.fetchGiftHistory();
    _received = _service.fetchGiftReceived();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reloadSent() async {
    setState(() => _sent = _service.fetchGiftHistory());
    await _sent.catchError((_) => <MiniSeriesGiftHistoryEntry>[]);
  }

  Future<void> _reloadReceived() async {
    setState(() => _received = _service.fetchGiftReceived());
    await _received.catchError((_) => <MiniSeriesGiftHistoryEntry>[]);
  }

  /// Existing claim dialog (routes MSG- codes to the Mini Series claim API).
  /// Refreshes Received Gifts only after a backend-confirmed claim.
  Future<void> _claimGift() async {
    final claimed = await showGiftClaimDialog(context);
    if (claimed == true && mounted) {
      _tabController.animateTo(0);
      await _reloadReceived();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: FilmytellAppBar(title: lang.miniSeriesGiftsTitle),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveWidget.isMobile(context) ? double.infinity : 760,
          ),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: theme.primaryColor,
                labelColor: theme.primaryColor,
                unselectedLabelColor: theme.canvasColor.withValues(alpha: 0.7),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.move_to_inbox_rounded),
                    text: lang.miniSeriesGiftsReceivedTab,
                  ),
                  Tab(
                    icon: const Icon(Icons.outbox_rounded),
                    text: lang.miniSeriesGiftsSentTab,
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _GiftTab(
                      future: _received,
                      onRefresh: _reloadReceived,
                      description: lang.miniSeriesGiftsReceivedSubtitle,
                      emptyIcon: Icons.move_to_inbox_rounded,
                      emptyMessage: lang.miniSeriesGiftsReceivedEmpty,
                      headerAction: _ClaimButton(onPressed: _claimGift),
                      itemBuilder: (entry) => _ReceivedGiftCard(
                        entry: entry,
                        onClaim: _claimGift,
                      ),
                    ),
                    _GiftTab(
                      future: _sent,
                      onRefresh: _reloadSent,
                      description: lang.miniSeriesGiftsSentSubtitle,
                      emptyIcon: Icons.outbox_rounded,
                      emptyMessage: lang.miniSeriesGiftsSentEmpty,
                      itemBuilder: (entry) => _SentGiftCard(entry: entry),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tab: explanation line, optional action, then loading / error / empty
/// / list states. Pull to refresh in every state.
class _GiftTab extends StatelessWidget {
  const _GiftTab({
    required this.future,
    required this.onRefresh,
    required this.description,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.itemBuilder,
    this.headerAction,
  });

  final Future<List<MiniSeriesGiftHistoryEntry>> future;
  final Future<void> Function() onRefresh;
  final String description;
  final IconData emptyIcon;
  final String emptyMessage;
  final Widget Function(MiniSeriesGiftHistoryEntry entry) itemBuilder;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final header = <Widget>[
      Text(
        description,
        style: TextStyle(
          color: theme.canvasColor.withValues(alpha: 0.75),
          fontSize: 13,
        ),
      ),
      if (headerAction != null) ...[
        const SizedBox(height: 12),
        headerAction!,
      ],
      const SizedBox(height: 16),
    ];

    return FutureBuilder<List<MiniSeriesGiftHistoryEntry>>(
      future: future,
      builder: (context, snapshot) {
        final List<Widget> body;
        if (snapshot.connectionState != ConnectionState.done) {
          body = const [
            SizedBox(height: 80),
            Center(child: CircularProgressIndicator()),
          ];
        } else if (snapshot.hasError) {
          body = [
            const SizedBox(height: 40),
            _StateMessage(
              icon: Icons.error_outline_rounded,
              message:
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
              actionLabel: lang.retry,
              onAction: onRefresh,
            ),
          ];
        } else if ((snapshot.data ?? const []).isEmpty) {
          body = [
            const SizedBox(height: 40),
            _StateMessage(icon: emptyIcon, message: emptyMessage),
          ];
        } else {
          final items = snapshot.data!;
          body = [
            for (var i = 0; i < items.length; i++) ...[
              itemBuilder(items[i]),
              if (i < items.length - 1) const SizedBox(height: 16),
            ],
          ];
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [...header, ...body],
          ),
        );
      },
    );
  }
}

class _ClaimButton extends StatelessWidget {
  const _ClaimButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onPressed,
        icon: const Icon(LucideIcons.gift, color: Colors.white, size: 18),
        label: Text(
          lang.miniSeriesGiftClaimAction,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

String _formatDate(BuildContext context, DateTime? date) {
  if (date == null) return '-';
  final locale = Localizations.localeOf(context).toString();
  try {
    return DateFormat.yMMMd(locale).format(date);
  } catch (_) {
    return DateFormat.yMMMd().format(date);
  }
}

/// Card frame shared by both tabs, matching the movie GiftCard.
class _GiftCardFrame extends StatelessWidget {
  const _GiftCardFrame({required this.entry, required this.children, this.onTap});

  final MiniSeriesGiftHistoryEntry entry;
  final List<Widget> children;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Poster(url: entry.poster),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.miniSeriesTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.canvasColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...children,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SentGiftCard extends StatelessWidget {
  const _SentGiftCard({required this.entry});

  final MiniSeriesGiftHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final canShare = entry.isAvailable && entry.giftCode.isNotEmpty;
    return _GiftCardFrame(
      entry: entry,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _StatusChip(status: entry.giftStatus),
            if (entry.codeExpiry != null && !entry.isClaimed)
              _InfoChip(
                icon: Icons.event_outlined,
                text: lang.miniSeriesGiftCodeExpiryDate(
                    _formatDate(context, entry.codeExpiry)),
              ),
            if (entry.claimDate != null)
              _InfoChip(
                icon: Icons.check_circle_outline,
                text: lang.miniSeriesGiftClaimedOn(
                    _formatDate(context, entry.claimDate)),
              ),
            if (entry.purchaseDate != null)
              _InfoChip(
                icon: Icons.shopping_bag_outlined,
                text: lang.miniSeriesGiftPurchasedOn(
                    _formatDate(context, entry.purchaseDate)),
              ),
            if (entry.giftPrice != null)
              _InfoChip(
                icon: Icons.payments_outlined,
                text: lang.miniSeriesGiftPrice(
                    entry.giftPrice!.toStringAsFixed(2)),
              ),
          ],
        ),
        if (entry.giftCode.isNotEmpty) ...[
          const SizedBox(height: 12),
          // Same bordered code box as the movie gift card.
          Container(
            padding: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    entry.giftCode,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: canShare
                          ? theme.canvasColor
                          : theme.canvasColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  color: theme.primaryColor,
                  tooltip: lang.giftCopyCouponCode,
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: entry.giftCode));
                    if (context.mounted) {
                      CustomToast.show(context, lang.copied, isSuccess: true);
                    }
                  },
                ),
                // Only an unclaimed, unexpired code is worth sharing.
                if (canShare)
                  IconButton(
                    icon: const Icon(Icons.share, size: 18),
                    color: theme.primaryColor,
                    tooltip: lang.giftShareGiftLink,
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(
                        text:
                            '${lang.miniSeriesGiftShareText(entry.miniSeriesTitle, entry.giftCode)}\n'
                            '${GiftDeepLinkService.buildGiftUrl(entry.giftCode)}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ReceivedGiftCard extends StatelessWidget {
  const _ReceivedGiftCard({required this.entry, required this.onClaim});

  final MiniSeriesGiftHistoryEntry entry;

  /// Opens the existing claim dialog (refreshes this tab on success).
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final canOpen = entry.miniSeriesId != null;
    void open() =>
        openClaimedMiniSeries(Navigator.of(context), entry.miniSeriesId!);
    return _GiftCardFrame(
      entry: entry,
      onTap: canOpen ? open : null,
      children: [
        // Sender display name from the API; "A friend" when null or blank.
        // Never an email, phone or user id.
        Row(
          children: [
            Icon(LucideIcons.gift, size: 15, color: theme.primaryColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                lang.miniSeriesGiftedBy(
                    entry.displaySenderName ?? lang.miniSeriesGiftSenderFallback),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.canvasColor.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _StatusChip(status: entry.giftStatus),
            if (entry.claimDate != null)
              _InfoChip(
                icon: Icons.check_circle_outline,
                text: lang.miniSeriesGiftClaimedOn(
                    _formatDate(context, entry.claimDate)),
              ),
            // Access validity only from the backend's accessValidUntil;
            // never derived from the gift-code expiry.
            if (entry.accessValidUntil != null)
              _InfoChip(
                icon: Icons.verified_user_outlined,
                text: lang.miniSeriesGiftAccessValidUntil(
                    _formatDate(context, entry.accessValidUntil)),
              ),
            // Gift-code claim deadline: only meaningful while unclaimed.
            if (entry.codeExpiry != null && !entry.isClaimed)
              _InfoChip(
                icon: Icons.event_outlined,
                text: lang.miniSeriesGiftCodeExpiryDate(
                    _formatDate(context, entry.codeExpiry)),
              ),
          ],
        ),
        if (entry.isAvailable) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onClaim,
              icon: const Icon(LucideIcons.gift, size: 18, color: Colors.white),
              label: Text(lang.miniSeriesGiftClaimGift,
                  style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ] else if (canOpen) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: open,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(lang.watchNow),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primaryColor,
                side: BorderSide(color: theme.primaryColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 72,
      height: 108,
      color: Colors.black26,
      child: const Icon(LucideIcons.gift),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url.isEmpty
          ? placeholder
          : Image.network(
              url,
              width: 72,
              height: 108,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}

/// AVAILABLE / CLAIMED / EXPIRED (Swagger giftStatus) as a coloured chip.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final (label, color, icon) = switch (status.toUpperCase()) {
      'AVAILABLE' => (
          lang.miniSeriesGiftStatusAvailable,
          Colors.green,
          Icons.hourglass_top_rounded
        ),
      'CLAIMED' => (
          lang.miniSeriesGiftStatusClaimed,
          Colors.blue,
          Icons.check_circle_rounded
        ),
      'EXPIRED' => (
          lang.miniSeriesGiftStatusExpired,
          Colors.grey,
          Icons.timer_off_rounded
        ),
      _ => (status, Colors.grey, Icons.info_outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.primaryColor),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  color: theme.canvasColor.withValues(alpha: 0.85),
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 90, color: theme.canvasColor.withValues(alpha: 0.5)),
        const SizedBox(height: 20),
        Text(message,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );
  }
}
