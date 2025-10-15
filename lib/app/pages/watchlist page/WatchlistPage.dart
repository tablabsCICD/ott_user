import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/watchlist%20page/playMoviePage.dart';
import 'package:ott/app/provider/purchaseContentProvider.dart';
import 'package:ott/app/widgets/shimmer%20loader/comming_soon_shimmer.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final purchaseContentProvider =
          Provider.of<PurchaseContentProvider>(context, listen: false);
      await purchaseContentProvider.getPurchaseContent();
    } catch (e) {
      debugPrint("Error initializing data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                lang.watchlist,
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
                    lang.watchlist,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                ],
              ), //const Text("Content Purchase History"),
        backgroundColor: theme.primaryColor,
      ),
      body: isLoading
          ? ComingSoonShimmer()
          : Consumer<PurchaseContentProvider>(
              builder: (context, provider, child) {
                if (provider.userContentList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.movie_creation_sharp,
                          size: 90,
                          color: theme.canvasColor.withOpacity(0.7),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "No content available.",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final content = provider.userContentList[index];
                            final item = content.movie;

                            if (item == null) {
                              return const Center(
                                child: Text("Invalid content data."),
                              );
                            }

                            final fromDate =
                                DateTime.fromMillisecondsSinceEpoch(
                                    content.dateFrom ?? 0);
                            final toDate = DateTime.fromMillisecondsSinceEpoch(
                                content.dateTo ?? 0);

                            return Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: InkWell(
                                onTap: content.active == false
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PlayMoviePage(
                                              movieId: item.id!,
                                            ),
                                          ),
                                        );
                                      },
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Poster
                                          Expanded(
                                            flex: 6,
                                            child: item.posterUrlList
                                                        ?.isNotEmpty ==
                                                    true
                                                ? Image.network(
                                                    item.posterUrlList![0],
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                            error,
                                                            stackTrace) =>
                                                        Container(
                                                      color:
                                                          Colors.grey.shade300,
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.red,
                                                        size: 50,
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    color: Colors.grey.shade300,
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.red,
                                                      size: 50,
                                                    ),
                                                  ),
                                          ),
                                          Expanded(
                                            flex: 5,
                                            child: SingleChildScrollView(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.title ??
                                                          "Unknown Title",
                                                      style: TextStyle(
                                                        color:
                                                            theme.canvasColor,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text.rich(
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      TextSpan(
                                                          style: TextStyle(
                                                            color: theme
                                                                .canvasColor,
                                                            fontSize: 12,
                                                          ),
                                                          children: [
                                                            TextSpan(
                                                              text: 'Access: ',
                                                              style: TextStyle(
                                                                color: theme
                                                                    .primaryColor,
                                                              ),
                                                            ),
                                                            TextSpan(
                                                              text:
                                                                  item.rentlDuration ??
                                                                      '',
                                                            )
                                                          ]),
                                                    ),
                                                    Text.rich(
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      TextSpan(
                                                          style: TextStyle(
                                                            color: theme
                                                                .canvasColor,
                                                            fontSize: 12,
                                                          ),
                                                          children: [
                                                            TextSpan(
                                                              text:
                                                                  'Date From: ',
                                                              style: TextStyle(
                                                                color: theme
                                                                    .primaryColor,
                                                              ),
                                                            ),
                                                            TextSpan(
                                                              text: fromDate
                                                                  .toLocal()
                                                                  .toString()
                                                                  .split(
                                                                      ' ')[0],
                                                            )
                                                          ]),
                                                    ),
                                                    Text.rich(
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      TextSpan(
                                                          style: TextStyle(
                                                            color: theme
                                                                .canvasColor,
                                                            fontSize: 12,
                                                          ),
                                                          children: [
                                                            TextSpan(
                                                              text: 'Date To: ',
                                                              style: TextStyle(
                                                                color: theme
                                                                    .primaryColor,
                                                              ),
                                                            ),
                                                            TextSpan(
                                                              text: toDate
                                                                  .toLocal()
                                                                  .toString()
                                                                  .split(
                                                                      ' ')[0],
                                                            )
                                                          ]),
                                                    ),
                                                    Divider(
                                                      color: theme.primaryColor
                                                          .withOpacity(0.5),
                                                    ),
                                                    Text.rich(
                                                      maxLines: 4,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      TextSpan(
                                                          style: TextStyle(
                                                            color: theme
                                                                .canvasColor
                                                                .withOpacity(
                                                                    0.7),
                                                            fontSize: 12,
                                                          ),
                                                          children: [
                                                            TextSpan(
                                                              text:
                                                                  item.releaseDate ??
                                                                      '',
                                                              style: TextStyle(
                                                                color: theme
                                                                    .canvasColor,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                            TextSpan(
                                                              text: ' | ',
                                                              style: TextStyle(
                                                                color: theme
                                                                    .canvasColor
                                                                    .withOpacity(
                                                                        0.7),
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                            TextSpan(
                                                              text:
                                                                  item.description ??
                                                                      '',
                                                              style: TextStyle(
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                fontSize: 12,
                                                                color: theme
                                                                    .canvasColor
                                                                    .withOpacity(
                                                                        0.7),
                                                              ),
                                                            )
                                                          ]),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      right: 5,
                                      top: 1,
                                      child: Text(
                                        content.remainingDays! > 0
                                            ? "Expires in ${content.remainingDays} days"
                                            : content.remainingDays! == 0
                                                ? "Expires In Today"
                                                : "Expired",
                                        style: TextStyle(
                                          backgroundColor: Colors.black26,
                                          color: content.remainingDays! > 0
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 5,
                                      left: 5,
                                      child: content.isGifted!
                                          ? Container(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 0.5, horizontal: 3),
                                              decoration: BoxDecoration(
                                                color: theme.primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  10,
                                                ),
                                              ),
                                              child: Text(
                                                'Gifted',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          : SizedBox(),
                                    ),
                                    if (content.active == false)
                                      Positioned.fill(
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: theme.cardColor
                                                .withOpacity(0.7),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4, horizontal: 8),
                                            decoration: BoxDecoration(
                                              color: theme
                                                  .scaffoldBackgroundColor
                                                  .withOpacity(0.4),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              "Expired",
                                              style: TextStyle(
                                                color: theme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: provider.userContentList.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              ResponsiveWidget.isMobile(context) ? 2 : 4,
                          mainAxisSpacing: 8.0,
                          crossAxisSpacing: 8.0,
                          childAspectRatio: 2 / 3,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
