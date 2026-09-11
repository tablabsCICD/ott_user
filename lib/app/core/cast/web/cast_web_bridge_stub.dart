typedef CastWebStateCallback = void Function(Map<String, dynamic> state);

abstract class CastWebBridge {
  static CastWebBridge create() => throw UnsupportedError('Cannot create CastWebBridge on this platform');

  void init(String appId, CastWebStateCallback onState);
  Future<bool> requestSession();
  Future<void> endCurrentSession(bool stopCasting);
  Future<bool> loadMedia(Map<String, dynamic> mediaData);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(double seconds);
  Future<void> setVolume(double level);
  Future<void> stop();
}

CastWebBridge getCastWebBridge() => CastWebBridgeStub();

class CastWebBridgeStub implements CastWebBridge {
  @override
  void init(String appId, CastWebStateCallback onState) {}

  @override
  Future<bool> requestSession() async => false;

  @override
  Future<void> endCurrentSession(bool stopCasting) async {}

  @override
  Future<bool> loadMedia(Map<String, dynamic> mediaData) async => false;

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seek(double seconds) async {}

  @override
  Future<void> setVolume(double level) async {}

  @override
  Future<void> stop() async {}
}
