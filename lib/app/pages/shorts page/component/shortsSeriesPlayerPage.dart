import 'package:flutter/material.dart';
import 'package:ott/data/models/shorts.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
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

  int _currentIndex = 0;
  bool _isInitialized = false;

  List<ShortPart> get parts => widget.short.parts;
  int get totalParts => parts.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (totalParts > 0) {
      _loadVideo(0);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller?.pause();
    }
  }

  Future<void> _loadVideo(int index) async {
    final url = parts[index].videoUrl;

    final old = _controller;
    _controller = null;
    _isInitialized = false;
    await old?.pause();
    await old?.dispose();

    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      await ctrl.initialize();
      ctrl.setLooping(false);
      await ctrl.play();
    } catch (e) {
      debugPrint("Video error: $e");
    }

    if (!mounted) return;

    setState(() {
      _controller = ctrl;
      _isInitialized = ctrl.value.isInitialized;
    });
  }

  Future<void> _changePage(int index) async {
    _currentIndex = index;
    await _loadVideo(index);
  }

  // --------------------------------------------------------
  // BUILD
  // --------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: ResponsiveWidget.isMobile(context) ? double.infinity : 450,
          child: Stack(
            children: [
              _videoBackground(),
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                itemCount: totalParts,
                onPageChanged: (i) => _changePage(i),
                itemBuilder: (c, i) => _overlay(i),
              ),
              _backButton(),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // VIDEO — fullscreen shorts style
  // --------------------------------------------------------
  Widget _videoBackground() {
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final size = _controller!.value.size;

    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // OVERLAY UI (per page)
  // --------------------------------------------------------
  Widget _overlay(int index) {
    final part = parts[index];
    return GestureDetector(
      onTap: () {
        if (_controller == null) return;
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
        setState(() {});
      },
      child: Stack(
        children: [
          _leftInfo(part),
          _rightButtons(part),
          _bottomEpisodeBar(),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // LEFT: creator + title
  // --------------------------------------------------------
  Widget _leftInfo(ShortPart part) {
    return Positioned(
      left: 16,
      bottom: 120,
      right: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "@${widget.short.creatorName}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            part.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // RIGHT ACTION BUTTONS
  // --------------------------------------------------------
  Widget _rightButtons(ShortPart part) {
    bool isMuted = _controller?.value.volume == 0;

    return Positioned(
      right: 12,
      bottom: 120,
      child: Column(
        children: [
          _iconBtn(Icons.thumb_up_alt_outlined, "0"),
          const SizedBox(height: 20),
          _iconBtn(Icons.visibility_outlined, "0"),
          const SizedBox(height: 20),
          _iconBtn(Icons.share, "Share"),
          const SizedBox(height: 25),

          // Mute/Unmute
          InkWell(
            onTap: () {
              if (_controller == null) return;
              _controller!.setVolume(isMuted ? 1 : 0);
              setState(() {});
            },
            child: Icon(
              isMuted ? Icons.volume_off : Icons.volume_up,
              size: 32,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 35),

          // Profile pic
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(widget.short.poster),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white12,
          ),
          child: Icon(icon, size: 26, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ],
    );
  }

  // --------------------------------------------------------
  // BOTTOM EPISODE BAR
  // --------------------------------------------------------
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

  // --------------------------------------------------------
  // BACK BUTTON
  // --------------------------------------------------------
  Widget _backButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 12,
      child: InkWell(
        onTap: () {
          _controller?.pause();
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // EPISODE SELECTOR SHEET
  // --------------------------------------------------------
  void _openEpisodes() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
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
              final active = i == _currentIndex;
              final locked = parts[i].locked;

              return GestureDetector(
                onTap: locked
                    ? null
                    : () {
                        Navigator.pop(context);
                        _pageController.jumpToPage(i);
                        _changePage(i);
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: active ? Colors.redAccent : Colors.grey[900],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: locked ? Colors.white10 : Colors.white24,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "EP ${parts[i].partNumber}",
                      style: TextStyle(
                        color: locked ? Colors.white38 : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
