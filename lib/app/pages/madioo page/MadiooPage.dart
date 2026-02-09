import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class MadiooPage extends StatefulWidget {
  const MadiooPage({super.key, this.useParentScroll = false});

  final bool useParentScroll;

  @override
  State<MadiooPage> createState() => _MadiooPageState();
}

class _MadiooPageState extends State<MadiooPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          SizedBox(
            height: 300,
          ),
          Text("This feature is under development"),
        ],
      ),
    );
  }
}
