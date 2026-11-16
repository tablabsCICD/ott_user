import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
import 'package:ott/data/models/response/push_notification_response.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationDetailPage extends StatelessWidget {
  const NotificationDetailPage({
    super.key,
    required this.notification,
  });

  final PushNotificationItem notification;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: true).getTheme;
    final hasAttachments = notification.attachments.isNotEmpty;

    if (ResponsiveWidget.isAndroidTv(context)) {
      return _buildAndroidTv(context, theme, hasAttachments);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: !(kIsWeb || ResponsiveWidget.isTv(context)),
        forceMaterialTransparency: true,
        foregroundColor: theme.canvasColor,
        title: const Text(
          'Notification',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      // Android TV: Up/Down scroll the message, then move on to attachments.
      body: OttTvKeyScroll(
        child: ListView(
        primary: ResponsiveWidget.isAndroidTv(context) ? true : null,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _header(context, theme),
          const SizedBox(height: 16),
          _messageCard(theme),
          const SizedBox(height: 16),
          _detailsSection(theme),
          if (hasAttachments) ...[
            const SizedBox(height: 18),
            _attachmentsSection(context, theme),
          ],
        ],
      ),
      ),
    );
  }

  /// Android TV: full-screen reading view. The text sits in a centred column
  /// at most 640 px wide; Up/Down scroll it (OttTvKeyScroll) and then move on
  /// to the attachments, which open with OK exactly like the other layouts.
  Widget _buildAndroidTv(
    BuildContext context,
    ThemeData theme,
    bool hasAttachments,
  ) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const maxTextWidth = 640.0;
            final side = constraints.maxWidth > maxTextWidth + 40
                ? (constraints.maxWidth - maxTextWidth) / 2
                : TvDesign.pageGutter;
            return OttTvKeyScroll(
              child: ListView(
                primary: true,
                padding: EdgeInsets.fromLTRB(side, 18, side, 28),
                children: [
                  Text(
                    'Notification',
                    style: TvDesign.caption(theme).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _header(context, theme, tv: true),
                  const SizedBox(height: 14),
                  _messageCard(theme, tv: true),
                  const SizedBox(height: 14),
                  _detailsSection(theme, tv: true),
                  if (hasAttachments) ...[
                    const SizedBox(height: 14),
                    _attachmentsSection(context, theme, tv: true),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  BoxDecoration _tvPanel(ThemeData theme) => BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(TvDesign.panelRadius),
        border: Border.all(color: theme.canvasColor.withValues(alpha: 0.06)),
      );

  Widget _header(BuildContext context, ThemeData theme, {bool tv = false}) {
    final status = notification.deliveryStatus ?? 'UNKNOWN';
    final priority = notification.priority ?? 'NORMAL';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tv ? 14 : 16),
      decoration: tv
          ? _tvPanel(theme)
          : BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.primaryColor.withOpacity(0.18)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: tv ? 34 : 44,
                width: tv ? 34 : 44,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(status),
                  color: theme.primaryColor,
                  size: tv ? 18 : 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: theme.canvasColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    if (_clean(notification.displayDate) != null) ...[
                      SizedBox(height: tv ? 6 : 8),
                      Row(
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: tv ? 13 : 15,
                            color: theme.canvasColor.withOpacity(0.62),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              notification.displayDate!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.canvasColor.withOpacity(0.68),
                                fontSize: tv ? 10.5 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _messageCard(ThemeData theme, {bool tv = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          theme,
          'Message',
          Icons.chat_bubble_outline_rounded,
          tv: tv,
        ),
        SizedBox(height: tv ? 8 : 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: tv
              ? _tvPanel(theme)
              : BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
          child: Text(
            notification.body,
            style: TextStyle(
              color: theme.canvasColor.withOpacity(0.86),
              fontSize: tv ? 13 : 15,
              height: tv ? 1.55 : 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailsSection(ThemeData theme, {bool tv = false}) {
    final rows = <_InfoItem>[
      _InfoItem('Subject', notification.emailSubject, Icons.subject_outlined),
      _InfoItem('Sent By', notification.sentBy, Icons.person_outline),
      _InfoItem('Sent Date', notification.sentDateTime, Icons.send_outlined),
    ].where((item) => _clean(item.value?.toString()) != null).toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, 'Details', Icons.info_outline_rounded, tv: tv),
        SizedBox(height: tv ? 8 : 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: tv
              ? _tvPanel(theme)
              : BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                _infoRow(theme, rows[i], tv: tv),
                if (i != rows.length - 1)
                  Divider(
                    height: 1,
                    color: theme.canvasColor.withOpacity(0.08),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _attachmentsSection(
    BuildContext context,
    ThemeData theme, {
    bool tv = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          theme,
          'Attachments',
          Icons.attach_file_rounded,
          count: notification.attachments.length,
          tv: tv,
        ),
        SizedBox(height: tv ? 8 : 10),
        ...notification.attachments.map(
          (attachment) => Padding(
            padding: EdgeInsets.only(bottom: tv ? 8 : 10),
            child: _attachmentTile(context, theme, attachment, tv: tv),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(
    ThemeData theme,
    String title,
    IconData icon, {
    int? count,
    bool tv = false,
  }) {
    final label = count == null ? title : '$title ($count)';
    return Row(
      children: [
        Icon(icon, color: theme.primaryColor, size: tv ? 15 : 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: tv
              ? TvDesign.sectionTitle(theme)
              : TextStyle(
                  color: theme.canvasColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
        ),
      ],
    );
  }

  Widget _chip(ThemeData theme, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.canvasColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, _InfoItem item, {bool tv = false}) {
    final value = item.value?.toString().trim() ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tv ? 8 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: tv ? 26 : 30,
            width: tv ? 26 : 30,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon,
                color: theme.primaryColor, size: tv ? 14 : 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    color: theme.canvasColor.withOpacity(0.58),
                    fontSize: tv ? 10.5 : 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: theme.canvasColor,
                    fontSize: tv ? 12.5 : 14,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachmentTile(
    BuildContext context,
    ThemeData theme,
    PushNotificationAttachment attachment, {
    bool tv = false,
  }) {
    final fileName = _clean(attachment.fileName) ?? 'Attachment';
    final double thumb = tv ? 40 : 54;
    final fileUrl = _clean(attachment.fileUrl);
    final fileType = _clean(attachment.fileType);
    final fileSize = _formatFileSize(attachment.fileSize);
    final image = _isImageAttachment(attachment) && fileUrl != null;

    return OttTvFocus(
      borderRadius: tv ? TvDesign.cardRadius : 8,
      scale: tv ? 1.02 : 1.04,
      semanticLabel: 'Open $fileName',
      onTap: () => _openAttachment(context, fileUrl),
      child: Container(
        padding: EdgeInsets.all(tv ? 8 : 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(tv ? TvDesign.cardRadius : 8),
          border: Border.all(
            color: theme.canvasColor.withOpacity(tv ? 0.06 : 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: thumb,
              width: thumb,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: image
                  ? Image.network(
                      fileUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _attachmentIconBox(
                        theme,
                        attachment,
                      ),
                    )
                  : _attachmentIconBox(theme, attachment),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.canvasColor,
                      fontWeight: FontWeight.w800,
                      fontSize: tv ? 13 : 14,
                    ),
                  ),
                  SizedBox(height: tv ? 3 : 5),
                  Text(
                    [
                      if (fileType != null) fileType,
                      if (fileSize != null) fileSize,
                    ].join(' - '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.canvasColor.withOpacity(0.58),
                      fontSize: tv ? 10.5 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (fileUrl != null) ...[
                    SizedBox(height: tv ? 2 : 3),
                    Text(
                      Uri.tryParse(fileUrl)?.host ?? fileUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: tv ? 10.5 : 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.open_in_new_rounded,
              color: theme.canvasColor.withOpacity(0.62),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentIconBox(
    ThemeData theme,
    PushNotificationAttachment attachment,
  ) {
    return Center(
      child: Icon(
        _attachmentIcon(attachment),
        color: theme.primaryColor,
        size: 24,
      ),
    );
  }

  IconData _statusIcon(String status) {
    final normalized = status.toUpperCase();
    if (normalized.contains('SUCCESS') || normalized.contains('SENT')) {
      return Icons.check_circle_outline_rounded;
    }
    if (normalized.contains('FAIL')) return Icons.error_outline_rounded;
    if (normalized.contains('PENDING')) return Icons.schedule_rounded;
    return Icons.notifications_none_rounded;
  }

  IconData _attachmentIcon(PushNotificationAttachment attachment) {
    final type = attachment.fileType?.toLowerCase() ?? '';
    final name = attachment.fileName?.toLowerCase() ?? '';
    if (_isImageAttachment(attachment)) return Icons.image_outlined;
    if (type.contains('pdf') || name.endsWith('.pdf')) {
      return Icons.picture_as_pdf_outlined;
    }
    if (type.contains('video')) return Icons.movie_creation_outlined;
    if (type.contains('audio')) return Icons.audio_file_outlined;
    return Icons.insert_drive_file_outlined;
  }

  bool _isImageAttachment(PushNotificationAttachment attachment) {
    final type = attachment.fileType?.toLowerCase() ?? '';
    final name = attachment.fileName?.toLowerCase() ?? '';
    return type.contains('image') ||
        name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.webp');
  }

  String? _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return null;
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
  }

  String? _clean(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  Future<void> _openAttachment(BuildContext context, String? url) async {
    final text = url?.trim();
    if (text == null || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment URL is not available.')),
      );
      return;
    }

    final uri = Uri.tryParse(text);
    final opened = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open attachment.')),
      );
    }
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value, this.icon);

  final String label;
  final Object? value;
  final IconData icon;
}
