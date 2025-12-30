import '../../core/app_export.dart';
import './models/memory_share_options_model.dart';
import './notifier/memory_share_options_notifier.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';

class MemoryShareOptionsScreen extends ConsumerStatefulWidget {
  const MemoryShareOptionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MemoryShareOptionsScreen> createState() =>
      _MemoryShareOptionsScreenState();
}

class _MemoryShareOptionsScreenState
    extends ConsumerState<MemoryShareOptionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final memoryId = args?['memory_id'] as String? ?? '';
      final memoryName = args?['memory_name'] as String? ?? '';
      ref
          .read(memoryShareOptionsNotifierProvider.notifier)
          .initialize(memoryId, memoryName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(memoryShareOptionsNotifierProvider);
    final notifier = ref.read(memoryShareOptionsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Share Memory',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.fSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: model.isLoading
          ? Center(
              child: CircularProgressIndicator(color: Color(0xFF9C27B0)),
            )
          : model.inviteCode == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.white54, size: 48.fSize),
                      SizedBox(height: 2.h.fSize),
                      Text(
                        'Failed to load sharing options',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 14.fSize),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(4.w.fSize),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Success Header
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(4.w.fSize),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.white, size: 48.fSize),
                              SizedBox(height: 2.h.fSize),
                              Text(
                                'Memory Created!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.fSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 1.h.fSize),
                              Text(
                                model.memoryName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.fSize,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 1.h.fSize),
                              Text(
                                'Your memory is now active with a 12-hour posting window',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.fSize,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 3.h.fSize),

                        // Share Options Section
                        Text(
                          'Share Options',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.fSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2.h.fSize),

                        // Share Link Button
                        _buildShareOptionButton(
                          icon: Icons.link,
                          label: 'Share Link',
                          subtitle: 'Copy invite link to clipboard',
                          onTap: () => notifier.copyLinkToClipboard(context),
                        ),

                        SizedBox(height: 2.h.fSize),

                        // Generate QR Code Button
                        _buildShareOptionButton(
                          icon: Icons.qr_code,
                          label: 'Generate QR Code',
                          subtitle: 'Show scannable QR code',
                          onTap: () => _showQRCodeDialog(context, model),
                        ),

                        SizedBox(height: 3.h.fSize),

                        // Invite Friends Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Invite Friends',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.fSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (model.selectedFriends.isNotEmpty)
                              Text(
                                '${model.selectedFriends.length} selected',
                                style: TextStyle(
                                  color: Color(0xFF9C27B0),
                                  fontSize: 12.fSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),

                        SizedBox(height: 2.h.fSize),

                        // Friends Search Bar
                        TextField(
                          onChanged: notifier.updateFriendSearchQuery,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search friends...',
                            hintStyle: TextStyle(color: Colors.white54),
                            prefixIcon:
                                Icon(Icons.search, color: Colors.white54),
                            filled: true,
                            fillColor: Color(0xFF2A2A2A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 1.5.h.fSize),
                          ),
                        ),

                        SizedBox(height: 2.h.fSize),

                        // Friends List
                        Container(
                          height: 25.h.fSize,
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: model.filteredFriends.isEmpty
                              ? Center(
                                  child: Text(
                                    model.friendSearchQuery.isEmpty
                                        ? 'No friends to invite'
                                        : 'No friends found',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 12.fSize),
                                  ),
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.all(2.w.fSize),
                                  itemCount: model.filteredFriends.length,
                                  separatorBuilder: (context, index) =>
                                      Divider(color: Colors.white10, height: 1),
                                  itemBuilder: (context, index) {
                                    final friend = model.filteredFriends[index];
                                    final isSelected = model.selectedFriends
                                        .contains(friend['id']);

                                    return ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 2.w.fSize, vertical: 0.5.h.fSize),
                                      leading: CircleAvatar(
                                        radius: 20.fSize,
                                        backgroundColor: Color(0xFF9C27B0),
                                        backgroundImage: friend['avatar_url'] !=
                                                    null &&
                                                friend['avatar_url']
                                                    .toString()
                                                    .isNotEmpty
                                            ? NetworkImage(friend['avatar_url'])
                                            : null,
                                        child: friend['avatar_url'] == null ||
                                                friend['avatar_url']
                                                    .toString()
                                                    .isEmpty
                                            ? Text(
                                                (friend['display_name'] ?? 'U')
                                                    .toString()
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14.fSize,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )
                                            : null,
                                      ),
                                      title: Text(
                                        friend['display_name'] ?? 'Unknown',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.fSize,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '@${friend['username'] ?? 'username'}',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12.fSize,
                                        ),
                                      ),
                                      trailing: Checkbox(
                                        value: isSelected,
                                        onChanged: (value) =>
                                            notifier.toggleFriendSelection(
                                                friend['id']),
                                        activeColor: Color(0xFF9C27B0),
                                        checkColor: Colors.white,
                                        side: BorderSide(
                                            color: Colors.white54, width: 1.5),
                                      ),
                                      onTap: () => notifier
                                          .toggleFriendSelection(friend['id']),
                                    );
                                  },
                                ),
                        ),

                        SizedBox(height: 3.h.fSize),

                        // Invite Groups Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Invite Groups',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.fSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (model.selectedGroups.isNotEmpty)
                              Text(
                                '${model.selectedGroups.length} selected',
                                style: TextStyle(
                                  color: Color(0xFF9C27B0),
                                  fontSize: 12.fSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),

                        SizedBox(height: 2.h.fSize),

                        // Groups List
                        Container(
                          height: 20.h.fSize,
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: model.groups.isEmpty
                              ? Center(
                                  child: Text(
                                    'No groups to invite',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 12.fSize),
                                  ),
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.all(2.w.fSize),
                                  itemCount: model.groups.length,
                                  separatorBuilder: (context, index) =>
                                      Divider(color: Colors.white10, height: 1),
                                  itemBuilder: (context, index) {
                                    final group = model.groups[index];
                                    final isSelected = model.selectedGroups
                                        .contains(group['id']);

                                    return ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 2.w.fSize, vertical: 0.5.h.fSize),
                                      leading: CircleAvatar(
                                        radius: 20.fSize,
                                        backgroundColor: Color(0xFF673AB7),
                                        child: Icon(Icons.group,
                                            color: Colors.white, size: 20.fSize),
                                      ),
                                      title: Text(
                                        group['name'] ?? 'Unknown Group',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.fSize,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${group['member_count'] ?? 0} members',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12.fSize,
                                        ),
                                      ),
                                      trailing: Checkbox(
                                        value: isSelected,
                                        onChanged: (value) => notifier
                                            .toggleGroupSelection(group['id']),
                                        activeColor: Color(0xFF9C27B0),
                                        checkColor: Colors.white,
                                        side: BorderSide(
                                            color: Colors.white54, width: 1.5),
                                      ),
                                      onTap: () => notifier
                                          .toggleGroupSelection(group['id']),
                                    );
                                  },
                                ),
                        ),

                        SizedBox(height: 3.h.fSize),

                        // Info Text
                        Container(
                          padding: EdgeInsets.all(3.w.fSize),
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Color(0xFF9C27B0), size: 20.fSize),
                              SizedBox(width: 2.w.fSize),
                              Expanded(
                                child: Text(
                                  'Invitees will receive notifications and can join immediately. Memory remains open for 12 hours.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.fSize,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 3.h.fSize),

                        // Action Buttons
                        Row(
                          children: [
                            if (model.selectedFriends.isNotEmpty ||
                                model.selectedGroups.isNotEmpty)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: model.isSendingInvites
                                      ? null
                                      : () => notifier.sendInvites(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF9C27B0),
                                    padding:
                                        EdgeInsets.symmetric(vertical: 1.8.h.fSize),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: model.isSendingInvites
                                      ? SizedBox(
                                          height: 20.fSize,
                                          width: 20.fSize,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Send Invites',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.fSize,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            if (model.selectedFriends.isNotEmpty ||
                                model.selectedGroups.isNotEmpty)
                              SizedBox(width: 3.w.fSize),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 1.8.h.fSize),
                                  side: BorderSide(color: Color(0xFF9C27B0)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Done',
                                  style: TextStyle(
                                    color: Color(0xFF9C27B0),
                                    fontSize: 14.fSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 2.h.fSize),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildShareOptionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(3.w.fSize),
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w.fSize),
              decoration: BoxDecoration(
                color: Color(0xFF9C27B0).withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Color(0xFF9C27B0), size: 24.fSize),
            ),
            SizedBox(width: 3.w.fSize),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.fSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h.fSize),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12.fSize,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16.fSize),
          ],
        ),
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context, MemoryShareOptionsModel model) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(5.w.fSize),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scan to Join Memory',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h.fSize),
              Text(
                model.memoryName,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.fSize,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h.fSize),
              Container(
                padding: EdgeInsets.all(4.w.fSize),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PrettyQrView.data(
                  data: 'https://capsule.app/join/${model.inviteCode}',
                  decoration: PrettyQrDecoration(
                    shape: PrettyQrSmoothSymbol(
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 3.h.fSize),
              Text(
                'Invite Code: ${model.inviteCode}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.fSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 3.h.fSize),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Share.share(
                          'Join my Capsule memory: ${model.memoryName}\n\nhttps://capsule.app/join/${model.inviteCode}',
                          subject: 'Join ${model.memoryName} on Capsule',
                        );
                      },
                      icon: Icon(Icons.share, size: 18.fSize),
                      label: Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF9C27B0),
                        side: BorderSide(color: Color(0xFF9C27B0)),
                        padding: EdgeInsets.symmetric(vertical: 1.5.h.fSize),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w.fSize),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF9C27B0),
                        padding: EdgeInsets.symmetric(vertical: 1.5.h.fSize),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.fSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}