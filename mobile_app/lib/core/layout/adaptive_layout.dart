import 'package:flutter/widgets.dart';

class AdaptiveLayout {
  static const desktopBreakpoint = 1100.0;

  static bool isDesktopWidth(double width) => width >= desktopBreakpoint;

  static bool isDesktopContext(BuildContext context) =>
      isDesktopWidth(MediaQuery.sizeOf(context).width);
}
