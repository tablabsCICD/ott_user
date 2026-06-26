import 'dart:io';

/// Copies Android Digital Asset Links into the generated web build before a
/// Firebase Hosting deployment. Flutter does not copy hidden web directories.
void main() {
  final webBuildDirectory = Directory('build/web');
  final webEntrypoint = File('${webBuildDirectory.path}/index.html');
  final source = File('web/.well-known/assetlinks.json');
  final destination =
      File('${webBuildDirectory.path}/.well-known/assetlinks.json');

  if (!webEntrypoint.existsSync()) {
    stderr.writeln(
      'Missing build/web/index.html. Run `flutter build web` before deploying.',
    );
    exitCode = 1;
    return;
  }

  if (!source.existsSync()) {
    stderr.writeln('Missing Android Asset Links file: ${source.path}.');
    exitCode = 1;
    return;
  }

  destination.parent.createSync(recursive: true);
  source.copySync(destination.path);
  stdout.writeln('Staged Android Digital Asset Links file.');
}
