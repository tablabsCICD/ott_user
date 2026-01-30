import 'package:flutter/material.dart';
import 'package:ott/app/provider/videoProvider.dart';
import 'package:ott/app/widgets/shimmer%20loader/comming_soon_shimmer.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class UpcomingPage extends StatefulWidget {
  const UpcomingPage({super.key});

  @override
  State<UpcomingPage> createState() => _UpcomingPageState();
}

class _UpcomingPageState extends State<UpcomingPage> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = Provider.of<VideoProvider>(context, listen: false);
    await provider.upcomingContent();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme.primaryColor,
        elevation: 0,
        title: Text(
          lang.upcoming,
          style: TextStyle(
            color: theme.canvasColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? ComingSoonShimmer()
          : Consumer<VideoProvider>(
              builder: (_, provider, __) {
                if (provider.upcomingContentList.isEmpty) {
                  return _emptyState(theme);
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.upcomingContentList.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ResponsiveWidget.isMobile(context) ? 1 : 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 16 / 9, // 🔒 fixed
                  ),
                  itemBuilder: (_, index) {
                    final item = provider.upcomingContentList[index];
                    return _upcomingCard(context, item);
                  },
                );
              },
            ),
    );
  }

  // 🎬 Netflix-style upcoming card
  Widget _upcomingCard(BuildContext context, dynamic item) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // 🎞 Poster
          Positioned.fill(
            child: Image.network(
              item.posterUrlList?.first ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black26),
            ),
          ),

          // 🌑 Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                    Colors.black87,
                  ],
                ),
              ),
            ),
          ),

          // 📄 Content
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  item.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                // Release date
                Row(
                  children: [
                    const Icon(Icons.date_range,
                        size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      item.releaseDate ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 🔔 Notify Me button
                SizedBox(
                  height: 28,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      CustomToast.show(
                        context,
                        "You’ll be notified on release day",
                        isSuccess: true,
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_active,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: Text(
                      AppLocalizations.of(context)!.notifyMe,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upcoming_outlined,
              size: 80, color: theme.canvasColor.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text(
            "No upcoming content",
            style: TextStyle(
              color: theme.canvasColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
