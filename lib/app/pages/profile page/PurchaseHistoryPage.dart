import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ott/app/provider/purchase_history_provider.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/widgets/filmytell_poster_image.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
import 'package:ott/data/models/response/purchase_history_response.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PurchaseHistoryPage extends StatefulWidget {
  const PurchaseHistoryPage({super.key});

  @override
  State<PurchaseHistoryPage> createState() => _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends State<PurchaseHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PurchaseHistoryProvider>().fetchPurchaseHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().getTheme;

    if (ResponsiveWidget.isAndroidTv(context)) return _buildTv(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        title: const Text(
          'Purchase History',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<PurchaseHistoryProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    /// 🔹 DROPDOWN
                    DropdownButtonFormField<String>(
                      initialValue: provider.selectedType,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      dropdownColor: Theme.of(context).cardColor,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      elevation: 6,
                      selectedItemBuilder: (context) {
                        return [
                          "All",
                          "Movies",
                          "Series",
                          "Shorts",
                          "Short Films"
                        ].map((item) {
                          return Text(
                            item == "Shorts" ? "Mini Series" : item,
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }).toList();
                      },
                      items: [
                        "All",
                        "Movies",
                        "Series",
                        "Shorts",
                        "Short Films"
                      ].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(
                            value == "Shorts" ? "Mini Series" : value,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                                fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        provider.setSelectedType(value);
                      },
                    ),
                    const SizedBox(height: 12),

                    /// 🔹 DATE RANGE
                    Row(
                      children: [
                        Expanded(
                          child: OttTvFocus(
                            borderRadius: 10,
                            onTap: () => _pickDate(context, provider, true),
                            child: OutlinedButton.icon(
                              onPressed: () => _pickDate(context, provider, true),
                              icon: Icon(
                                Icons.date_range,
                                color:
                                    Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                              label: Text(
                                DateFormat('dd MMM yyyy')
                                    .format(provider.selectedFromDate),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                side: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10), // ✅ as required
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OttTvFocus(
                            borderRadius: 10,
                            onTap: () => _pickDate(context, provider, false),
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _pickDate(context, provider, false),
                              icon: Icon(
                                Icons.date_range,
                                color:
                                    Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                              label: Text(
                                DateFormat('dd MMM yyyy')
                                    .format(provider.selectedToDate),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                side: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              if (provider.isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.error != null && provider.items.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        provider.error!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else if (provider.items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No purchase history found for selected date.'),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: provider.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = provider.items[index];
                      return _PurchaseHistoryCard(item: item);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ---------------- Android TV ----------------

  static const List<String> _tvTypeFilters = [
    "All",
    "Movies",
    "Series",
    "Shorts",
    "Short Films",
  ];

  /// Android TV: page title, filter chips (same values as the dropdown) and
  /// the From / To date buttons on one row, then a 2-column grid of compact
  /// ticket cards. Filters call the same provider methods and [_pickDate].
  Widget _buildTv(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<PurchaseHistoryProvider>(
          builder: (context, provider, _) {
            final muted = theme.canvasColor.withValues(alpha: 0.62);
            Widget message(String text) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                  ),
                );

            final Widget body;
            if (provider.isLoading) {
              body = const Center(child: CircularProgressIndicator());
            } else if (provider.error != null && provider.items.isEmpty) {
              body = message(provider.error!);
            } else if (provider.items.isEmpty) {
              body = message('No purchase history found for selected date.');
            } else {
              body = GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  TvDesign.pageGutter,
                  4,
                  TvDesign.pageGutter,
                  TvDesign.pageGutter,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 96,
                ),
                itemCount: provider.items.length,
                itemBuilder: (context, index) =>
                    _PurchaseHistoryCard(item: provider.items[index]),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TvDesign.pageGutter,
                    16,
                    TvDesign.pageGutter,
                    12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Purchase History', style: TvDesign.pageTitle(theme)),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(
                          children: [
                            for (final type in _tvTypeFilters) ...[
                              _tvFilterChip(
                                theme,
                                label:
                                    type == "Shorts" ? "Mini Series" : type,
                                selected: provider.selectedType == type,
                                autofocus: provider.selectedType == type,
                                onTap: () => provider.setSelectedType(type),
                              ),
                              const SizedBox(width: 6),
                            ],
                            const SizedBox(width: 10),
                            _tvDateButton(
                              theme,
                              label: 'From',
                              date: provider.selectedFromDate,
                              onTap: () => _pickDate(context, provider, true),
                            ),
                            const SizedBox(width: 6),
                            _tvDateButton(
                              theme,
                              label: 'To',
                              date: provider.selectedToDate,
                              onTap: () => _pickDate(context, provider, false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: body),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tvFilterChip(
    ThemeData theme, {
    required String label,
    required bool selected,
    required bool autofocus,
    required VoidCallback onTap,
  }) {
    return OttTvFocus(
      autofocus: autofocus,
      borderRadius: 16,
      scale: 1.04,
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.primaryColor
                : theme.canvasColor.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : theme.canvasColor,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _tvDateButton(
    ThemeData theme, {
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return OttTvFocus(
      borderRadius: 8,
      scale: 1.04,
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range, size: 14, color: theme.canvasColor),
            const SizedBox(width: 6),
            Text(
              '$label  ',
              style: TvDesign.caption(theme),
            ),
            Text(
              DateFormat('dd MMM yyyy').format(date),
              style: TextStyle(
                color: theme.canvasColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _showTvDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required String title,
  }) {
    DateTime tempDate = initialDate;
    if (tempDate.isBefore(firstDate)) tempDate = firstDate;
    if (tempDate.isAfter(lastDate)) tempDate = lastDate;

    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updateDate(int year, int month, int day) {
              final maxDays = DateUtils.getDaysInMonth(year, month);
              final validDay = day.clamp(1, maxDays);
              var newDate = DateTime(year, month, validDay);
              if (newDate.isBefore(firstDate)) newDate = firstDate;
              if (newDate.isAfter(lastDate)) newDate = lastDate;
              setDialogState(() {
                tempDate = newDate;
              });
            }

            return Dialog(
              backgroundColor: theme.scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.canvasColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        DateFormat('EEEE, dd MMMM yyyy').format(tempDate),
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDateSpinner(
                          label: 'Day',
                          value: tempDate.day.toString().padLeft(2, '0'),
                          onDecrement: () => updateDate(
                              tempDate.year, tempDate.month, tempDate.day - 1),
                          onIncrement: () => updateDate(
                              tempDate.year, tempDate.month, tempDate.day + 1),
                          theme: theme,
                        ),
                        _buildDateSpinner(
                          label: 'Month',
                          value: DateFormat('MMM').format(tempDate),
                          onDecrement: () => updateDate(
                              tempDate.year, tempDate.month - 1, tempDate.day),
                          onIncrement: () => updateDate(
                              tempDate.year, tempDate.month + 1, tempDate.day),
                          theme: theme,
                        ),
                        _buildDateSpinner(
                          label: 'Year',
                          value: tempDate.year.toString(),
                          onDecrement: () => updateDate(
                              tempDate.year - 1, tempDate.month, tempDate.day),
                          onIncrement: () => updateDate(
                              tempDate.year + 1, tempDate.month, tempDate.day),
                          theme: theme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OttTvFocus(
                            borderRadius: 10,
                            onTap: () => Navigator.of(dialogContext).pop(null),
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(null),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: theme.canvasColor),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: OttTvFocus(
                            autofocus: true,
                            borderRadius: 10,
                            onTap: () =>
                                Navigator.of(dialogContext).pop(tempDate),
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(tempDate),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'OK',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateSpinner({
    required String label,
    required String value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.canvasColor.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        OttTvFocus(
          borderRadius: 8,
          onTap: onIncrement,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.keyboard_arrow_up,
                color: theme.canvasColor, size: 24),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.primaryColor.withOpacity(0.4)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: theme.canvasColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        OttTvFocus(
          borderRadius: 8,
          onTap: onDecrement,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.keyboard_arrow_down,
                color: theme.canvasColor, size: 24),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, PurchaseHistoryProvider provider,
      bool isFromDate) async {
    final initialDate =
        isFromDate ? provider.selectedFromDate : provider.selectedToDate;
    final firstDate = DateTime(2020);
    final lastDate = DateTime.now();

    final DateTime? picked;
    if (ResponsiveWidget.isTv(context)) {
      picked = await _showTvDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        title: isFromDate ? 'Select From Date' : 'Select To Date',
      );
    } else {
      picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }

    if (picked != null) {
      final pickedDate = DateUtils.dateOnly(picked);
      final fromDate = DateUtils.dateOnly(provider.selectedFromDate);
      final toDate = DateUtils.dateOnly(provider.selectedToDate);
      final isInvalidRange = isFromDate
          ? !pickedDate.isBefore(toDate) && !pickedDate.isAtSameMomentAs(toDate)
          : !fromDate.isBefore(pickedDate) &&
              !fromDate.isAtSameMomentAs(pickedDate);

      if (isInvalidRange) {
        if (!context.mounted) return;
        CustomToast.show(
          context,
          'Start date should be less than or equal to end date.',
          isSuccess: false,
        );
        return;
      }

      await provider.setDate(picked, isFromDate);
    }
  }
}

class _PurchaseHistoryCard extends StatelessWidget {
  const _PurchaseHistoryCard({required this.item});

  final PurchaseHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().getTheme;
    final content = item.content;
    final purchaseDate = item.purchaseDate;
    final invoiceUrl = item.invoiceUrl?.trim() ?? '';
    final hasInvoiceUrl = invoiceUrl.isNotEmpty;

    if (ResponsiveWidget.isAndroidTv(context)) {
      return _buildTv(context, invoiceUrl, hasInvoiceUrl);
    }

    final card = Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content?.title ?? item.itemTitle ?? 'Purchased Content',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Type: ${item.contentType ?? content?.type ?? 'N/A'}'),
            Text(
              'Date: ${purchaseDate != null ? DateFormat('dd MMM yyyy, hh:mm a').format(purchaseDate) : 'N/A'}',
            ),
            Text(
                'Amount: Rs ${(item.amount ?? content?.price ?? 0).toStringAsFixed(2)}'),
            Text('Invoice: ${item.invoiceNumber ?? item.invoiceId ?? 'N/A'}'),
            if ((item.rentalDuration ?? '').trim().isNotEmpty)
              Text('Duration: ${item.rentalDuration}'),
            const SizedBox(height: 12),
            if (hasInvoiceUrl)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OttTvFocus(
                    borderRadius: 8,
                    onTap: () => _viewInvoice(context, invoiceUrl),
                    child: OutlinedButton.icon(
                      onPressed: () => _viewInvoice(context, invoiceUrl),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('View Invoice'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OttTvFocus(
                    borderRadius: 8,
                    onTap: () => _shareInvoice(context, invoiceUrl),
                    child: ElevatedButton.icon(
                      onPressed: () => _shareInvoice(context, invoiceUrl),
                      icon:
                          Icon(Icons.share_outlined, color: theme.primaryColor),
                      label: Text(
                        'Share Invoice',
                        style: TextStyle(color: theme.primaryColor),
                      ),
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Invoice URL not available',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return card;
  }

  /// Android TV ticket card: 16:9 thumbnail, title, type / date, rent
  /// duration, invoice number and amount. The card is one focus stop; OK
  /// opens the invoice, Down selects View / Share (via [OttTvActionsCard]).
  /// Uses the same [_viewInvoice] / [_shareInvoice] handlers as mobile.
  Widget _buildTv(
    BuildContext context,
    String invoiceUrl,
    bool hasInvoiceUrl,
  ) {
    final theme = Theme.of(context);
    final content = item.content;
    final purchaseDate = item.purchaseDate;
    final posterUrl = content?.posterUrlList?.isNotEmpty == true
        ? content!.posterUrlList!.first
        : null;
    final rentalDuration = (item.rentalDuration ?? '').trim();
    final muted = theme.canvasColor.withValues(alpha: 0.62);
    final actions = <VoidCallback>[
      if (hasInvoiceUrl) () => _viewInvoice(context, invoiceUrl),
      if (hasInvoiceUrl) () => _shareInvoice(context, invoiceUrl),
    ];

    Widget actionPill(
      String label,
      IconData icon, {
      required bool selected,
    }) {
      return OttTvActionHighlight(
        selected: selected,
        borderRadius: 6,
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: theme.canvasColor.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: theme.canvasColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: theme.canvasColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return OttTvActionsCard(
      onTap: hasInvoiceUrl ? () => _viewInvoice(context, invoiceUrl) : null,
      actions: actions,
      borderRadius: TvDesign.cardRadius,
      scale: 1.0,
      semanticLabel: content?.title ?? item.itemTitle ?? 'Purchased Content',
      builder: (context, selectedAction) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(TvDesign.cardRadius),
          border: Border.all(color: theme.canvasColor.withValues(alpha: 0.06)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: TvDesign.imageAspectRatio,
              child: FilmytellPosterImage(
                posterUrl: posterUrl,
                fit: BoxFit.cover,
                fallbackIcon: Icons.confirmation_number_outlined,
                fallbackIconSize: 26,
                backgroundColor: theme.scaffoldBackgroundColor,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            content?.title ??
                                item.itemTitle ??
                                'Purchased Content',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.canvasColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rs ${(item.amount ?? content?.price ?? 0).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: theme.canvasColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.contentType ?? content?.type ?? 'N/A'}  ·  ${purchaseDate != null ? DateFormat('dd MMM yyyy, hh:mm a').format(purchaseDate) : 'N/A'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TvDesign.caption(theme),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (rentalDuration.isNotEmpty)
                          'Duration: $rentalDuration',
                        'Invoice: ${item.invoiceNumber ?? item.invoiceId ?? 'N/A'}',
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TvDesign.caption(theme),
                    ),
                    const SizedBox(height: 6),
                    if (hasInvoiceUrl)
                      Row(
                        children: [
                          actionPill(
                            'View Invoice',
                            Icons.picture_as_pdf_outlined,
                            selected: selectedAction == 0,
                          ),
                          const SizedBox(width: 6),
                          actionPill(
                            'Share Invoice',
                            Icons.share_outlined,
                            selected: selectedAction == 1,
                          ),
                        ],
                      )
                    else
                      Text(
                        'Invoice URL not available',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: muted, fontSize: 10.5),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewInvoice(BuildContext context, String invoiceUrl) async {
    try {
      final uri = Uri.tryParse(invoiceUrl);
      if (uri == null) {
        CustomToast.show(context, 'Invalid invoice URL.', isSuccess: false);
        return;
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        CustomToast.show(
          context,
          'Unable to open invoice right now.',
          isSuccess: false,
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      CustomToast.show(
        context,
        'Unable to open invoice right now.',
        isSuccess: false,
      );
    }
  }

  Future<void> _shareInvoice(BuildContext context, String invoiceUrl) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Purchase Invoice',
          subject: 'Purchase Invoice',
          text:
              'Here is your invoice for ${item.content?.title ?? item.itemTitle ?? 'Content'}.\n$invoiceUrl',
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      CustomToast.show(
        context,
        'Unable to share invoice right now.',
        isSuccess: false,
      );
    }
  }
}
