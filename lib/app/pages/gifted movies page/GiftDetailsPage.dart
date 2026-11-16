import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/provider/giftProvider.dart';
import 'package:ott/app/widgets/filmytell_poster_image.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
import 'package:ott/data/models/giftMasterModel.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
// avoid conflict
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class GiftDetailsPage extends StatefulWidget {
  final int giftMasterId;

  const GiftDetailsPage({super.key, required this.giftMasterId});

  @override
  State<GiftDetailsPage> createState() => _GiftDetailsPageState();
}

class _GiftDetailsPageState extends State<GiftDetailsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<GiftProvider>().getByMasterId(widget.giftMasterId);
    });
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: !(kIsWeb || ResponsiveWidget.isTv(context)),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Gift Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<GiftProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }

          final giftMaster = provider.giftMaster;
          if (giftMaster == null) {
            return Center(
              child: Text(
                "No gift details found",
                style: TextStyle(
                  color: theme.canvasColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final total = giftMaster.totalGiftCount ?? 0;
          final remaining = giftMaster.remainingGiftCount ?? 0;
          final used = total - remaining;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🎬 Movie Info
                if (giftMaster.movie != null)
                  Card(
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          if (giftMaster.movie?.posterUrlList != null &&
                              giftMaster.movie!.posterUrlList!.isNotEmpty)
                            SizedBox(
                              width: 80,
                              height: 120,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  giftMaster.movie!.posterUrlList!.first,
                                  width: 80,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  giftMaster.movie?.title ?? "",
                                  style: TextStyle(
                                    color: theme.canvasColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Price: ₹${giftMaster.movie?.price ?? 0}",
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Description: ${giftMaster.movie?.description ?? "-"}",
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.canvasColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                /// 🎁 Gift Information
                Card(
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (giftMaster.couponCode != null)
                              GestureDetector(
                                onTap: () => _shareGift(giftMaster),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        giftMaster.couponCode!,
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.share, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (giftMaster.createdDate != null)
                          _buildInfoRow(
                            "Created Date",
                            DateFormat("dd MMM yyyy").format(
                              DateTime.fromMillisecondsSinceEpoch(
                                  giftMaster.createdDate!),
                            ),
                          ),
                        _buildInfoRow("Total Gift Count", "$total"),
                        _buildInfoRow("Remaining", "$remaining"),
                        _buildInfoRow("Used", "$used"),
                        _buildInfoRow(
                            "Total Paid", "₹${giftMaster.totalPaid ?? 0}"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// 👥 Users who claimed
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Users who claimed",
                      style: TextStyle(
                        color: theme.canvasColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "$used / $total",
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (giftMaster.user == null || giftMaster.user!.isEmpty)
                  Center(
                      child: Column(
                    children: [
                      SizedBox(
                        height: 50,
                      ),
                      const Text("No users have claimed this gift yet."),
                    ],
                  )),
                if (giftMaster.user != null && giftMaster.user!.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: giftMaster.user!.length,
                    itemBuilder: (context, index) {
                      final user = giftMaster.user![index];
                      return Card(
                        color: theme.cardColor,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.canvasColor.withOpacity(0.3),
                            backgroundImage:
                                (user.image != null && user.image!.isNotEmpty)
                                    ? NetworkImage(user.image!)
                                    : null,
                            child: (user.image == null || user.image!.isEmpty)
                                ? Icon(
                                    Icons.person,
                                    color: theme.canvasColor.withOpacity(0.7),
                                  )
                                : null,
                          ),
                          title: Text(user.name ?? "Unknown"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (user.email != null && user.email!.isNotEmpty)
                                Text(user.email!),
                              if (user.mobile != null &&
                                  user.mobile!.isNotEmpty)
                                Text(user.mobile!),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _shareGift(GiftMasterModel giftMaster) {
    shareGiftLink(
      giftMaster.couponCode!,
      giftMaster.movie?.title ?? "this movie",
    );
  }

  // ---------------- Android TV ----------------

  /// Android TV: movie + gift summary on the left (with the share-code
  /// button), users who claimed on the right. Same provider data, texts and
  /// share handler ([_shareGift]) as the other layouts.
  Widget _buildTv(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.canvasColor.withValues(alpha: 0.62);

    Widget centered(String text) => Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 13),
          ),
        );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TvDesign.pageGutter,
            16,
            TvDesign.pageGutter,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Gift Details", style: TvDesign.pageTitle(theme)),
              const SizedBox(height: 14),
              Expanded(
                child: Consumer<GiftProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.errorMessage != null) {
                      return centered(provider.errorMessage!);
                    }
                    final giftMaster = provider.giftMaster;
                    if (giftMaster == null) {
                      return centered("No gift details found");
                    }

                    final total = giftMaster.totalGiftCount ?? 0;
                    final remaining = giftMaster.remainingGiftCount ?? 0;
                    final used = total - remaining;
                    final users = giftMaster.user ?? const <GiftUser>[];

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(
                            child: _buildTvGiftPanel(
                              theme,
                              giftMaster,
                              total: total,
                              remaining: remaining,
                              used: used,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 6,
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: _tvPanelDecoration(theme),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TvSectionHeader(
                                  "Users who claimed",
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 12, 14, 8),
                                  trailing: Text(
                                    "$used / $total",
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: users.isEmpty
                                      ? centered(
                                          "No users have claimed this gift yet.",
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.fromLTRB(
                                              10, 0, 10, 10),
                                          itemCount: users.length,
                                          itemBuilder: (context, index) =>
                                              _tvUserRow(
                                            theme,
                                            users[index],
                                            // No share button: start on the
                                            // first user.
                                            autofocus: index == 0 &&
                                                giftMaster.couponCode == null,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _tvPanelDecoration(ThemeData theme) => BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(TvDesign.panelRadius),
        border: Border.all(color: theme.canvasColor.withValues(alpha: 0.06)),
      );

  Widget _buildTvGiftPanel(
    ThemeData theme,
    GiftMasterModel giftMaster, {
    required int total,
    required int remaining,
    required int used,
  }) {
    final movie = giftMaster.movie;
    final posterUrl = movie?.posterUrlList?.isNotEmpty == true
        ? movie!.posterUrlList!.first
        : null;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _tvPanelDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (movie != null) ...[
            AspectRatio(
              aspectRatio: TvDesign.imageAspectRatio,
              child: FilmytellPosterImage(
                posterUrl: posterUrl,
                fit: BoxFit.cover,
                fallbackIcon: Icons.movie_outlined,
                fallbackIconSize: 32,
                backgroundColor: theme.scaffoldBackgroundColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TvDesign.sectionTitle(theme),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Price: ₹${movie.price ?? 0}",
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Description: ${movie.description ?? "-"}",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TvDesign.caption(theme),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (giftMaster.couponCode != null) ...[
                  OttTvFocus(
                    autofocus: true,
                    borderRadius: 8,
                    scale: 1.03,
                    semanticLabel: "Share gift link",
                    onTap: () => _shareGift(giftMaster),
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.primaryColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              giftMaster.couponCode!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.share,
                            size: 16,
                            color: theme.canvasColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (giftMaster.createdDate != null)
                  _tvInfoRow(
                    theme,
                    "Created Date",
                    DateFormat("dd MMM yyyy").format(
                      DateTime.fromMillisecondsSinceEpoch(
                        giftMaster.createdDate!,
                      ),
                    ),
                  ),
                _tvInfoRow(theme, "Total Gift Count", "$total"),
                _tvInfoRow(theme, "Remaining", "$remaining"),
                _tvInfoRow(theme, "Used", "$used"),
                _tvInfoRow(theme, "Total Paid", "₹${giftMaster.totalPaid ?? 0}"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tvInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.canvasColor.withValues(alpha: 0.62),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              color: theme.canvasColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tvUserRow(ThemeData theme, GiftUser user, {bool autofocus = false}) {
    final hasImage = user.image != null && user.image!.isNotEmpty;
    final details = [
      if (user.email != null && user.email!.isNotEmpty) user.email!,
      if (user.mobile != null && user.mobile!.isNotEmpty) user.mobile!,
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      // No action: a focus stop so the remote can scroll the list.
      child: OttTvFocus(
        autofocus: autofocus,
        onTap: () {},
        borderRadius: 8,
        scale: 1.0,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: theme.canvasColor.withValues(alpha: 0.3),
                backgroundImage: hasImage ? NetworkImage(user.image!) : null,
                child: hasImage
                    ? null
                    : Icon(
                        Icons.person,
                        size: 16,
                        color: theme.canvasColor.withValues(alpha: 0.7),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.name ?? "Unknown",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.canvasColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TvDesign.caption(theme),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(flex: 5, child: Text(value ?? "-")),
        ],
      ),
    );
  }
}
