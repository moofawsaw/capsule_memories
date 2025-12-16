import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_qr_info_card.dart';

class GroupQRInviteScreen extends ConsumerStatefulWidget {
  GroupQRInviteScreen({Key? key}) : super(key: key);

  @override
  GroupQRInviteScreenState createState() => GroupQRInviteScreenState();
}

class GroupQRInviteScreenState extends ConsumerState<GroupQRInviteScreen> {
  final GlobalKey _qrKey = GlobalKey();
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlController.text =
        ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.black_900,
        body: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          child: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              height: 848.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.maxFinite,
                      height: 618.h,
                      decoration: BoxDecoration(
                        color: appTheme.gray_900_02,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(26.h),
                          topRight: Radius.circular(26.h),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: double.maxFinite,
                      height: double.maxFinite,
                      padding: EdgeInsets.all(22.h),
                      decoration: BoxDecoration(
                        color: appTheme.color5B0000,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 228.h),
                          Container(
                            width: 116.h,
                            height: 12.h,
                            decoration: BoxDecoration(
                              color: appTheme.color3BD81E,
                              borderRadius: BorderRadius.circular(6.h),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          CustomQrInfoCard(
                            title: "Jones Family",
                            description: "Scan to join the group",
                          ),
                          SizedBox(height: 16.h),
                          _buildQRCodeSection(),
                          SizedBox(height: 20.h),
                          _buildUrlSection(),
                          SizedBox(height: 20.h),
                          _buildActionButtons(),
                          SizedBox(height: 20.h),
                          _buildInfoText(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildQRCodeSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 68.h),
      child: RepaintBoundary(
        key: _qrKey,
        child: Container(
          padding: EdgeInsets.all(16.h),
          decoration: BoxDecoration(
            color: appTheme.whiteCustom,
            borderRadius: BorderRadius.circular(12.h),
          ),
          child: QrImageView(
            data: _urlController.text,
            version: QrVersions.auto,
            size: 200.h,
            backgroundColor: appTheme.whiteCustom,
            foregroundColor: appTheme.blackCustom,
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildUrlSection() {
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
                _urlController.text,
                style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(width: 22.h),
          GestureDetector(
            onTap: () => _copyUrl(),
            child: CustomImageView(
              imagePath: ImageConstant.imgIcon14,
              height: 24.h,
              width: 24.h,
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildActionButtons() {
    return Container(
      child: Row(
        children: [
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                return GestureDetector(
                  onTap: () => _downloadQR(),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 22.h, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: appTheme.color41C124,
                      borderRadius: BorderRadius.circular(6.h),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomImageView(
                          imagePath: ImageConstant.imgIcon15,
                          height: 18.h,
                          width: 18.h,
                        ),
                        SizedBox(width: 8.h),
                        Text(
                          "Download QR",
                          style: TextStyleHelper
                              .instance.body14BoldPlusJakartaSans
                              .copyWith(color: appTheme.gray_50),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: GestureDetector(
              onTap: () => _shareLink(),
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
      ),
    );
  }

  /// Section Widget
  Widget _buildInfoText() {
    return Container(
      child: Text(
        "People who scan this code or open the link will be added to your group",
        textAlign: TextAlign.center,
        style: TextStyleHelper.instance.body14RegularPlusJakartaSans
            .copyWith(color: appTheme.blue_gray_300, height: 1.2),
      ),
    );
  }

  /// Copy URL to clipboard
  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: _urlController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copied to clipboard'),
        backgroundColor: appTheme.colorFF52D1,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Download QR code as image
  Future<void> _downloadQR() async {
    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // Get the downloads directory
        final directory = await getApplicationDocumentsDirectory();
        final String fileName =
            'jones_family_qr_${DateTime.now().millisecondsSinceEpoch}.png';
        final File file = File('${directory.path}/$fileName');

        await file.writeAsBytes(pngBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR code saved successfully'),
            backgroundColor: appTheme.colorFF52D1,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download QR code'),
          backgroundColor: appTheme.redCustom,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Share the group invitation link
  void _shareLink() {
    Share.share(
      'Join the Jones Family group on Capsule! ${_urlController.text}',
      subject: 'Join Jones Family on Capsule',
    );
  }
}
