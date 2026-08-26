import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ott/app/provider/purchase_history_provider.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/show_toast.dart';
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
                        return ["All", "Movies", "Series", "Shorts"]
                            .map((item) {
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

    return Card(
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
