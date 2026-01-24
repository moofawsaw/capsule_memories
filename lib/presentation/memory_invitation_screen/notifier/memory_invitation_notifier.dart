import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

class MemoryInvitationState {
  final Map<String, dynamic>? memoryInvitationModel;
  final bool isLoading;
  final bool isDownloading;
  final bool isSharing;
  final bool downloadSuccess;
  final bool shareSuccess;
  final bool copySuccess;
  final String? errorMessage;

  MemoryInvitationState({
    this.memoryInvitationModel,
    this.isLoading = false,
    this.isDownloading = false,
    this.isSharing = false,
    this.downloadSuccess = false,
    this.shareSuccess = false,
    this.copySuccess = false,
    this.errorMessage,
  });
}

final memoryInvitationNotifier = StateNotifierProvider.autoDispose<
    MemoryInvitationNotifier, MemoryInvitationState>(
  (ref) => MemoryInvitationNotifier(
    MemoryInvitationState(
      memoryInvitationModel: null,
    ),
  ),
);

class MemoryInvitationNotifier extends StateNotifier<MemoryInvitationState> {
  MemoryInvitationNotifier(MemoryInvitationState state) : super(state);

  /// Initialize with memory ID to load real data
  Future<void> initialize(String memoryId) async {
    state = MemoryInvitationState(
      memoryInvitationModel: null,
      isLoading: true,
      errorMessage: null,
    );

    try {
      final memoryData = await _fetchMemoryData(memoryId);

      if (memoryData != null && mounted) {
        final inviteCode = memoryData['invite_code'] as String;
        final memoryTitle = memoryData['title'] as String;
        final qrCodeUrl = memoryData['qr_code_url'] as String?;
        final inviteUrl = 'https://capapp.co/join/memory/$inviteCode';

        state = MemoryInvitationState(
          isLoading: false,
          memoryInvitationModel: {
            'id': memoryData['id'] as String,
            'name': memoryTitle,
            'url': inviteUrl,
            'qr_data': inviteUrl,
            'qr_code_url': qrCodeUrl,
            'description': 'Scan to join the memory',
            'icon': Icons.qr_code_2_rounded,
          },
        );
      } else if (mounted) {
        state = MemoryInvitationState(
          memoryInvitationModel: null,
          isLoading: false,
          errorMessage: 'Failed to load memory data',
        );
      }
    } catch (e) {
      if (mounted) {
        state = MemoryInvitationState(
          memoryInvitationModel: null,
          isLoading: false,
          errorMessage: 'Error loading memory: ${e.toString()}',
        );
      }
    }
  }

  /// Fetch memory data from Supabase
  Future<Map<String, dynamic>?> _fetchMemoryData(String memoryId) async {
    try {
      final response =
          await SupabaseService.instance.client?.from('memories').select('''
            id,
            title,
            invite_code,
            qr_code_url,
            created_at,
            updated_at
          ''').eq('id', memoryId).single();

      return response;
    } catch (e) {
      print('Error fetching memory data: $e');
      return null;
    }
  }

  void updateUrl(String newUrl) {
    final updatedModel = Map<String, dynamic>.from(null ?? {})
      ..['url'] = newUrl
      ..['qr_data'] = newUrl;

    state = MemoryInvitationState(
      memoryInvitationModel: updatedModel,
    );
  }

  void onDownloadQR() {
    state = MemoryInvitationState(
      memoryInvitationModel: null,
      isDownloading: true,
    );

    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        state = MemoryInvitationState(
          memoryInvitationModel: null,
          isDownloading: false,
          downloadSuccess: true,
        );
      }
    });
  }

  void onShareLink() {
    state = MemoryInvitationState(
      memoryInvitationModel: null,
      isSharing: true,
    );

    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        state = MemoryInvitationState(
          memoryInvitationModel: null,
          isSharing: false,
          shareSuccess: true,
        );
      }
    });
  }

  void onCopyUrl() {
    state = MemoryInvitationState(
      memoryInvitationModel: null,
      copySuccess: true,
    );

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        state = MemoryInvitationState(
          memoryInvitationModel: null,
          copySuccess: false,
        );
      }
    });
  }

  void resetActions() {
    state = MemoryInvitationState(
      memoryInvitationModel: null,
      downloadSuccess: false,
      shareSuccess: false,
      copySuccess: false,
    );
  }
}
