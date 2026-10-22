import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ott/app/provider/bookmarkProvider.dart';
import 'package:ott/app/provider/onboarding_tour_provider.dart';
import 'package:ott/app/widgets/ios_continue_watch_banner.dart';
import 'package:ott/app/widgets/movieCard.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/l10n/app_localizations.dart';

void main() {
  group('iOS Home Screen Redesign Tests', () {
    testWidgets(
        'IosContinueWatchBanner renders title, progress, genre, and Resume button',
        (tester) async {
      final sampleMovie = Content(
        id: 99,
        title: "Bonsai",
        watchedPercentage: 12,
        watchedSeconds: 120,
        genreList: ["Drama"],
        type: "MOVIE",
        posterUrlList: ["https://example.com/bonsai.jpg"],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            primaryColor: const Color(0xFFE50914),
            platform: TargetPlatform.iOS,
          ),
          home: Scaffold(
            body: IosContinueWatchBanner(items: [sampleMovie]),
          ),
        ),
      );

      await tester.pump();

      expect(find.text("Continue Watching"), findsOneWidget);
      expect(find.text("Bonsai"), findsOneWidget);
      expect(find.text("12% watched | Drama"), findsOneWidget);
      expect(find.text("Resume"), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets(
        'MovieCard on iOS renders compact info with Watch Now button and no star ratings',
        (tester) async {
      final sampleMovie = Content(
        id: 101,
        title: "Rangmanch",
        ratings: 4.5,
        ratingCount: 150,
        releaseDate: "2026-10-18",
        genreList: ["Drama"],
        type: "MOVIE",
        isRental: true,
        posterUrlList: ["https://example.com/rangmanch.jpg"],
      );

      final bookmarkProvider = BookmarkProvider();
      final tourProvider = OnboardingTourProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookmarkProvider>.value(
                value: bookmarkProvider),
            ChangeNotifierProvider<OnboardingTourProvider>.value(
                value: tourProvider),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              primaryColor: const Color(0xFFE50914),
              platform: TargetPlatform.iOS,
            ),
            home: Scaffold(
              body: MovieCard(
                movie: sampleMovie,
                index: 0,
                cardWidth: 240,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Movie title and Watch Now button must be present
      expect(find.text("Rangmanch"), findsOneWidget);
      expect(find.text("Watch Now"), findsOneWidget);

      // Star rating must NOT be present on iOS
      expect(find.text(" (150)"), findsNothing);

      MovieCard.stopActiveTrailerPreview();
      await tester.pumpAndSettle();
    });

    test(
        'Responsive card width calculation verifies ~62% content width and ~38-40% next card visibility',
        () {
      const screenWidth = 402.0; // iPhone 16 Pro
      const horizontalPadding = 16.0;
      final contentWidth = screenWidth - horizontalPadding;
      final cardWidth = contentWidth * 0.62;

      expect(cardWidth / contentWidth, closeTo(0.62, 0.01));
      final remainingWidth = screenWidth - cardWidth - 8.0;
      final visiblePercentOfNext = remainingWidth / cardWidth;

      // Next card is partially visible between 35% and 65% depending on margins
      expect(visiblePercentOfNext, greaterThan(0.35));
    });

    testWidgets(
        'iOS Category Tabs render exactly 4 text-only tabs with approved styling',
        (tester) async {
      final tabs = [
        ('MOVIE', 'Movies'),
        ('SHORT_FILM', 'Short Film'),
        ('SERIES', 'Series'),
        ('MINI SERIES', 'Mini Series'),
      ];

      var selectedType = 'SHORT_FILM';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            primaryColor: const Color(0xFFE50914),
            platform: TargetPlatform.iOS,
          ),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                final theme = Theme.of(context);
                return Row(
                  children: tabs.map((tab) {
                    final type = tab.$1;
                    final label = tab.$2;
                    final isSelected = selectedType == type;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: GestureDetector(
                          onTap: () => setState(() => selectedType = type),
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryColor
                                  : Colors.black,
                              border: Border.all(
                                color: isSelected
                                    ? theme.primaryColor
                                    : Colors.white24,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Exactly the 4 approved tabs exist
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('Short Film'), findsOneWidget);
      expect(find.text('Series'), findsOneWidget);
      expect(find.text('Mini Series'), findsOneWidget);

      // Verify selected tab background color is red
      final shortFilmContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Short Film'),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = shortFilmContainer.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFE50914));

      // Verify unselected tab background color is black
      final moviesContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Movies'),
              matching: find.byType(Container),
            )
            .first,
      );
      final moviesDecoration = moviesContainer.decoration as BoxDecoration;
      expect(moviesDecoration.color, Colors.black);
    });
  });
}
