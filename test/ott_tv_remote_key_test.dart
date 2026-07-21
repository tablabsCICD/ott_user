import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/widgets/ott_tv_app_shell.dart';

void main() {
  test('remote key groups cover Android TV navigation and activation', () {
    expect(OttTvRemoteKey.up, contains(LogicalKeyboardKey.arrowUp));
    expect(OttTvRemoteKey.down, contains(LogicalKeyboardKey.arrowDown));
    expect(OttTvRemoteKey.left, contains(LogicalKeyboardKey.arrowLeft));
    expect(OttTvRemoteKey.right, contains(LogicalKeyboardKey.arrowRight));
    expect(OttTvRemoteKey.activate, contains(LogicalKeyboardKey.select));
    expect(OttTvRemoteKey.activate, contains(LogicalKeyboardKey.enter));
    expect(OttTvRemoteKey.back, contains(LogicalKeyboardKey.goBack));
  });

  test('remote key groups cover dedicated playback buttons', () {
    expect(
      OttTvRemoteKey.playPause,
      containsAll(<LogicalKeyboardKey>{
        LogicalKeyboardKey.mediaPlayPause,
        LogicalKeyboardKey.mediaPlay,
        LogicalKeyboardKey.mediaPause,
      }),
    );
    expect(OttTvRemoteKey.rewind, contains(LogicalKeyboardKey.mediaRewind));
    expect(
      OttTvRemoteKey.fastForward,
      contains(LogicalKeyboardKey.mediaFastForward),
    );
  });

  test('directional classification excludes action keys', () {
    expect(OttTvRemoteKey.isDirectional(LogicalKeyboardKey.arrowLeft), isTrue);
    expect(OttTvRemoteKey.isDirectional(LogicalKeyboardKey.select), isFalse);
  });
}
