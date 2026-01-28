import 'package:flutter/material.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/pages/wallet%20page/WalletPage.dart';
import 'package:ott/app/provider/shorts_provider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/app/widgets/shimmer%20loader/shimmer_loader.dart';
import 'package:ott/data/models/shorts.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
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
  VideoPlayerController? _controller;
  final PageController _pageController = PageController();

  List<ShortPart> _parts = [];
  int _currentIndex = 0;

  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isLoadingPart = false;

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
        .fetchShortDetail(widget.short.id, user!.id!);

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
        .fetchShortDetail(widget.short.id, user!.id!);

    if (!mounted) return;

    setState(() {
      _parts = List.from(context.read<ShortProvider>().shortDetail!.parts);
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
        _isMuted = false;
        ctrl.setVolume(1);
      });
    } finally {
      _isLoadingPart = false;
    }
  }

  Future<void> _changePage(int index) async {
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
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: totalParts,
                onPageChanged: _changePage,
                itemBuilder: (_, i) => _overlay(i),
              ),
              _backButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _videoBackground() {
    if (!_isInitialized || _controller == null) {
      return const ShimmerLoader(
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

  Widget _overlay(int index) {
    final part = _parts[index];
    return Stack(
      children: [
        Positioned(
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
              Text(part.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        _rightButtons(index),
        _bottomEpisodeBar(),
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
                shape: BoxShape.circle, color: Colors.white12),
            child: Icon(icon,
                size: 26, color: isActive ? theme.primaryColor : Colors.white),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

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
              Text("Episode ${_currentIndex + 1} / $totalParts",
                  style: const TextStyle(color: Colors.white)),
              const Icon(Icons.expand_less, color: Colors.white),
            ],
          ),
        ),
      ),
    );
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
                        child: Text("EP ${part.partNumber}",
                            style: TextStyle(
                                color:
                                    active ? Colors.white : theme.canvasColor,
                                fontWeight: FontWeight.bold)),
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
