import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../core/app_export.dart';

extension ImageTypeExtension on String {
  ImageType get imageType {
    if (startsWith('http') || startsWith('https')) {
      if (endsWith('.svg')) return ImageType.networkSvg;
      return ImageType.network;
    } else if (endsWith('.svg')) {
      return ImageType.svg;
    } else if (startsWith('file://')) {
      return ImageType.file;
    } else {
      return ImageType.png;
    }
  }
}

enum ImageType { svg, png, network, networkSvg, file, unknown }

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
  }) : super(key: key) {
    if (imagePath == null || imagePath!.isEmpty) {
      imagePath = ImageConstant.imgImageNotFound;
    }
  }

  ///[imagePath] is required parameter for showing image
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

  @override
  State<CustomImageView> createState() => _CustomImageViewState();
}

class _CustomImageViewState extends State<CustomImageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  String? _previousImagePath;
  bool _hasAnimationCompleted = false;

  @override
  void initState() {
    super.initState();
    _previousImagePath = widget.imagePath;

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

    if (_isNetworkImage(widget.imagePath)) {
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
      _previousImagePath = widget.imagePath;
      _hasAnimationCompleted = false;

      if (_isNetworkImage(widget.imagePath)) {
        _animationController.reset();
        _animationController.forward();
      } else {
        _animationController.value = 1.0;
        _hasAnimationCompleted = true;
      }
    } else if (!_hasAnimationCompleted && _isNetworkImage(widget.imagePath)) {
      if (_animationController.status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _hasImagePathChanged(String? oldPath, String? newPath) {
    if (oldPath == null && newPath == null) return false;
    if (oldPath == null || newPath == null) return true;
    return oldPath != newPath;
  }

  bool _isNetworkImage(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  // ✅ Prevent Infinity/NaN toInt crashes
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

    if (_isNetworkImage(widget.imagePath)) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: imageContent,
      );
    }

    return imageContent;
  }

  Widget _buildCircleImage() {
    if (widget.radius != null) {
      return ClipRRect(
        borderRadius: widget.radius ?? BorderRadius.zero,
        child: _buildImageWithBorder(),
      );
    } else {
      return _buildImageWithBorder();
    }
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
    } else {
      return _buildImageView();
    }
  }

  Widget _buildImageView() {
    final safeH = _safeFiniteDouble(widget.height);
    final safeW = _safeFiniteDouble(widget.width);

    switch (widget.imagePath!.imageType) {
      case ImageType.svg:
        return SizedBox(
          height: safeH,
          width: safeW,
          child: SvgPicture.asset(
            widget.imagePath!,
            height: safeH,
            width: safeW,
            fit: widget.fit ?? BoxFit.contain,
            colorFilter: widget.color != null
                ? ColorFilter.mode(
                widget.color ?? appTheme.transparentCustom, BlendMode.srcIn)
                : null,
          ),
        );

      case ImageType.file:
        return Image.file(
          File(widget.imagePath!),
          height: safeH,
          width: safeW,
          fit: widget.fit ?? BoxFit.cover,
          color: widget.color,
        );

      case ImageType.networkSvg:
        return SvgPicture.network(
          widget.imagePath!,
          height: safeH,
          width: safeW,
          fit: widget.fit ?? BoxFit.contain,
          colorFilter: widget.color != null
              ? ColorFilter.mode(
              widget.color ?? appTheme.transparentCustom, BlendMode.srcIn)
              : null,
        );

      case ImageType.network:
        final cacheH = _safeCacheDim(widget.height, fallback: 200) * 2;
        final cacheW = _safeCacheDim(widget.width, fallback: 200) * 2;

        return CachedNetworkImage(
          height: safeH,
          width: safeW,
          fit: widget.fit,
          imageUrl: widget.imagePath!,
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

            return Container(
              height: safeH,
              width: safeW,
              decoration: BoxDecoration(
                color: appTheme.grey100,
                borderRadius: widget.radius,
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            appTheme.gray_300.withAlpha(51),
                            appTheme.gray_300.withAlpha(128),
                            appTheme.gray_300.withAlpha(51),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        borderRadius: widget.radius,
                      ),
                    ),
                  ),
                  Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: appTheme.gray_300,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          fadeInDuration: const Duration(milliseconds: 200),
          // ✅ SAFE: never toInt() Infinity/NaN
          memCacheHeight: cacheH,
          memCacheWidth: cacheW,
        );

      case ImageType.png:
      default:
        return Image.asset(
          widget.imagePath!,
          height: safeH,
          width: safeW,
          fit: widget.fit ?? BoxFit.cover,
          color: widget.color,
          errorBuilder: (context, error, stackTrace) {
            print('❌ ASSET LOAD FAILED:');
            print('   Asset Path: ${widget.imagePath}');
            print('   Error: $error');
            print('   Stack Trace: $stackTrace');

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
