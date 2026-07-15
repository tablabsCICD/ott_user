import 'package:ott/data/models/content.dart';

class WebLandingSection {
  const WebLandingSection({
    required this.title,
    required this.items,
    this.numbered = false,
  });

  final String title;
  final List<Content> items;
  final bool numbered;
}
