import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/app_export.dart';

/// CustomQrCodeCard
/// Standardizes the Capsule QR presentation:
/// - White rounded background
/// - Consistent outer padding (white border space)
/// - Fixed QR size
/// - Forces QrImageView padding to zero so it matches image-based QRs
class CustomQrCodeCard extends StatelessWidget {
  const CustomQrCodeCard({
    Key? key,
    this.qrData,
    this.qrImageUrl,
    this.assetImagePath,
    this.qrSize,
    this.outerPadding,
    this.borderRadius,
    this.margin,
    this.onImageErrorFallbackToGenerated = true,
  }) : super(key: key);

  /// If provided, renders a generated QR.
  final String? qrData;

  /// If provided, tries to render a remote image QR (storage URL).
  final String? qrImageUrl;

  /// If provided, renders an asset QR image.
  final String? assetImagePath;

  /// Inner QR square size (does NOT include outer white padding).
  final double? qrSize;

  /// White padding around QR content (the “white border”).
  final double? outerPadding;

  /// Card corner radius.
  final double? borderRadius;

  /// Optional margin for positioning in layouts.
  final EdgeInsetsGeometry? margin;

  /// If network image fails, fall back to generated QR (requires qrData).
  final bool onImageErrorFallbackToGenerated;

  @override
  Widget build(BuildContext context) {
    final double size = qrSize ?? 200.h;
    final double pad = outerPadding ?? 16.h;
    final double radius = borderRadius ?? 16.h;

    Widget content;

    final hasNetwork = qrImageUrl != null && qrImageUrl!.trim().isNotEmpty;
    final hasAsset = assetImagePath != null && assetImagePath!.trim().isNotEmpty;
    final hasData = qrData != null && qrData!.trim().isNotEmpty;

    if (hasNetwork) {
      content = Image.network(
        qrImageUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: CircularProgressIndicator(
                color: appTheme.deep_purple_A100,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          if (onImageErrorFallbackToGenerated && hasData) {
            return _buildGeneratedQr(size);
          }
          // If no fallback data, show a simple placeholder box
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Icon(
                Icons.qr_code_2_rounded,
                color: appTheme.gray_900_02,
                size: 36.h,
              ),
            ),
          );
        },
      );
    } else if (hasAsset) {
      content = Image.asset(
        assetImagePath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else {
      // Default to generated QR
      content = _buildGeneratedQr(size);
    }

    return Container(
      margin: margin,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: appTheme.white_A700,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: content,
      ),
    );
  }

  Widget _buildGeneratedQr(double size) {
    final data = (qrData ?? '').trim();

    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      padding: EdgeInsets.zero, // ✅ critical: removes default quiet-zone padding
      backgroundColor: appTheme.white_A700,
      foregroundColor: appTheme.blackCustom,
    );
  }
}