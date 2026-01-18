// lib/widgets/custom_profile_header.dart

import '../core/app_export.dart';
import './custom_image_view.dart';

class CustomProfileHeader extends StatefulWidget {
  const CustomProfileHeader({
    Key? key,
    required this.avatarImagePath,
    this.displayNameError,
    this.usernameError,
    // ✅ DB-backed fields
    required this.displayName, // display_name
    required this.username, // username (raw, no @ preferred)

    // not rendered (kept for compatibility)
    required this.email,

    // avatar edit
    this.onEditTap,

    // ✅ editing control (current user)
    this.allowEdit = false,
    this.onDisplayNameChanged,
    this.onUsernameChanged,

    this.margin,

    // ✅ NEW: save UX flags (optional)
    this.isSavingDisplayName = false,
    this.isSavingUsername = false,
    this.displayNameSavedPulse = false,
    this.usernameSavedPulse = false,
  }) : super(key: key);

  final String avatarImagePath;

  final String displayName;
  final String username;

  final String email;

  final VoidCallback? onEditTap;

  /// When true: both display name + username become editable
  final bool allowEdit;

  /// Called with trimmed display name
  final Function(String)? onDisplayNameChanged;

  /// Called with trimmed username (RAW, no @)
  final Function(String)? onUsernameChanged;

  final EdgeInsetsGeometry? margin;

  // ✅ NEW: name/username save indicators
  final bool isSavingDisplayName;
  final bool isSavingUsername;
  final bool displayNameSavedPulse;
  final bool usernameSavedPulse;
  final String? displayNameError;
  final String? usernameError;

  @override
  State<CustomProfileHeader> createState() => _CustomProfileHeaderState();
}

class _CustomProfileHeaderState extends State<CustomProfileHeader> {
  final TextEditingController _displayNameController = TextEditingController();
  final FocusNode _displayNameFocus = FocusNode();
  bool _editingDisplayName = false;

  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  bool _editingUsername = false;

  @override
  void initState() {
    super.initState();

    _displayNameController.text = widget.displayName.trim();
    _usernameController.text = _stripAt(widget.username);

    _displayNameFocus.addListener(() {
      if (!_displayNameFocus.hasFocus && _editingDisplayName) {
        _saveDisplayName();
      }
    });

    _usernameFocus.addListener(() {
      if (!_usernameFocus.hasFocus && _editingUsername) {
        _saveUsername();
      }
    });
  }

  @override
  void didUpdateWidget(covariant CustomProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.displayName != oldWidget.displayName && !_editingDisplayName) {
      _displayNameController.text = widget.displayName.trim();
    }
    if (widget.username != oldWidget.username && !_editingUsername) {
      _usernameController.text = _stripAt(widget.username);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _displayNameFocus.dispose();
    _usernameController.dispose();
    _usernameFocus.dispose();
    super.dispose();
  }

  bool get _showAvatarEdit => widget.onEditTap != null;

  String _stripAt(String s) {
    final t = s.trim();
    return t.startsWith('@') ? t.substring(1) : t;
  }

  String _formatHandle(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    return t.startsWith('@') ? t : '@$t';
  }
  Widget _editPencil({
    required bool show,
    double size = 14,
  }) {
    if (!show) {
      return SizedBox(width: size, height: size);
    }

    return Icon(
      Icons.edit,
      size: size,
      color: appTheme.blue_gray_300,
    );
  }

