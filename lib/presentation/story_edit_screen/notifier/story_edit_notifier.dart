// lib/presentation/story_edit_screen/notifier/story_edit_notifier.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'preupload_state.dart';
import 'story_edit_state.dart';

import '../../../services/network_quality_service.dart';
import '../../../services/story_service.dart';
import '../../../services/supabase_service.dart';
import '../../../services/supabase_tus_uploader.dart' as tus;
import '../../../services/video_compression_service.dart';
import '../../../services/location_service.dart';
import '../models/story_edit_model.dart';

final storyEditProvider =
StateNotifierProvider.autoDispose<StoryEditNotifier, StoryEditState>(
      (ref) => StoryEditNotifier(),
);

class StoryEditNotifier extends StateNotifier<StoryEditState> {
  StoryEditNotifier() : super(const StoryEditState());

  final _supabase = SupabaseService.instance.client!;
  final _uuid = const Uuid();
  final _storyService = StoryService();

  tus.SupabaseTusUploader get _tus => SupabaseService.instance.sharedTusUploader;

  // Storage objects (relative paths inside bucket)
  String? _activeMediaObject; // videos/<id>.mp4
  String? _activeThumbObject; // thumbnails/<id>.jpg

  // The one true “pending story id” chosen at record-stop time.
  String? _pendingStoryId;
  String? _pendingVideoPath; // videos/<pendingStoryId>.mp4
  String? _pendingThumbPath; // thumbnails/<pendingStoryId>.jpg

  bool _preuploadCancelled = false;
  bool _shareCommitted = false;

  // Critical: keep the ONE preupload future so Share can await it (no re-upload)
  Future<void>? _preuploadFuture;

  // ✅ Location prefetch (best-effort) so Share isn't blocked by GPS/geocode.
  Future<Map<String, dynamic>?>? _locationPrefetchFuture;

  // One-time warmup per notifier lifetime
  bool _didWarmup = false;

  static const int _mb = 1024 * 1024;
  static const int _wifiCompressThresholdBytes = 18 * _mb;
  static const int _cellCompressThresholdBytes = 8 * _mb;

  int? _recordedDurationSeconds;

  @override
  void dispose() {
    super.dispose();
  }

  // -------------------------
  // PUBLIC API
  // -------------------------
  void initializeScreen({
    required String mediaPath,
    required bool isVideo,
    required String memoryId,
    int? recordedDurationSeconds,
    double? prefetchedLocationLat,
    double? prefetchedLocationLng,
    String? prefetchedLocationName,
  }) {
    state = state.copyWith(isLoading: false);

    // Warm cheap stuff (filesystem, network stack, tus store, tls handshake)
    _warmupPipeline();

    // ✅ Make prewarm finish BEFORE the first upload begins (fire-and-forget, but early)
    unawaited(SupabaseService.instance.sharedTusUploader.prewarm(
      timeout: const Duration(seconds: 6),
      alsoWarmUrlStore: true,
    ));

    // ✅ TRUE network/TLS warmup BEFORE any upload requests start
    unawaited(_tus.prewarm(
      timeout: const Duration(seconds: 6),
      alsoWarmUrlStore: true,
    ));

    // If the recorder already prefetched location, reuse it (don't prompt again).
    if (prefetchedLocationLat != null || prefetchedLocationLng != null) {
      _locationPrefetchFuture = Future.value(<String, dynamic>{
        'lat': prefetchedLocationLat,
        'lng': prefetchedLocationLng,
        'location_name': (prefetchedLocationName ?? '').trim().isNotEmpty
            ? prefetchedLocationName
            : null,
      });
    } else if (prefetchedLocationName != null &&
        prefetchedLocationName.trim().isNotEmpty) {
      // Name-only is still useful for UI; keep it around.
      _locationPrefetchFuture = Future.value(<String, dynamic>{
        'lat': null,
        'lng': null,
        'location_name': prefetchedLocationName.trim(),
      });
    }

    // Start location prefetch for BOTH image + video stories.
    _startLocationPrefetch();

    if (isVideo) {
      _pendingStoryId = _uuid.v4();
      _pendingVideoPath = 'videos/${_pendingStoryId!}.mp4';
      _pendingThumbPath = 'thumbnails/${_pendingStoryId!}.jpg';

      _recordedDurationSeconds = recordedDurationSeconds;
      unawaited(startPreupload(memoryId: memoryId, mediaPath: mediaPath));
    }
  }

