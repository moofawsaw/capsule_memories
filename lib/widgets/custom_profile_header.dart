import '../core/app_export.dart';
import './custom_image_view.dart';

/** 
 * CustomProfileHeader - A reusable profile header component that displays user avatar, name, and email
 * 
 * This component provides:
 * - Circular avatar image with edit button overlay
 * - Letter avatar fallback when no image is available
 * - User name display with tap-to-edit functionality
 * - Email address display with secondary styling
 * - Edit functionality with callback support
 * - Responsive design using SizeUtils extensions
 * - Proper spacing and alignment for profile information
 */
class CustomProfileHeader extends StatefulWidget {
  const CustomProfileHeader({
    Key? key,
    required this.avatarImagePath,
    required this.userName,
    required this.email,
    this.onEditTap,
    this.onUserNameChanged,
    this.margin,
    this.allowUsernameEdit = false,
  }) : super(key: key);

  /// Path to the user's avatar image
  final String avatarImagePath;

  /// Display name of the user
  final String userName;

  /// Email address of the user
  final String email;

  /// Callback function when edit button is tapped
  final VoidCallback? onEditTap;

  /// Callback function when username is changed
  final Function(String)? onUserNameChanged;

  /// Margin around the entire component
  final EdgeInsetsGeometry? margin;

  /// Allow username editing (only for current user)
  final bool allowUsernameEdit;

  @override
  State<CustomProfileHeader> createState() => _CustomProfileHeaderState();
}

class _CustomProfileHeaderState extends State<CustomProfileHeader> {
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  bool _isEditingUsername = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.userName;

    // Listen for focus changes to save on blur
    _usernameFocusNode.addListener(() {
      if (!_usernameFocusNode.hasFocus && _isEditingUsername) {
        _saveUsername();
      }
    });
  }

  @override
  void didUpdateWidget(CustomProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller if userName changes externally
    if (widget.userName != oldWidget.userName && !_isEditingUsername) {
      _usernameController.text = widget.userName;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  void _saveUsername() {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isNotEmpty && newUsername != widget.userName) {
      widget.onUserNameChanged?.call(newUsername);
    } else if (newUsername.isEmpty) {
      // Revert to original username if empty
      _usernameController.text = widget.userName;
    }

    setState(() {
      _isEditingUsername = false;
    });
  }

  /// Determines if the edit button should be displayed
  bool get showEditButton => widget.onEditTap != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? EdgeInsets.symmetric(horizontal: 68.h),
      child: Column(
        children: [
          _buildAvatarSection(context),
          SizedBox(height: 4.h),
          _buildUserName(context),
          SizedBox(height: 8.h),
          _buildEmail(context),
        ],
      ),
    );
  }

  /// Builds the avatar section with optional edit button
  Widget _buildAvatarSection(BuildContext context) {
    final size = 96.h;

    return SizedBox(
      width: size,
      height: size + (showEditButton ? 6.h : 0),
      child: Stack(
        children: [
          // Avatar display - letter avatar or image
          _shouldShowLetterAvatar()
              ? _buildLetterAvatar(size)
              : CustomImageView(
                  imagePath: widget.avatarImagePath,
                  height: size,
                  width: size,
                  fit: BoxFit.cover,
                  radius: BorderRadius.circular(size / 2),
                ),
          // Edit button positioned at bottom-right
          if (showEditButton)
            Positioned(
              bottom: 0,
              right: 0,
              child: CustomIconButton(
                iconPath: ImageConstant.imgEdit,
                onTap: widget.onEditTap,
                backgroundColor: Color(0xFFD81E29).withAlpha(59),
                borderRadius: 18.h,
                height: 38.h,
                width: 38.h,
                padding: EdgeInsets.all(8.h),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds letter avatar fallback
  Widget _buildLetterAvatar(double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: appTheme.color3BD81E,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getAvatarLetter(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Determines if letter avatar should be shown
  bool _shouldShowLetterAvatar() {
    return widget.avatarImagePath.isEmpty ||
        widget.avatarImagePath == ImageConstant.imgDefaultAvatar;
  }

  /// Gets the first letter of user name for avatar
  String _getAvatarLetter() {
    return widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?';
  }

  /// Builds the user name text with tap-to-edit functionality
  Widget _buildUserName(BuildContext context) {
    if (widget.allowUsernameEdit && _isEditingUsername) {
      return Container(
        constraints: BoxConstraints(maxWidth: 250.h),
        child: TextField(
          controller: _usernameController,
          focusNode: _usernameFocusNode,
          autofocus: true,
          textAlign: TextAlign.center,
          style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
              .copyWith(height: 1.29),
          decoration: InputDecoration(
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: appTheme.color3BD81E),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: appTheme.blue_gray_300),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: appTheme.color3BD81E, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 4.h),
          ),
          onSubmitted: (_) => _saveUsername(),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.allowUsernameEdit
          ? () {
              setState(() {
                _isEditingUsername = true;
              });
            }
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.h),
        decoration: widget.allowUsernameEdit
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.transparent, width: 1),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.userName,
                style: TextStyleHelper
                    .instance.headline24ExtraBoldPlusJakartaSans
                    .copyWith(height: 1.29),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.allowUsernameEdit) ...[
              SizedBox(width: 4.h),
              Icon(
                Icons.edit,
                size: 16.h,
                color: appTheme.blue_gray_300,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the email text
  Widget _buildEmail(BuildContext context) {
    return Text(
      widget.email,
      style: TextStyleHelper.instance.title16RegularPlusJakartaSans
          .copyWith(color: appTheme.blue_gray_300, height: 1.31),
    );
  }
}
