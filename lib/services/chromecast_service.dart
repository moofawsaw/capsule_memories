import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/app_export.dart';

/// Service to handle Chromecast device discovery and media casting
/// Uses platform channels to communicate with native Android/iOS Chromecast SDKs
class ChromecastService {
  static const MethodChannel _channel =
      MethodChannel('com.capsule.app/chromecast');

  // Singleton pattern
  static final ChromecastService _instance = ChromecastService._internal();
  factory ChromecastService() => _instance;
  ChromecastService._internal();

  // State management
  bool _isConnected = false;
  String? _connectedDeviceName;
  final List<ChromecastDevice> _availableDevices = [];

  // Callbacks for state changes
  Function(bool isConnected)? onConnectionStateChanged;
  Function(List<ChromecastDevice> devices)? onDevicesUpdated;
  Function(String error)? onError;

  /// Initialize Chromecast service and start device discovery
  Future<void> initialize() async {
    try {
      // Set up method call handler for callbacks from native code
      _channel.setMethodCallHandler(_handleMethodCall);

      // Initialize native Chromecast SDK
      final bool? initialized = await _channel.invokeMethod('initialize');

      if (initialized == true) {
        debugPrint('✅ Chromecast service initialized successfully');
        await startDeviceDiscovery();
      } else {
        debugPrint('❌ Failed to initialize Chromecast service');
      }
    } on PlatformException catch (e) {
      debugPrint('❌ Chromecast initialization error: ${e.message}');
      onError?.call('Failed to initialize Chromecast: ${e.message}');
    }
  }

