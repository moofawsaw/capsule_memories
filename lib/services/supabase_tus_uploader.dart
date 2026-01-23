import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class SupabaseTusUploader {
  SupabaseTusUploader(this._supabase, {http.Client? client})
      : _client = client ?? http.Client();

  final SupabaseClient _supabase;
  final http.Client _client;

  // TUS requires this version header
  static const String _tusVersion = '1.0.0';

  // Reasonable defaults; override per upload for cellular vs wifi
  static const int _mb = 1024 * 1024;
  static const int defaultChunkWifi = 12 * _mb;
  static const int defaultChunkCell = 5 * _mb;

  // ---------
  // In-memory URL store cache (big perf win on first upload + avoids file IO per upload)
  // ---------
  bool _storeLoaded = false;
  Map<String, dynamic> _storeCache = <String, dynamic>{};
  Timer? _storeWriteDebounce;

  // Prewarm guard
  bool _didPrewarm = false;
  Future<void>? _prewarmFuture;

  Uri _tusEndpoint() {
    // https://<project>.supabase.co/storage/v1/upload/resumable
    final base = SupabaseService.supabaseUrl.trim();
    if (base.isNotEmpty) {
      return Uri.parse('$base/storage/v1/upload/resumable');
    }

    // fallback if env constant isn't set
    final rest = _supabase.rest.url; // .../rest/v1
    final root = rest.replaceFirst(RegExp(r'/rest/v1/?$'), '');
    return Uri.parse('$root/storage/v1/upload/resumable');
  }

  Uri _storageBase() {
    // https://<project>.supabase.co/storage/v1/
    final endpoint = _tusEndpoint().toString();
    // .../upload/resumable -> .../
    final base = endpoint.replaceFirst(RegExp(r'/upload/resumable/?$'), '/');
    return Uri.parse(base);
  }

  String _accessTokenOrThrow() {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('User not authenticated');
    }
    return token;
  }

  Future<File> _getUrlStoreFile() async {
    final dir = await getApplicationSupportDirectory();
    final storeDir = Directory('${dir.path}/tus_upload_store');
    if (!await storeDir.exists()) {
      await storeDir.create(recursive: true);
    }
    return File('${storeDir.path}/tus_urls.json');
  }

  Future<void> _ensureStoreLoaded() async {
    if (_storeLoaded) return;
    _storeLoaded = true;
    try {
      final f = await _getUrlStoreFile();
      if (!await f.exists()) {
        _storeCache = <String, dynamic>{};
        return;
      }
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) {
        _storeCache = <String, dynamic>{};
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _storeCache = decoded;
      } else {
        _storeCache = <String, dynamic>{};
      }
    } catch (_) {
      _storeCache = <String, dynamic>{};
    }
  }

  void _scheduleStoreWrite() {
    _storeWriteDebounce?.cancel();
    _storeWriteDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final f = await _getUrlStoreFile();
        await f.writeAsString(jsonEncode(_storeCache));
      } catch (_) {}
    });
  }

  String _storeKey({
    required String bucketName,
    required String objectName,
    required File file,
  }) {
    // ✅ Stronger fingerprint than size alone
    final stat = file.statSync();
    final size = stat.size;
    final modified = stat.modified.millisecondsSinceEpoch;

    // Path included to reduce collision risk (safe because this is local-only)
    final path = file.path;

    return '$bucketName::$objectName::$size::$modified::$path';
  }

  String _encodeMetadata(Map<String, String> meta) {
    // tus metadata format: key base64(value), comma-separated
    return meta.entries
        .map((e) => '${e.key} ${base64Encode(utf8.encode(e.value))}')
        .join(',');
  }

  Map<String, String> _authHeaders({
    required String token,
    required bool upsert,
  }) {
    return <String, String>{
      'authorization': 'Bearer $token',
      'apikey': SupabaseService.supabaseAnonKey,
      'x-upsert': upsert ? 'true' : 'false',
      'tus-resumable': _tusVersion,
      // keep-alive is implicit but harmless to include
      'connection': 'keep-alive',
    };
  }

  Future<http.Response> _withRetry(
      Future<http.Response> Function() fn, {
        int retries = 3,
        Duration baseDelay = const Duration(milliseconds: 350),
      }) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        if (attempt > retries) rethrow;
        await Future.delayed(baseDelay * attempt);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // TRUE PREWARM (DNS/TLS/HTTP connection + auth header path + filesystem store)
  //
  // Call this once after app launch or when opening the first upload screen.
  // It intentionally makes a tiny request that may return 404/405 — that's fine.
  // The point is to force the OS to do DNS + TLS handshake + open the socket.
  // ---------------------------------------------------------------------------
  Future<void> prewarm({
    Duration timeout = const Duration(seconds: 8),
    bool alsoWarmUrlStore = true,
  }) {
    if (_didPrewarm) return Future.value();
    _prewarmFuture ??= _doPrewarm(timeout: timeout, alsoWarmUrlStore: alsoWarmUrlStore)
        .whenComplete(() {
      _didPrewarm = true;
      _prewarmFuture = null;
    });
    return _prewarmFuture!;
  }

  Future<void> _doPrewarm({
    required Duration timeout,
    required bool alsoWarmUrlStore,
  }) async {
    try {
      final token = _accessTokenOrThrow();
      if (alsoWarmUrlStore) {
        await _ensureStoreLoaded();
        // Touch file path/dir again (filesystem cache warm)
        await _getUrlStoreFile();
      }

      final endpoint = _tusEndpoint();

      // 1) OPTIONS (ideal preflight for this endpoint). Some stacks return 404/405 — acceptable.
      final optionsReq = http.Request('OPTIONS', endpoint);
      optionsReq.headers.addAll(_authHeaders(token: token, upsert: true));
      await _client.send(optionsReq).timeout(timeout).catchError((_) async {});

      // 2) HEAD on storage base (another cheap request to stabilize handshake).
      final headReq = http.Request('HEAD', _storageBase());
      headReq.headers.addAll(_authHeaders(token: token, upsert: true));
      await _client.send(headReq).timeout(timeout).catchError((_) async {});
    } catch (_) {
      // Best-effort only; never block UI
    }
  }

  /// Real resumable upload (TUS) to Supabase Storage.
  ///
  /// IMPORTANT knobs:
  /// - chunkSizeBytes: use smaller on cellular (2-4MB), bigger on Wi-Fi (8-12MB)
  /// - requestTimeout: per request timeout to avoid hanging on mobile data
  Future<String> uploadResumable({
    required String bucketName,
    required String objectName,
    required File file,
    bool upsert = true,
    int? chunkSizeBytes,
    Duration requestTimeout = const Duration(seconds: 45),
    void Function(double progress01)? onProgress,
  }) async {
    if (!await file.exists()) {
      throw Exception('File not found: ${file.path}');
    }

    // Fire-and-forget prewarm (doesn't delay upload if it already started)
    // You can remove this if you prefer to call prewarm() explicitly in UI.
    unawaited(prewarm(timeout: const Duration(seconds: 6), alsoWarmUrlStore: true));

    final token = _accessTokenOrThrow();
    final endpoint = _tusEndpoint();
    final totalBytes = await file.length();
    final contentType = lookupMimeType(file.path) ?? 'application/octet-stream';

    // Choose chunk size
    final int chunkSize = (chunkSizeBytes == null || chunkSizeBytes <= 0)
        ? defaultChunkCell
        : chunkSizeBytes;

    onProgress?.call(0.0);

    // ---- 1) Load stored upload URL if exists (from in-memory cache)
    await _ensureStoreLoaded();
    final key = _storeKey(bucketName: bucketName, objectName: objectName, file: file);

    Uri? uploadUrl;
    final stored = _storeCache[key];
    if (stored is String && stored.startsWith('http')) {
      uploadUrl = Uri.parse(stored);
    }

    // ---- 2) If no stored URL, create upload via POST
    if (uploadUrl == null) {
      final meta = <String, String>{
        'bucketName': bucketName,
        'objectName': objectName,
        'contentType': contentType,
      };

      final res = await _withRetry(
            () => _client
            .post(
          endpoint,
          headers: <String, String>{
            ..._authHeaders(token: token, upsert: upsert),
            'upload-length': totalBytes.toString(),
            'upload-metadata': _encodeMetadata(meta),
          },
        )
            .timeout(requestTimeout),
        retries: 2,
      );

      if (res.statusCode != 201 && res.statusCode != 204) {
        throw Exception('TUS create failed: ${res.statusCode} ${res.body}');
      }

      final loc = res.headers['location'];
      if (loc == null || loc.isEmpty) {
        throw Exception('TUS create failed: missing Location header');
      }

      uploadUrl = loc.startsWith('http') ? Uri.parse(loc) : endpoint.resolve(loc);

      // persist (cached + debounced write)
      _storeCache[key] = uploadUrl.toString();
      _scheduleStoreWrite();
    }

    // ---- 3) Get current offset (HEAD)
    int offset = 0;
    {
      final head = await _withRetry(
            () => _client
            .head(
          uploadUrl!,
          headers: _authHeaders(token: token, upsert: upsert),
        )
            .timeout(requestTimeout),
        retries: 2,
      );

      if (head.statusCode == 404 || head.statusCode == 410) {
        // upload expired on server; clear and recreate once
        _storeCache.remove(key);
        _scheduleStoreWrite();

        // Recreate fresh upload URL (single restart)
        return uploadResumable(
          bucketName: bucketName,
          objectName: objectName,
          file: file,
          upsert: upsert,
          chunkSizeBytes: chunkSizeBytes,
          requestTimeout: requestTimeout,
          onProgress: onProgress,
        );
      }

      if (head.statusCode < 200 || head.statusCode >= 300) {
        throw Exception('TUS head failed: ${head.statusCode}');
      }

      final offStr = head.headers['upload-offset'] ?? '0';
      offset = int.tryParse(offStr) ?? 0;
      if (offset < 0) offset = 0;
      if (offset > totalBytes) offset = totalBytes;
    }

    // ---- 4) Upload chunks (PATCH)
    final raf = await file.open();
    try {
      // Seek to current offset so we don't read+discard bytes
      await raf.setPosition(offset);

      while (offset < totalBytes) {
        final remaining = totalBytes - offset;
        final toRead = remaining < chunkSize ? remaining : chunkSize;

        final bytes = await raf.read(toRead);
        if (bytes.isEmpty) break;

        final patch = await _withRetry(
              () => _client
              .patch(
            uploadUrl!,
            headers: <String, String>{
              ..._authHeaders(token: token, upsert: upsert),
              'content-type': 'application/offset+octet-stream',
              'upload-offset': offset.toString(),
            },
            body: bytes,
          )
              .timeout(requestTimeout),
          retries: 3,
          baseDelay: const Duration(milliseconds: 500),
        );

        if (patch.statusCode < 200 || patch.statusCode >= 300) {
          throw Exception('TUS patch failed: ${patch.statusCode} ${patch.body}');
        }

        final newOffsetStr = patch.headers['upload-offset'];
        final newOffset = int.tryParse(newOffsetStr ?? '');
        if (newOffset == null) {
          offset += bytes.length;
        } else {
          offset = newOffset;
        }

        onProgress?.call((offset / totalBytes).clamp(0.0, 1.0));
      }
    } finally {
      await raf.close();
    }

    // ---- 5) Done; clear store for this key
    _storeCache.remove(key);
    _scheduleStoreWrite();

    onProgress?.call(1.0);
    return objectName;
  }

  void dispose() {
    _storeWriteDebounce?.cancel();
    _client.close();
  }
}