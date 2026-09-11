import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/core/cast/cast_constants.dart';
import 'package:ott/app/core/cast/cast_models.dart';
import 'package:ott/app/core/cast/web/cast_web_bridge.dart';

/// Central Google Cast Manager for FilmyTell.
/// Connects Flutter UI to native Android Google Cast SDK (via MethodChannel)
/// and to Google Cast Web Sender SDK (via Web Bridge).
class CastManager extends ChangeNotifier {
  CastManager._internal() {
    _initPlatformBridge();
  }

  static final CastManager instance = CastManager._internal();

  static const MethodChannel _androidChannel = MethodChannel('com.filmytell.ott/cast');
  late final CastWebBridge _webBridge;

  final List<CastDevice> _devices = [];
  List<CastDevice> get devices => List.unmodifiable(_devices);

  CastDevice? _connectedDevice;
  CastDevice? get connectedDevice => _connectedDevice;

  bool get isCasting =>
      _connectedDevice != null &&
      (_state == CastPlayerState.playing ||
          _state == CastPlayerState.paused ||
          _state == CastPlayerState.buffering ||
          _state == CastPlayerState.connected);

  CastPlayerState _state = CastPlayerState.disconnected;
  CastPlayerState get state => _state;

  CastMediaMetadata? _currentMedia;
  CastMediaMetadata? get currentMedia => _currentMedia;

  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  double _volume = 1.0;
  double get volume => _volume;

  bool _isDiscovering = false;
  bool get isDiscovering => _isDiscovering;

  bool _isInitialized = false;

  void _initPlatformBridge() {
    if (_isInitialized) return;
    _isInitialized = true;

    if (kIsWeb) {
      try {
        _webBridge = getCastWebBridge();
        _webBridge.init(CastConstants.castAppId, _handleWebState);
      } catch (e) {
        log('[CastManager] Web bridge init error: $e');
      }
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      _androidChannel.setMethodCallHandler(_handleNativeMethodCall);
      _queryNativeInitialState();
    }
  }

