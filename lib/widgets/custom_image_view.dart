// lib/widgets/custom_image_view.dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_export.dart';
import '../utils/storage_utils.dart';

extension ImageTypeExtension on String {
  ImageType get imageType {
    final raw = trim();
    if (raw.isEmpty) return ImageType.unknown;

    // ignore query params / fragments when checking extensions
    final normalized = raw.split('?').first.split('#').first;

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      if (normalized.toLowerCase().endsWith('.svg')) return ImageType.networkSvg;
      return ImageType.network;
    } else if (normalized.toLowerCase().endsWith('.svg')) {
      return ImageType.svg;
    } else if (raw.startsWith('file://') || raw.startsWith('/')) {
      return ImageType.file;
    } else {
      return ImageType.png;
    }
  }
}

enum ImageType { svg, png, network, networkSvg, file, unknown }

bool _isEffectivelyEmpty(String? s) {
  final v = (s ?? '').trim().toLowerCase();
  return v.isEmpty || v == 'null' || v == 'undefined';
}

/// Cache: baseKey -> resolved working URL (or '' if none).
final Map<String, String> _categoryIconProbeCache = {};

String? _extractCategoryIconBaseKey(String input) {
  final s = input.trim();
  if (s.isEmpty) return null;

  // If it's a Supabase public URL to the category-icons bucket, extract the object path.
  // Example:
  //   https://<project>.supabase.co/storage/v1/object/public/category-icons/latest.svg
  // -> latest
  final withoutQuery = s.split('?').first.split('#').first;
  const marker = '/storage/v1/object/public/category-icons/';
  if (withoutQuery.contains(marker)) {
    final idx = withoutQuery.indexOf(marker);
    final objectPath = withoutQuery.substring(idx + marker.length);
    if (objectPath.trim().isEmpty) return null;
    final stripped = objectPath.replaceAll(RegExp(r'\.(svg|png|webp|jpg|jpeg)$', caseSensitive: false), '');
    return stripped.trim().isEmpty ? null : stripped.trim();
  }

  // If it's not a Supabase URL, treat as a bucket path or icon name.
  var normalized = s;
  if (normalized.startsWith('/')) normalized = normalized.substring(1);
  if (normalized.startsWith('category-icons/')) {
    normalized = normalized.substring('category-icons/'.length);
  }

  // Strip extension if present; keep subfolders if any.
  normalized = normalized.split('?').first.split('#').first;
  normalized = normalized.replaceAll(
    RegExp(r'\.(svg|png|webp|jpg|jpeg)$', caseSensitive: false),
    '',
  );

  if (normalized.trim().isEmpty) return null;
  return normalized.trim();
}

List<String> _categoryIconCandidateUrlsFromBase(String baseKey) {
  // Preserve folder prefixes (if baseKey contains '/')
  final candidates = <String>[
    '$baseKey.svg',
    '$baseKey.png',
    '$baseKey.webp',
    '$baseKey.jpg',
    '$baseKey.jpeg',
  ];

  // Convert to public URLs in category-icons bucket
  return candidates
      .map(
        (obj) => Supabase.instance.client.storage
            .from('category-icons')
            .getPublicUrl(obj),
      )
      .toList(growable: false);
}

/// Centralized resolver:
/// - If a string is a raw category `icon_name` resolve via StorageUtils.
/// - If already a URL / asset path, leave as-is.
String _resolveMaybeCategoryIcon(String? input) {
  if (_isEffectivelyEmpty(input)) return '';
  final s = input!.trim();
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
    // Could still be a bare filename intended for storage resolution.
    final maybe = StorageUtils.resolveMemoryCategoryIconUrl(s);
    if (maybe.trim().isNotEmpty) return maybe.trim();
    return s;
  }

  // Looks like icon_name
  final looksLikeIconName = !s.contains('/') && !s.contains('.');
  if (looksLikeIconName) {
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
    this.enableCategoryIconResolution = true,

    /// ✅ NEW: if true, only render actual http(s) URLs as images.
    /// Otherwise fallback placeholder is shown (prevents “stretched” assets).
    this.networkOnly = false,

    /// ✅ NEW: Optional widget placeholder when image is missing or fails to load.
    this.placeholderWidget,
  }) : super(key: key) {
    // Do not force an asset fallback here (assets may not exist).
    // Rendering fallback is handled in build based on resolved path.
  }

  final String? imagePath;

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

  final bool enableCategoryIconResolution;

  final bool networkOnly;

  final Widget? placeholderWidget;

  @override
  State<CustomImageView> createState() => _CustomImageViewState();
}

