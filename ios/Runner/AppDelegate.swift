import UIKit
import Flutter
import UserNotifications
import GoogleCast

final class CastChannelHandler: NSObject, GCKSessionManagerListener {
  private let receiverAppId: String
  private let channel: FlutterMethodChannel

  init(channel: FlutterMethodChannel, receiverAppId: String) {
    self.channel = channel
    self.receiverAppId = receiverAppId
    super.init()
  }

  // MARK: - Setup

  @discardableResult
  func ensureCastInitialized() -> Bool {
    if !GCKCastContext.isSharedInstanceInitialized() {
      let criteria = GCKDiscoveryCriteria(applicationID: receiverAppId)
      let options = GCKCastOptions(discoveryCriteria: criteria)
      GCKCastContext.setSharedInstanceWith(options)
      GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = true
    }

    GCKCastContext.sharedInstance().sessionManager.add(self)
    GCKCastContext.sharedInstance().discoveryManager.startDiscovery()
    return true
  }

  private func remoteClient() -> GCKRemoteMediaClient? {
    return GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
  }

  private func connectedDeviceName() -> String? {
    return GCKCastContext.sharedInstance().sessionManager.currentCastSession?.device.friendlyName
  }

  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      result(ensureCastInitialized())

    case "startDiscovery":
      ensureCastInitialized()
      GCKCastContext.sharedInstance().discoveryManager.startDiscovery()
      result(true)

    case "stopDiscovery":
      if GCKCastContext.isSharedInstanceInitialized() {
        GCKCastContext.sharedInstance().discoveryManager.stopDiscovery()
      }
      result(true)

    case "showCastDialog", "connect":
      ensureCastInitialized()
      DispatchQueue.main.async {
        GCKCastContext.sharedInstance().presentCastDialog()
      }
      result(true)

    case "disconnect":
      if GCKCastContext.isSharedInstanceInitialized() {
        _ = GCKCastContext.sharedInstance().sessionManager.endSessionAndStopCasting(true)
      }
      result(true)