  /// Handle callbacks from native platform code
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDeviceDiscovered':
        _handleDeviceDiscovered(call.arguments as Map);
        break;
      case 'onDeviceDisconnected':
        _handleDeviceDisconnected(call.arguments as String);
        break;
      case 'onConnectionStateChanged':
        _handleConnectionStateChanged(call.arguments as Map);
        break;
      case 'onCastError':
        _handleCastError(call.arguments as String);
        break;
      default:
        debugPrint('⚠️ Unhandled method call: ${call.method}');
    }
  }

  /// Start discovering available Chromecast devices on the network
  Future<void> startDeviceDiscovery() async {
    try {
      await _channel.invokeMethod('startDiscovery');
      debugPrint('🔍 Started Chromecast device discovery');
    } on PlatformException catch (e) {
      debugPrint('❌ Device discovery error: ${e.message}');
      onError?.call('Failed to start device discovery: ${e.message}');
    }
  }

  /// Stop device discovery to save battery
  Future<void> stopDeviceDiscovery() async {
    try {
      await _channel.invokeMethod('stopDiscovery');
      debugPrint('🛑 Stopped Chromecast device discovery');
    } on PlatformException catch (e) {
      debugPrint('❌ Stop discovery error: ${e.message}');
    }
  }

  /// Show the native Cast device chooser dialog.
  ///
  /// On Android/iOS, Cast device selection is driven by the native Cast dialog UI.
  Future<void> showCastDialog() async {
    try {
      await _channel.invokeMethod('showCastDialog');
    } on PlatformException catch (e) {
      debugPrint('❌ Show cast dialog error: ${e.message}');
      onError?.call('Failed to open Cast dialog: ${e.message}');
    }
  }

  /// Connect to a specific Chromecast device.
  ///
  /// NOTE: Modern Cast SDKs expect the native Cast dialog to handle device selection.
  /// This method is kept for compatibility and will open the Cast dialog.
  Future<bool> connectToDevice(String deviceId) async {
    try {
      final bool? ok = await _channel.invokeMethod('connect', {
        'deviceId': deviceId,
      });
      return ok == true;
    } on PlatformException catch (e) {
      debugPrint('❌ Connection error: ${e.message}');
      onError?.call('Failed to connect: ${e.message}');
      return false;
    }
  }

  /// Disconnect from currently connected Chromecast device
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
      _isConnected = false;
      _connectedDeviceName = null;
      onConnectionStateChanged?.call(false);
      debugPrint('🔌 Disconnected from Chromecast device');
    } on PlatformException catch (e) {
      debugPrint('❌ Disconnect error: ${e.message}');
    }
  }

  /// Cast media (image or video) to the connected Chromecast device
  Future<bool> castMedia({
    required String mediaUrl,
    required String mediaType, // 'image' or 'video'
    String? title,
    String? description,
    String? thumbnailUrl,
  }) async {
    if (!_isConnected) {
      debugPrint('❌ Cannot cast: No device connected');
      onError?.call('Please connect to a Chromecast device first');
      return false;
    }

    try {
      final bool? success = await _channel.invokeMethod('castMedia', {
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'title': title ?? 'Capsule Memory',
        'description': description ?? '',
        'thumbnailUrl': thumbnailUrl ?? '',
      });

      if (success == true) {
        debugPrint('✅ Successfully casting media: $mediaUrl');
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      debugPrint('❌ Cast media error: ${e.message}');
      onError?.call('Failed to cast media: ${e.message}');
      return false;
    }
  }

  /// Cast a full playlist/queue to the connected Chromecast device.
  ///
  /// `items` elements should include:
  /// - mediaUrl (String, required)
  /// - mediaType ('video'|'image')
  /// - contentType (mime type String)
  /// - title/subtitle/thumbnailUrl (optional)
  /// - customData (Map<String, dynamic>, optional) for future custom receiver UI
  Future<bool> castQueue({
    required List<Map<String, dynamic>> items,
    int startIndex = 0,
  }) async {
    if (!_isConnected) {
      debugPrint('❌ Cannot cast queue: No device connected');
      onError?.call('Please connect to a Chromecast device first');
      return false;
    }

    try {
      final bool? success = await _channel.invokeMethod('castQueue', {
        'items': items,
        'startIndex': startIndex,
      });
      return success == true;
    } on PlatformException catch (e) {
      debugPrint('❌ Cast queue error: ${e.message}');
      onError?.call('Failed to cast playlist: ${e.message}');
      return false;
    }
  }

  /// Play the currently casted media
  Future<void> play() async {
    try {
      await _channel.invokeMethod('play');
      debugPrint('▶️ Playing casted media');
    } on PlatformException catch (e) {
      debugPrint('❌ Play error: ${e.message}');
    }
  }

  /// Pause the currently casted media
  Future<void> pause() async {
    try {
      await _channel.invokeMethod('pause');
      debugPrint('⏸️ Paused casted media');
    } on PlatformException catch (e) {
      debugPrint('❌ Pause error: ${e.message}');
    }
  }

  /// Advance to the next item in the cast queue (if any).
  Future<void> queueNext() async {
    try {
      await _channel.invokeMethod('queueNext');
    } on PlatformException catch (e) {
      debugPrint('❌ Queue next error: ${e.message}');
    }
  }

  /// Go to the previous item in the cast queue (if any).
  Future<void> queuePrev() async {
    try {
      await _channel.invokeMethod('queuePrev');
    } on PlatformException catch (e) {
      debugPrint('❌ Queue prev error: ${e.message}');
    }
  }

  /// Stop casting and return to device selection
  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
      debugPrint('⏹️ Stopped casting');
    } on PlatformException catch (e) {
      debugPrint('❌ Stop error: ${e.message}');
    }
  }

  /// Seek to a specific position in the casted video (in seconds)
  Future<void> seek(double position) async {
    try {
      await _channel.invokeMethod('seek', {'position': position});
      debugPrint('⏩ Seeking to position: ${position}s');
    } on PlatformException catch (e) {
      debugPrint('❌ Seek error: ${e.message}');
    }
  }

  /// Set volume for casted media (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _channel.invokeMethod('setVolume', {
        'volume': volume.clamp(0.0, 1.0),
      });
      debugPrint('🔊 Set volume: ${(volume * 100).toInt()}%');
    } on PlatformException catch (e) {
      debugPrint('❌ Set volume error: ${e.message}');
    }
  }

  /// Fetch current receiver playback status (best-effort).
  /// Used to keep the in-app overlay in sync with the TV.
  Future<Map<String, dynamic>?> getPlaybackStatus() async {
    try {
      final res = await _channel.invokeMethod('getPlaybackStatus');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return null;
    } on PlatformException catch (e) {
      debugPrint('❌ getPlaybackStatus error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ getPlaybackStatus error: $e');
      return null;
    }
  }

  // Handler methods for platform callbacks

  void _handleDeviceDiscovered(Map<dynamic, dynamic> deviceData) {
    final device = ChromecastDevice(
      id: deviceData['id'] as String,
      name: deviceData['name'] as String,
      model: deviceData['model'] as String?,
      isAvailable: deviceData['isAvailable'] as bool? ?? true,
    );

    // Add to available devices if not already present
    if (!_availableDevices.any((d) => d.id == device.id)) {
      _availableDevices.add(device);
      onDevicesUpdated?.call(List.from(_availableDevices));
      debugPrint('📱 Discovered Chromecast: ${device.name}');
    }
  }

  void _handleDeviceDisconnected(String deviceId) {
    _availableDevices.removeWhere((device) => device.id == deviceId);
    onDevicesUpdated?.call(List.from(_availableDevices));

    if (_isConnected && _connectedDeviceName != null) {
      _isConnected = false;
      _connectedDeviceName = null;
      onConnectionStateChanged?.call(false);
      debugPrint('📱 Device disconnected: $deviceId');
    }
  }

  void _handleConnectionStateChanged(Map<dynamic, dynamic> stateData) {
    final bool isConnected = stateData['isConnected'] as bool;
    final String? deviceName = stateData['deviceName'] as String?;

    _isConnected = isConnected;
    _connectedDeviceName = deviceName;
    onConnectionStateChanged?.call(isConnected);

    if (isConnected) {
      debugPrint('✅ Connected to: $deviceName');
    } else {
      debugPrint('🔌 Disconnected from Chromecast');
    }
  }

  void _handleCastError(String error) {
    debugPrint('❌ Cast error: $error');
    onError?.call(error);
  }

  // Getters
  bool get isConnected => _isConnected;
  String? get connectedDeviceName => _connectedDeviceName;
  List<ChromecastDevice> get availableDevices => List.from(_availableDevices);

  /// Dispose and cleanup resources
  void dispose() {
    stopDeviceDiscovery();
    _availableDevices.clear();
  }
}

/// Model for Chromecast device information
class ChromecastDevice {
  final String id;
  final String name;
  final String? model;
  final bool isAvailable;

  ChromecastDevice({
    required this.id,
    required this.name,
    this.model,
    this.isAvailable = true,
  });

  @override
  String toString() => 'ChromecastDevice(id: $id, name: $name, model: $model)';
}
