import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/pages/wallet%20page/WalletPage.dart';
import 'package:ott/app/provider/shorts_provider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/app/widgets/shimmer%20loader/shimmer_loader.dart';
import 'package:ott/data/models/shorts.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class ShortsPlayerPage extends StatefulWidget {
  final ShortDetailModel short;
  const ShortsPlayerPage({super.key, required this.short});

  @override
  State<ShortsPlayerPage> createState() => _ShortsPlayerPageState();
}

class _ShortsPlayerPageState extends State<ShortsPlayerPage>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  final PageController _pageController = PageController();

  List<ShortPart> _parts = [];
  int _currentIndex = 0;

  bool _isInitialized = false;
  bool _isLoadingPart = false;
  bool _isMetaExpanded = false;

  int get totalParts => _parts.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final user = await LocalSharePreferences.localSharePreferences.getUser();
    if (!mounted) return;

    await context
        .read<ShortProvider>()
        .fetchShortDetail(widget.short.id, user?.id ?? 1);

    final detail = context.read<ShortProvider>().shortDetail;
    if (detail == null || detail.parts.isEmpty) return;

    setState(() {
      _parts = List.from(detail.parts);
    });

    await _loadPart(0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refreshFromBackend() async {
    final user = await LocalSharePreferences.localSharePreferences.getUser();

    await context
        .read<ShortProvider>()
        .fetchShortDetail(widget.short.id, user?.id ?? 1);

    if (!mounted) return;

    final detail = context.read<ShortProvider>().shortDetail;
    if (detail == null) return;

    setState(() {
      _parts = List.from(detail.parts);
    });
  }

  Future<void> _loadPart(int index) async {
    if (_isLoadingPart || index < 0 || index >= _parts.length) return;
    _isLoadingPart = true;

    try {
      final part = _parts[index];

      final old = _controller;
      _controller = null;
      _isInitialized = false;
      await old?.pause();
      await old?.dispose();

      if (!part.isFreePreview && !part.isPurchased) {
        final wallet = context.read<WalletProvider>();
        await wallet.getBalance();

        if (wallet.walletBalance < part.coins) {
          await _showInsufficientBalanceDialog();
          return;
        }

        await context
            .read<ShortProvider>()
            .purchaseShortPart(partId: int.parse(part.partId));

        await _refreshFromBackend();
      }

      final updated = _parts[index];
      if (!updated.isFreePreview && !updated.isPurchased) return;

      final ctrl = VideoPlayerController.network(updated.videoUrl);
      await ctrl.initialize();
      await ctrl.play();

      if (!mounted) return;

      await context
          .read<ShortProvider>()
          .addShortView(partId: int.parse(updated.partId));

      await _refreshFromBackend();

      setState(() {
        _controller = ctrl;
        _isInitialized = true;
        _currentIndex = index;
        ctrl.setVolume(1);
      });
    } finally {
      _isLoadingPart = false;
    }
  }

  Future<void> _changePage(int index) async {
    if (_isMetaExpanded) {
      setState(() {
        _isMetaExpanded = false;
      });
    }
    await _loadPart(index);
  }

  Future<void> _showInsufficientBalanceDialog() async {
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Insufficient Balance",
            style: TextStyle(
                color: theme.primaryColor, fontWeight: FontWeight.bold)),
        content: Text("You don't have enough coins.",
            style: TextStyle(color: theme.canvasColor)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("Cancel", style: TextStyle(color: theme.canvasColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => WalletPage()));
            },
            child: const Text("Recharge"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanceProvider = Provider.of<WalletProvider>(context);
    balanceProvider.getBalance();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: ResponsiveWidget.isMobile(context) ? double.infinity : 450,
          child: Stack(
            children: [
              _videoBackground(),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _togglePlayPause,
                onDoubleTap: _handleDoubleTapLike,
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: totalParts,
                  onPageChanged: _changePage,
                  itemBuilder: (_, i) => _overlay(i),
                ),
              ),
              _backButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _videoBackground() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ShimmerLoader(
        height: double.infinity,
        width: double.infinity,
      );
    }

    final size = controller.value.size;
    if (size.width == 0 || size.height == 0) {
      return const ShimmerLoader(
        height: double.infinity,
        width: double.infinity,
      );
    }

    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _overlay(int index) {
    final part = _parts[index];
    final theme = Theme.of(context);
    final titleText = part.title.trim().isNotEmpty
        ? part.title.trim()
        : widget.short.title.trim();
    final descriptionText = widget.short.description.trim();
    final hasDescription = descriptionText.isNotEmpty;
    final showSeeMore =
        !_isMetaExpanded && (titleText.length > 36 || hasDescription);
    return Stack(
      children: [
        Positioned(
          left: 16,
          bottom: 80,
          right: 130,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 1),
                      color: Colors.white10,
                    ),
                    child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(100),
                        child: Image.network(
                          part.thumbnail,
                          fit: BoxFit.cover,
                        )),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "${widget.short.creatorName}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2), // x, y
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isMetaExpanded = !_isMetaExpanded;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        maxLines: _isMetaExpanded ? 3 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2), // x, y
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ],
                        ),
                      ),
                      if (_isMetaExpanded && hasDescription) ...[
                        const SizedBox(height: 3),
                        Text(
                          descriptionText,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            height: 1.35,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2), // x, y
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.2),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (showSeeMore) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "See more",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    offset: Offset(2, 2), // x, y
                                    blurRadius: 4,
                                    color: Colors.black.withOpacity(0.2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.expand_more,
                              size: 12,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(2, 2), // x, y
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      if (_isMetaExpanded) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "See less",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    offset: Offset(2, 2), // x, y
                                    blurRadius: 4,
                                    color: Colors.black.withOpacity(0.2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.expand_more,
                              size: 12,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(2, 2), // x, y
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _rightButtons(index),
        _bottomEpisodeBar(),
        if (_controller != null)
          _controller!.value.isPlaying
              ? SizedBox()
              : Center(
                  child: Icon(
                    Icons.play_arrow_sharp,
                    color: Colors.white60,
                    size: 50,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2), // x, y
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
      ],
    );
  }

  Widget _rightButtons(int index) {
    final part = _parts[index];
    final provider = context.watch<ShortProvider>();

    return Positioned(
      right: 12,
      bottom: 120,
      child: Column(
        children: [
          _actionBtn(
            part.isLiked ? Icons.favorite : Icons.favorite_border,
            "${part.likes}",
            provider.isLiking
                ? null
                : () async {
                    final ok = part.isLiked
                        ? await context
                            .read<ShortProvider>()
                            .unlikeShortPart(partId: int.parse(part.partId))
                        : await context
                            .read<ShortProvider>()
                            .likeShortPart(partId: int.parse(part.partId));

                    if (ok) await _refreshFromBackend();
                  },
            isActive: part.isLiked,
          ),
          const SizedBox(height: 18),
          _actionBtn(Icons.telegram_outlined, "share", () {
            _shareShort(context, part);
          }),
          const SizedBox(height: 18),
          _actionBtn(Icons.visibility_outlined, "${part.views}", null),
        ],
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Colors.black12),
            child: Icon(icon,
                size: 26, color: isActive ? theme.primaryColor : Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              shadows: [
                Shadow(
                  offset: Offset(2, 2), // x, y
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareShort(BuildContext context, ShortPart short) async {
    final String shareText = '''
🎬 ${short.title ?? ''}

${short.durationSec ?? ''}

▶️ Watch here:
** filmytell navigation link **

📲 Download Filmytell App now!
'''
        .trim();

    if (kIsWeb) {
      // Flutter Web fallback → Copy to Clipboard
      await Clipboard.setData(ClipboardData(text: shareText));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Share text copied to clipboard"),
        ),
      );
    } else {
      // Android / iOS / Desktop
      await Share.share(
        shareText,
        subject: short.title ?? "Movie",
      );
    }
  }

  Widget _bottomEpisodeBar() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 24,
      child: Column(
        children: [
          InkWell(
            onTap: _openEpisodes,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
              decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [
                    BoxShadow(color: Colors.black12),
                  ]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Episode ${_currentIndex + 1} / $totalParts",
                    style: TextStyle(
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2), // x, y
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.expand_less,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2), // x, y
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _videoProgressBar(),
        ],
      ),
    );
  }

  Widget _videoProgressBar() {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    final value = controller.value;
    if (!value.isInitialized || value.duration == Duration.zero) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 2,
      right: 2,
      //bottom: 3, //max(8.0, bottomInset + 6.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: VideoProgressIndicator(
          controller,
          allowScrubbing: true,
          colors: VideoProgressColors(
            playedColor: theme.primaryColor,
            bufferedColor: Colors.white30,
            backgroundColor: Colors.white24,
          ),
        ),
      ),
    );
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
  }

  Future<void> _handleDoubleTapLike() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _parts.isEmpty) {
      return;
    }

    final part = _parts[_currentIndex];
    final provider = context.read<ShortProvider>();
    if (provider.isLiking || part.isLiked) return;

    HapticFeedback.lightImpact();
    final ok = await provider.likeShortPart(partId: int.parse(part.partId));

    if (ok) await _refreshFromBackend();
  }

  void _openEpisodes() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.builder(
            itemCount: totalParts,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, i) {
              final part = _parts[i];
              final active = i == _currentIndex;

              return GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  _pageController.jumpToPage(i);
                  await _loadPart(i);
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: active ? theme.primaryColor : theme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: theme.canvasColor.withOpacity(.7)),
                      ),
                      child: Center(
                        child: Text(
                          "EP ${part.partNumber}",
                          style: TextStyle(
                            color: active ? Colors.white : theme.canvasColor,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2), // x, y
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!part.isPurchased && !part.isFreePreview)
                      const Positioned(
                          right: 4, top: 4, child: Icon(Icons.lock, size: 14)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _backButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 12,
      child: InkWell(
        onTap: () {
          _controller?.pause();
          Navigator.pop(context);
        },
        child: const CircleAvatar(
          radius: 18,
          backgroundColor: Colors.black45,
          child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
