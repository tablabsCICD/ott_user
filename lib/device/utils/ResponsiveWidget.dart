import 'package:flutter/material.dart';
import 'package:ott/app/flavor/app_flavor.dart';

class ResponsiveWidget extends StatelessWidget {
  static const double mobileBreakpoint = 750;
  static const double desktopBreakpoint = 1100;

  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      !FlavorConfig.current.isTv &&
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      !FlavorConfig.current.isTv &&
      MediaQuery.of(context).size.width < desktopBreakpoint &&
      MediaQuery.of(context).size.width >= mobileBreakpoint;

  static bool isDesktop(BuildContext context) =>
      FlavorConfig.current.isTv ||
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  static bool isTv(BuildContext context) {
    if (FlavorConfig.current.isTv) return true;
    final media = MediaQuery.of(context);
    return media.size.width >= desktopBreakpoint &&
        media.orientation == Orientation.landscape;
  }

  static bool isTabletOrTv(BuildContext context) => !isMobile(context);

  @override
  Widget build(BuildContext context) {
    if (FlavorConfig.current.isTv) return desktop;
    final Size size = MediaQuery.of(context).size;
    // If our width is more than 1100 then we consider it a desktop
    if (size.width >= desktopBreakpoint) {
      return desktop;
    }
    // If width it less then 1100 and more then 850 we consider it as tablet
    else if (size.width >= mobileBreakpoint && tablet != null) {
      return tablet!;
    }
    // Or less then that we called it mobile
    else {
      return mobile;
    }
  }
}
