import '../core/app_export.dart';
import './custom_image_view.dart';

class CustomProfileHeader extends StatefulWidget {
  const CustomProfileHeader({
    Key? key,
    required this.avatarImagePath,

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
    final size = 96.h;
    final displayName = widget.displayName.trim();

    final shouldLetter =
        widget.avatarImagePath.isEmpty ||
            widget.avatarImagePath == ImageConstant.imgDefaultAvatar;

    return SizedBox(
      width: size,
      height: size + (_showAvatarEdit ? 6.h : 0),
      child: Stack(
        children: [
          shouldLetter
              ? Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: appTheme.color3BD81E,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
              : CustomImageView(
            imagePath: widget.avatarImagePath,
            height: size,
            width: size,
            fit: BoxFit.cover,
            radius: BorderRadius.circular(size / 2),
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

    if (widget.allowEdit && _editingDisplayName) {
      return SizedBox(
        width: 260.h,
        child: TextField(
          controller: _displayNameController,
          focusNode: _displayNameFocus,
          autofocus: true,
          textAlign: TextAlign.center,
          style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
              .copyWith(color: appTheme.white_A700, height: 1.29),
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
          ),
          onSubmitted: (_) => _saveDisplayName(),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.allowEdit
          ? () => setState(() => _editingDisplayName = true)
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              current.isNotEmpty ? current : 'User',
              style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
                  .copyWith(color: appTheme.white_A700, height: 1.29),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.allowEdit) ...[
            SizedBox(width: 6.h),
            Icon(Icons.edit, size: 16.h, color: appTheme.blue_gray_300),
          ],
        ],
      ),
    );
  }

  Widget _buildUsername() {
    final handle = _formatHandle(widget.username);

    if (widget.allowEdit && _editingUsername) {
      return SizedBox(
        width: 260.h,
        child: TextField(
          controller: _usernameController,
          focusNode: _usernameFocus,
          autofocus: true,
          textAlign: TextAlign.center,
          style: TextStyleHelper.instance.title16RegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300, height: 1.31),
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
          ),
          onSubmitted: (_) => _saveUsername(),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.allowEdit
          ? () => setState(() {
        _editingUsername = true;
        _usernameController.text = _stripAt(handle);
      })
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              handle.isNotEmpty ? handle : '@',
              style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300, height: 1.31),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.allowEdit) ...[
            SizedBox(width: 6.h),
            Icon(Icons.edit, size: 14.h, color: appTheme.blue_gray_300),
          ],
        ],
      ),
    );
  }
}
