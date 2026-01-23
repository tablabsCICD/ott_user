import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/pages/wallet%20page/WalletPage.dart';
import 'package:ott/app/provider/shorts_provider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/app/widgets/shimmer%20loader/shimmer_loader.dart';
import 'package:ott/data/models/shorts.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class ShortsPlayerPage extends StatefulWidget {
  final ShortDetailModel short;

  const ShortsPlayerPage({super.key, required this.short});

  @override
  State<ShortsPlayerPage> createState() => _ShortsPlayerPageState();
}

class _ShortsPlayerPageState extends State<ShortsPlayerPage>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller; // video controller for current short
  final PageController _pageController = PageController(); // vertical pager

  int _currentIndex = 0; // currently playing index
  bool _isInitialized = false; // video ready flag
  bool _isMuted = false; // mute state
  bool _isLoadingPart = false; // prevent parallel loads

  List<ShortPart> get parts => widget.short.parts;
  int get totalParts => parts.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (totalParts > 0) {
        _loadPart(0); // First reel goes through SAME logic as others
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Future<void> _prepareFirstPart() async {
  //   final first = parts[0];

  //   // If already free or purchased, play normally
  //   if (first.isFreePreview || first.isPurchased) {
  //     _loadPart(0);
  //     return;
  //   }

  //   // Otherwise check wallet
  //   final walletProvider = context.read<WalletProvider>();
  //   await walletProvider.getBalance();

  //   // If insufficient balance, do nothing now (no autoplay, no popup)
  //   if (walletProvider.walletBalance < first.coins) {
  //     return;
  //   }

  //   // Try to purchase silently
  //   final data = await context.read<ShortProvider>().purchaseShortPart(
  //         partId: int.parse(first.partId),
  //       );

  //   if (data != null) {
  //     await _refreshFromBackend();

  //     // Now it is purchased → load & play
  //     _loadPart(0);
  //   }
  // }

  // Pause video when app goes background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller?.pause();
    }
  }

  // Re-fetch detail from backend (backend is source of truth)
  Future<void> _refreshFromBackend() async {
    final provider = context.read<ShortProvider>();
    final user = await LocalSharePreferences.localSharePreferences.getUser();

    await provider.fetchShortDetail(widget.short.id, user!.id!);

    setState(() {
      widget.short.parts
        ..clear()
        ..addAll(provider.shortDetail!.parts);
    });
  }

  // Popup when wallet balance is insufficient
  Future<void> _showInsufficientBalanceDialog() async {
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Insufficient Balance",
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          "You don't have enough coins to purchase this short.",
          style: TextStyle(
            color: theme.canvasColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              "Cancel",
              style: TextStyle(color: theme.canvasColor),
            ),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WalletPage()),
              );
            },
            child: const Text(
              "Recharge",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Core logic to load & play a short
  Future<void> _loadPart(int index) async {
    if (_isLoadingPart) return;
    _isLoadingPart = true;

    final part = parts[index];

    // Stop previous video
    final old = _controller;
    _controller = null;
    _isInitialized = false;
    await old?.pause();
    await old?.dispose();

    // If not free & not purchased → try purchase
    if (!part.isFreePreview && !part.isPurchased) {
      final walletProvider = context.read<WalletProvider>();
      await walletProvider.getBalance();

      final balance = walletProvider.walletBalance;
      final requiredCoins = part.coins;

      // Insufficient balance → block & show popup
      if (balance < requiredCoins) {
        _isLoadingPart = false;
        await _showInsufficientBalanceDialog();
        return;
      }

      // Try purchase
      final data = await context.read<ShortProvider>().purchaseShortPart(
            partId: int.parse(part.partId),
          );

      if (data == null) {
        _isLoadingPart = false;
        return;
      }

      // Refresh backend state
      await _refreshFromBackend();
    }

    // Re-read updated part
    final updatedPart = parts[index];

    // Still not allowed → never play
    if (!updatedPart.isFreePreview && !updatedPart.isPurchased) {
      _isLoadingPart = false;
      return;
    }

    // Play video
    final ctrl = VideoPlayerController.network(updatedPart.videoUrl);
    await ctrl.initialize();
    await ctrl.play();

    if (!mounted) return;

    // Add view
    final viewed = await context
        .read<ShortProvider>()
        .addShortView(partId: int.parse(updatedPart.partId));

    if (viewed) {
      await _refreshFromBackend();
    }

    setState(() {
      _controller = ctrl;
      _isInitialized = true;
      _isMuted = false;
      ctrl.setVolume(1);
      _currentIndex = index;
    });

    _isLoadingPart = false;
  }

  Future<void> _changePage(int index) async {
    await _loadPart(index);
  }

  @override
  Widget build(BuildContext context) {
    final balanceProvider = Provider.of<WalletProvider>(context);
    balanceProvider.getBalance(); // keep wallet in sync
    final coinsBalance = balanceProvider.walletBalance;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: ResponsiveWidget.isMobile(context) ? double.infinity : 450,
          child: Stack(
            children: [
              _videoBackground(),

              // Play / Pause on tap
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    if (_controller == null) return;
                    _controller!.value.isPlaying
                        ? _controller!.pause()
                        : _controller!.play();
                  },
                ),
              ),

              // Vertical swipe shorts
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: totalParts,
                onPageChanged: _changePage,
                itemBuilder: (_, i) => _overlay(i),
              ),

              _backButton(),

              // Wallet balance pill
              Positioned(
                right: 2,
                top: 50,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WalletPage()),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    padding:
                        const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'coin',
                          child: SizedBox(
                            height: 20,
                            child: Image.asset(ImageConstant.coin),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          coinsBalance.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Background video layer
  Widget _videoBackground() {
    if (!_isInitialized || _controller == null) {
      return ShimmerLoader(
        height: double.infinity,
        width: double.infinity,
      );
    }

    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }

  // Overlay UI for each short
  Widget _overlay(int index) {
    final part = parts[index];
    return Stack(
      children: [
        _leftInfo(part),
        _rightButtons(index),
        _bottomEpisodeBar(),
      ],
    );
  }

  // Creator & title
  Widget _leftInfo(ShortPart part) {
    return Positioned(
      left: 16,
      bottom: 100,
      right: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("@${widget.short.creatorName}",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            part.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Like & View buttons
  Widget _rightButtons(int index) {
    final part = parts[index];
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

                    if (ok) {
                      await _refreshFromBackend();
                    }
                  },
            isActive: part.isLiked,
          ),
          const SizedBox(height: 18),
          _actionBtn(Icons.visibility_outlined, "${part.views}", () {}),
        ],
      ),
    );
  }

  // Common circular action button
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
              shape: BoxShape.circle,
              color: Colors.white12,
            ),
            child: Icon(
              icon,
              size: 26,
              color: isActive ? theme.primaryColor : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  // Episode selector bar
  Widget _bottomEpisodeBar() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 24,
      child: InkWell(
        onTap: _openEpisodes,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Episode ${_currentIndex + 1} / $totalParts",
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const Icon(Icons.expand_less, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  // Bottom sheet to jump between episodes
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
              childAspectRatio: 1,
            ),
            itemBuilder: (_, i) {
              final part = parts[i];
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
                          color: theme.canvasColor.withOpacity(0.7),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "EP ${part.partNumber}",
                          style: TextStyle(
                            color: active ? Colors.white : theme.canvasColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (!part.isPurchased && !part.isFreePreview)
                      const Positioned(
                        right: 4,
                        top: 4,
                        child: Icon(Icons.lock, size: 14),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Back button
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
