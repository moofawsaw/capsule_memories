// lib/presentation/group_qr_invite_screen/group_qr_invite_screen.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_qr_info_card.dart';
import './models/group_qr_invite_model.dart';
import 'notifier/group_qr_invite_notifier.dart';

class GroupQRInviteScreen extends ConsumerStatefulWidget {
  const GroupQRInviteScreen({Key? key}) : super(key: key);

  @override
  GroupQRInviteScreenState createState() => GroupQRInviteScreenState();
}

class GroupQRInviteScreenState extends ConsumerState<GroupQRInviteScreen> {
  final GlobalKey _qrKey = GlobalKey();
  String? _groupId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get group ID from route arguments
    if (_groupId == null) {
      _groupId = ModalRoute.of(context)?.settings.arguments as String?;

      if (_groupId != null) {
        // Initialize notifier with group ID
        Future.microtask(() {
          ref.read(groupQRInviteNotifier.notifier).initialize(_groupId!);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: appTheme.gray_900_02,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.h),
            topRight: Radius.circular(20.h),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            // Drag handle indicator
            Container(
              width: 48.h,
              height: 5.h,
              decoration: BoxDecoration(
                color: appTheme.colorFF3A3A,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            SizedBox(height: 20.h),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.h),
                child: _buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupQRInviteNotifier);
        final model = state.groupQRInviteModel;

        if (state.isLoading == true) {
          return Container(
            height: 400.h,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              color: appTheme.deep_purple_A100,
            ),
          );
        }

        if (state.errorMessage != null) {
          return Container(
            height: 400.h,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    color: appTheme.redCustom, size: 48.h),
                SizedBox(height: 16.h),
                Text(
                  state.errorMessage!,
                  style: TextStyleHelper.instance.body16RegularPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (model == null) {
          return SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomQrInfoCard(
              title: model.groupName ?? "Group",
              description: model.groupDescription ?? "Scan to join",
            ),
            SizedBox(height: 16.h),
            _buildQRCodeSection(model),
            SizedBox(height: 20.h),
            _buildUrlSection(model),
            SizedBox(height: 20.h),
            _buildActionButtons(model),
            SizedBox(height: 20.h),
            _buildInfoText(),
            SizedBox(height: 20.h),
          ],
        );
      },
    );
  }

