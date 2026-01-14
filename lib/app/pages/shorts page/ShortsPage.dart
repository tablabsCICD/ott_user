import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/shorts%20page/component/shortsLibraryPage.dart';
import 'package:ott/app/provider/shorts_provider.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';

class ShortsPage extends StatefulWidget {
  const ShortsPage({super.key});

  @override
  State<ShortsPage> createState() => _ShortsPageState();
}

class _ShortsPageState extends State<ShortsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ShortProvider>().fetchShorts();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: ResponsiveWidget.isDesktop(context)
            ? theme.scaffoldBackgroundColor
            : theme.primaryColor,
        forceMaterialTransparency:
            ResponsiveWidget.isDesktop(context) ? true : false,
        title: CustomTextField(
          controller: TextEditingController(),
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search),
          textInputType: TextInputType.text,
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8.0),
            padding: EdgeInsets.symmetric(
              vertical: 3,
              horizontal: 6,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border.all(
                color: theme.canvasColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 20,
                  child: Image.asset(
                    ImageConstant.coin,
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                Text(
                  '96.7',
                  style: TextStyle(
                    color: theme.canvasColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ShortsLibraryPage(),
    );
  }
}
