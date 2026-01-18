// lib/widgets/custom_image_view.dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../core/app_export.dart';
import '../utils/storage_utils.dart';

extension ImageTypeExtension on String {
  ImageType get imageType {
    final raw = trim();
    if (raw.isEmpty) return ImageType.unknown;

    // ✅ IMPORTANT: ignore query params / fragments when checking extensions
    // ex: road-trip.svg?token=... should still be treated as svg
    String normalized = raw;
    final q = normalized.indexOf('?');
    if (q != -1) normalized = normalized.substring(0, q);
    final h = normalized.indexOf('#');
    if (h != -1) normalized = normalized.substring(0, h);

    if (raw.startsWith('http') || raw.startsWith('https')) {
      if (normalized.toLowerCase().endsWith('.svg')) return ImageType.networkSvg;
      return ImageType.network;
    } else if (normalized.toLowerCase().endsWith('.svg')) {
      return ImageType.svg;
    } else if (raw.startsWith('file://')) {
      return ImageType.file;
    } else {
      return ImageType.png;
    }
  }
}

enum ImageType { svg, png, network, networkSvg, file, unknown }

/// ✅ Centralized resolver:
/// - If a string is a raw category `icon_name` (ex: "road-trip") resolve via StorageUtils.
/// - If already a URL / asset path, leave as-is.
String _resolveMaybeCategoryIcon(String? input) {
  if (input == null) return '';
  final s = input.trim();
  if (s.isEmpty) return s;

  // Already a URL
  if (s.startsWith('http://') || s.startsWith('https://')) return s;

  // Asset-ish
  if (s.startsWith('assets/') || s.startsWith('packages/')) return s;

  // File paths
  if (s.startsWith('file://') || s.startsWith('/')) return s;

  // If it has an extension already, assume it is a filename/path-like string.
  final hasExt =
  RegExp(r'\.(png|jpg|jpeg|webp|svg)$', caseSensitive: false).hasMatch(s);
  if (hasExt) {
    // Could still be a bare filename (road-trip.svg) intended for storage resolution.
    // If it's not an asset path, try resolving it anyway.
    final maybe = StorageUtils.resolveMemoryCategoryIconUrl(s);
    if (maybe.trim().isNotEmpty) return maybe.trim();
    return s;
  }

  // Looks like icon_name
  final looksLikeIconName = !s.contains('/') && !s.contains('.');
  if (looksLikeIconName) {
    // Your bucket uses .svg files, but icon_name in DB is without extension.
    // Try plain name first, then common extensions.
    final direct = StorageUtils.resolveMemoryCategoryIconUrl(s);
    if (direct.trim().isNotEmpty) return direct.trim();

    const exts = <String>['svg', 'png', 'webp', 'jpg', 'jpeg'];
    for (final ext in exts) {
      final candidate = '$s.$ext';
      final resolved = StorageUtils.resolveMemoryCategoryIconUrl(candidate);
      if (resolved.trim().isNotEmpty) return resolved.trim();
    }
  }

  return s;
}

class CustomImageView extends StatefulWidget {
  CustomImageView({
    Key? key,
    this.imagePath,
    this.height,
    this.width,
    this.color,
    this.fit,
    this.alignment,
    this.onTap,
    this.radius,
    this.margin,
    this.border,
    this.placeHolder,
    this.isCircular = false,
  }) : super(key: key) {
    if (imagePath == null || imagePath!.trim().isEmpty) {
      imagePath = ImageConstant.imgImageNotFound;
    }
  }

  late String? imagePath;

  final double? height;
  final double? width;

  final Color? color;
  final BoxFit? fit;

  final String? placeHolder;

  final Alignment? alignment;
  final VoidCallback? onTap;

  final EdgeInsetsGeometry? margin;
  final BorderRadius? radius;
  final BoxBorder? border;

  final bool isCircular;

  @override
  State<CustomImageView> createState() => _CustomImageViewState();
}

