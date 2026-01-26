import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore_for_file: unused_field
import '../core/app_export.dart';
import '../presentation/create_memory_screen/create_memory_screen.dart';
import '../presentation/notifications_screen/notifier/notifications_notifier.dart';
import '../services/network_connectivity_provider.dart';
import '../services/avatar_state_service.dart';
import '../services/create_memory_preload_service.dart';
import '../services/supabase_service.dart';
import './custom_image_view.dart';

/// Custom AppBar component that provides flexible layout options
/// Supports logo display, action buttons, profile images, and custom titles
/// Implements PreferredSizeWidget for proper AppBar integration
/// INTERNALLY MANAGES notification count state and user avatar - no need for screens to pass them
class CustomAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  CustomAppBar({
    Key? key,
    this.logoImagePath,
    this.title,
    this.showIconButton = false,
    this.iconButtonBackgroundColor,
    this.actionIcons,
    this.showProfileImage = false,
    this.layoutType = CustomAppBarLayoutType.logoWithActions,
    this.customHeight,
    this.showBottomBorder = true,
    this.backgroundColor,
    this.titleTextStyle,
    this.showLeading = false,
    this.onLeadingTap,
  }) : super(key: key);

  /// Path to the logo image (typically SVG)
  final String? logoImagePath;

  /// Title text for the app bar
  final String? title;

  /// Whether to show the icon button (plus button)
  final bool showIconButton;

  /// Background color for the icon button
  final Color? iconButtonBackgroundColor;

  /// List of action buttons to render on the right.
  final List<CustomAppBarActionType>? actionIcons;

  /// Whether to show profile image
  final bool showProfileImage;

  /// Layout type for the app bar
  final CustomAppBarLayoutType layoutType;

  /// Custom height for the app bar
  final double? customHeight;

  /// Whether to show bottom border
  final bool showBottomBorder;

  /// Background color for the app bar
  final Color? backgroundColor;

  /// Custom text style for title
  final TextStyle? titleTextStyle;

  /// Whether to show a leading icon (icon chosen by layout).
  final bool showLeading;

  /// Callback for leading icon tap
  final VoidCallback? onLeadingTap;

  @override
  ConsumerState<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(
    (customHeight ?? 86.h) + (showBottomBorder ? 1.h : 0),
  );
}

