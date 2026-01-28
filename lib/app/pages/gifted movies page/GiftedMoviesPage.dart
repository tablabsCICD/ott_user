import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ott/app/pages/gifted%20movies%20page/GiftDetailsPage.dart';
import 'package:ott/app/provider/giftProvider.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Gifted Movies",
          style: TextStyle(
            color: Colors.white,
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
              final record = provider.giftRecords[index];
              return GiftCard(
                title: record.movie?.title ?? "Movie #${record.movie}",
                date: formatDate(record.createdDate!),
                totalGifted: record.totalGiftCount ?? 0,
                remainingGifted: record.remainingGiftCount ?? 0,
                moviePrice: record.movie?.price ?? 0,
                totalPaid: record.totalPaid ?? 0,
                couponCode: record.couponCode,
                onTap: () {
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
              );
            },
          );
        },
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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          color: theme.primaryColor,
                          onPressed: onCopy,
                          tooltip: "Copy coupon code",
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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
