import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/pages/shorts%20page/component/shortsLibraryPage.dart';
import 'package:ott/app/pages/wallet%20page/WalletPage.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';

class ShortsPage extends StatefulWidget {
  const ShortsPage({super.key});

  @override
  State<ShortsPage> createState() => _ShortsPageState();
}

class _ShortsPageState extends State<ShortsPage> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var balanceProvider = Provider.of<WalletProvider>(context);
    balanceProvider.getBalance();
    var coinsBalance = balanceProvider.walletBalance;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !(kIsWeb || ResponsiveWidget.isTv(context)),
        toolbarHeight: 80,
        backgroundColor: ResponsiveWidget.isDesktop(context)
            ? theme.scaffoldBackgroundColor
            : theme.primaryColor,
        forceMaterialTransparency:
            ResponsiveWidget.isDesktop(context) ? true : false,
        centerTitle: true,
        title: SizedBox(
          width: ResponsiveWidget.isDesktop(context)
              ? 500
              : ResponsiveWidget.isTablet(context)
                  ? 400
                  : double.infinity,
          child: CustomTextField(
            controller: TextEditingController(),
            hintText: 'Search',
            prefixIcon: const Icon(Icons.search),
            textInputType: TextInputType.text,
          ),
        ),
        actions: [
          OttTvFocus(
            borderRadius: 12,
            scale: 1.06,
            semanticLabel: "Wallet balance",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WalletPage(),
                ),
              );
            },
            child: Container(
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
              child: Text(
                "₹ $coinsBalance",
                style: TextStyle(
                  color: theme.canvasColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ShortsLibraryPage(),
    );
  }
}