class _CustomAppBarState extends ConsumerState<CustomAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _plusSpinController;
  late final Animation<double> _plusSpin;

  // ============================================================
  // AVATAR: GLOBAL (STATIC) CACHE SO NAVIGATION DOESN'T THRASH
  // ============================================================

  /// Dedicated avatar cache with long stale period (prevents eviction / re-fetches).
  static final CacheManager _avatarCacheManager = CacheManager(
    Config(
      'capsule_avatar_cache_v1',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
    ),
  );

  /// Global avatar provider cache across ALL CustomAppBar instances/routes.
  static String? _globalAvatarCacheKey;
  static String? _globalAvatarUrlNoQuery;
  static ImageProvider? _globalAvatarProvider;

  /// Track which cacheKey we already precached (avoid repeat precache work).
  static String? _globalPrecachedKey;

  /// Local mirrors (still useful for debug / consistency, but global is the win).
  String? _cachedAvatarUrl;
  ImageProvider? _cachedAvatarProvider;

  // ✅ Riverpod: listenManual subscription (required if listening from initState)
  ProviderSubscription<String?>? _avatarUrlSub;

  @override
  void initState() {
    super.initState();

    // Plus micro-interaction (one quick spin)
    _plusSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _plusSpin = CurvedAnimation(
      parent: _plusSpinController,
      curve: Curves.easeOutCubic,
    );

    // Load avatar only if not already cached
    if (widget.showProfileImage) {
      Future.microtask(() => _ensureAvatarLoaded());
    }

    // ✅ FIX: ref.listen(...) is NOT allowed here -> must use ref.listenManual(...)
    _avatarUrlSub = ref.listenManual<String?>(
      avatarStateProvider.select((s) => s.avatarUrl),
          (prev, next) {
        if (next == null || next.trim().isEmpty) return;
        _primeAvatarProvider(next);
      },
    );

    // ✅ Preload Create Memory dependencies AFTER first paint (keeps splash fast).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fire-and-forget warm cache; CreateMemoryNotifier will consume it.
      CreateMemoryPreloadService.instance.warm();
    });
  }

  @override
  void didUpdateWidget(covariant CustomAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If profile image gets enabled after init, ensure avatar is loaded.
    if (widget.showProfileImage && !oldWidget.showProfileImage) {
      Future.microtask(() => _ensureAvatarLoaded());
    }
  }

  @override
  void dispose() {
    _avatarUrlSub?.close();
    _plusSpinController.dispose();
    super.dispose();
  }

  /// Ensure avatar is loaded whenever avatarUrl is null/empty
  /// 🎯 UPDATED: Load based on avatarUrl state, not userId
  Future<void> _ensureAvatarLoaded() async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return;

      final user = client.auth.currentUser;
      if (user == null) return;

      final currentAvatarState = ref.read(avatarStateProvider);

      // 🎯 CRITICAL: Load if avatarUrl is null/empty (not based on userId)
      if ((currentAvatarState.avatarUrl == null ||
          currentAvatarState.avatarUrl!.isEmpty) &&
          !currentAvatarState.isLoading) {
        await ref.read(avatarStateProvider.notifier).loadCurrentUserAvatar();
        // ignore: avoid_print
        print('✅ Avatar loaded in custom_app_bar based on empty avatarUrl');
      } else {
        // If we already have a URL, prime provider immediately
        final url = currentAvatarState.avatarUrl;
        if (url != null && url.trim().isNotEmpty) {
          _primeAvatarProvider(url);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error ensuring avatar loaded: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Only rebuild AppBar title content when unreadCount changes (not on every notifier change)
    final unreadCount = ref.watch(
      notificationsNotifier.select(
            (s) => s.notificationsModel?.unreadCount ?? 0,
      ),
    );

    return AppBar(
      backgroundColor: widget.backgroundColor ?? appTheme.transparentCustom,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: widget.customHeight ?? 102.h,
      title: _buildAppBarContent(context, unreadCount),
      titleSpacing: 0,
      bottom: widget.showBottomBorder ? _buildBottomBorder() : null,
    );
  }

  Widget _buildAppBarContent(BuildContext context, int unreadCount) {
    switch (widget.layoutType) {
      case CustomAppBarLayoutType.logoWithActions:
        return _buildLogoWithActionsLayout(context, unreadCount);
      case CustomAppBarLayoutType.titleWithLeading:
        return _buildTitleWithLeadingLayout();
      case CustomAppBarLayoutType.spaceBetween:
        return _buildSpaceBetweenLayout();
    }
  }

  Widget _buildLogoWithActionsLayout(BuildContext context, int unreadCount) {
    // ✅ Only watch the auth flag here (prevents avatarUrl changes from rebuilding the whole row)
    final isAuthenticated = ref.watch(
      avatarStateProvider.select((s) => s.userId != null),
    );
    final isOffline = ref.watch(isOfflineProvider).maybeWhen(
          data: (v) => v,
          orElse: () => false,
        );

    // 🔥 Get current route to determine active state
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 22.h, vertical: 26.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.logoImagePath != null) ...[
            Expanded(
              flex: 44,
              child: GestureDetector(
                onTap: () => _handleLogoTap(context),
                child: CustomImageView(
                  imagePath: widget.logoImagePath!,
                  height: 33.h,
                  width: 130.h,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
            SizedBox(width: 18.h),
          ],

          if (isAuthenticated) ...[
            // ➕ PLUS BUTTON (spin stays)
            if (widget.showIconButton) ...[
              isOffline
                  ? _buildSquareSkeleton(size: 46.h, radius: 22.h)
                  : Container(
                      width: 46.h,
                      height: 46.h,
                      decoration: BoxDecoration(
                        color: widget.iconButtonBackgroundColor ??
                            const Color(0x3BD81E29),
                        borderRadius: BorderRadius.circular(22.h),
                      ),
                      child: IconButton(
                        onPressed: () => _handlePlusButtonTap(context),
                        padding: EdgeInsets.all(6.h),
                        icon: AnimatedBuilder(
                          animation: _plusSpinController,
                          builder: (context, child) {
                            final angle = _plusSpin.value * 2 * math.pi;
                            return Transform.rotate(
                              angle: angle,
                              child: child,
                            );
                          },
                          child: Icon(
                            Icons.add,
                            size: 34,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
              SizedBox(width: 18.h),
            ],

            // ACTION ICONS
            if (widget.actionIcons != null) ...[
              ...widget.actionIcons!.asMap().entries.map((entry) {
                final index = entry.key;
                final actionType = entry.value;

                final isNotificationIcon =
                    actionType == CustomAppBarActionType.notifications;
                final isPicturesIcon =
                    actionType == CustomAppBarActionType.memories;

                bool isActive = false;
                if (isNotificationIcon && currentRoute == AppRoutes.appNotifications) {
                  isActive = true;
                } else if (isPicturesIcon && currentRoute == AppRoutes.appMemories) {
                  isActive = true;
                }

                IconData outlineIcon;
                IconData filledIcon;

                if (isNotificationIcon) {
                  outlineIcon = Icons.notifications_outlined;
                  filledIcon = Icons.notifications;
                } else if (isPicturesIcon) {
                  outlineIcon = Icons.photo_outlined;
                  filledIcon = Icons.photo;
                } else {
                  outlineIcon = Icons.help_outline;
                  filledIcon = Icons.help;
                }

                final iconColor = isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface;

                return Padding(
                  padding: EdgeInsets.only(left: index > 0 ? 6.h : 0),
                  child: isOffline
                      ? _buildSquareSkeleton(size: 32.h, radius: 16.h)
                      : GestureDetector(
                          onTap: () => _handleActionIconTap(context, actionType),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              SizedBox(
                                width: 32.h,
                                height: 32.h,
                                child: Center(
                                  child: Icon(
                                    isActive ? filledIcon : outlineIcon,
                                    size: 32,
                                    color: iconColor,
                                  ),
                                ),
                              ),
                              if (isNotificationIcon && unreadCount > 0)
                                Positioned(
                                  right: -4.h,
                                  top: -4.h,
                                  child: Container(
                                    padding: EdgeInsets.all(4.h),
                                    decoration: BoxDecoration(
                                      color: appTheme.colorFF52D1,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: appTheme.gray_900_02,
                                        width: 1.5.h,
                                      ),
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 18.h,
                                      minHeight: 18.h,
                                    ),
                                    child: Center(
                                      child: Text(
                                        unreadCount > 99
                                            ? '99+'
                                            : unreadCount.toString(),
                                        style: TextStyleHelper
                                            .instance.body10BoldPlusJakartaSans
                                            .copyWith(
                                          color: appTheme.gray_50,
                                          height: 1.0,
                                          fontSize: unreadCount > 99 ? 8.h : 10.h,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                );
              }),
            ],
          ],

          if (widget.showProfileImage) ...[
            SizedBox(width: 8.h),
            isOffline ? _buildCircleSkeleton(size: 54.h) : _buildAuthenticationWidget(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSquareSkeleton({required double size, required double radius}) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: appTheme.blue_gray_900_01,
          borderRadius: BorderRadius.circular(radius),
          // border: Border.all(
          //   color: appTheme.blue_gray_300.withAlpha(40),
          //   width: 1.h,
          // ),
        ),
        // child: Center(
        //   child: Container(
        //     width: size * 0.46,
        //     height: size * 0.46,
        //     decoration: BoxDecoration(
        //       color: appTheme.blue_gray_300.withAlpha(60),
        //       borderRadius: BorderRadius.circular(radius / 2),
        //     ),
        //   ),
        // ),
      ),
    );
  }

  Widget _buildCircleSkeleton({required double size}) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: appTheme.blue_gray_900_01,
          shape: BoxShape.circle,
          // border: Border.all(
          //   color: appTheme.blue_gray_300.withAlpha(40),
          //   width: 1.h,
          // ),
        ),
        // child: Center(
        //   child: Container(
        //     width: size * 0.46,
        //     height: size * 0.46,
        //     decoration: BoxDecoration(
        //       color: appTheme.blue_gray_300.withAlpha(60),
        //       shape: BoxShape.circle,
        //     ),
        //   ),
        // ),
      ),
    );
  }

  Widget _buildAuthenticationWidget(BuildContext context) {
    final userId = ref.watch(avatarStateProvider.select((s) => s.userId));
    final avatarUrl = ref.watch(avatarStateProvider.select((s) => s.avatarUrl));
    final userEmail = ref.watch(avatarStateProvider.select((s) => s.userEmail));
    final isLoading = ref.watch(avatarStateProvider.select((s) => s.isLoading));

    final isAuthenticated = userId != null;

    if (!isAuthenticated) {
      if (isLoading) {
        return Container(
          width: 50.h,
          height: 50.h,
          decoration: BoxDecoration(
            color: appTheme.deep_purple_A100.withAlpha(77),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SizedBox(
              width: 20.h,
              height: 20.h,
              child: CircularProgressIndicator(
                strokeWidth: 2.h,
                valueColor: AlwaysStoppedAnimation<Color>(appTheme.gray_50),
              ),
            ),
          ),
        );
      }

      return GestureDetector(
        onTap: () => _handleLoginButtonTap(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
          decoration: BoxDecoration(
            color: appTheme.deep_purple_A100,
            borderRadius: BorderRadius.circular(8.h),
          ),
          child: Text(
            'Login',
            style: TextStyleHelper.instance.body14BoldPlusJakartaSans.copyWith(
              color: appTheme.gray_50,
            ),
          ),
        ),
      );
    }

    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      _primeAvatarProvider(avatarUrl);
    }

    return GestureDetector(
      onTap: () => _handleProfileTap(context),
      child: _buildUserAvatar(
        avatarUrl: avatarUrl,
        userEmail: userEmail,
        isLoading: isLoading,
      ),
    );
  }

  void _handleLoginButtonTap(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.authLogin);
  }

  // ============================================================
  // AVATAR HELPERS
  // ============================================================

  String _stripQuery(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.replace(query: '').toString();
  }

  void _primeAvatarProvider(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;

    final urlNoQuery = _stripQuery(trimmed);
    final cacheKey = urlNoQuery;

    if (_globalAvatarCacheKey == cacheKey && _globalAvatarProvider != null) {
      _cachedAvatarUrl = urlNoQuery;
      _cachedAvatarProvider = _globalAvatarProvider;
      _maybePrecacheGlobal(cacheKey, _globalAvatarProvider!);
      return;
    }

    final provider = CachedNetworkImageProvider(
      trimmed,
      cacheKey: cacheKey,
      cacheManager: _avatarCacheManager,
    );

    _globalAvatarCacheKey = cacheKey;
    _globalAvatarUrlNoQuery = urlNoQuery;
    _globalAvatarProvider = provider;

    _cachedAvatarUrl = urlNoQuery;
    _cachedAvatarProvider = provider;

    _maybePrecacheGlobal(cacheKey, provider);
  }

  void _maybePrecacheGlobal(String cacheKey, ImageProvider provider) {
    if (_globalPrecachedKey == cacheKey) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_globalPrecachedKey == cacheKey) return;
      _globalPrecachedKey = cacheKey;
      precacheImage(provider, context);
    });
  }

  Widget _buildUserAvatar({
    required String? avatarUrl,
    required String? userEmail,
    required bool isLoading,
  }) {
    final hasUrl = (avatarUrl != null && avatarUrl.trim().isNotEmpty);

    final email = userEmail ?? '';
    final avatarLetter = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    if (hasUrl) {
      _primeAvatarProvider(avatarUrl);
    } else {
      _cachedAvatarUrl = null;
      _cachedAvatarProvider = null;
    }

    final providerToUse = _globalAvatarProvider ?? _cachedAvatarProvider;

    // ===== RING CONFIG =====
    final double avatarSize = 54.h;
    final double ringPadding = 3.h; // thickness of ring
    final Color ringColor = appTheme.blue_gray_900_02;

    // ===== FALLBACK (LETTER AVATAR) =====
    if (!hasUrl || providerToUse == null) {
      return SizedBox(
        width: avatarSize,
        height: avatarSize,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ringColor,
          ),
          padding: EdgeInsets.all(ringPadding),
          child: ClipOval(
            child: Container(
              color: appTheme.deep_purple_A100,
              child: Center(
                child: Text(
                  avatarLetter,
                  style: TextStyleHelper.instance.title18BoldPlusJakartaSans.copyWith(
                    color: appTheme.gray_50,
                    fontSize: 20.h,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ===== IMAGE AVATAR =====
    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ringColor,
        ),
        padding: EdgeInsets.all(ringPadding),
        child: ClipOval(
          child: RepaintBoundary(
            child: Image(
              image: providerToUse,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleWithLeadingLayout() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 36.h, vertical: 4.h),
      child: Row(
        children: [
          if (widget.showLeading)
            GestureDetector(
              onTap: widget.onLeadingTap,
              child: Icon(
                Icons.arrow_back,
                size: 42,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          if (widget.title != null) ...[
            SizedBox(width: 52.h),
            Text(
              widget.title!,
              style: widget.titleTextStyle ??
                  TextStyleHelper.instance.headline28ExtraBoldPlusJakartaSans.copyWith(
                    color: appTheme.gray_50,
                    height: 1.28,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpaceBetweenLayout() {
    return Padding(
      padding: EdgeInsets.fromLTRB(19.h, 14.h, 18.h, 14.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.showLeading)
            GestureDetector(
              onTap: widget.onLeadingTap,
              child: Icon(
                Icons.close,
                size: 26,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          if (widget.title != null)
            Text(
              widget.title!,
              style: widget.titleTextStyle ??
                  TextStyleHelper.instance.title18BoldPlusJakartaSans.copyWith(
                    color: appTheme.blue_A700,
                    height: 1.28,
                  ),
            ),
        ],
      ),
    );
  }

  void _handlePlusButtonTap(BuildContext context) {
    _plusSpinController.forward(from: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CreateMemoryScreen(),
      );
    });
  }

  void _handleActionIconTap(
      BuildContext context, CustomAppBarActionType actionType) {
    if (actionType == CustomAppBarActionType.notifications) {
      NavigatorService.pushNamed(AppRoutes.appNotifications);
    } else if (actionType == CustomAppBarActionType.memories) {
      NavigatorService.pushNamed(AppRoutes.appMemories);
    }
  }

  void _handleProfileTap(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appMenu);
  }

  void _handleLogoTap(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appFeed);
  }

  PreferredSizeWidget? _buildBottomBorder() {
    return PreferredSize(
      preferredSize: Size.fromHeight(1.h),
      child: Container(
        height: 1.h,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: appTheme.blue_gray_900,
              width: 1.h,
            ),
          ),
        ),
      ),
    );
  }
}

enum CustomAppBarLayoutType {
  logoWithActions,
  titleWithLeading,
  spaceBetween,
}

enum CustomAppBarActionType {
  memories,
  notifications,
}
