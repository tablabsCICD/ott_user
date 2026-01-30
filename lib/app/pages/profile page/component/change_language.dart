import 'package:flutter/material.dart';
import 'package:ott/app/pages/NavigationPage.dart';
import 'package:ott/app/provider/language_provider.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ChangeLanguage extends StatefulWidget {
  const ChangeLanguage({super.key});

  @override
  State<ChangeLanguage> createState() => _ChangeLanguageState();
}

class _ChangeLanguageState extends State<ChangeLanguage> {
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    // ✅ Fetch once, safely
    Future.microtask(() {
      context.read<LanguageProvider>().fetchLanguages();
    });
  }

  void _toggleSelection(
    String language,
    LanguageProvider provider,
  ) {
    final updated = List<String>.from(provider.selectedLanguages);

    if (updated.contains(language)) {
      updated.remove(language);
    } else {
      updated.add(language);
    }

    provider.updateLanguages(updated);
  }

  Future<void> _saveLanguages(
    UserProvider userProvider,
    LanguageProvider languageProvider,
  ) async {
    if (languageProvider.selectedLanguages.isEmpty) {
      CustomToast.show(
        context,
        'Please select at least one language.',
        isSuccess: false,
      );
      return;
    }

    setState(() => _saving = true);

    final result =
        await userProvider.updateUserLang(languageProvider.selectedLanguages);

    setState(() => _saving = false);

    if (result['success'] == true) {
      CustomToast.show(
        context,
        "Language updated successfully.",
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
        result['message']?.toString() ?? "Update failed",
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final userProvider = context.read<UserProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: theme.canvasColor),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          lang.selectPreferredLanguage,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.canvasColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<LanguageProvider>(
          builder: (context, provider, _) {
            // 🔄 Loading
            if (provider.loading) {
              return Center(
                child: CircularProgressIndicator(
                  color: theme.primaryColor,
                ),
              );
            }

            // ❌ Error
            if (provider.error != null) {
              return Center(
                child: Text(
                  "Failed to load languages",
                  style: TextStyle(color: theme.canvasColor),
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    itemCount: provider.allLanguages.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          ResponsiveWidget.isMobile(context) ? 3 : 6,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 5 / 1.5,
                    ),
                    itemBuilder: (context, index) {
                      final language = provider.allLanguages[index];
                      final isSelected =
                          provider.selectedLanguages.contains(language);

                      return ElevatedButton(
                        onPressed: () => _toggleSelection(language, provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSelected ? theme.primaryColor : theme.cardColor,
                          foregroundColor:
                              isSelected ? Colors.white : theme.canvasColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          language,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: ResponsiveWidget.isMobile(context)
                      ? double.infinity
                      : 400,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving
                        ? null
                        : () => _saveLanguages(userProvider, provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            lang.save,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }
}
