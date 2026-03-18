import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ott/app/pages/NavigationPage.dart';
import 'package:ott/app/provider/language_provider.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/app/widgets/show_toast.dart';
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

            return InkWell(
              onTap: () => provider.toggleLanguage(lang.name),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
}
