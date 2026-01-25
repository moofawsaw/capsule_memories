// lib/widgets/custom_profile_header.dart

import '../core/app_export.dart';
import '../services/supabase_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomProfileHeader extends StatefulWidget {
  const CustomProfileHeader({
    Key? key,
    required this.avatarImagePath,

    // ✅ errors
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

    // ✅ inline save UX
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

  // ✅ save indicators
  final bool isSavingDisplayName;
  final bool isSavingUsername;
  final bool displayNameSavedPulse;
  final bool usernameSavedPulse;

  // ✅ errors
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

  // ✅ CHANGE THIS TO YOUR REAL AVATAR BUCKET NAME
  static const String _avatarBucket = 'avatars';

  @override
  void initState() {
    super.initState();

    _displayNameController.text = widget.displayName.trim();
    _usernameController.text = _stripAt(widget.username);

    _displayNameFocus.addListener(() {
      if (!_displayNameFocus.hasFocus && _editingDisplayName) {
        // Use post-frame callback to ensure state is consistent
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_displayNameFocus.hasFocus && _editingDisplayName) {
            _saveDisplayName();
          }
        });
      }
    });

    _usernameFocus.addListener(() {
      if (!_usernameFocus.hasFocus && _editingUsername) {
        // Use post-frame callback to ensure state is consistent
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_usernameFocus.hasFocus && _editingUsername) {
            _saveUsername();
          }
        });
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

  bool _isNetworkUrl(String? s) {
    if (s == null) return false;
    final v = s.trim();
    if (v.isEmpty) return false;
    if (v == 'null' || v == 'undefined') return false;
    return v.startsWith('http://') || v.startsWith('https://');
  }

  /// ✅ Resolves either:
  /// - Full network URL -> returns as-is
  /// - Supabase storage key -> returns public URL
  /// - invalid/empty -> returns null
  String? _resolveAvatarPath(String? raw) {
    if (raw == null) return null;
    final v = raw.trim();
    if (v.isEmpty || v == 'null' || v == 'undefined') return null;

    if (_isNetworkUrl(v)) return v;

    final client = SupabaseService.instance.client;
    if (client == null) return null;

    try {
      return client.storage.from(_avatarBucket).getPublicUrl(v);
    } catch (_) {
      return null;
    }
  }

  Widget _editPencil({double size = 14}) {
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

  void _startEditDisplayName() {
    if (!widget.allowEdit) return;
    if (_editingDisplayName) return;
    setState(() => _editingDisplayName = true);
    _displayNameFocus.requestFocus();
  }

  void _startEditUsername() {
    if (!widget.allowEdit) return;
    if (_editingUsername) return;
    setState(() {
      _editingUsername = true;
      _usernameController.text = _stripAt(_usernameController.text);
    });
    _usernameFocus.requestFocus();
  }

  void _saveDisplayName() {
    if (!_editingDisplayName) return;
    
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
    if (!_editingUsername) return;
    
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

    final resolvedAvatarPath = _resolveAvatarPath(widget.avatarImagePath);

    final shouldLetter = resolvedAvatarPath == null ||
        resolvedAvatarPath.isEmpty;

    // Strip query so cacheKey is stable (same as your header logic)
    String _stripQuery(String url) {
      final uri = Uri.tryParse(url);
      if (uri == null) return url;
      return uri.replace(query: '').toString();
    }

    // Non-null avatar path when shouldLetter is false
    final avatarUrl = resolvedAvatarPath ?? '';

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
                  child: ClipOval(
                    child: Image(
                      image: CachedNetworkImageProvider(
                        avatarUrl,
                        cacheKey: _stripQuery(avatarUrl),
                      ),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.low,
                    ),
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
                icon: Icons.edit,
                onTap: widget.onEditTap,
                backgroundColor: const Color(0xFFD81E29).withAlpha(59),
                borderRadius: 18.h,
                height: 38.h,
                width: 38.h,
                padding: EdgeInsets.all(8.h),
                iconColor: appTheme.gray_50,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDisplayName() {
    final current = widget.displayName.trim();
    const double fieldWidth = 260;

    final bool hasStateIcon = widget.isSavingDisplayName ||
        widget.displayNameSavedPulse ||
        (widget.displayNameError != null && widget.displayNameError!.trim().isNotEmpty);

    // ✅ EDITING: show TextField, indicator on right
    if (widget.allowEdit && _editingDisplayName) {
      return SizedBox(
        width: fieldWidth.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TextField(
              controller: _displayNameController,
              focusNode: _displayNameFocus,
              autofocus: true,
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50, height: 1.29),
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
              ),
              onSubmitted: (_) => _saveDisplayName(),
              onEditingComplete: _saveDisplayName,
              onTapOutside: (_) {
                // Save immediately when tapping outside (iOS compatibility)
                if (_editingDisplayName) {
                  _saveDisplayName();
                }
                _displayNameFocus.unfocus();
              },
            ),
            Positioned(
              right: 0,
              child: AbsorbPointer(
                absorbing: true, // ✅ do not let taps bubble to parent
                child: _saveIndicator(
                  saving: widget.isSavingDisplayName,
                  savedPulse: widget.displayNameSavedPulse,
                  errorText: widget.displayNameError,
                  size: 16.h,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ IDLE: tap anywhere (including pencil) enters edit; pencil is purely visual
    return SizedBox(
      width: fieldWidth.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.allowEdit ? _startEditDisplayName : null,
            child: Text(
              current.isNotEmpty ? current : 'User',
              style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50, height: 1.29),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.allowEdit)
            Positioned(
              right: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // ✅ consume the tap so it doesn't trigger any parent GestureDetector (avatar picker)
                onTap: _startEditDisplayName,
                child: hasStateIcon
                    ? AbsorbPointer(
                  absorbing: true,
                  child: _saveIndicator(
                    saving: widget.isSavingDisplayName,
                    savedPulse: widget.displayNameSavedPulse,
                    errorText: widget.displayNameError,
                    size: 16.h,
                  ),
                )
                    : AbsorbPointer(
                  absorbing: true,
                  child: _editPencil(size: 16.h),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUsername() {
    final handle = _formatHandle(widget.username);
    const double fieldWidth = 260;

    final bool hasStateIcon = widget.isSavingUsername ||
        widget.usernameSavedPulse ||
        (widget.usernameError != null && widget.usernameError!.trim().isNotEmpty);

    // ✅ EDITING
    if (widget.allowEdit && _editingUsername) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: fieldWidth.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TextField(
                  controller: _usernameController,
                  focusNode: _usernameFocus,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300, height: 1.31),
                  decoration: InputDecoration(
                    border: const UnderlineInputBorder(),
                    prefixText: '@',
                    prefixStyle: TextStyleHelper.instance.title16RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300, height: 1.31),
                  ),
                  onSubmitted: (_) => _saveUsername(),
                  onEditingComplete: _saveUsername,
                  onTapOutside: (_) {
                    // Save immediately when tapping outside (iOS compatibility)
                    if (_editingUsername) {
                      _saveUsername();
                    }
                    _usernameFocus.unfocus();
                  },
                ),
                Positioned(
                  right: 0,
                  child: AbsorbPointer(
                    absorbing: true,
                    child: _saveIndicator(
                      saving: widget.isSavingUsername,
                      savedPulse: widget.usernameSavedPulse,
                      errorText: widget.usernameError,
                      size: 14.h,
                    ),
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

    // ✅ IDLE
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: fieldWidth.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.allowEdit ? _startEditUsername : null,
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
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // ✅ consume tap so it doesn't trigger parent avatar picker
                    onTap: _startEditUsername,
                    child: hasStateIcon
                        ? AbsorbPointer(
                      absorbing: true,
                      child: _saveIndicator(
                        saving: widget.isSavingUsername,
                        savedPulse: widget.usernameSavedPulse,
                        errorText: widget.usernameError,
                        size: 14.h,
                      ),
                    )
                        : AbsorbPointer(
                      absorbing: true,
                      child: _editPencil(size: 14.h),
                    ),
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
