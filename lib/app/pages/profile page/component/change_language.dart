import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ott/app/pages/NavigationPage.dart';
import 'package:ott/app/pages/profile%20page/component/profile_detail_shell.dart';
import 'package:ott/app/provider/language_provider.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';

class ChangeLanguage extends StatefulWidget {
  const ChangeLanguage({super.key});

  @override
  State<ChangeLanguage> createState() => _ChangeLanguageState();
}

class _ChangeLanguageState extends State<ChangeLanguage> {
  bool _saving = false;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final languageProvider = context.read<LanguageProvider>();
      final userProvider = context.read<UserProvider>();

      // 1️⃣ NEW grouped API
      await languageProvider.fetchGroupedLanguages();

      // 2️⃣ KEEP OLD FLOW (IMPORTANT)
      final userSelected = userProvider.userObject.selectedLanguages ?? [];

      if (userSelected.isNotEmpty) {
        languageProvider.updateLanguages(
          List<String>.from(userSelected),
        );
      }
    });
  }

  Future<void> _saveLanguages(
    UserProvider userProvider,
    LanguageProvider provider,
  ) async {
    if (provider.selectedLanguages.isEmpty) {
      CustomToast.show(
        context,
        'Please select at least one language.',
        isSuccess: false,
      );
      return;
    }

    setState(() => _saving = true);

    log("=====+====+==== selected languages ${provider.selectedLanguages}");
    final result =
        await userProvider.updateUserLang(provider.selectedLanguages);

    setState(() => _saving = false);

    if (result['success'] == true) {
      CustomToast.show(
        context,
        'Language updated successfully.',
        isSuccess: true,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => NavigationPage()),
        (_) => false,
      );
    } else {
      CustomToast.show(
        context,
        "${result['message'] ?? 'Update failed'}",
        isSuccess: false,
      );
    }
  }

  Widget _buildSection(
    String title,
    List items,
    LanguageProvider provider,
    ThemeData theme,
  ) {
    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveWidget.isMobile(context)
                ? 2
                : ResponsiveWidget.isTablet(context)
                    ? 4
                    : 5,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            childAspectRatio: 2.5,
          ),
          itemBuilder: (context, index) {
            final lang = items[index];
            final isSelected = provider.selectedLanguages.contains(lang.name);

            return OttTvFocus(
              onTap: () => provider.toggleLanguage(lang.name),
              borderRadius: 12,
              semanticLabel: '${lang.name} language',
              child: Card(
                color: isSelected ? theme.primaryColor : theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      lang.native ?? lang.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : theme.canvasColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lang.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white70
                            : theme.canvasColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLanguageTab(
    String title,
    int index,
    ThemeData theme,
  ) {
    final isSelected = _selectedTabIndex == index;

    return Expanded(
      child: OttTvFocus(
        borderRadius: 12,
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor : theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.primaryColor
                  : theme.canvasColor.withOpacity(0.2),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : theme.canvasColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final userProvider = context.read<UserProvider>();

    // Android TV: compact header with the Save action, tabs and a dense
    // language grid sized for the 540 px canvas.
    if (ResponsiveWidget.isAndroidTv(context)) {
      return _buildTv(theme, lang, userProvider);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Preferred Languages",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Consumer<LanguageProvider>(
          builder: (context, provider, _) {
            if (provider.loading) {
              return Center(
                  child: CircularProgressIndicator(
                color: theme.primaryColor,
              ));
            }

            if (provider.error != null) {
              return Center(
                child: Text(
                  'Failed to load languages',
                  style: TextStyle(
                    color: theme.canvasColor,
                  ),
                ),
              );
            }

            final languageSections = [
              {
                'title': 'Major Indian Languages',
                'items': provider.majorIndianLanguages,
              },
              {
                'title': 'Other Indian Languages',
                'items': provider.otherIndianLanguages,
              },
              {
                'title': 'Foreign Languages',
                'items': provider.foreignLanguages,
              },
            ];
            final currentSection = languageSections[_selectedTabIndex];

            return Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildLanguageTab(
                            'Major Indian Languages',
                            0,
                            theme,
                          ),
                          _buildLanguageTab(
                            'Other Indian Languages',
                            1,
                            theme,
                          ),
                          _buildLanguageTab(
                            'Foreign Languages',
                            2,
                            theme,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      _buildSection(
                        currentSection['title'] as String,
                        currentSection['items'] as List,
                        provider,
                        theme,
                      ),
                      const SizedBox(
                        height: 80,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: ResponsiveWidget.isMobile(context)
                      ? 90
                      : ResponsiveWidget.isTablet(context)
                          ? 200
                          : 300,
                  right: ResponsiveWidget.isMobile(context)
                      ? 90
                      : ResponsiveWidget.isTablet(context)
                          ? 200
                          : 300,
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saving
                          ? null
                          : () => _saveLanguages(
                                userProvider,
                                provider,
                              ),
                      child: _saving
                          ? CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.primaryColor,
                            )
                          : Text(
                              lang.save,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // ANDROID TV
  // ===========================================================================

  static const List<String> _tabTitles = [
    'Major Indian Languages',
    'Other Indian Languages',
    'Foreign Languages',
  ];

  Widget _buildTv(
    ThemeData theme,
    AppLocalizations lang,
    UserProvider userProvider,
  ) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<LanguageProvider>(
        builder: (context, provider, _) {
          final selectedCount = provider.selectedLanguages.length;
          final ready = !provider.loading && provider.error == null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TvDetailHeader(
                title: "Preferred Languages",
                subtitle: ready && selectedCount > 0
                    ? '$selectedCount selected'
                    : null,
                trailing: [
                  if (ready)
                    TvCompactButton(
                      label: lang.save,
                      icon: Icons.check_rounded,
                      loading: _saving,
                      onPressed: () => _saveLanguages(userProvider, provider),
                    ),
                ],
              ),
              Expanded(child: _buildTvBody(theme, provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTvBody(ThemeData theme, LanguageProvider provider) {
    if (provider.loading) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: theme.primaryColor,
          ),
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Text(
          'Failed to load languages',
          style: TextStyle(color: theme.canvasColor, fontSize: 13),
        ),
      );
    }

    final sections = [
      provider.majorIndianLanguages,
      provider.otherIndianLanguages,
      provider.foreignLanguages,
    ];
    final items = sections[_selectedTabIndex] as List;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TvDesign.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < _tabTitles.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _buildTvTab(_tabTitles[i], i, theme),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? const SizedBox()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(2, 4, 2, 20),
                    itemCount: items.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 150,
                      mainAxisExtent: 52,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) =>
                        _buildTvLanguageTile(items[index], provider, theme),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTvTab(String title, int index, ThemeData theme) {
    final isSelected = _selectedTabIndex == index;

    return OttTvFocus(
      autofocus: index == _selectedTabIndex,
      borderRadius: 16,
      scale: 1.04,
      semanticLabel: title,
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : theme.canvasColor.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.canvasColor,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTvLanguageTile(
    dynamic language,
    LanguageProvider provider,
    ThemeData theme,
  ) {
    final isSelected = provider.selectedLanguages.contains(language.name);
    final String name = language.name;
    final String native = language.native ?? language.name;

    return OttTvFocus(
      onTap: () => provider.toggleLanguage(language.name),
      borderRadius: TvDesign.cardRadius,
      scale: 1.05,
      semanticLabel: '$name language',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.circular(TvDesign.cardRadius),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : theme.canvasColor.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    native,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : theme.canvasColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isSelected
                          ? Colors.white70
                          : theme.canvasColor.withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }
}
