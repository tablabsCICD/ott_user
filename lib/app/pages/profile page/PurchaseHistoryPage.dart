import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ott/app/provider/purchase_history_provider.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/data/models/response/purchase_history_response.dart';
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
                        const SizedBox(width: 10),
                        Expanded(
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

  Future<void> _pickDate(BuildContext context, PurchaseHistoryProvider provider,
      bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          isFromDate ? provider.selectedFromDate : provider.selectedToDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final pickedDate = DateUtils.dateOnly(picked);
      final fromDate = DateUtils.dateOnly(provider.selectedFromDate);
      final toDate = DateUtils.dateOnly(provider.selectedToDate);
      final isInvalidRange = isFromDate
          ? !pickedDate.isBefore(toDate)
          : !fromDate.isBefore(pickedDate);

      if (isInvalidRange) {
        if (!context.mounted) return;
        CustomToast.show(
          context,
          'Start date should be less than end date.',
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
                  OutlinedButton.icon(
                    onPressed: () => _viewInvoice(context, invoiceUrl),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('View Invoice'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _shareInvoice(context, invoiceUrl),
                    icon: Icon(Icons.share_outlined, color: theme.primaryColor),
                    label: Text(
                      'Share Invoice',
                      style: TextStyle(color: theme.primaryColor),
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
