import 'package:flutter/material.dart';
import 'package:ott/app/pages/bookmarks page/component/bookmark_card.dart';
import 'package:ott/app/provider/bookmarkProvider.dart';
import 'package:provider/provider.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookmarkProvider>().getUserBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "My Bookmarks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.bookmarksList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    color: theme.canvasColor,
                    size: 60,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    'No bookmarks added',
                    style: TextStyle(
                      color: theme.canvasColor,
                    ),
                  )
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              int crossAxisCount = 1;
              if (width >= 1400) {
                crossAxisCount = 4;
              } else if (width >= 1100) {
                crossAxisCount = 3;
              } else if (width >= 800) {
                crossAxisCount = 2;
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.3,
                ),
                itemCount: provider.bookmarksList.length,
                itemBuilder: (context, index) {
                  final movie = provider.bookmarksList[index];
                  return BookmarkPosterCard(movie: movie);
                },
              );
            },
          );
        },
      ),
    );
  }
}