  Future<void> cancelAndCleanupPreupload() async {
    await cancelPreuploadAndCleanup();
  }

  Future<String?> finalizeShare({
    required String memoryId,
    required String mediaPath,
    required bool isVideo,
    required String caption,
  }) async {
    return uploadAndShareStory(
      memoryId: memoryId,
      mediaPath: mediaPath,
      isVideo: isVideo,
      caption: caption,
    );
  }

  void updateCaption(String caption) {
    state = state.copyWith(caption: caption);
  }

  void addTextOverlay(TextOverlay overlay) {
    state = state.copyWith(textOverlays: [...state.textOverlays, overlay]);
  }

  void addSticker(String stickerUrl) {
    state = state.copyWith(stickers: [...state.stickers, stickerUrl]);
  }

  void addDrawing(Drawing drawing) {
    state = state.copyWith(drawings: [...state.drawings, drawing]);
  }

  void setBackgroundMusic(String musicUrl) {
    state = state.copyWith(backgroundMusic: musicUrl);
  }

  void _setStage(String? s) {
    state = state.copyWith(uploadStage: s);
  }

  // -------------------------
  // WARMUP (reduces first-upload cold start)
  // -------------------------
  void _warmupPipeline() {
    if (_didWarmup) return;
    _didWarmup = true;

    unawaited(() async {
      try {
        // 1) Touch auth/session (forces lazy init paths earlier)
        _supabase.auth.currentUser?.id;

        // 2) Warm directories + store file (common first-time delay)
        final supportDir = await getApplicationSupportDirectory();
        final storeDir = Directory('${supportDir.path}/tus_upload_store');
        if (!await storeDir.exists()) {
          await storeDir.create(recursive: true);
        }

        final storeFile = File('${storeDir.path}/tus_urls.json');
        if (await storeFile.exists()) {
          // read once (warms filesystem cache)
          await storeFile.readAsString().catchError((_) => '');
        }

        // 3) Warm network quality (so first upload doesn’t wait on it)
        await NetworkQualityService.getQuality()
            .catchError((_) => NetworkQuality.unknown);

        // 4) Force-create uploader instance (ensures any lazy setup happens now)
        // ignore: unused_local_variable
        final uploader = SupabaseService.instance.sharedTusUploader;
      } catch (_) {
        // Best-effort only
      }
    }());
  }

  void _startLocationPrefetch() {
    if (_locationPrefetchFuture != null) return;

    _locationPrefetchFuture = () async {
      try {
        // Keep same timeouts as StoryService, but do it early while preupload is running.
        Map<String, dynamic>? coords;
        try {
          coords = await LocationService.getCoordsOnly(
            timeout: const Duration(seconds: 3),
          );
        } catch (_) {
          coords = null;
        }

        final double? lat = (coords?['latitude'] as num?)?.toDouble();
        final double? lng = (coords?['longitude'] as num?)?.toDouble();

        String? locationName;
        if (lat != null && lng != null) {
          try {
            locationName = await LocationService.getLocationNameBestEffort(
              lat,
              lng,
              timeout: const Duration(seconds: 6),
            );
          } catch (_) {
            locationName = null;
          }
        }

        return <String, dynamic>{
          'lat': lat,
          'lng': lng,
          'location_name': locationName,
        };
      } catch (_) {
        return null;
      }
    }();
  }

  // -------------------------
  // HELPERS
  // -------------------------

