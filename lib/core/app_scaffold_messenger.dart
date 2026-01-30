import 'package:flutter/material.dart';

class AppScaffoldMessenger extends ScaffoldMessenger {
  const AppScaffoldMessenger({
    Key? key,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  ScaffoldMessengerState createState() => _AppScaffoldMessengerState();
}

class _AppScaffoldMessengerState extends ScaffoldMessengerState {
  @override
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    SnackBar snackBar, {
    AnimationStyle? snackBarAnimationStyle,
  }) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Enforce consistent toast styling app-wide:
    // - floating behavior
    // - safe bottom margin
    // - background color from SnackBarTheme (do not allow per-call overrides)
    final SnackBar finalBar = _rebuildSnackBarWith(
      snackBar,
      margin: snackBar.margin ?? EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      behavior: SnackBarBehavior.floating,
    );

    return super.showSnackBar(
      finalBar,
      snackBarAnimationStyle: snackBarAnimationStyle,
    );
  }

  SnackBar _rebuildSnackBarWith(
    SnackBar original, {
    EdgeInsetsGeometry? margin,
    SnackBarBehavior? behavior,
  }) {
    return SnackBar(
      // Required
      content: original.content,

      // Common
      action: original.action,
      duration: original.duration,
      elevation: original.elevation,
      shape: original.shape,
      behavior: behavior ?? original.behavior,

      // Layout
      margin: margin ?? original.margin,
      padding: original.padding,
      width: original.width,

      // Text/action behavior
      actionOverflowThreshold: original.actionOverflowThreshold,

      // Close icon (newer Flutter)
      showCloseIcon: original.showCloseIcon,
      closeIconColor: original.closeIconColor,

      // Dismiss direction
      dismissDirection: original.dismissDirection,

      // Animation (SnackBar has its own animation curve/duration props)
      animation: original.animation,
      onVisible: original.onVisible,

      // Accessibility
      clipBehavior: original.clipBehavior,
    );
  }
}
