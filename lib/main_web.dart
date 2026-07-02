import 'package:ott/app/flavor/app_bootstrap.dart';
import 'package:ott/app/flavor/app_flavor.dart';

Future<void> main() => runFilmytellApp(
      fallbackFlavor: FilmytellFlavor.web,
    );
