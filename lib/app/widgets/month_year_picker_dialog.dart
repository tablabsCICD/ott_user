import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/l10n/app_localizations.dart';

const List<String> kBirthMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Localized display label for an English month name from [kBirthMonths].
/// The English value itself is kept as the stored/returned data.
String localizedBirthMonth(AppLocalizations lang, String month) {
  switch (kBirthMonths.indexOf(month)) {
    case 0:
      return lang.pickerJanuary;
    case 1:
      return lang.pickerFebruary;
    case 2:
      return lang.pickerMarch;
    case 3:
      return lang.pickerApril;
    case 4:
      return lang.pickerMay;
    case 5:
      return lang.pickerJune;
    case 6:
      return lang.pickerJuly;
    case 7:
      return lang.pickerAugust;
    case 8:
      return lang.pickerSeptember;
    case 9:
      return lang.pickerOctober;
    case 10:
      return lang.pickerNovember;
    case 11:
      return lang.pickerDecember;
    default:
      return month;
  }
}

List<int> getBirthYears() {
  final currentYear = DateTime.now().year;
  return List.generate(
    currentYear - 1900 + 1,
    (index) => currentYear - index,
  );
}

Map<String, dynamic> parseBirthMonthAndYear(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return {'month': null, 'year': null};
  }
  final text = raw.trim();

  // Pattern 1: "October 1992"
  final parts = text.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    final m = kBirthMonths.firstWhere(
      (m) => m.toLowerCase() == parts[0].toLowerCase(),
      orElse: () => '',
    );
    final y = int.tryParse(parts[1]);
    if (m.isNotEmpty && y != null) {
      return {'month': m, 'year': y};
    }
  }

  // Pattern 2: "1992-10-15" or "1992-10"
  final parsed = DateTime.tryParse(text);
  if (parsed != null && parsed.month >= 1 && parsed.month <= 12) {
    return {
      'month': kBirthMonths[parsed.month - 1],
      'year': parsed.year,
    };
  }

  return {'month': null, 'year': null};
}

Future<Map<String, dynamic>?> showBirthMonthYearPicker({
  required BuildContext context,
  String? currentValue,
}) async {
  final parsed = parseBirthMonthAndYear(currentValue);
  String? selectedMonth = parsed['month'];
  int? selectedYear = parsed['year'];

  final currentYear = DateTime.now().year;
  final currentMonth = DateTime.now().month;
  final years = getBirthYears();
  final themeData = Provider.of<ThemeProvider>(context, listen: false).getTheme;

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final lang = AppLocalizations.of(dialogCtx)!;
          String? errorMessage;
          if (selectedYear == currentYear && selectedMonth != null) {
            final monthIndex = kBirthMonths.indexOf(selectedMonth!) + 1;
            if (monthIndex > currentMonth) {
              errorMessage = lang.pickerBirthMonthInFuture;
            }
          }

          return AlertDialog(
            backgroundColor: themeData.scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: themeData.primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  lang.pickerSelectBirthMonthYear,
                  style: TextStyle(
                    color: themeData.canvasColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      // Month Dropdown
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: selectedMonth,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: lang.homeMonth,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          dropdownColor: themeData.scaffoldBackgroundColor,
                          items: kBirthMonths
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    localizedBirthMonth(lang, m),
                                    style: TextStyle(
                                      color: themeData.canvasColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedMonth = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Year Dropdown
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: selectedYear,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: lang.homeYear,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          dropdownColor: themeData.scaffoldBackgroundColor,
                          items: years
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text(
                                    '$y',
                                    style: TextStyle(
                                      color: themeData.canvasColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedYear = val;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (selectedMonth != null && selectedYear != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: themeData.cardColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: themeData.primaryColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        lang.pickerSelectedMonthYear(
                          localizedBirthMonth(lang, selectedMonth!),
                          '$selectedYear',
                        ),
                        style: TextStyle(
                          color: themeData.canvasColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(null),
                child: Text(
                  lang.cancel,
                  style: TextStyle(color: themeData.canvasColor),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: (selectedMonth == null ||
                        selectedYear == null ||
                        errorMessage != null)
                    ? null
                    : () {
                        Navigator.of(dialogCtx).pop({
                          'month': selectedMonth,
                          'year': selectedYear,
                        });
                      },
                child: Text(
                  lang.done,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