  Future<void> _queryNativeInitialState() async {
    try {
      final stateMap = await _androidChannel.invokeMapMethod<String, dynamic>('init');
      if (stateMap != null) {
        final isConnected = stateMap['isConnected'] == true;
        final deviceName = (stateMap['deviceName'] as String?) ?? 'Google TV';
        final playerStateStr = (stateMap['playerState'] as String?) ?? 'DISCONNECTED';
        final posSec = (stateMap['positionSeconds'] as num?)?.toInt() ?? 0;
        final durSec = (stateMap['durationSeconds'] as num?)?.toInt() ?? 0;

        if (isConnected) {
          _connectedDevice = CastDevice(
            id: 'android-cast-device',
            name: deviceName.isNotEmpty ? deviceName : 'Google Cast',
            host: 'local',
            isConnected: true,
          );
          _state = _mapPlayerState(playerStateStr);
        } else {
          _connectedDevice = null;
          _state = CastPlayerState.disconnected;
        }

        _position = Duration(seconds: posSec);
        _duration = Duration(seconds: durSec);
        notifyListeners();
      }
    } catch (e) {
      log('[CastManager] Failed to query native initial state: $e');
    }
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSessionStateChanged':
        final args = call.arguments as Map<dynamic, dynamic>?;
        if (args != null) {
          final sessionState = (args['sessionState'] as String?) ?? 'DISCONNECTED';
          final deviceName = (args['deviceName'] as String?) ?? 'Google Cast';
          final isConnected = args['isConnected'] == true;

          if (isConnected) {
            _connectedDevice = CastDevice(
              id: 'android-cast-device',
              name: deviceName.isNotEmpty ? deviceName : 'Google Cast',
              host: 'local',
              isConnected: true,
            );
            _state = CastPlayerState.connected;
          } else if (sessionState == 'CONNECTING') {
            _state = CastPlayerState.connecting;
          } else {
            _connectedDevice = null;
            _state = CastPlayerState.disconnected;
            _currentMedia = null;
            _position = Duration.zero;
            _duration = Duration.zero;
          }
          notifyListeners();
        }
        break;

      case 'onMediaStateChanged':
        final args = call.arguments as Map<dynamic, dynamic>?;
        if (args != null) {
          final playerStateStr = (args['playerState'] as String?) ?? 'IDLE';
          final posSec = (args['positionSeconds'] as num?)?.toInt() ?? 0;
          final durSec = (args['durationSeconds'] as num?)?.toInt() ?? 0;
          final isMuted = args['isMuted'] == true;

          _state = _mapPlayerState(playerStateStr);
          _position = Duration(seconds: posSec);
          if (durSec > 0) _duration = Duration(seconds: durSec);
          _isMuted = isMuted;
          notifyListeners();
        }
        break;

      case 'onProgressUpdated':
        final args = call.arguments as Map<dynamic, dynamic>?;
        if (args != null) {
          final posSec = (args['positionSeconds'] as num?)?.toInt() ?? 0;
          final durSec = (args['durationSeconds'] as num?)?.toInt() ?? 0;
          _position = Duration(seconds: posSec);
          if (durSec > 0) _duration = Duration(seconds: durSec);
          notifyListeners();
        }
        break;
    }
  }

  void _handleWebState(Map<String, dynamic> state) {
    final isConnected = state['isConnected'] == true;
    final deviceName = (state['deviceName'] as String?) ?? 'Google Cast';
    final playerStateStr = (state['playerState'] as String?) ?? 'IDLE';
    final curTime = (state['currentTime'] as num?)?.toDouble() ?? 0.0;
    final dur = (state['duration'] as num?)?.toDouble() ?? 0.0;
    final muted = state['isMuted'] == true;
    final vol = (state['volumeLevel'] as num?)?.toDouble() ?? 1.0;

    if (isConnected) {
      _connectedDevice = CastDevice(
        id: 'web-cast-device',
        name: deviceName.isNotEmpty ? deviceName : 'Google Cast',
        host: 'web',
        isConnected: true,
      );
      _state = _mapPlayerState(playerStateStr);
    } else {
      _connectedDevice = null;
      _state = CastPlayerState.disconnected;
      _currentMedia = null;
    }

    _position = Duration(seconds: curTime.toInt());
    if (dur > 0) _duration = Duration(seconds: dur.toInt());
    _isMuted = muted;
    _volume = vol;
    notifyListeners();
  }

  CastPlayerState _mapPlayerState(String stateStr) {
    switch (stateStr.toUpperCase()) {
      case 'PLAYING':
        return CastPlayerState.playing;
      case 'PAUSED':
        return CastPlayerState.paused;
      case 'BUFFERING':
        return CastPlayerState.buffering;
      case 'CONNECTED':
        return CastPlayerState.connected;
      case 'CONNECTING':
        return CastPlayerState.connecting;
      case 'IDLE':
      case 'DISCONNECTED':
      default:
        return _connectedDevice != null ? CastPlayerState.connected : CastPlayerState.disconnected;
    }
  }

  /// Launch native/web Google Cast device dialog to select a Google TV or Chromecast.
  Future<void> showCastDialog() async {
    if (kIsWeb) {
      try {
        await _webBridge.requestSession();
      } catch (e) {
        log('[CastManager] Web requestSession error: $e');
      }
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _androidChannel.invokeMethod('showCastDialog');
      } catch (e) {
        log('[CastManager] Android showCastDialog error: $e');
      }
    }
  }

  /// Start device discovery (maintained for backward compatibility with existing UI).
  Future<void> startDiscovery({Duration timeout = const Duration(seconds: 15)}) async {
    _isDiscovering = true;
    notifyListeners();
    // On Android & Web, real discovery runs inside the official Cast SDK / dialog.
    Future.delayed(const Duration(milliseconds: 500), () {
      _isDiscovering = false;
      notifyListeners();
    });
  }

  void stopDiscovery() {
    _isDiscovering = false;
    notifyListeners();
  }

  void addOrUpdateDevice(CastDevice device) {
    final index = _devices.indexWhere((d) => d.id == device.id || d.host == device.host);
    if (index >= 0) {
      _devices[index] = device;
    } else {
      _devices.add(device);
    }
    notifyListeners();
  }

  void removeDevice(String deviceId) {
    _devices.removeWhere((d) => d.id == deviceId);
    notifyListeners();
  }

  /// Connect to a specific device (invokes native cast dialog or session request).
  Future<bool> connect(CastDevice device) async {
    await showCastDialog();
    return isCasting || _state == CastPlayerState.connected || _state == CastPlayerState.connecting;
  }

  /// Disconnect from the currently connected Cast device
  Future<void> disconnect() async {
    if (kIsWeb) {
      await _webBridge.endCurrentSession(true);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _androidChannel.invokeMethod('disconnect');
      } catch (e) {
        log('[CastManager] Android disconnect error: $e');
      }
    }

    _connectedDevice = null;
    _state = CastPlayerState.disconnected;
    _currentMedia = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  /// Load and start playing media on the Cast receiver
  Future<bool> loadMedia(CastMediaMetadata metadata) async {
    _currentMedia = metadata;
    _position = metadata.initialPosition;
    _duration = metadata.duration ?? Duration.zero;
    _state = CastPlayerState.buffering;
    notifyListeners();

    final payload = metadata.toJson();

    if (kIsWeb) {
      try {
        final success = await _webBridge.loadMedia(payload);
        if (success) {
          _state = CastPlayerState.playing;
          notifyListeners();
          return true;
        }
      } catch (e) {
        log('[CastManager] Web loadMedia error: $e');
      }
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final success = await _androidChannel.invokeMethod<bool>('loadMedia', payload);
        if (success == true) {
          _state = CastPlayerState.playing;
          notifyListeners();
          return true;
        }
      } catch (e) {
        log('[CastManager] Android loadMedia error: $e');
      }
    }

    _state = CastPlayerState.error;
    notifyListeners();
    return false;
  }

  /// Play current media on Cast device
  Future<void> play() async {
    if (kIsWeb) {
      await _webBridge.play();
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _androidChannel.invokeMethod('play');
      } catch (_) {}
    }
    _state = CastPlayerState.playing;
    notifyListeners();
  }

  /// Pause playback on Cast device
  Future<void> pause() async {
    if (kIsWeb) {
      await _webBridge.pause();
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _androidChannel.invokeMethod('pause');
      } catch (_) {}
    }
    _state = CastPlayerState.paused;
    notifyListeners();
  }

  /// Seek to position on Cast device
  Future<void> seek(Duration targetPosition) async {
    _position = targetPosition;
    notifyListeners();

    if (kIsWeb) {
      await _webBridge.seek(targetPosition.inSeconds.toDouble());
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _androidChannel.invokeMethod('seek', {'positionSeconds': targetPosition.inSeconds});
      } catch (_) {}
    }
  }

  /// Stop media playback on Cast device
  Future<void> stop() async {
    if (kIsWeb) {
      await _webBridge.stop();
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _androidChannel.invokeMethod('stop');
      } catch (_) {}
    }
    _state = CastPlayerState.connected;
    _position = Duration.zero;
    notifyListeners();
  }

  /// Set Cast playback volume (0.0 to 1.0)
  Future<void> setVolume(double newVolume) async {
    _volume = newVolume.clamp(0.0, 1.0);
    _isMuted = _volume == 0.0;
    notifyListeners();

    if (kIsWeb) {
      await _webBridge.setVolume(_volume);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _androidChannel.invokeMethod('setVolume', {'volume': _volume});
      } catch (_) {}
    }
  }

  /// Toggle mute state on Cast device
  Future<void> toggleMute() async {
    final targetVol = _isMuted ? (_volume > 0.0 ? _volume : 1.0) : 0.0;
    await setVolume(targetVol);
  }
}