class _CustomImageViewState extends State<CustomImageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _hasAnimationCompleted = false;

  String _resolvedPathOrFallback(String? raw) {
    final resolved = _resolveMaybeCategoryIcon(raw);
    if (resolved.trim().isEmpty) return ImageConstant.imgImageNotFound;
    return resolved;
  }

  bool _isNetworkImage(String? path) {
    if (path == null) return false;
    final p = path.trim();
    if (p.isEmpty) return false;
    return p.startsWith('http://') || p.startsWith('https://');
  }

  bool _hasImagePathChanged(String? oldPath, String? newPath) {
    final oldResolved = _resolvedPathOrFallback(oldPath);
    final newResolved = _resolvedPathOrFallback(newPath);
    return oldResolved != newResolved;
  }

  int _safeCacheDim(double? v, {int fallback = 200}) {
    if (v == null) return fallback;
    if (!v.isFinite) return fallback;
    if (v <= 0) return fallback;
    final rounded = v.round();
    return rounded <= 0 ? fallback : rounded;
  }

  double? _safeFiniteDouble(double? v) {
    if (v == null) return null;
    if (!v.isFinite) return null;
    if (v <= 0) return null;
    return v;
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _hasAnimationCompleted = true;
      }
    });

    final currentResolved = _resolvedPathOrFallback(widget.imagePath);

    if (_isNetworkImage(currentResolved)) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
      _hasAnimationCompleted = true;
    }
  }

  @override
  void didUpdateWidget(CustomImageView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool urlChanged =
    _hasImagePathChanged(oldWidget.imagePath, widget.imagePath);

    if (urlChanged) {
      _hasAnimationCompleted = false;

      final resolved = _resolvedPathOrFallback(widget.imagePath);

      if (_isNetworkImage(resolved)) {
        _animationController.reset();
        _animationController.forward();
      } else {
        _animationController.value = 1.0;
        _hasAnimationCompleted = true;
      }
    } else if (!_hasAnimationCompleted) {
      final resolved = _resolvedPathOrFallback(widget.imagePath);
      if (_isNetworkImage(resolved) &&
          _animationController.status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.alignment != null
        ? Align(alignment: widget.alignment!, child: _buildWidget())
        : _buildWidget();
  }

  Widget _buildWidget() {
    Widget imageContent = Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: InkWell(
        onTap: widget.onTap,
        child: _buildCircleImage(),
      ),
    );

    final resolved = _resolvedPathOrFallback(widget.imagePath);

    if (_isNetworkImage(resolved)) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: imageContent,
      );
    }

    return imageContent;
  }

  Widget _buildCircleImage() {
    if (widget.isCircular) {
      return ClipOval(
        child: _buildImageWithBorder(),
      );
    }

    if (widget.radius != null) {
      return ClipRRect(
        borderRadius: widget.radius ?? BorderRadius.zero,
        child: _buildImageWithBorder(),
      );
    }

    return _buildImageWithBorder();
  }

  Widget _buildImageWithBorder() {
    if (widget.border != null) {
      return Container(
        decoration: BoxDecoration(
          border: widget.border,
          borderRadius: widget.radius,
        ),
        child: _buildImageView(),
      );
    }
    return _buildImageView();
  }

  Widget _buildImageView() {
    final safeH = _safeFiniteDouble(widget.height);
    final safeW = _safeFiniteDouble(widget.width);

    final resolvedPath = _resolvedPathOrFallback(widget.imagePath);

    switch (resolvedPath.imageType) {
      case ImageType.svg:
        return SizedBox(
          height: safeH,
          width: safeW,
          child: SvgPicture.asset(
            resolvedPath,
            height: safeH,
            width: safeW,
            fit: widget.fit ?? BoxFit.contain,
            colorFilter: widget.color != null
                ? ColorFilter.mode(
              widget.color ?? appTheme.transparentCustom,
              BlendMode.srcIn,
            )
                : null,
          ),
        );

      case ImageType.file:
        return Image.file(
          File(resolvedPath),
          height: safeH,
          width: safeW,
          fit: widget.fit ?? BoxFit.cover,
          color: widget.color,
        );

      case ImageType.networkSvg:
        return SvgPicture.network(
          resolvedPath,
          height: safeH,
          width: safeW,
          fit: widget.fit ?? BoxFit.contain,
          colorFilter: widget.color != null
              ? ColorFilter.mode(
            widget.color ?? appTheme.transparentCustom,
            BlendMode.srcIn,
          )
              : null,
        );

      case ImageType.network:
        final cacheH = _safeCacheDim(widget.height, fallback: 200) * 2;
        final cacheW = _safeCacheDim(widget.width, fallback: 200) * 2;

        return CachedNetworkImage(
          height: safeH,
          width: safeW,
          fit: widget.fit ?? BoxFit.cover,
          imageUrl: resolvedPath,
          color: widget.color,
          cacheManager: CacheManager(
            Config(
              'customCacheKey',
              stalePeriod: const Duration(days: 7),
              maxNrOfCacheObjects: 200,
              repo: JsonCacheInfoRepository(databaseName: 'customCacheKey'),
              fileService: HttpFileService(
                httpClient: http.Client(),
              ),
            ),
          ),
          placeholder: (context, url) => Container(
            height: safeH,
            width: safeW,
            color: appTheme.grey100,
            child: Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: appTheme.gray_300,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            // If the URL is an svg with query params but got misrouted here,
            // the ImageTypeExtension fix above prevents that now.
            final isInvalidUrl = url.isEmpty ||
                url == 'null' ||
                url == 'undefined' ||
                !url.startsWith('http');

            if (isInvalidUrl) {
              return Image.asset(
                widget.placeHolder ?? ImageConstant.imgImageNotFound,
                height: safeH,
                width: safeW,
                fit: widget.fit ?? BoxFit.cover,
              );
            }

            return Image.asset(
              widget.placeHolder ?? ImageConstant.imgImageNotFound,
              height: safeH,
              width: safeW,
              fit: widget.fit ?? BoxFit.cover,
            );
          },
          fadeInDuration: const Duration(milliseconds: 200),
          memCacheHeight: cacheH,
          memCacheWidth: cacheW,
        );

      case ImageType.png:
      default:
        return Image.asset(
          resolvedPath,
          height: safeH,
          width: safeW,
          fit: widget.fit ?? BoxFit.cover,
          color: widget.color,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              widget.placeHolder ?? ImageConstant.imgImageNotFound,
              height: safeH,
              width: safeW,
              fit: widget.fit ?? BoxFit.cover,
            );
          },
        );
    }
  }
}
