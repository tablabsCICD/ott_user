import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/widgets/filmytell_poster_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FilmytellPosterImage Unit & Widget Tests', () {
    test('sanitizeUrl handles schemes, relative slashes, and whitespace', () {
      expect(FilmytellPosterImage.sanitizeUrl(null), isNull);
      expect(FilmytellPosterImage.sanitizeUrl('   '), isNull);
      expect(
        FilmytellPosterImage.sanitizeUrl('//example.com/poster.jpg'),
        equals('https://example.com/poster.jpg'),
      );
      expect(
        FilmytellPosterImage.sanitizeUrl('http://example.com/poster.jpg'),
        equals('https://example.com/poster.jpg'),
      );
      expect(
        FilmytellPosterImage.sanitizeUrl('  https://example.com/poster.jpg  '),
        equals('https://example.com/poster.jpg'),
      );
    });

    testWidgets('Renders fallback icon when posterUrl is null or empty',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 180,
              child: FilmytellPosterImage(
                posterUrl: null,
                fallbackIcon: Icons.broken_image,
                fallbackIconSize: 60,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.broken_image), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets(
        'Renders dual-layer composition: ambient cover + scrim + contain foreground',
        (tester) async {
      const testUrl = 'https://example.com/test_poster.jpg';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 180,
              child: FilmytellPosterImage(
                posterUrl: testUrl,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                ambientOpacity: 0.72,
              ),
            ),
          ),
        ),
      );

      // Verify Stack is used inside FilmytellPosterImage
      expect(
        find.descendant(
          of: find.byType(FilmytellPosterImage),
          matching: find.byType(Stack),
        ),
        findsOneWidget,
      );

      // Verify DecoratedBox (scrim) exists
      expect(find.byType(DecoratedBox), findsWidgets);

      // Verify two Image widgets are instantiated (ambient background + foreground)
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images.length, equals(2));

      // Layer 1: Ambient background
      expect(images[0].fit, equals(BoxFit.cover));
      expect(images[0].alignment, equals(Alignment.center));

      // Layer 2: Foreground uncropped poster
      expect(images[1].fit, equals(BoxFit.contain));
      expect(images[1].alignment, equals(Alignment.center));
    });

    testWidgets(
        'Renders without overflow or distortion across multiple device card dimensions',
        (tester) async {
      final testSizes = [
        const Size(150, 108), // Small Mobile Card
        const Size(225, 163), // Tablet Card
        const Size(300, 180), // Standard TV & Desktop Card
        const Size(340, 246), // Ultra-wide / 4K TV Card
      ];

      for (final size in testSizes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: const FilmytellPosterImage(
                  posterUrl: 'https://example.com/vertical_poster.jpg',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
        );

        // Verify zero RenderFlex overflow errors
        expect(tester.takeException(), isNull);
        expect(find.byType(FilmytellPosterImage), findsOneWidget);
      }
    });
  });
}