  // Ensures we ALWAYS store relative storage paths in DB/state.
  // If something passed a full public URL by mistake, strip it back to videos/... or thumbnails/...
  String _normalizeStoragePath(String input) {
    var v = input.trim();

    // If it's a full URL like:
    // https://<proj>.supabase.co/storage/v1/object/public/story-media/videos/<id>.mp4
    // strip everything up to "/story-media/"
    const marker = '/story-media/';
    final idx = v.indexOf(marker);
    if (idx != -1) {
      v = v.substring(idx + marker.length);
    }

    // Also handle cases like "/videos/..."
    if (v.startsWith('/')) v = v.substring(1);

    return v;
  }

  Future<File?> _generateVideoThumbnail(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath =
          '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 75,
        timeMs: 1000,
      );

      if (thumbnail == null) return null;
      return File(thumbnail);
    } catch (_) {
      return null;
    }
  }

  Future<int> _getVideoDuration(String videoPath) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      final duration = controller.value.duration.inSeconds;
      return duration > 0 ? duration : 10;
    } catch (_) {
      return 10;
    } finally {
      try {
        await controller?.dispose();
      } catch (_) {}
    }
  }

  Future<void> _cleanupUploadedFiles(List<String> paths) async {
    for (final p in paths) {
      try {
        await _supabase.storage.from('story-media').remove([p]);
      } catch (_) {}
    }
  }

  bool _shouldCompress(NetworkQuality net, int bytes) {
    if (bytes <= 0) return false;
    if (net == NetworkQuality.wifi) return bytes >= _wifiCompressThresholdBytes;
    return bytes >= _cellCompressThresholdBytes;
  }

  Duration _compressionTimeout(NetworkQuality net) {
    if (net == NetworkQuality.wifi) return const Duration(seconds: 20);
    return const Duration(seconds: 40);
  }

  int _chunkSizeFor(NetworkQuality net) {
    return (net == NetworkQuality.wifi)
        ? tus.SupabaseTusUploader.defaultChunkWifi
        : tus.SupabaseTusUploader.defaultChunkCell;
  }

  Duration _requestTimeoutFor(NetworkQuality net) {
    return const Duration(seconds: 45);
  }

  Future<void> _ensureContributorForMemory({
    required String memoryId,
    required String userId,
  }) async {
    try {
      await _supabase.from('memory_contributors').upsert(
        {'memory_id': memoryId, 'user_id': userId},
        onConflict: 'memory_id,user_id',
      );
    } catch (_) {
      // do not block share
    }
  }

  // -------------------------
  // PREUPLOAD (STORAGE ONLY)
  // -------------------------
  Future<void> startPreupload({
    required String memoryId,
    required String mediaPath,
  }) async {
    // If already started, do not start again.
    if (_preuploadFuture != null) return;

    if (state.preuploadState == PreuploadState.uploading ||
        state.preuploadState == PreuploadState.ready ||
        state.preuploadState == PreuploadState.preparing) {
      return;
    }

    _preuploadCancelled = false;
    _shareCommitted = false;

    state = state.copyWith(
      preuploadState: PreuploadState.preparing,
      preuploadError: null,
      preuploadedMediaObjectName: null,
      preuploadedThumbObjectName: null,
      preuploadIsVideo: true,
      mediaProgress: 0.0,
      thumbProgress: 0.0,
      uploadStage: 'Preparing upload...',
    );

    _preuploadFuture = _runPreupload(mediaPath).whenComplete(() {
      // Allow a new preupload on next recording
      _preuploadFuture = null;

      // Clear the stage if share isn't happening
      if (!state.isUploading) {
        _setStage(null);
      }
    });
  }

  Future<void> _runPreupload(String mediaPath) async {
    File? tempThumb;
    File? tempCompressed;

    // Basic timing logs (helps confirm what is eating the 30s)
    final swAll = Stopwatch()..start();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final originalFile = File(mediaPath);
      if (!await originalFile.exists()) throw Exception('Media file not found');

      final int origLen = await originalFile.length();
      final net = await NetworkQualityService.getQuality();
      final chunkSize = _chunkSizeFor(net);
      final requestTimeout = _requestTimeoutFor(net);

      // MUST be RELATIVE paths (never full URLs)
      final mediaObject =
      _normalizeStoragePath(_pendingVideoPath ?? 'videos/${_uuid.v4()}.mp4');
      final thumbObject = _normalizeStoragePath(
          _pendingThumbPath ?? 'thumbnails/${_uuid.v4()}.jpg');

      _activeMediaObject = mediaObject;
      _activeThumbObject = thumbObject;

      // Generate thumb from original
      _setStage('Preparing upload...');

      final swThumb = Stopwatch()..start();
      final thumbFuture = _generateVideoThumbnail(originalFile.path)
          .whenComplete(() => swThumb.stop());

      File uploadFile = originalFile;
      Future<File> compressFuture = Future.value(originalFile);

      if (_shouldCompress(net, origLen)) {
        final swComp = Stopwatch()..start();
        compressFuture = () async {
          try {
            final NetworkQuality useQuality =
                (net == NetworkQuality.cellular || net == NetworkQuality.unknown)
                    ? NetworkQuality.cellular
                    : NetworkQuality.wifi;

            final f = await VideoCompressionService.compressForNetwork(
              input: originalFile,
              quality: useQuality,
            ).timeout(
              _compressionTimeout(net),
              onTimeout: () => originalFile,
            );
            return f;
          } catch (_) {
            return originalFile;
          } finally {
            swComp.stop();
            debugPrint('🟣 preupload: compress ${swComp.elapsedMilliseconds}ms');
          }
        }();
      }

      // Await both concurrently (saves time vs sequential thumb -> compress).
      final results = await Future.wait<dynamic>([thumbFuture, compressFuture]);
      tempThumb = results[0] as File?;
      uploadFile = results[1] as File;

      debugPrint('🟣 preupload: thumb gen ${swThumb.elapsedMilliseconds}ms');

      if (uploadFile.path != originalFile.path) {
        tempCompressed = uploadFile;
      }

      state = state.copyWith(
        preuploadState: PreuploadState.uploading,
        // expose names immediately so UI and Share can reference them
        preuploadedMediaObjectName: mediaObject,
        preuploadedThumbObjectName:
        (tempThumb != null && await tempThumb.exists()) ? thumbObject : null,
        uploadStage: 'Uploading...',
      );

      // Upload video + thumb in parallel
      final futures = <Future<void>>[];

      futures.add(
        _tus.uploadResumable(
          bucketName: 'story-media',
          objectName: mediaObject,
          file: uploadFile,
          chunkSizeBytes: chunkSize,
          requestTimeout: requestTimeout,
          onProgress: (p) => state = state.copyWith(mediaProgress: p),
        ),
      );

      if (tempThumb != null && await tempThumb.exists()) {
        futures.add(
          _tus.uploadResumable(
            bucketName: 'story-media',
            objectName: thumbObject,
            file: tempThumb,
            chunkSizeBytes: chunkSize,
            requestTimeout: requestTimeout,
            onProgress: (p) => state = state.copyWith(thumbProgress: p),
          ),
        );
      }

      await Future.wait(futures);

      // If user canceled while uploading AND hasn’t shared, delete.
      if (_preuploadCancelled && !_shareCommitted) {
        await _cleanupUploadedFiles([
          if (_activeMediaObject != null) _activeMediaObject!,
          if (_activeThumbObject != null) _activeThumbObject!,
        ]);

        state = state.copyWith(
          preuploadState: PreuploadState.cancelled,
          preuploadedMediaObjectName: null,
          preuploadedThumbObjectName: null,
          uploadStage: null,
        );
        return;
      }

      state = state.copyWith(
        preuploadState: PreuploadState.ready,
        preuploadedMediaObjectName: mediaObject,
        preuploadedThumbObjectName:
        (tempThumb != null && await tempThumb.exists()) ? thumbObject : null,
        uploadStage: 'Ready to share',
      );
    } catch (e) {
      state = state.copyWith(
        preuploadState: PreuploadState.failed,
        preuploadError: e.toString(),
        preuploadedMediaObjectName: null,
        preuploadedThumbObjectName: null,
        uploadStage: null,
      );
    } finally {
      swAll.stop();
      debugPrint('🟣 preupload: total ${swAll.elapsedMilliseconds}ms');

      if (tempThumb != null) {
        try {
          await tempThumb.delete();
        } catch (_) {}
      }
      if (tempCompressed != null) {
        try {
          await tempCompressed.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> cancelPreuploadAndCleanup() async {
    _preuploadCancelled = true;

    // If Share already happened, do not delete.
    if (_shareCommitted) return;

    if (_activeMediaObject == null && _activeThumbObject == null) {
      state = state.copyWith(
        preuploadState: PreuploadState.cancelled,
        uploadStage: null,
      );
      return;
    }

    await _cleanupUploadedFiles([
      if (_activeMediaObject != null) _activeMediaObject!,
      if (_activeThumbObject != null) _activeThumbObject!,
    ]);

    state = state.copyWith(
      preuploadState: PreuploadState.cancelled,
      preuploadedMediaObjectName: null,
      preuploadedThumbObjectName: null,
      uploadStage: null,
    );
  }

  // -------------------------
  // SHARE (DB COMMIT ONLY)
  // -------------------------
  Future<String?> uploadAndShareStory({
    required String memoryId,
    required String mediaPath,
    required bool isVideo,
    required String caption,
  }) async {
    try {
      state = state.copyWith(
        isUploading: true,
        errorMessage: null,
        uploadStage: 'Posting...',
        // keep current progress values (preupload owns them)
        mediaProgress: state.mediaProgress,
        thumbProgress: state.thumbProgress,
      );

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // VIDEO: wait for the already-started preupload (no loops, no restart).
      if (isVideo) {
        // If preupload never started (shouldn’t happen), start it now.
        if (state.preuploadState == PreuploadState.idle &&
            _preuploadFuture == null) {
          _setStage('Preparing upload...');
          await startPreupload(memoryId: memoryId, mediaPath: mediaPath);
        }

        // Await the one true preupload future if it exists
        if (_preuploadFuture != null) {
          if (state.preuploadState == PreuploadState.preparing) {
            _setStage('Preparing upload...');
          } else if (state.preuploadState == PreuploadState.uploading) {
            _setStage('Uploading...');
          } else {
            _setStage('Waiting for upload...');
          }
          await _preuploadFuture!;
        }

        // If cancelled, do not post.
        if (state.preuploadState == PreuploadState.cancelled) {
          state = state.copyWith(isUploading: false, uploadStage: null);
          return null;
        }

        // If failed, fail.
        if (state.preuploadState != PreuploadState.ready ||
            state.preuploadedMediaObjectName == null) {
          throw Exception(state.preuploadError ?? 'Upload failed');
        }

        // Commit = user pressed Share (keep it)
        _shareCommitted = true;

        // Normalize again to guarantee DB format is relative paths
        final mediaRel =
        _normalizeStoragePath(state.preuploadedMediaObjectName!);
        final thumbRel = state.preuploadedThumbObjectName != null
            ? _normalizeStoragePath(state.preuploadedThumbObjectName!)
            : mediaRel;

        _setStage('Creating story...');

        // Prefer duration from recorder to avoid video decoder init during "Posting...".
        final durationSeconds = (_recordedDurationSeconds != null &&
                _recordedDurationSeconds! > 0)
            ? _recordedDurationSeconds!
            : await _getVideoDuration(mediaPath);

        // Try to use prefetched location if ready; don't block share on GPS/geocode.
        Map<String, dynamic>? loc;
        final lf = _locationPrefetchFuture;
        if (lf != null) {
          try {
            loc = await lf.timeout(
              const Duration(milliseconds: 800),
              onTimeout: () => null,
            );
          } catch (_) {
            loc = null;
          }
        }

        final double? lat = (loc?['lat'] as num?)?.toDouble();
        final double? lng = (loc?['lng'] as num?)?.toDouble();
        final String? locationName =
            (loc?['location_name'] as String?)?.trim().isNotEmpty == true
                ? (loc?['location_name'] as String?)
                : null;

        final storyData = await _storyService.createStory(
          memoryId: memoryId,
          contributorId: userId,
          mediaUrl: mediaRel,
          mediaType: 'video',
          thumbnailUrl: thumbRel,
          caption: caption.isNotEmpty ? caption : null,
          durationSeconds: durationSeconds,
          // If prefetch didn't complete, do not stall sharing on location.
          skipLocationLookup: (lat == null || lng == null),
          locationLat: lat,
          locationLng: lng,
          locationNameOverride: locationName,
          // backfillLocationAsync defaults to false in StoryService now
        );

        if (storyData == null) throw Exception('Failed to create story');
        final createdStoryId = storyData['id']?.toString();
        if (createdStoryId == null || createdStoryId.isEmpty) {
          throw Exception('Story created but missing id');
        }

        await _ensureContributorForMemory(memoryId: memoryId, userId: userId);

        state = state.copyWith(isUploading: false, uploadStage: 'Done');
        return createdStoryId;
      }

      // IMAGE FLOW (still store relative path)
      final storyId = _uuid.v4();
      final originalFile = File(mediaPath);
      if (!await originalFile.exists()) throw Exception('Media file not found');

      final imageRelativePath = 'images/$storyId.jpg';

      final net = await NetworkQualityService.getQuality();
      final chunkSize = _chunkSizeFor(net);
      final requestTimeout = _requestTimeoutFor(net);

      _setStage('Uploading image...');

      await _tus.uploadResumable(
        bucketName: 'story-media',
        objectName: imageRelativePath,
        file: originalFile,
        chunkSizeBytes: chunkSize,
        requestTimeout: requestTimeout,
        onProgress: (p) => state = state.copyWith(mediaProgress: p),
      );

      _setStage('Creating story...');

      // Try to use prefetched location if ready; don't block share on GPS/geocode.
      Map<String, dynamic>? loc;
      final lf = _locationPrefetchFuture;
      if (lf != null) {
        try {
          loc = await lf.timeout(
            const Duration(milliseconds: 800),
            onTimeout: () => null,
          );
        } catch (_) {
          loc = null;
        }
      }

      final double? lat = (loc?['lat'] as num?)?.toDouble();
      final double? lng = (loc?['lng'] as num?)?.toDouble();
      final String? locationName =
          (loc?['location_name'] as String?)?.trim().isNotEmpty == true
              ? (loc?['location_name'] as String?)
              : null;

      final storyData = await _storyService.createStory(
        memoryId: memoryId,
        contributorId: userId,
        mediaUrl: imageRelativePath,
        mediaType: 'image',
        thumbnailUrl: imageRelativePath,
        caption: caption.isNotEmpty ? caption : null,
        durationSeconds: 5,
        // If prefetch didn't complete, do not stall sharing on location.
        skipLocationLookup: (lat == null || lng == null),
        locationLat: lat,
        locationLng: lng,
        locationNameOverride: locationName,
        // backfillLocationAsync defaults to false in StoryService now
      );

      if (storyData == null) throw Exception('Failed to create story');
      final createdStoryId = storyData['id']?.toString();
      if (createdStoryId == null || createdStoryId.isEmpty) {
        throw Exception('Story created but missing id');
      }

      await _ensureContributorForMemory(memoryId: memoryId, userId: userId);

      state = state.copyWith(isUploading: false, uploadStage: 'Done');
      return createdStoryId;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Failed to post story: $e',
        uploadStage: null,
      );
      return null;
    }
  }
}