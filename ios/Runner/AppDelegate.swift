import UIKit
import Flutter
import GoogleCast

@main
@objc class AppDelegate: FlutterAppDelegate, GCKSessionManagerListener, GCKRemoteMediaClientListener {
    private let chromecastChannel = "com.capsule.app/chromecast"
    private var flutterChannel: FlutterMethodChannel?
    private var sessionManager: GCKSessionManager?
    private var currentSession: GCKCastSession?
    private var remoteMediaClient: GCKRemoteMediaClient?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize Google Cast SDK
        let options = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID))
        options.physicalVolumeButtonsWillControlDeviceVolume = true
        GCKCastContext.setSharedInstanceWith(options)
        
        // Get session manager
        sessionManager = GCKCastContext.sharedInstance().sessionManager
        sessionManager?.add(self)
        
        GeneratedPluginRegistrant.register(with: self)
        
        // Set up Chromecast method channel
        let controller = window?.rootViewController as! FlutterViewController
        flutterChannel = FlutterMethodChannel(
            name: chromecastChannel,
            binaryMessenger: controller.binaryMessenger
        )
        
        flutterChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else { return }
            
            switch call.method {
            case "initialize":
                // Already initialized in didFinishLaunchingWithOptions
                print("Chromecast: ✅ Already initialized")
                result(true)
                
            case "startDiscovery":
                // Discovery is automatic with Google Cast SDK
                print("Chromecast: Discovery is automatic")
                result(true)
                
            case "stopDiscovery":
                // Discovery management is handled by SDK
                result(true)
                
            case "connect":
                // Connection is handled through Cast button UI
                result(true)
                
            case "disconnect":
                self.sessionManager?.endSession()
                print("Chromecast: Disconnected")
                result(true)
                
            case "castMedia":
                guard let args = call.arguments as? [String: Any],
                      let mediaUrl = args["mediaUrl"] as? String,
                      let mediaType = args["mediaType"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Media URL and type required", details: nil))
                    return
                }
                
                let title = args["title"] as? String ?? "Capsule Memory"
                let description = args["description"] as? String ?? ""
                let thumbnailUrl = args["thumbnailUrl"] as? String
                
                let metadata = GCKMediaMetadata(
                    metadataType: mediaType == "video" ? .movie : .photo
                )
                metadata.setString(title, forKey: kGCKMetadataKeyTitle)
                metadata.setString(description, forKey: kGCKMetadataKeySubtitle)
                
                if let thumbnailUrl = thumbnailUrl, let url = URL(string: thumbnailUrl) {
                    metadata.addImage(GCKImage(url: url, width: 480, height: 360))
                }
                
                let contentType = mediaType == "video" ? "video/mp4" : "image/jpeg"
                guard let url = URL(string: mediaUrl) else {
                    result(FlutterError(code: "INVALID_URL", message: "Invalid media URL", details: nil))
                    return
                }
                
                let mediaInfoBuilder = GCKMediaInformationBuilder(contentURL: url)
                mediaInfoBuilder.contentType = contentType
                mediaInfoBuilder.streamType = .buffered
                mediaInfoBuilder.metadata = metadata
                
                let mediaInfo = mediaInfoBuilder.build()
                let request = GCKMediaLoadRequestData()
                request.mediaInformation = mediaInfo
                request.autoplay = true
                
                self.remoteMediaClient?.loadMedia(with: request)
                print("Chromecast: ✅ Casting media: \(mediaUrl)")
                result(true)
                
            case "play":
                self.remoteMediaClient?.play()
                result(nil)
                
            case "pause":
                self.remoteMediaClient?.pause()
                result(nil)
                
            case "stop":
                self.remoteMediaClient?.stop()
                result(nil)
                
            case "seek":
                if let args = call.arguments as? [String: Any],
                   let position = args["position"] as? Double {
                    let seekOptions = GCKMediaSeekOptions()
                    seekOptions.interval = position
                    self.remoteMediaClient?.seek(with: seekOptions)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Position required", details: nil))
                }
                
            case "setVolume":
                if let args = call.arguments as? [String: Any],
                   let volume = args["volume"] as? Double {
                    self.remoteMediaClient?.setStreamVolume(Float(volume))
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Volume required", details: nil))
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - GCKSessionManagerListener
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
        currentSession = session
        remoteMediaClient = session.remoteMediaClient
        remoteMediaClient?.add(self)
        
        flutterChannel?.invokeMethod("onConnectionStateChanged", arguments: [
            "isConnected": true,
            "deviceName": session.device.friendlyName ?? "Unknown Device"
        ])
        
        print("Chromecast: ✅ Session started with \(session.device.friendlyName ?? "device")")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        currentSession = session
        remoteMediaClient = session.remoteMediaClient
        remoteMediaClient?.add(self)
        
        flutterChannel?.invokeMethod("onConnectionStateChanged", arguments: [
            "isConnected": true,
            "deviceName": session.device.friendlyName ?? "Unknown Device"
        ])
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        currentSession = nil
        remoteMediaClient?.remove(self)
        remoteMediaClient = nil
        
        flutterChannel?.invokeMethod("onConnectionStateChanged", arguments: [
            "isConnected": false,
            "deviceName": nil
        ])
        
        if let error = error {
            print("Chromecast: ❌ Session ended with error: \(error.localizedDescription)")
        } else {
            print("Chromecast: Session ended")
        }
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        flutterChannel?.invokeMethod("onCastError", arguments: "Failed to start casting: \(error.localizedDescription)")
    }
    
    // MARK: - GCKRemoteMediaClientListener
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        // Handle media status updates if needed
    }
}