class _CustomImageViewState extends State<CustomImageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _hasAnimationCompleted = false;

  String? _resolvedCategoryOverride;
  String? _lastCategoryProbeKey;

  bool _shouldProbeCategoryIcon(String raw, String resolved) {
    if (!widget.enableCategoryIconResolution) return false;
    if (_isEffectivelyEmpty(raw)) return false;

    // Heuristic: only probe when it looks like a category icon reference.
    // - raw icon name (no extension)
    // - bucket path (category-icons/...)
    // - Supabase public URL to category-icons
    final s = raw.trim();
    final looksLikeIconName = !s.contains('/') && !s.contains('.') && !_isEffectivelyEmpty(s);
    final looksLikeBucketPath = s.contains('category-icons/');
    final looksLikeSupabaseBucketUrl =
        resolved.contains('/storage/v1/object/public/category-icons/');

    return looksLikeIconName || looksLikeBucketPath || looksLikeSupabaseBucketUrl;
  }

  Future<void> _probeAndResolveCategoryIcon(String raw, String resolved) async {
    final baseKey = _extractCategoryIconBaseKey(raw) ??
        _extractCategoryIconBaseKey(resolved);
    if (baseKey == null || baseKey.isEmpty) return;

    if (_lastCategoryProbeKey == baseKey) return;
    _lastCategoryProbeKey = baseKey;

    final cached = _categoryIconProbeCache[baseKey];
    if (cached != null) {
      if (cached.isNotEmpty && mounted) {
        setState(() => _resolvedCategoryOverride = cached);
      }
      return;
    }

    final candidates = _categoryIconCandidateUrlsFromBase(baseKey);
    String found = '';

    for (final url in candidates) {
      try {
        // HEAD is cheaper; fall back to GET on odd servers.
        final uri = Uri.parse(url);
        http.Response resp;
        try {
          resp = await http.head(uri).timeout(const Duration(seconds: 2));
          if (resp.statusCode == 405) {
            resp = await http.get(uri).timeout(const Duration(seconds: 2));
          }
        } catch (_) {
          resp = await http.get(uri).timeout(const Duration(seconds: 2));
        }

        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          found = url;
          break;
        }
      } catch (_) {
        // ignore
      }
    }

    // Cache result (including negative) to avoid repeated network probes.
    _categoryIconProbeCache[baseKey] = found;
    if (!mounted) return;
    if (found.isNotEmpty) {
      setState(() => _resolvedCategoryOverride = found);
    }
  }

  String _resolvedPathOrFallback(String? raw) {
    if (_isEffectivelyEmpty(raw)) return widget.placeHolder ?? '';

    final input = (raw ?? '').trim();

    final resolved = widget.enableCategoryIconResolution
        ? _resolveMaybeCategoryIcon(input)
        : input;

    // If this looks like a category icon (and may have the wrong extension),
    // asynchronously probe for the first existing icon asset and use that.
    if (_resolvedCategoryOverride != null &&
        !_isEffectivelyEmpty(_resolvedCategoryOverride)) {
      return _resolvedCategoryOverride!.trim();
    }

    if (_shouldProbeCategoryIcon(input, resolved)) {
      // Kick off probe (cached) without blocking build.
      Future.microtask(() => _probeAndResolveCategoryIcon(input, resolved));
    }

    if (_isEffectivelyEmpty(resolved)) {
      return widget.placeHolder ?? '';
    }
    return resolved;
  }

  bool _isNetworkImage(String? path) {
    if (_isEffectivelyEmpty(path)) return false;
    final p = path!.trim();
    return p.startsWith('http://') || p.startsWith('https://');
  }

  bool _hasImagePathChanged(String? oldPath, String? newPath) {
    final oldResolved = _resolvedPathOrFallback(oldPath);
    final newResolved = _resolvedPathOrFallback(newPath);
    return oldResolved != newResolved;
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
      _resolvedCategoryOverride = null;
      _lastCategoryProbeKey = null;

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
    final resolved = _resolvedPathOrFallback(widget.imagePath);

    // ✅ If networkOnly is true and this isn't an http(s) URL, force placeholder.
    final effectivePath =
    (widget.networkOnly && !_isNetworkImage(resolved))
        ? (widget.placeHolder ?? '')
        : resolved;

    if (_isEffectivelyEmpty(effectivePath)) {
      return _buildPlaceholder();
    }

    Widget imageContent = Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: InkWell(
        onTap: widget.onTap,
        child: _buildCircleImage(effectivePath),
      ),
    );

    if (_isNetworkImage(effectivePath)) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: imageContent,
      );
    }

    return imageContent;
  }

  Widget _buildPlaceholder() {
    if (widget.placeholderWidget != null) return widget.placeholderWidget!;

    final sizeHint = (widget.height ?? widget.width ?? 24.0).toDouble();
    final iconSize = (sizeHint * 0.55).clamp(14.0, 48.0);
    final iconData = widget.isCircular ? Icons.person_outline : Icons.image_not_supported_outlined;

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: Container(
        height: _safeFiniteDouble(widget.height),
        width: _safeFiniteDouble(widget.width),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: appTheme.gray_900_01.withAlpha(51),
          borderRadius: widget.radius,
          shape: widget.isCircular ? BoxShape.circle : BoxShape.rectangle,
          border: widget.border,
        ),
        child: Icon(
          iconData,
          size: iconSize,
          color: appTheme.blue_gray_300.withAlpha(179),
        ),
      ),
    );
  }

  Widget _buildCircleImage(String resolvedPath) {
    if (widget.isCircular) {
      return ClipOval(
        child: _buildImageWithBorder(resolvedPath),
      );
    }

    if (widget.radius != null) {
      return ClipRRect(
        borderRadius: widget.radius ?? BorderRadius.zero,
        child: _buildImageWithBorder(resolvedPath),
      );
    }

    return _buildImageWithBorder(resolvedPath);
  }

  Widget _buildImageWithBorder(String resolvedPath) {
    if (widget.border != null) {
      return Container(
        decoration: BoxDecoration(
          border: widget.border,
          borderRadius: widget.radius,
        ),
        child: _buildImageView(resolvedPath),
      );
    }
    return _buildImageView(resolvedPath);
  }

  Widget _buildImageView(String resolvedPath) {
    final safeH = _safeFiniteDouble(widget.height);
    final safeW = _safeFiniteDouble(widget.width);

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
            placeholderBuilder: (_) => _buildPlaceholder(),
          ),
        );

      case ImageType.file:
        return Image.file(
          File(resolvedPath.replaceFirst('file://', '')),
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
          placeholderBuilder: (_) => _buildPlaceholder(),
        );

      case ImageType.network:
      // ✅ Match CustomAppBar: render using Image(ImageProvider) for consistent cover behavior.
        final provider = CachedNetworkImageProvider(
          resolvedPath,
          cacheKey: Uri.parse(resolvedPath).replace(query: '').toString(),
          cacheManager: CacheManager(
            Config(
              'capsule_image_cache_v1',
              stalePeriod: const Duration(days: 14),
              maxNrOfCacheObjects: 500,
              repo: JsonCacheInfoRepository(databaseName: 'capsule_image_cache_v1'),
              fileService: HttpFileService(httpClient: http.Client()),
            ),
          ),
        );

        return Image(
          image: provider,
          height: safeH,
          width: safeW,
          fit: widget.fit ?? BoxFit.cover,
          color: widget.color,
          gaplessPlayback: true,
          filterQuality: FilterQuality.low,
          errorBuilder: (_, __, ___) {
            return _buildPlaceholder();
          },
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
            return _buildPlaceholder();
          },
        );
    }
  }
}