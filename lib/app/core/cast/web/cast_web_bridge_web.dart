import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:ott/app/core/cast/web/cast_web_bridge_stub.dart';
export 'package:ott/app/core/cast/web/cast_web_bridge_stub.dart' show CastWebBridge, CastWebStateCallback;

CastWebBridge getCastWebBridge() => CastWebBridgeWeb();

class CastWebBridgeWeb implements CastWebBridge {
  @override
  void init(String appId, CastWebStateCallback onState) {
    try {
      html.window.addEventListener('filmytell-cast-state', (html.Event event) {
        if (event is html.CustomEvent && event.detail != null) {
          try {
            final detail = event.detail;
            final jsonStr = detail is String ? detail : jsonEncode(detail);
            final map = jsonDecode(jsonStr) as Map<String, dynamic>;
            onState(map);
          } catch (_) {}
        }
      });

      _sendCmd({'action': 'init', 'appId': appId});
    } catch (_) {}
  }

  void _sendCmd(Map<String, dynamic> detail) {
    try {
      html.window.dispatchEvent(html.CustomEvent('filmytell-cast-cmd', detail: detail));
    } catch (_) {}
  }

  @override
  Future<bool> requestSession() async {
    _sendCmd({'action': 'requestSession'});
    return true;
  }

  @override
  Future<void> endCurrentSession(bool stopCasting) async {
    _sendCmd({'action': 'endCurrentSession', 'stopCasting': stopCasting});
  }

  @override
  Future<bool> loadMedia(Map<String, dynamic> mediaData) async {
    _sendCmd({'action': 'loadMedia', 'mediaData': mediaData});
    return true;
  }

  @override
  Future<void> play() async {
    _sendCmd({'action': 'play'});
  }

  @override
  Future<void> pause() async {
    _sendCmd({'action': 'pause'});
  }

  @override
  Future<void> seek(double seconds) async {
    _sendCmd({'action': 'seek', 'seconds': seconds});
  }

  @override
  Future<void> setVolume(double level) async {
    _sendCmd({'action': 'setVolume', 'level': level});
  }

  @override
  Future<void> stop() async {
    _sendCmd({'action': 'stop'});
  }
}
