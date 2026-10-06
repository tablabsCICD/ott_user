import 'package:flutter/material.dart';
import 'package:ott/presentation/web_landing/designs/common/animated_theme_toggle.dart';
import 'package:ott/presentation/web_landing/designs/design1_cinematic_ott/landing_page_design_1.dart';
import 'package:ott/presentation/web_landing/designs/design2_modern_streaming/landing_page_design_2.dart';
import 'package:ott/presentation/web_landing/designs/design3_motion_marketing/landing_page_design_3.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme_provider.dart';
import 'package:ott/presentation/web_landing/screens/web_landing_screen.dart';
import 'package:provider/provider.dart';

enum LandingDesignVariant {
  existing,
  design1Cinematic,
  design2Modern,
  design3Marketing,
}

/// Dedicated Interactive Landing Page Design Preview Screen.
/// Allows clients and stakeholders to toggle live between the existing production page
/// and the 3 new premium designs in both Light and Dark themes.
class LandingPageDesignPreview extends StatefulWidget {
  const LandingPageDesignPreview({
    super.key,
    this.initialVariant = LandingDesignVariant.design1Cinematic,
  });

  final LandingDesignVariant initialVariant;

  @override
  State<LandingPageDesignPreview> createState() =>
      _LandingPageDesignPreviewState();
}

class _LandingPageDesignPreviewState extends State<LandingPageDesignPreview> {
  late LandingDesignVariant _selectedVariant;
  late final LandingThemeProvider _themeProvider;
  bool _toolbarExpanded = true;

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.initialVariant;
    _themeProvider = LandingThemeProvider(initialMode: ThemeMode.dark);
  }

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LandingThemeProvider>.value(
      value: _themeProvider,
      child: Consumer<LandingThemeProvider>(
        builder: (context, themeProvider, _) {
          final isDark = themeProvider.isDarkMode;
          final brightness = isDark ? Brightness.dark : Brightness.light;

          return Theme(
            data: ThemeData(
              brightness: brightness,
              primaryColor: const Color(0xFFE50914),
              scaffoldBackgroundColor:
                  isDark ? const Color(0xFF08090D) : const Color(0xFFF8FAFC),
            ),
            child: Scaffold(
              body: Stack(
                children: [
                  // Active Landing Page Body
                  Positioned.fill(
                    child: _buildCurrentDesign(),
                  ),

                  // Floating Client Presentation Control Dock
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: _buildFloatingDock(context, themeProvider),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentDesign() {
    switch (_selectedVariant) {
      case LandingDesignVariant.existing:
        return const WebLandingScreen();
      case LandingDesignVariant.design1Cinematic:
        return const LandingPageDesign1();
      case LandingDesignVariant.design2Modern:
        return const LandingPageDesign2();
      case LandingDesignVariant.design3Marketing:
        return const LandingPageDesign3();
    }
  }

  Widget _buildFloatingDock(
    BuildContext context,
    LandingThemeProvider themeProvider,
  ) {
    final colors = LandingThemeColors.of(context);
    final isDark = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF141720).withOpacity(0.94)
            : Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: colors.primaryAccent.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isMobile && !_toolbarExpanded
          ? GestureDetector(
              onTap: () => setState(() => _toolbarExpanded = true),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.palette_rounded, color: colors.primaryAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Preview Switcher',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_up_rounded, color: colors.textPrimary, size: 18),
                ],
              ),
            )
          : Wrap(
              spacing: isMobile ? 6 : 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              children: [
                // Design Label Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primaryAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.layers_rounded, size: 14, color: colors.primaryAccent),
                      const SizedBox(width: 6),
                      Text(
                        'DESIGNS',
                        style: TextStyle(
                          color: colors.primaryAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),

                // Variant Selector Buttons
                _DockOptionBtn(
                  label: 'Existing',
                  isSelected: _selectedVariant == LandingDesignVariant.existing,
                  onTap: () => setState(() =>
                      _selectedVariant = LandingDesignVariant.existing),
                ),
                _DockOptionBtn(
                  label: 'Design 1 (Cinematic)',
                  isSelected: _selectedVariant ==
                      LandingDesignVariant.design1Cinematic,
                  onTap: () => setState(() =>
                      _selectedVariant = LandingDesignVariant.design1Cinematic),
                ),
                _DockOptionBtn(
                  label: 'Design 2 (Modern)',
                  isSelected:
                      _selectedVariant == LandingDesignVariant.design2Modern,
                  onTap: () => setState(() =>
                      _selectedVariant = LandingDesignVariant.design2Modern),
                ),
                _DockOptionBtn(
                  label: 'Design 3 (Marketing)',
                  isSelected:
                      _selectedVariant == LandingDesignVariant.design3Marketing,
                  onTap: () => setState(() =>
                      _selectedVariant = LandingDesignVariant.design3Marketing),
                ),

                // Divider
                Container(
                  height: 24,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: colors.border,
                ),

                // Theme Switcher in Dock
                const AnimatedThemeToggle(compact: true),

                if (isMobile)
                  GestureDetector(
                    onTap: () => setState(() => _toolbarExpanded = false),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _DockOptionBtn extends StatefulWidget {
  const _DockOptionBtn({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_DockOptionBtn> createState() => _DockOptionBtnState();
}

class _DockOptionBtnState extends State<_DockOptionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colors.primaryAccent
                : (_hovered
                    ? colors.primaryAccent.withOpacity(0.12)
                    : colors.surfaceElevated),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? colors.primaryAccent
                  : (_hovered ? colors.primaryAccent.withOpacity(0.4) : colors.border),
              width: 1.2,
            ),
            boxShadow: [
              if (widget.isSelected)
                BoxShadow(
                  color: colors.primaryAccent.withOpacity(0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isSelected
                  ? Colors.white
                  : (_hovered ? colors.textPrimary : colors.textSecondary),
              fontSize: 12,
              fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
