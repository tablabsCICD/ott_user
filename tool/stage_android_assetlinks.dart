import 'dart:io';

/// Copies static compliance files into the generated web build before a
/// Firebase Hosting deployment.
void main() {
  final webBuildDirectory = Directory('build/web');
  final webEntrypoint = File('${webBuildDirectory.path}/index.html');

  if (!webEntrypoint.existsSync()) {
    stderr.writeln(
      'Missing build/web/index.html. Run `flutter build web` before deploying.',
    );
    exitCode = 1;
    return;
  }

  if (!_verifyFlutterWebAssets(webBuildDirectory)) {
    return;
  }

  if (!_copyRequiredFile(
    source: File('web/.well-known/assetlinks.json'),
    destination: File('${webBuildDirectory.path}/.well-known/assetlinks.json'),
    label: 'Android Digital Asset Links file',
  )) {
    return;
  }
  if (!_copyRequiredFile(
    source: File('web/account-delete.html'),
    destination: File('${webBuildDirectory.path}/account-delete.html'),
    label: 'account deletion page',
  )) {
    return;
  }
}

bool _verifyFlutterWebAssets(Directory webBuildDirectory) {
  final requiredFiles = <String>[
    'assets/AssetManifest.bin',
    'assets/AssetManifest.bin.json',
    'assets/FontManifest.json',
    'assets/fonts/MaterialIcons-Regular.otf',
    'flutter_bootstrap.js',
    'main.dart.js',
    'canvaskit/canvaskit.js',
    'canvaskit/canvaskit.wasm',
  ];

  for (final relativePath in requiredFiles) {
    final file = File('${webBuildDirectory.path}/$relativePath');
    if (!file.existsSync() || file.lengthSync() == 0) {
      stderr.writeln(
        'Incomplete Flutter web build: missing or empty ${file.path}. '
        'Run `flutter build web` and deploy the complete build/web directory.',
      );
      exitCode = 1;
      return false;
    }
  }

  final fontManifest = File(
    '${webBuildDirectory.path}/assets/FontManifest.json',
  ).readAsStringSync();
  if (!fontManifest.contains('fonts/MaterialIcons-Regular.otf')) {
    stderr.writeln(
      'Incomplete Flutter web build: FontManifest.json does not reference '
      'MaterialIcons-Regular.otf.',
    );
    exitCode = 1;
    return false;
  }

  stdout.writeln('Verified required Flutter web assets.');
  return true;
}

bool _copyRequiredFile({
  required File source,
  required File destination,
  required String label,
}) {
  if (!source.existsSync()) {
    stderr.writeln('Missing $label: ${source.path}.');
    exitCode = 1;
    return false;
  }
  destination.parent.createSync(recursive: true);
  source.copySync(destination.path);
  stdout.writeln('Staged $label.');
  return true;
}
