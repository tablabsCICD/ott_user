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
