import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_qr_code_card.dart';

/// QR Timeline Share Screen - For CURRENT USER to SHARE memory QR code
/// This opens when user clicks QR icon on /timeline screen
/// Shows QR code + memory details for sharing with others
class QRTimelineShareScreen extends ConsumerStatefulWidget {
  final String memoryId;

  const QRTimelineShareScreen({
    Key? key,
    required this.memoryId,
  }) : super(key: key);

  @override
  QRTimelineShareScreenState createState() => QRTimelineShareScreenState();
}

class QRTimelineShareScreenState extends ConsumerState<QRTimelineShareScreen> {
  Map<String, dynamic>? _memoryData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isUrlCopied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMemoryDetails();
    });
  }

  /// Fetch memory details from Supabase for QR code generation
  Future<void> _fetchMemoryDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print(
          '🔍 QR TIMELINE SHARE: Fetching memory details for: ${widget.memoryId}');

      // Fetch memory with all necessary details INCLUDING qr_code_url
      final response =
          await SupabaseService.instance.client?.from('memories').select('''
            id,
            title,
            invite_code,
            qr_code_url,
            contributor_count,
            state,
            created_at,
            location_name,
            user_profiles!memories_creator_id_fkey(
              id,
              username,
              display_name,
              avatar_url
            )
          ''').eq('id', widget.memoryId).single();

      if (response == null) {
        setState(() {
          _errorMessage = 'Memory not found';
          _isLoading = false;
        });
        return;
      }

      // Fetch stories count
      final storiesResponse = await SupabaseService.instance.client
          ?.from('stories')
          .select('id')
          .eq('memory_id', widget.memoryId);

      final storiesCount = storiesResponse?.length ?? 0;
      print('✅ QR TIMELINE SHARE: Successfully loaded memory');
      print('   - Title: ${response['title']}');
      print('   - Invite Code: ${response['invite_code']}');
      print('   - QR Code URL: ${response['qr_code_url']}');
      print('   - Stories: $storiesCount');

      // 🔍 ENHANCED DEBUG - Check qr_code_url status
      final rawQrUrl = response['qr_code_url'];
      print('🔍 DEBUG qr_code_url analysis:');
      print('   - Raw value: $rawQrUrl');
      print('   - Type: ${rawQrUrl.runtimeType}');
      print('   - Is null: ${rawQrUrl == null}');
      print('   - Is empty string: ${rawQrUrl == ""}');
      print('   - Full response keys: ${response.keys.toList()}');

      setState(() {
        _memoryData = {
          ...response,
          'stories_count': storiesCount,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('❌ ERROR fetching memory for QR share: $e');
      setState(() {
        _errorMessage = 'Failed to load memory details';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.85,
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
            // Drag handle
            Container(
              width: 40.h,
              height: 4.h,
              decoration: BoxDecoration(
                color: appTheme.colorFF3A3A,
                borderRadius: BorderRadius.circular(2.h),
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
    // Loading state
    if (_isLoading) {
      return Container(
        height: 300.h,
        child: Center(
          child: CircularProgressIndicator(
            color: appTheme.deep_purple_A100,
          ),
        ),
      );
    }

    // Error state
    if (_errorMessage != null || _memoryData == null) {
      return Container(
        height: 300.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48.h,
                color: appTheme.colorFF3A3A,
              ),
              SizedBox(height: 16.h),
              Text(
                _errorMessage ?? 'Failed to load memory',
                style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.white_A700),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              CustomButton(
                text: 'Retry',
                onPressed: _fetchMemoryDetails,
                buttonStyle: CustomButtonStyle.fillPrimary,
                width: 120.h,
              ),
            ],
          ),
        ),
      );
    }

    // Extract data
    final memoryTitle = _memoryData!['title'] as String? ?? 'Untitled Memory';
    final inviteCode = _memoryData!['invite_code'] as String? ?? '';
    final qrCodeUrl = _memoryData!['qr_code_url'] as String?;
    final membersCount = _memoryData!['contributor_count'] as int? ?? 0;
    final storiesCount = _memoryData!['stories_count'] as int? ?? 0;
    final status = _memoryData!['state'] as String? ?? 'open';
    final locationName = _memoryData!['location_name'] as String?;

    // Generate correct deep link URL
    final deepLinkUrl = 'https://capapp.co/join/memory/$inviteCode';

// DEBUG: Log what we extracted
    print('📋 _buildContent data extraction:');
    print('   - inviteCode: "$inviteCode"');
    print('   - qrCodeUrl: "$qrCodeUrl"');
    print('   - deepLinkUrl: "$deepLinkUrl"');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header icon
        // Container(
        //   width: 64.h,
        //   height: 64.h,
        //   decoration: BoxDecoration(
        //     color: appTheme.deep_purple_A100.withAlpha(51),
        //     shape: BoxShape.circle,
        //   ),
        //   child: Icon(
        //     Icons.qr_code_2_rounded,
        //     size: 32.h,
        //     color: appTheme.deep_purple_A100,
        //   ),
        // ),
        SizedBox(height: 16.h),
        Text(
          'Share Memory',
          style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
              .copyWith(color: appTheme.white_A700),
        ),
        SizedBox(height: 8.h),
        Text(
          'Let others scan this QR code to join',
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32.h),
        // QR Code - Display from database or fallback to local generation
        _buildQRCode(deepLinkUrl, qrCodeUrl),
        SizedBox(height: 24.h),
        // Memory title
        Text(
          memoryTitle,
          style: TextStyleHelper.instance.title20BoldPlusJakartaSans
              .copyWith(color: appTheme.white_A700),
          textAlign: TextAlign.center,
        ),
        if (locationName != null) ...[
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 16.h,
                color: appTheme.blue_gray_300,
              ),
              SizedBox(width: 4.h),
              Text(
                locationName,
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ),
        ],
        SizedBox(height: 24.h),
        // Stats
        _buildStatsRow(membersCount, storiesCount, status),
        SizedBox(height: 32.h),
        // Share URL section with correct deep link
        _buildUrlSection(deepLinkUrl),
        SizedBox(height: 24.h),
        // Action buttons with correct deep link
        _buildActionButtons(deepLinkUrl),
        SizedBox(height: 16.h),
        // Helper text
        Text(
          'Anyone who scans this code will be able to join and add stories',
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  /// QR Code widget - Display database image with fallback
  Widget _buildQRCode(String deepLinkUrl, String? qrCodeUrl) {
    return CustomQrCodeCard(
      qrData: deepLinkUrl,     // fallback + generated version
      qrImageUrl: qrCodeUrl,   // preferred if present
      qrSize: 200.h,
      outerPadding: 16.h,
      borderRadius: 16.h,
    );
  }

  /// Stats row showing memory details
  Widget _buildStatsRow(int members, int stories, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(members.toString(), 'Members'),
        Container(
          width: 1.h,
          height: 40.h,
          color: appTheme.blue_gray_300.withAlpha(77),
        ),
        _buildStatItem(stories.toString(), 'Stories'),
        Container(
          width: 1.h,
          height: 40.h,
          color: appTheme.blue_gray_300.withAlpha(77),
        ),
        _buildStatItem(
          status == 'open' ? 'Open' : 'Sealed',
          'Status',
        ),
      ],
    );
  }

  /// Individual stat item
  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
              .copyWith(color: appTheme.white_A700),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300),
        ),
      ],
    );
  }

  /// Share URL section with copy button
  Widget _buildUrlSection(String url) {
    return Container(
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_03,
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              url,
              style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                  .copyWith(color: appTheme.gray_300),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(width: 12.h),
          GestureDetector(
            onTap: _copyUrlToClipboard,
            child: Container(
              padding: EdgeInsets.all(8.h),
              decoration: BoxDecoration(
                color: appTheme.deep_purple_A100.withAlpha(51),
                borderRadius: BorderRadius.circular(8.h),
              ),
              child: Icon(
                _isUrlCopied ? Icons.check : Icons.copy,
                size: 20.h,
                color: appTheme.deep_purple_A100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Action buttons (Download & Share)
  Widget _buildActionButtons(String url) {
    return Row(
      children: [
        SizedBox(width: 12.h),
        Expanded(
          child: CustomButton(
            text: 'Share Link',
            leftIcon: Icons.share,
            onPressed: () => _shareLink(url),
            buttonStyle: CustomButtonStyle.fillPrimary,
            buttonTextStyle: CustomButtonTextStyle.bodyMedium,
          ),
        ),
      ],
    );
  }

  /// Copy URL to clipboard with correct deep link
  void _copyUrlToClipboard() async {
    final inviteCode = _memoryData!['invite_code'] as String;
    final url = 'https://capapp.co/join/memory/$inviteCode';

    await Clipboard.setData(ClipboardData(text: url));

    setState(() {
      _isUrlCopied = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copied to clipboard'),
        backgroundColor: appTheme.colorFF52D1,
        duration: Duration(seconds: 2),
      ),
    );

    // Reset copied state after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isUrlCopied = false;
        });
      }
    });
  }

  /// Download QR code as image
  void _downloadQRCode() {
    // TODO: Implement QR code download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('QR code download feature coming soon'),
        backgroundColor: appTheme.deep_purple_A100,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Share link via system share sheet
  void _shareLink(String url) async {
    final memoryTitle = _memoryData!['title'] as String;

    await Share.share(
      'Join my memory "$memoryTitle" on Capsule:\n$url',
      subject: 'Join Memory on Capsule',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link shared successfully'),
        backgroundColor: appTheme.colorFF52D1,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
