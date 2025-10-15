import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/widgets/shimmer%20loader/download_shimmer.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';

import '../../widgets/show_toast.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  bool isLoading = true; // Simulating loading state

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mock list of downloaded movies
    List<Map<String, dynamic>> downloadedMovies = [
      {
        'id': 1,
        'title': 'Inception',
        'poster_url':
            'https://m.media-amazon.com/images/M/MV5BYjk4M2VjYmEtNGJlNy00NDhjLTlhY2YtNDA0NjdhYWEwZjdmXkEyXkFqcGc@._V1_QL75_UX804_.jpg',
        'size': '1.2 GB'
      },
      {
        'id': 2,
        'title': 'Interstellar',
        'poster_url':
            'https://m.media-amazon.com/images/M/MV5BYjk4M2VjYmEtNGJlNy00NDhjLTlhY2YtNDA0NjdhYWEwZjdmXkEyXkFqcGc@._V1_QL75_UX804_.jpg',
        'size': '980 MB'
      },
      {
        'id': 1,
        'title': 'Inception',
        'poster_url':
            'https://m.media-amazon.com/images/M/MV5BYjk4M2VjYmEtNGJlNy00NDhjLTlhY2YtNDA0NjdhYWEwZjdmXkEyXkFqcGc@._V1_QL75_UX804_.jpg',
        'size': '1.2 GB'
      },
      {
        'id': 2,
        'title': 'Interstellar',
        'poster_url':
            'https://m.media-amazon.com/images/M/MV5BYjk4M2VjYmEtNGJlNy00NDhjLTlhY2YtNDA0NjdhYWEwZjdmXkEyXkFqcGc@._V1_QL75_UX804_.jpg',
        'size': '980 MB'
      }
    ];

    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        forceMaterialTransparency:
            ResponsiveWidget.isDesktop(context) ? true : false,
        centerTitle: ResponsiveWidget.isDesktop(context) ? true : false,
        title: ResponsiveWidget.isDesktop(context)
            ? Text(
                lang.downloads,
                style: TextStyle(
                    color: theme.canvasColor, fontWeight: FontWeight.bold),
              )
            : Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        top: 1,
                        bottom: 1,
                        left: ResponsiveWidget.isTablet(context) ? 30 : 5),
                    child: SizedBox(
                      width: 40,
                      child: Image.asset(ImageConstant.logo2),
                    ),
                  ),
                  Spacer(),
                  Text(
                    lang.downloads,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                ],
              ),
        backgroundColor: theme.primaryColor,
      ),
      body: isLoading
          ? DownloadShimmer()
          : downloadedMovies.isNotEmpty
              ? ListView.builder(
                  itemCount: downloadedMovies.length,
                  itemBuilder: (context, index) {
                    var movie = downloadedMovies[index];
                    return Dismissible(
                      key: Key(movie['id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        // Handle delete action
                        downloadedMovies.removeAt(index);
                        CustomToast.show(context, "${movie['title']} deleted",
                            isSuccess: true);
                      },
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            movie['poster_url'],
                            width: 60,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(movie['title'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(movie['size']),
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.play_arrow, color: Colors.blue),
                          onPressed: () {
                            // Handle play functionality
                          },
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download, size: 80, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        lang.noContentAvailable,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                    ],
                  ),
                ),
    );
  }
}