  Widget _saveIndicator({
    required bool saving,
    required bool savedPulse,
    String? errorText,
    double size = 16,
  }) {
    if (saving) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: appTheme.deep_purple_A100,
        ),
      );
    }

    if (errorText != null && errorText.trim().isNotEmpty) {
      return Icon(
        Icons.cancel,
        size: size,
        color: appTheme.red_500,
      );
    }

    if (savedPulse) {
      return Icon(
        Icons.check_circle,
        size: size,
        color: appTheme.deep_purple_A100,
      );
    }

    return SizedBox(width: size, height: size);
  }

  void _saveDisplayName() {
    final next = _displayNameController.text.trim();
    final current = widget.displayName.trim();

    if (next.isEmpty) {
      _displayNameController.text = current.isNotEmpty ? current : 'User';
      setState(() => _editingDisplayName = false);
      return;
    }

    if (next != current) {
      widget.onDisplayNameChanged?.call(next);
    }

    setState(() => _editingDisplayName = false);
  }

  void _saveUsername() {
    final nextRaw = _stripAt(_usernameController.text).trim();
    final currentRaw = _stripAt(widget.username).trim();

    if (nextRaw.isEmpty) {
      _usernameController.text = currentRaw;
      setState(() => _editingUsername = false);
      return;
    }

    if (nextRaw != currentRaw) {
      widget.onUsernameChanged?.call(nextRaw);
    }

    setState(() => _editingUsername = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? EdgeInsets.symmetric(horizontal: 68.h),
      child: Column(
        children: [
          _buildAvatar(),
          SizedBox(height: 6.h),
          _buildDisplayName(),
          SizedBox(height: 6.h),
          _buildUsername(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final double size = 96.h;
    final displayName = widget.displayName.trim();

    final shouldLetter = widget.avatarImagePath.isEmpty ||
        widget.avatarImagePath == ImageConstant.imgDefaultAvatar;

    return SizedBox(
      width: size,
      height: size + (_showAvatarEdit ? 6.h : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: shouldLetter
                    ? Container(
                  height: size,
                  width: size,
                  decoration: BoxDecoration(
                    color: appTheme.color3BD81E,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                    : SizedBox(
                  width: size,
                  height: size,
                  child: CustomImageView(
                    imagePath: widget.avatarImagePath,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    isCircular: true,
                  ),
                ),
              ),
            ),
          ),
          if (_showAvatarEdit)
            Positioned(
              bottom: 0,
              right: 0,
              child: CustomIconButton(
                iconPath: ImageConstant.imgEdit,
                onTap: widget.onEditTap,
                backgroundColor: const Color(0xFFD81E29).withAlpha(59),
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

  Widget _buildDisplayName() {
    final current = widget.displayName.trim();

    const double fieldWidth = 260; // fixed width = stable centering

    if (widget.allowEdit && _editingDisplayName) {
      return SizedBox(
        width: fieldWidth.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: widget.allowEdit
                  ? () => setState(() => _editingDisplayName = true)
                  : null,
              child: Text(
                current.isNotEmpty ? current : 'User',
                style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
                    .copyWith(color: appTheme.white_A700, height: 1.29),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ✅ RIGHT-SIDE ABSOLUTE ICON SLOT
            if (widget.allowEdit)
              Positioned(
                right: 0,
                child: widget.isSavingDisplayName ||
                    widget.displayNameSavedPulse ||
                    widget.displayNameError != null
                    ? _saveIndicator(
                  saving: widget.isSavingDisplayName,
                  savedPulse: widget.displayNameSavedPulse,
                  errorText: widget.displayNameError,
                  size: 16.h,
                )
                    : _editPencil(show: true, size: 16.h),
              ),
          ],
        ),
      );
    }

    return SizedBox(
      width: fieldWidth.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: widget.allowEdit
                ? () => setState(() => _editingDisplayName = true)
                : null,
            child: Text(
              current.isNotEmpty ? current : 'User',
              style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
                  .copyWith(color: appTheme.white_A700, height: 1.29),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ✅ ABSOLUTE indicator
          if (widget.allowEdit)
            Positioned(
              right: 0,
              child: _saveIndicator(
                saving: widget.isSavingDisplayName,
                savedPulse: widget.displayNameSavedPulse,
                size: 16.h,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUsername() {
    final handle = _formatHandle(widget.username);

    const double fieldWidth = 260;

    if (widget.allowEdit && _editingUsername) {
      SizedBox(
        width: fieldWidth.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: widget.allowEdit
                  ? () => setState(() {
                _editingUsername = true;
                _usernameController.text = _stripAt(handle);
              })
                  : null,
              child: Text(
                handle.isNotEmpty ? handle : '@',
                style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300, height: 1.31),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            if (widget.allowEdit)
              Positioned(
                right: 0,
                child: widget.isSavingUsername ||
                    widget.usernameSavedPulse ||
                    widget.usernameError != null
                    ? _saveIndicator(
                  saving: widget.isSavingUsername,
                  savedPulse: widget.usernameSavedPulse,
                  errorText: widget.usernameError,
                  size: 14.h,
                )
                    : _editPencil(show: true, size: 14.h),
              ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: fieldWidth.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: widget.allowEdit
                    ? () => setState(() {
                  _editingUsername = true;
                  _usernameController.text = _stripAt(handle);
                })
                    : null,
                child: Text(
                  handle.isNotEmpty ? handle : '@',
                  style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300, height: 1.31),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.allowEdit)
                Positioned(
                  right: 0,
                  child: _saveIndicator(
                    saving: widget.isSavingUsername,
                    savedPulse: widget.usernameSavedPulse,
                    errorText: widget.usernameError,
                    size: 14.h,
                  ),
                ),
            ],
          ),
        ),

        if (widget.usernameError != null && widget.usernameError!.trim().isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              widget.usernameError!,
              style: TextStyle(
                color: appTheme.red_500,
                fontSize: 12.h,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );

  }
}