    case "castMedia":
      guard let args = call.arguments as? [String: Any],
            let mediaUrl = (args["mediaUrl"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
            !mediaUrl.isEmpty
      else {
        result(FlutterError(code: "INVALID_ARGS", message: "Media URL is required", details: nil))
        return
      }

      guard let url = URL(string: mediaUrl) else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid media URL", details: nil))
        return
      }

      guard let client = remoteClient() else {
        result(FlutterError(code: "NO_SESSION", message: "No active casting session", details: nil))
        return
      }

      let mediaType = ((args["mediaType"] as? String) ?? "video").lowercased()
      let title = (args["title"] as? String) ?? "Capsule"
      let subtitle = (args["description"] as? String) ?? ""
      let thumbnailUrl = (args["thumbnailUrl"] as? String) ?? ""

      let metadataType: GCKMediaMetadataType = (mediaType == "image") ? .photo : .movie
      let metadata = GCKMediaMetadata(metadataType: metadataType)
      metadata.setString(title, forKey: kGCKMetadataKeyTitle)
      metadata.setString(subtitle, forKey: kGCKMetadataKeySubtitle)

      if let thumb = URL(string: thumbnailUrl), !thumbnailUrl.isEmpty {
        metadata.addImage(GCKImage(url: thumb, width: 480, height: 270))
      }

      let contentType = (args["contentType"] as? String) ?? ((mediaType == "image") ? "image/jpeg" : "video/mp4")
      let builder = GCKMediaInformationBuilder(contentURL: url)
      builder.streamType = .buffered
      builder.contentType = contentType
      builder.metadata = metadata

      let mediaInfo = builder.build()
      client.loadMedia(mediaInfo)
      result(true)

    case "castQueue":
      guard let args = call.arguments as? [String: Any],
            let itemsRaw = args["items"] as? [[String: Any]],
            !itemsRaw.isEmpty
      else {
        result(FlutterError(code: "INVALID_ARGS", message: "Queue items are required", details: nil))
        return
      }

      guard let client = remoteClient() else {
        result(FlutterError(code: "NO_SESSION", message: "No active casting session", details: nil))
        return
      }

      let startIndexAny = args["startIndex"]
      let startIndex: Int = {
        if let v = startIndexAny as? Int { return v }
        if let v = startIndexAny as? NSNumber { return v.intValue }
        if let v = startIndexAny as? String, let i = Int(v) { return i }
        return 0
      }()

      let queueItems: [GCKMediaQueueItem] = itemsRaw.compactMap { item in
        guard let mediaUrl = (item["mediaUrl"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !mediaUrl.isEmpty,
              let url = URL(string: mediaUrl)
        else { return nil }

        let mediaType = ((item["mediaType"] as? String) ?? "video").lowercased()
        let title = (item["title"] as? String) ?? "Capsule"
        let subtitle = (item["subtitle"] as? String) ?? ""
        let thumbnailUrl = (item["thumbnailUrl"] as? String) ?? ""
        let contentType = (item["contentType"] as? String) ?? ((mediaType == "image") ? "image/jpeg" : "video/mp4")

        let metadataType: GCKMediaMetadataType = (mediaType == "image") ? .photo : .movie
        let metadata = GCKMediaMetadata(metadataType: metadataType)
        metadata.setString(title, forKey: kGCKMetadataKeyTitle)
        metadata.setString(subtitle, forKey: kGCKMetadataKeySubtitle)

        if let thumb = URL(string: thumbnailUrl), !thumbnailUrl.isEmpty {
          metadata.addImage(GCKImage(url: thumb, width: 480, height: 270))
        }

        let infoBuilder = GCKMediaInformationBuilder(contentURL: url)
        infoBuilder.streamType = .buffered
        infoBuilder.contentType = contentType
        infoBuilder.metadata = metadata

        let mediaInfo = infoBuilder.build()

        let qBuilder = GCKMediaQueueItemBuilder()
        qBuilder.mediaInformation = mediaInfo
        qBuilder.autoplay = true
        if let cd = item["customData"] {
          qBuilder.customData = cd
        }
        return qBuilder.build()
      }

      if queueItems.isEmpty {
        result(FlutterError(code: "INVALID_ARGS", message: "No valid queue items", details: nil))
        return
      }

      let safeStartInt = max(0, min(startIndex, queueItems.count - 1))
      let safeStart = UInt(safeStartInt)
      client.queueLoad(queueItems, start: safeStart, repeatMode: .off, customData: nil)
      result(true)

    case "queueNext":
      remoteClient()?.queueNextItem()
      result(nil)

    case "queuePrev":
      remoteClient()?.queuePreviousItem()
      result(nil)

    case "play":
      remoteClient()?.play()
      result(nil)

    case "pause":
      remoteClient()?.pause()
      result(nil)

    case "stop":
      remoteClient()?.stop()
      result(nil)

    case "seek":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Position is required", details: nil))
        return
      }
      let posAny = args["position"]
      let seconds: Double? = {
        if let v = posAny as? Double { return v }
        if let v = posAny as? NSNumber { return v.doubleValue }
        if let v = posAny as? String { return Double(v) }
        return nil
      }()
      guard let s = seconds else {
        result(FlutterError(code: "INVALID_ARGS", message: "Position is required", details: nil))
        return
      }
      remoteClient()?.seek(toTimeInterval: s)
      result(nil)

    case "setVolume":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Volume is required", details: nil))
        return
      }
      let volAny = args["volume"]
      let volume: Float? = {
        if let v = volAny as? Double { return Float(v) }
        if let v = volAny as? NSNumber { return v.floatValue }
        if let v = volAny as? String, let d = Double(v) { return Float(d) }
        return nil
      }()
      guard let vol = volume else {
        result(FlutterError(code: "INVALID_ARGS", message: "Volume is required", details: nil))
        return
      }
      remoteClient()?.setStreamVolume(vol)
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Session callbacks -> Flutter

  func sessionManager(_ sessionManager: GCKSessionManager, didStart castSession: GCKCastSession) {
    channel.invokeMethod("onConnectionStateChanged", arguments: [
      "isConnected": true,
      "deviceName": connectedDeviceName() as Any
    ])
  }

  func sessionManager(_ sessionManager: GCKSessionManager, didResume castSession: GCKCastSession) {
    channel.invokeMethod("onConnectionStateChanged", arguments: [
      "isConnected": true,
      "deviceName": connectedDeviceName() as Any
    ])
  }

  func sessionManager(_ sessionManager: GCKSessionManager, didEnd castSession: GCKCastSession, withError error: Error?) {
    channel.invokeMethod("onConnectionStateChanged", arguments: [
      "isConnected": false,
      "deviceName": NSNull()
    ])
  }

  func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart castSession: GCKCastSession, withError error: Error) {
    channel.invokeMethod("onCastError", arguments: error.localizedDescription)
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {

  private let castReceiverAppId = "CC1AD845" // Default Media Receiver
  private let castChannelName = "com.capsule.app/chromecast"
  private var castHandler: CastChannelHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Push notification delegate (safe)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    GeneratedPluginRegistrant.register(with: self)

    // Chromecast / Google Cast platform channel setup
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: castChannelName, binaryMessenger: controller.binaryMessenger)
      let handler = CastChannelHandler(channel: channel, receiverAppId: castReceiverAppId)
      self.castHandler = handler
      channel.setMethodCallHandler { [weak handler] call, result in
        handler?.handle(call: call, result: result)
      }
      // Initialize Cast early so discovery/session callbacks work reliably.
      _ = handler.ensureCastInitialized()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Push notifications (safe overrides)

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    super.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler
    )
  }
}