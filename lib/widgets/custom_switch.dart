import '../core/app_export.dart';

/**
 * CustomSwitch - A reusable switch component with configurable styling and behavior
 * 
 * This component wraps Flutter's Switch widget with additional customization options
 * including custom colors, sizing, and responsive design support.
 * 
 * @param value - Current state of the switch (true/false)
 * @param onChanged - Callback function triggered when switch state changes
 * @param activeColor - Color when switch is in active/on state
 * @param inactiveTrackColor - Color of track when switch is inactive/off
 * @param inactiveThumbColor - Color of thumb when switch is inactive/off
 * @param width - Custom width for the switch container
 * @param height - Custom height for the switch container
 * @param margin - External spacing around the switch
 * @param isEnabled - Whether the switch is enabled for interaction
 */
class CustomSwitch extends StatelessWidget {
  const CustomSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveTrackColor,
    this.inactiveThumbColor,
    this.width,
    this.height,
    this.margin,
    this.isEnabled = true,
  }) : super(key: key);

  /// Current state of the switch (true for on, false for off)
  final bool value;

  /// Callback function triggered when switch state changes
  final Function(bool) onChanged;

  /// Color when switch is in active/on state
  final Color? activeColor;

  /// Color of the track when switch is inactive/off
  final Color? inactiveTrackColor;

  /// Color of the thumb when switch is inactive/off
  final Color? inactiveThumbColor;

  /// Custom width for the switch container
  final double? width;

  /// Custom height for the switch container
  final double? height;

  /// External spacing around the switch
  final EdgeInsetsGeometry? margin;

  /// Whether the switch is enabled for interaction
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 20.h,
      margin: margin,
      child: Switch(
        value: value,
        onChanged: isEnabled ? onChanged : null,
        activeThumbColor: activeColor ?? appTheme.whiteCustom,
        activeTrackColor:
            activeColor?.withAlpha(128) ?? appTheme.deep_purple_A100,
        inactiveTrackColor: inactiveTrackColor ?? Color(0xFFE0E0E0),
        inactiveThumbColor: inactiveThumbColor ?? appTheme.whiteCustom,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        splashRadius: 20.h,
      ),
    );
  }
}
