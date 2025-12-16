import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'custom_image_view.dart';
import 'custom_switch.dart';

/**
 * CustomNotificationSettings - A comprehensive notification settings component that displays
 * a header section and a list of notification preferences with toggle switches.
 * 
 * Features:
 * - Header with icon and title
 * - Master push notifications toggle with separator
 * - List of individual notification preferences
 * - Consistent styling and responsive design
 * - Configurable notification options with callbacks
 */
class CustomNotificationSettings extends StatelessWidget {
  CustomNotificationSettings({
    Key? key,
    this.headerIcon,
    this.headerTitle,
    this.pushNotificationsEnabled,
    this.onPushNotificationsChanged,
    this.notificationOptions,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
  }) : super(key: key);

  /// Icon path for the header section
  final String? headerIcon;

  /// Title text for the header section
  final String? headerTitle;

  /// Current state of push notifications toggle
  final bool? pushNotificationsEnabled;

  /// Callback when push notifications toggle changes
  final Function(bool)? onPushNotificationsChanged;

  /// List of notification preference options
  final List<CustomNotificationOption>? notificationOptions;

  /// Background color of the container
  final Color? backgroundColor;

  /// Border radius of the container
  final double? borderRadius;

  /// Internal padding of the container
  final EdgeInsetsGeometry? padding;

  /// External margin of the container
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(24.h),
      margin: margin ?? EdgeInsets.only(left: 8.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? Color(0xFF151319),
        borderRadius: BorderRadius.circular(borderRadius ?? 20.h),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 30.h),
          _buildPushNotificationsSection(),
          SizedBox(height: 30.h),
          _buildNotificationOptions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (headerIcon != null)
          CustomImageView(
            imagePath: headerIcon!,
            height: 26.h,
            width: 26.h,
          ),
        SizedBox(width: 8.h),
        Text(
          headerTitle ?? 'Notifications',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
      ],
    );
  }

  Widget _buildPushNotificationsSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: appTheme.blue_gray_900,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Push Notifications',
            style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
          CustomSwitch(
            value: pushNotificationsEnabled ?? false,
            onChanged: onPushNotificationsChanged ?? (value) {},
            margin: EdgeInsets.only(bottom: 28.h),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationOptions() {
    final options = notificationOptions ?? _getDefaultNotificationOptions();

    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;

        return Container(
          margin:
              EdgeInsets.only(bottom: index < options.length - 1 ? 16.h : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                    ),
                    SizedBox(height: option.titleDescriptionGap ?? 6.h),
                    Container(
                      width: option.descriptionWidth ?? double.infinity,
                      child: Text(
                        option.description,
                        style: TextStyleHelper
                            .instance.body14RegularPlusJakartaSans
                            .copyWith(
                                color: appTheme.blue_gray_300,
                                height: option.descriptionLineHeight ?? 1.2),
                      ),
                    ),
                  ],
                ),
              ),
              CustomSwitch(
                value: option.isEnabled,
                onChanged: option.onChanged,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<CustomNotificationOption> _getDefaultNotificationOptions() {
    return [
      CustomNotificationOption(
        title: 'Memory Invites',
        description: 'Get notified when someone invites you to a memory',
        isEnabled: false,
        onChanged: (value) {},
      ),
      CustomNotificationOption(
        title: 'Memory Activity',
        description: 'Get notified when someone posts to a memory you\'re in',
        isEnabled: false,
        onChanged: (value) {},
      ),
      CustomNotificationOption(
        title: 'Memory Sealed',
        description: 'Get notified when a memory you\'re part of closes',
        isEnabled: false,
        onChanged: (value) {},
        titleDescriptionGap: 2.h,
      ),
      CustomNotificationOption(
        title: 'Reactions',
        description: 'Get notified when someone reacts to your story',
        isEnabled: false,
        onChanged: (value) {},
        titleDescriptionGap: 2.h,
      ),
      CustomNotificationOption(
        title: 'New Followers',
        description: 'Get notified when someone follows you',
        isEnabled: false,
        onChanged: (value) {},
        titleDescriptionGap: 2.h,
      ),
      CustomNotificationOption(
        title: 'Friend Requests',
        description: 'Get notified when someone sends a friend request',
        isEnabled: false,
        onChanged: (value) {},
      ),
      CustomNotificationOption(
        title: 'Group Invites',
        description: 'Get notified when invited to a group',
        isEnabled: false,
        onChanged: (value) {},
        titleDescriptionGap: 6.h,
      ),
    ];
  }
}

/// Data model for individual notification options
class CustomNotificationOption {
  CustomNotificationOption({
    required this.title,
    required this.description,
    required this.isEnabled,
    required this.onChanged,
    this.titleDescriptionGap,
    this.descriptionWidth,
    this.descriptionLineHeight,
  });

  /// Title of the notification option
  final String title;

  /// Description text explaining the notification
  final String description;

  /// Current enabled state of the notification
  final bool isEnabled;

  /// Callback when the switch state changes
  final Function(bool) onChanged;

  /// Gap between title and description
  final double? titleDescriptionGap;

  /// Width constraint for description text
  final double? descriptionWidth;

  /// Line height for description text
  final double? descriptionLineHeight;
}
