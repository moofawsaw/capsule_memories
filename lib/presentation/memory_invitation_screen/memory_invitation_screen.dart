import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';

class MemoryInvitationScreen extends ConsumerStatefulWidget {
  final String? memoryId;

  MemoryInvitationScreen({Key? key, this.memoryId}) : super(key: key);

  @override
  MemoryInvitationScreenState createState() => MemoryInvitationScreenState();
}

class MemoryInvitationScreenState
    extends ConsumerState<MemoryInvitationScreen> {
  Map<String, dynamic>? _memoryData;
  bool _isLoading = true;
  String? _errorMessage;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // CRITICAL FIX: Fetch memory details after widget is built to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMemoryDetails();
    });
  }

  /// Fetch memory details from Supabase
  Future<void> _fetchMemoryDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // CRITICAL FIX: Prioritize constructor parameter over route arguments
      String? memoryId = widget.memoryId;

      // Only try ModalRoute if constructor parameter is null
      if (memoryId == null || memoryId.isEmpty) {
        memoryId = ModalRoute.of(context)?.settings.arguments as String?;
      }

      if (memoryId == null || memoryId.isEmpty) {
        setState(() {
          _errorMessage = 'No memory ID provided';
          _isLoading = false;
        });
        return;
      }

      print('🔍 MEMORY INVITATION: Fetching details for memory ID: $memoryId');

      // Fetch memory with creator details
      final response =
          await SupabaseService.instance.client?.from('memories').select('''
            id,
            title,
            invite_code,
            contributor_count,
            state,
            creator_id,
            user_profiles!memories_creator_id_fkey(
              id,
              username,
              display_name,
              avatar_url
            )
          ''').eq('id', memoryId).single();

      if (response == null) {
        setState(() {
          _errorMessage = 'Memory not found';
          _isLoading = false;
        });
        return;
      }

      // Fetch stories count separately
      final storiesResponse = await SupabaseService.instance.client
          ?.from('stories')
          .select('id')
          .eq('memory_id', memoryId);

      final storiesCount = storiesResponse?.length ?? 0;

      print('✅ MEMORY INVITATION: Successfully loaded memory data');
      print('   - Title: ${response['title']}');
      print('   - Invite Code: ${response['invite_code']}');
      print('   - Stories Count: $storiesCount');

      setState(() {
        _memoryData = {
          ...response,
          'stories_count': storiesCount,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('❌ ERROR fetching memory details: $e');
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              appTheme.deep_purple_A100.withAlpha(77),
              appTheme.gray_900_02,
            ],
          ),
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
    // Show loading state
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

    // Show error state
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
            ],
          ),
        ),
      );
    }

    // Extract data
    final creator = _memoryData!['user_profiles'] as Map<String, dynamic>?;
    final memoryTitle = _memoryData!['title'] as String? ?? 'Untitled Memory';
    final inviteCode = _memoryData!['invite_code'] as String? ?? '';
    final membersCount = _memoryData!['contributor_count'] as int? ?? 0;
    final storiesCount = _memoryData!['stories_count'] as int? ?? 0;
    final status = _memoryData!['state'] as String? ?? 'open';
    final creatorName = creator?['display_name'] as String? ??
        creator?['username'] as String? ??
        'Unknown';
    final creatorAvatar = creator?['avatar_url'] as String?;

    // Generate QR code URL
    final qrCodeUrl = 'https://capapp.co/memories/$inviteCode';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 20.h),
        _buildQRCodeSection({
          'qr_code_url': qrCodeUrl,
          'qr_data': inviteCode,
        }),
        SizedBox(height: 24.h),
        _buildMemoryTitle(memoryTitle),
        SizedBox(height: 12.h),
        _buildInvitationMessage("You've been invited to join this memory"),
        SizedBox(height: 32.h),
        _buildCreatorProfile(
          creatorName,
          creatorAvatar,
        ),
        SizedBox(height: 32.h),
        _buildStatsRow(
          membersCount,
          storiesCount,
          status == 'open' ? 'Open' : 'Sealed',
        ),
        SizedBox(height: 40.h),
        _buildJoinButton(context),
        SizedBox(height: 16.h),
        _buildHelperText(),
        SizedBox(height: 20.h),
      ],
    );
  }

  /// Section Widget - QR Code Display
  Widget _buildQRCodeSection(Map<String, dynamic> model) {
    // Check if pre-generated QR code URL exists from backend
    final qrCodeUrl = model['qr_code_url'] as String?;
    final qrData = model['qr_data'] as String? ?? '';

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
          child: (qrCodeUrl != null && qrCodeUrl.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: qrCodeUrl,
                  width: 200.h,
                  height: 200.h,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    width: 200.h,
                    height: 200.h,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      color: appTheme.deep_purple_A100,
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    return QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.h,
                      backgroundColor: appTheme.whiteCustom,
                      foregroundColor: appTheme.blackCustom,
                    );
                  },
                )
              : QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.h,
                  backgroundColor: appTheme.whiteCustom,
                  foregroundColor: appTheme.blackCustom,
                ),
        ),
      ),
    );
  }

  /// Memory icon at the top
  Widget _buildMemoryIcon() {
    return Container(
      width: 80.h,
      height: 80.h,
      decoration: BoxDecoration(
        color: appTheme.deep_purple_A100.withAlpha(51),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.photo_library_rounded,
        size: 40.h,
        color: appTheme.deep_purple_A100,
      ),
    );
  }

  /// Memory title
  Widget _buildMemoryTitle(String title) {
    return Text(
      title,
      style:
          TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans.copyWith(
        color: appTheme.white_A700,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Invitation message
  Widget _buildInvitationMessage(String message) {
    return Text(
      message,
      style: TextStyleHelper.instance.title16RegularPlusJakartaSans.copyWith(
        color: appTheme.blue_gray_300,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Creator profile section
  Widget _buildCreatorProfile(String name, String? imageUrl) {
    return Column(
      children: [
        CircleAvatar(
          radius: 32.h,
          backgroundImage: imageUrl != null && imageUrl.isNotEmpty
              ? NetworkImage(imageUrl)
              : null,
          backgroundColor: appTheme.blue_gray_300,
          child: imageUrl == null || imageUrl.isEmpty
              ? Icon(
                  Icons.person,
                  size: 32.h,
                  color: appTheme.white_A700,
                )
              : null,
        ),
        SizedBox(height: 12.h),
        Text(
          name,
          style: TextStyleHelper.instance.title18BoldPlusJakartaSans.copyWith(
            color: appTheme.white_A700,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Creator',
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans.copyWith(
            color: appTheme.blue_gray_300,
          ),
        ),
      ],
    );
  }

  /// Stats row (Members, Stories, Status)
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
        _buildStatItem(status, 'Status'),
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
              .copyWith(
            color: appTheme.white_A700,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans.copyWith(
            color: appTheme.blue_gray_300,
          ),
        ),
      ],
    );
  }

  /// Join Memory button
  Widget _buildJoinButton(BuildContext context) {
    return CustomButton(
      text: 'Join Memory',
      onPressed: () => onTapJoinMemory(context),
      buttonStyle: CustomButtonStyle.fillPrimary,
      buttonTextStyle: CustomButtonTextStyle.bodyMedium,
    );
  }

  /// Helper text at the bottom
  Widget _buildHelperText() {
    return Text(
      "You'll be able to add your own stories",
      style: TextStyleHelper.instance.body14RegularPlusJakartaSans.copyWith(
        color: appTheme.blue_gray_300,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Navigates to user profile when the user card is tapped
  void onTapUserProfile(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appProfile);
  }

  /// Handles joining the memory invitation
  void onTapJoinMemory(BuildContext context) async {
    if (_memoryData == null) return;

    try {
      final inviteCode = _memoryData!['invite_code'] as String?;
      if (inviteCode == null || inviteCode.isEmpty) {
        throw Exception('Invalid invite code');
      }

      // Call join-memory-by-code edge function
      final response = await SupabaseService.instance.client?.functions
          .invoke('join-memory-by-code', body: {'invite_code': inviteCode});

      if (response?.data != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined memory!'),
            backgroundColor: appTheme.colorFF52D1,
          ),
        );

        // Navigate to memories screen
        Navigator.of(context).pop();
        NavigatorService.pushNamed(AppRoutes.appMemories);
      }
    } catch (e) {
      print('❌ ERROR joining memory: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join memory. Please try again.'),
          backgroundColor: appTheme.colorFF3A3A,
        ),
      );
    }
  }
}