import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/presentation/web_landing/designs/common/animated_theme_toggle.dart';
import 'package:ott/presentation/web_landing/designs/common/landing_common_footer.dart';
import 'package:ott/presentation/web_landing/designs/common/landing_common_header.dart';
import 'package:ott/presentation/web_landing/designs/common/premium_content_card.dart';
import 'package:ott/presentation/web_landing/designs/design1_cinematic_ott/cinematic_hero_section.dart';
import 'package:ott/presentation/web_landing/designs/design1_cinematic_ott/cinematic_rail_section.dart';
import 'package:ott/presentation/web_landing/designs/design2_modern_streaming/modern_floating_grid_section.dart';
import 'package:ott/presentation/web_landing/designs/design2_modern_streaming/modern_glass_device_section.dart';
import 'package:ott/presentation/web_landing/designs/design2_modern_streaming/modern_hero_section.dart';
import 'package:ott/presentation/web_landing/designs/design3_motion_marketing/marketing_app_ecosystem_section.dart';
import 'package:ott/presentation/web_landing/designs/design3_motion_marketing/marketing_hero_section.dart';
import 'package:ott/presentation/web_landing/designs/design3_motion_marketing/marketing_stats_showcase.dart';
import 'package:ott/presentation/web_landing/designs/design3_motion_marketing/why_filmytell_section.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  final sampleContent = Content(
    id: 101,
    title: 'Maharaja: The Warrior King',
    description: 'An epic tale of valor, courage, and empire in 4K HDR.',
    type: 'MOVIE',
    ratings: 9.2,
    releaseDate: '2026-05-12',
    genreList: ['Action', 'Drama', 'History'],
    posterUrlList: ['https://example.com/poster.jpg'],
    teaserUrl: 'https://example.com/trailer.mp4',
  );

  Widget wrapWithTheme(Widget child, {bool isDark = true}) {
    return ChangeNotifierProvider(
      create: (_) => LandingThemeProvider(
        initialMode: isDark ? ThemeMode.dark : ThemeMode.light,
      ),
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Landing Page Shared Components Test', () {
    testWidgets('AnimatedThemeToggle renders and can be tapped', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithTheme(const AnimatedThemeToggle()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AnimatedThemeToggle), findsOneWidget);
      await tester.tap(find.byType(AnimatedThemeToggle));
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('PremiumContentCard renders content details', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithTheme(
          PremiumContentCard(
            content: sampleContent,
            rankNumber: 1,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Maharaja: The Warrior King'), findsOneWidget);
      expect(find.text('TOP 1'), findsOneWidget);
    });

    testWidgets('LandingCommonHeader renders branding and CTA', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithTheme(
          LandingCommonHeader(
            scrolled: false,
            onLogin: () {},
            onSignUp: () {},
            onNavigate: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Watch Now'), findsOneWidget);
    });

    testWidgets('LandingCommonFooter renders links and copyright', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithTheme(const LandingCommonFooter()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Partners & Creators'), findsOneWidget);
      expect(find.text('Company & Legal'), findsOneWidget);
    });
  });

  group('Design 1: Cinematic OTT Components Test', () {
    testWidgets('CinematicHeroSection renders with content', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithTheme(
          CinematicHeroSection(
            items: [sampleContent],
            onWatchNow: (_) {},
            onPlayTrailer: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Maharaja: The Warrior King'), findsOneWidget);
      expect(find.text('Watch Now'), findsOneWidget);
      expect(find.text('Watch Trailer'), findsOneWidget);
    });

    testWidgets('CinematicRailSection renders ranked carousel', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithTheme(
          CinematicRailSection(
            title: 'Top 10 in India Today',
            items: [sampleContent],
            isRanked: true,
            onContentTap: (_) {},
            onPlayTrailer: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Top 10 in India Today'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('Design 2: Modern Streaming Platform Components Test', () {
    testWidgets('ModernHeroSection renders headline and floating cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithTheme(
          ModernHeroSection(
            items: [sampleContent],
            onGetStarted: () {},
            onExploreCatalog: () {},
            onContentTap: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Start Streaming Free'), findsOneWidget);
      expect(find.text('Browse Catalog'), findsOneWidget);
    });

    testWidgets('ModernFloatingGridSection renders category chips', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithTheme(
          ModernFloatingGridSection(
            items: [sampleContent],
            onCategoryChanged: (_) {},
            onContentTap: (_) {},
            onPlayTrailer: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('Web Series'), findsOneWidget);
      expect(find.text('Short Films'), findsOneWidget);
    });

    testWidgets('ModernGlassDeviceSection renders features', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithTheme(
          ModernGlassDeviceSection(onExplorePlans: () {}),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('4K Ultra HD & HDR10'), findsOneWidget);
      expect(find.text('Dolby Atmos Spatial Audio'), findsOneWidget);
    });
  });

  group('Design 3: Premium Motion Marketing Components Test', () {
    testWidgets('MarketingHeroSection renders headline and CTAs', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithTheme(
          MarketingHeroSection(
            onGetStarted: () {},
            onWatchTrailers: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Start Watching Free'), findsOneWidget);
      expect(find.text('Watch Free Trailers'), findsOneWidget);
    });

    testWidgets('MarketingStatsShowcase renders platform metrics', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithTheme(const MarketingStatsShowcase()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('100K+'), findsOneWidget);
      expect(find.text('4K HDR'), findsOneWidget);
    });

    testWidgets('WhyFilmytellSection renders 4 pillars', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithTheme(const WhyFilmytellSection()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Why Audiences Love Filmytell'), findsOneWidget);
      expect(find.text('Handpicked Regional & Indie Gems'), findsOneWidget);
    });

    testWidgets('MarketingAppEcosystemSection renders download QR and store links', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithTheme(const MarketingAppEcosystemSection()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Scan to Download App'), findsOneWidget);
      expect(find.text('Google Play'), findsOneWidget);
      expect(find.text('App Store'), findsOneWidget);
    });
  });
}
