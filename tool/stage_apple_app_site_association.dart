import 'dart:io';

/// Stages the Universal Links association file after `flutter build web` and
/// before Firebase Hosting deploys the generated web directory.
void main() {
  final webBuildDirectory = Directory('build/web');
  final webEntrypoint = File('${webBuildDirectory.path}/index.html');
  final source = File('web/apple-app-site-association');
  final destination =
      File('${webBuildDirectory.path}/.well-known/apple-app-site-association');

  if (!webEntrypoint.existsSync()) {
    stderr.writeln(
      'Missing build/web/index.html. Run `flutter build web` before deploying.',
    );
    exitCode = 1;
    return;
  }

  if (!source.existsSync()) {
    stderr.writeln('Missing source AASA file: ${source.path}.');
    exitCode = 1;
    return;
  }

  destination.parent.createSync(recursive: true);
  source.copySync(destination.path);
  stdout.writeln('Staged Apple App Site Association file.');
}
