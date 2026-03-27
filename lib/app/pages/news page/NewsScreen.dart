import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
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
              child: SingleChildScrollView(
                child: Text(args.payload.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
