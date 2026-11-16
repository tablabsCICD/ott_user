import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class NewsScreenArgs {
  const NewsScreenArgs({
    required this.title,
    required this.body,
    required this.payload,
  });

  final String title;
  final String body;
  final Map<String, dynamic> payload;

  factory NewsScreenArgs.fromMap(Map<String, dynamic> map) {
    final rawPayload = map['payload'];

    return NewsScreenArgs(
      title: map['title']?.toString() ?? 'News',
      body: map['body']?.toString() ?? 'No message body',
      payload: rawPayload is Map<String, dynamic>
          ? rawPayload
          : rawPayload is Map
              ? rawPayload.cast<String, dynamic>()
              : <String, dynamic>{},
    );
  }
}

class NewsScreen extends StatelessWidget {
  const NewsScreen({
    super.key,
    required this.args,
  });

  final NewsScreenArgs args;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveWidget.isAndroidTv(context)) return _buildAndroidTv(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !(kIsWeb || ResponsiveWidget.isTv(context)),
        title: const Text('News'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              args.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              args.body,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Payload',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              // Android TV: Up/Down scroll the payload with the remote.
              child: OttTvKeyScroll(
                child: SingleChildScrollView(
                  primary: ResponsiveWidget.isAndroidTv(context) ? true : null,
                  child: Text(args.payload.toString()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Android TV: full-screen reading view in a centred column at most 640 px
  /// wide; Up/Down scroll the whole page with the remote (OttTvKeyScroll).
  Widget _buildAndroidTv(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.canvasColor.withValues(alpha: 0.8);

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
                    'News',
                    style: TvDesign.caption(theme).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(args.title, style: TvDesign.pageTitle(theme)),
                  const SizedBox(height: 12),
                  Text(
                    args.body,
                    style: TextStyle(color: muted, fontSize: 13, height: 1.55),
                  ),
                  const SizedBox(height: 20),
                  Text('Payload', style: TvDesign.sectionTitle(theme)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius:
                          BorderRadius.circular(TvDesign.panelRadius),
                      border: Border.all(
                        color: theme.canvasColor.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Text(
                      args.payload.toString(),
                      style: TextStyle(color: muted, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