  /// QR Code section
  Widget _buildQRCodeSection(GroupQRInviteModel model) {
    final qrCodeUrl = model.qrCodeUrl;

    const double qrSize = 200;
    const double containerPadding = 12;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 68.h),
      child: RepaintBoundary(
        key: _qrKey,
        child: Container(
          padding: EdgeInsets.all(containerPadding.h),
          decoration: BoxDecoration(
            color: appTheme.whiteCustom,
            borderRadius: BorderRadius.circular(12.h),
          ),
          child: SizedBox(
            width: qrSize.h,
            height: qrSize.h,
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover, // crops baked padding for symmetry
                child: SizedBox(
                  width: qrSize,
                  height: qrSize,
                  child: (qrCodeUrl != null && qrCodeUrl.isNotEmpty)
                      ? _buildQrFromUrl(
                    qrCodeUrl,
                    qrSize,
                    fallbackData:
                    model.qrCodeData ?? model.invitationUrl ?? '',
                  )
                      : SizedBox(
                    width: qrSize,
                    height: qrSize,
                    child: Center(
                      child: Icon(
                        Icons.error_outline,
                        color: appTheme.gray_400,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ Supports both SVG and raster URLs (png/jpg/webp).
  /// SVG URLs must use flutter_svg; raster can use CachedNetworkImage.
  Widget _buildQrFromUrl(
      String url,
      double size, {
        required String fallbackData,
      }) {
    final lower = url.toLowerCase();
    final isSvg = lower.endsWith('.svg') || lower.contains('.svg?');

    if (isSvg) {
      return FutureBuilder<File>(
        future: DefaultCacheManager().getSingleFile(url),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: CircularProgressIndicator(
                  color: appTheme.deep_purple_A100,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            // fallback to generated QR if available, else icon
            if (fallbackData.isNotEmpty) {
              return QrImageView(
                data: fallbackData,
                version: QrVersions.auto,
                size: size,
                backgroundColor: appTheme.whiteCustom,
              );
            }
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: appTheme.gray_400,
                  size: 32,
                ),
              ),
            );
          }

          return SvgPicture.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => SizedBox(
              width: size,
              height: size,
              child: Center(
                child: CircularProgressIndicator(
                  color: appTheme.deep_purple_A100,
                ),
              ),
            ),
          );
        },
      );
    }

    // Raster images (png/jpg/webp/gif)
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholder: (context, _) => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: CircularProgressIndicator(
            color: appTheme.deep_purple_A100,
          ),
        ),
      ),
      errorWidget: (context, _, __) {
        if (fallbackData.isNotEmpty) {
          return QrImageView(
            data: fallbackData,
            version: QrVersions.auto,
            size: size,
            backgroundColor: appTheme.whiteCustom,
          );
        }
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: appTheme.gray_400,
              size: 32,
            ),
          ),
        );
      },
    );
  }

  /// URL section (✅ animated copy button, same pattern as friend QR screen)
  Widget _buildUrlSection(GroupQRInviteModel model) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupQRInviteNotifier);
        final isCopied = state.copySuccess == true;

        return Container(
          margin: EdgeInsets.only(right: 16.h, left: 4.h),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: appTheme.gray_900,
                    borderRadius: BorderRadius.circular(8.h),
                  ),
                  child: Text(
                    model.invitationUrl ?? '',
                    style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ),
              SizedBox(width: 22.h),

              // ✅ Copy animation: AnimatedContainer + AnimatedSwitcher (copy -> check)
              GestureDetector(
                onTap: () => _copyUrl(model.invitationUrl ?? ''),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.all(10.h),
                  decoration: BoxDecoration(
                    color: isCopied
                        ? appTheme.colorFF52D1.withAlpha(51)
                        : appTheme.deep_purple_A100.withAlpha(51),
                    borderRadius: BorderRadius.circular(10.h),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      isCopied ? Icons.check : Icons.copy,
                      key: ValueKey<bool>(isCopied),
                      size: 20.h,
                      color: isCopied
                          ? appTheme.colorFF52D1
                          : appTheme.deep_purple_A100,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Action buttons
  Widget _buildActionButtons(GroupQRInviteModel model) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _downloadQR(model.groupName ?? 'group'),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 22.h, vertical: 12.h),
              decoration: BoxDecoration(
                color: appTheme.color41C124,
                borderRadius: BorderRadius.circular(6.h),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_rounded, color: appTheme.white_A700, size: 18.h),
                  SizedBox(width: 8.h),
                  Text(
                    "Download",
                    style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                        .copyWith(color: appTheme.white_A700),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 12.h),
        Expanded(
          child: GestureDetector(
            onTap: () => _shareLink(
              model.groupName ?? 'group',
              model.invitationUrl ?? '',
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 30.h, vertical: 12.h),
              decoration: BoxDecoration(
                color: appTheme.deep_purple_A100,
                borderRadius: BorderRadius.circular(6.h),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgIcon16,
                    height: 18.h,
                    width: 18.h,
                  ),
                  SizedBox(width: 8.h),
                  Text(
                    "Share Link",
                    style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                        .copyWith(color: appTheme.white_A700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Info text
  Widget _buildInfoText() {
    return Text(
      "People who scan this code or open the link will be added to your group instantly",
      textAlign: TextAlign.center,
      style: TextStyleHelper.instance.body14RegularPlusJakartaSans
          .copyWith(color: appTheme.blue_gray_300, height: 1.2),
    );
  }

  /// Copy URL to clipboard
  void _copyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ref.read(groupQRInviteNotifier.notifier).onCopyUrl();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copied to clipboard'),
        backgroundColor: appTheme.colorFF52D1,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Download QR code as image
  Future<void> _downloadQR(String groupName) async {
    try {
      ref.read(groupQRInviteNotifier.notifier).onDownloadQR();

      final boundary =
      _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        final directory = await getApplicationDocumentsDirectory();
        final sanitizedName =
        groupName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
        final String fileName =
            '${sanitizedName}_qr_${DateTime.now().millisecondsSinceEpoch}.png';
        final File file = File('${directory.path}/$fileName');

        await file.writeAsBytes(pngBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('QR code saved successfully'),
              backgroundColor: appTheme.colorFF52D1,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download QR code'),
            backgroundColor: appTheme.redCustom,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Share the group invitation link
  void _shareLink(String groupName, String url) {
    ref.read(groupQRInviteNotifier.notifier).onShareLink();

    Share.share(
      'Join the $groupName group on Capsule! $url',
      subject: 'Join $groupName on Capsule',
    );
  }
}
