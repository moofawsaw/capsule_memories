import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../services/avatar_state_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'notifier/qr_code_share_screen_two_notifier.dart';

class QRCodeShareScreenTwoScreen extends ConsumerStatefulWidget {
  const QRCodeShareScreenTwoScreen({Key? key}) : super(key: key);

  @override
  QRCodeShareScreenTwoScreenState createState() =>
      QRCodeShareScreenTwoScreenState();
}

class QRCodeShareScreenTwoScreenState
    extends ConsumerState<QRCodeShareScreenTwoScreen> {
  // ✅ Needed for RepaintBoundary (download/share/export QR)
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(qrCodeShareScreenTwoNotifier.notifier).loadUserFriendCode();

      // ✅ Ensure global avatar is loaded for this bottom sheet
      ref.read(avatarStateProvider.notifier).loadCurrentUserAvatar();
    });
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
        final state = ref.watch(qrCodeShareScreenTwoNotifier);

        if (state.isLoading ?? false) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 100.h),
              child: CircularProgressIndicator(
                color: appTheme.colorFF52D1,
              ),
            ),
          );
        }

        if (state.errorMessage != null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 100.h),
              child: Column(
                children: [
                  Text(
                    'Unable to load friend code',
                    style: TextStyleHelper.instance.body16RegularPlusJakartaSans
                        .copyWith(color: appTheme.red_500),
                  ),
                  SizedBox(height: 12.h),
                  CustomButton(
                    text: 'Retry',
                    onPressed: () => ref
                        .read(qrCodeShareScreenTwoNotifier.notifier)
                        .loadUserFriendCode(),
                    buttonStyle: CustomButtonStyle.fillPrimary,
                  ),
                ],
              ),
            ),
          );
        }

        final displayName =
            state.qrCodeShareScreenTwoModel?.displayName ?? 'Add Friend';

        // ✅ Use the user's avatar instead of the mail/icon asset.
        // Assumes your model exposes avatarUrl (common pattern in your codebase).
        final avatarState = ref.watch(avatarStateProvider);

        // ✅ Prefer global cached avatar (already converted to signed URL / oauth URL)
        final avatarUrl = avatarState.avatarUrl?.trim().isNotEmpty == true
            ? avatarState.avatarUrl
            : state.qrCodeShareScreenTwoModel?.avatarUrl;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeaderCard(
              context,
              displayName: displayName,
              avatarUrl: avatarUrl,
            ),
            SizedBox(height: 16.h),
            _buildQRCodeSection(context),
            SizedBox(height: 20.h),
            _buildUrlSection(context),
            SizedBox(height: 20.h),
            _buildActionButtons(context),
            SizedBox(height: 20.h),
            _buildInfoText(context),
            SizedBox(height: 20.h),
          ],
        );
      },
    );
  }

  /// Replaces CustomNotificationCard so we can render a circular avatar.
  Widget _buildHeaderCard(
      BuildContext context, {
        required String displayName,
        required String? avatarUrl,
      }) {
    final initial = (displayName.trim().isNotEmpty)
        ? displayName.trim().characters.first.toUpperCase()
        : '?';

    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900,
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar (replaces mail icon)
          ClipRRect(
            borderRadius: BorderRadius.circular(999.h),
            child: Container(
              height: 54.h,
              width: 54.h,
              color: appTheme.gray_900_02,
              child: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildAvatarFallback(initial);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      height: 18.h,
                      width: 18.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: appTheme.colorFF52D1,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              )
                  : _buildAvatarFallback(initial),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: TextStyleHelper.instance.title16RegularPlusJakartaSans.copyWith(
              color: appTheme.gray_50,
              fontSize: 20.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Scan to add me as friend',
            textAlign: TextAlign.center,
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String initial) {
    return Center(
      child: Text(
        initial,
        style: TextStyleHelper.instance.title16RegularPlusJakartaSans.copyWith(
          color: appTheme.gray_50,
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQRCodeSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(qrCodeShareScreenTwoNotifier);
        final qrData = state.qrCodeShareScreenTwoModel?.qrCodeData ?? '';

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
                data: qrData,
                version: QrVersions.auto,
                size: 200.h,
                padding: EdgeInsets.zero, // ✅ KEY FIX (removes default padding)
                backgroundColor: appTheme.whiteCustom,
                foregroundColor: appTheme.blackCustom,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUrlSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(qrCodeShareScreenTwoNotifier);

        ref.listen(
          qrCodeShareScreenTwoNotifier,
              (previous, current) {
            if (current.isUrlCopied ?? false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Link copied to clipboard'),
                  backgroundColor: appTheme.colorFF52D1,
                ),
              );
            }
          },
        );

        final isCopied = state.isUrlCopied ?? false;
        final url = state.qrCodeShareScreenTwoModel?.shareUrl ?? '';

        return Container(
          margin: EdgeInsets.only(left: 4.h, right: 16.h),
          child: Row(
            spacing: 22.h,
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.h,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: appTheme.gray_900,
                    borderRadius: BorderRadius.circular(8.h),
                  ),
                  child: Text(
                    url,
                    style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                    maxLines: 1, // ✅ single line
                    overflow: TextOverflow.ellipsis, // ✅ ellipsis
                    softWrap: false, // ✅ prevent wrapping
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onTapCopyUrl(context),
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

  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(qrCodeShareScreenTwoNotifier);

        ref.listen(
          qrCodeShareScreenTwoNotifier,
              (previous, current) {
            if (current.isDownloadSuccess ?? false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('QR Code downloaded successfully'),
                  backgroundColor: appTheme.colorFF52D1,
                ),
              );
            }
            if (current.isShareSuccess ?? false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Link shared successfully'),
                  backgroundColor: appTheme.colorFF52D1,
                ),
              );
            }
          },
        );

        return Row(
          spacing: 12.h,
          children: [
            Expanded(
              child: CustomButton(
                text: 'Download QR',
                leftIcon: ImageConstant.imgIcon15,
                onPressed: () => onTapDownloadQR(context),
                buttonStyle: CustomButtonStyle.fillDark,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                padding: EdgeInsets.symmetric(
                  horizontal: 22.h,
                  vertical: 12.h,
                ),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: 'Share Link',
                leftIcon: ImageConstant.imgIcon16,
                onPressed: () => onTapShareLink(context),
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                padding: EdgeInsets.symmetric(
                  horizontal: 30.h,
                  vertical: 12.h,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoText(BuildContext context) {
    return Text(
      'People who scan this code or open the link will be added as your friend automatically',
      style: TextStyleHelper.instance.body14RegularPlusJakartaSans
          .copyWith(color: appTheme.blue_gray_300, height: 1.21),
      textAlign: TextAlign.center,
    );
  }

  void onTapCopyUrl(BuildContext context) {
    ref.read(qrCodeShareScreenTwoNotifier.notifier).copyUrlToClipboard();
  }

  void onTapDownloadQR(BuildContext context) {
    ref.read(qrCodeShareScreenTwoNotifier.notifier).downloadQRCode();
  }

  void onTapShareLink(BuildContext context) {
    ref.read(qrCodeShareScreenTwoNotifier.notifier).shareLink();
  }
}
