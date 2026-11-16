import 'package:flutter/material.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';

class ActionButtonWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool iconOnly;

  const ActionButtonWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    var selectedThemeData =
        Provider.of<ThemeProvider>(context, listen: true).getTheme;
    // Android TV: compact 36 px button (10-foot UI on the 540 px canvas);
    // OttTvFocus draws the white focus ring + lift.
    final tv = ResponsiveWidget.isAndroidTv(context);
    final radius = tv ? 8.0 : 12.0;
    return OttTvFocus(
      onTap: onTap,
      borderRadius: radius,
      scale: tv ? 1.04 : 1.05,
      semanticLabel: label,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedThemeData.primaryColor,
          foregroundColor: Colors.white,
          padding: tv
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          minimumSize: tv ? const Size(0, 36) : null,
          tapTargetSize: tv ? MaterialTapTargetSize.shrinkWrap : null,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ),
        child: Tooltip(
          message: iconOnly ? label : '',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
              if (!iconOnly) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: tv ? 13 : 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
