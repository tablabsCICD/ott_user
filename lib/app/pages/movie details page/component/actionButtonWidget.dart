import 'package:flutter/material.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class ActionButtonWidget extends StatelessWidget {
  IconData icon;
  String label;
  VoidCallback onTap;
  ActionButtonWidget(
      {super.key,
      required this.label,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    var selectedThemeData =
        Provider.of<ThemeProvider>(context, listen: true).getTheme;
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedThemeData.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(
        icon,
        color: Colors.white,
      ),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
