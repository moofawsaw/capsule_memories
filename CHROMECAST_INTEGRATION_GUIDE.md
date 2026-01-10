# Chromecast Integration Guide

This guide explains how to complete the Chromecast implementation for the Capsule app.

## Current Implementation Status

✅ **Completed:**
- Flutter-side Chromecast service with platform channel communication
- UI integration with Chromecast button in memory timeline playback screen
- Platform channel handlers in Android (MainActivity.kt) and iOS (AppDelegate.swift)
- State management for Chromecast connection and casting
- Media casting interface for images and videos

⚠️ **Pending:**
- Native Android Google Cast SDK integration
- Native iOS Google Cast SDK integration
- Actual device discovery and connection
- Real media casting implementation

## Next Steps for Full Implementation

### 1. Android Setup

#### Add Google Cast SDK Dependency

In `android/app/build.gradle`:

```gradle
dependencies {
    // ... existing dependencies
    implementation 'com.google.android.gms:play-services-cast-framework:21.5.0'
}
```

#### Update AndroidManifest.xml

```xml
<application>
    <!-- Existing configuration -->
    
    <meta-data
        android:name="com.google.android.gms.cast.framework.OPTIONS_PROVIDER_CLASS_NAME"
        android:value="com.capsule.app.CastOptionsProvider" />
</application>
```

#### Create CastOptionsProvider.kt

Create `android/app/src/main/kotlin/com/capsule/app/CastOptionsProvider.kt`:

```kotlin
package com.capsule.app

import android.content.Context
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider

class CastOptionsProvider : OptionsProvider {
    override fun getCastOptions(context: Context): CastOptions {
        return CastOptions.Builder()
            .setReceiverApplicationId("CC1AD845") // Default receiver app ID
            .build()
    }

    override fun getAdditionalSessionProviders(context: Context): List<SessionProvider>? {
        return null
    }
}
```

#### Implement Full Chromecast Logic in MainActivity.kt

Replace the placeholder implementations with actual Google Cast SDK calls:

```kotlin
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaLoadRequestData
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.common.images.WebImage
import android.net.Uri

class MainActivity: FlutterActivity() {
    private lateinit var castContext: CastContext
    private lateinit var sessionManagerListener: SessionManagerListener<CastSession>
    
    // ... implement full Chromecast functionality
}
```

### 2. iOS Setup

#### Add Google Cast SDK via CocoaPods

In `ios/Podfile`:

```ruby
target 'Runner' do
  # ... existing pods
  
  pod 'google-cast-sdk', '~> 4.8'
end
```

Run: `cd ios && pod install`

#### Update Info.plist

Add NSLocalNetworkUsageDescription and NSBonjourServices:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Capsule needs access to your local network to discover Chromecast devices.</string>
<key>NSBonjourServices</key>
<array>
    <string>_googlecast._tcp</string>
</array>
```

#### Implement Full Chromecast Logic in AppDelegate.swift

Replace the placeholder implementations with actual Google Cast SDK calls:

```swift
import GoogleCast

@main
@objc class AppDelegate: FlutterAppDelegate {
    var sessionManager: GCKSessionManager!
    
    override func application(...) -> Bool {
        // Initialize Google Cast SDK
        let criteria = GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID)
        let options = GCKCastOptions(discoveryCriteria: criteria)
        GCKCastContext.setSharedInstanceWith(options)
        
        // ... implement full Chromecast functionality
    }
}
```

### 3. Testing

1. **Build and run on physical devices** (Chromecast doesn't work on emulators)
2. **Ensure both device and Chromecast are on the same WiFi network**
3. **Test device discovery** - verify Chromecast devices appear
4. **Test connection** - connect to a Chromecast device
5. **Test media casting** - cast images and videos from memory playback
6. **Test playback controls** - play, pause, stop, seek functionality
7. **Test disconnection** - graceful handling of device disconnection

### 4. UI Enhancements

Consider adding:
- Device picker dialog for selecting from multiple Chromecasts
- Volume control slider
- Playback position indicator for videos
- Connection status indicator
- Error messages with retry options

## Resources

- [Google Cast Android Developer Guide](https://developers.google.com/cast/docs/android_sender)
- [Google Cast iOS Developer Guide](https://developers.google.com/cast/docs/ios_sender)
- [Cast Design Checklist](https://developers.google.com/cast/docs/design_checklist)

## Support

For implementation assistance, refer to:
- Google Cast SDK documentation
- Stack Overflow for specific technical issues
- Google Cast Developer Console for receiver app configuration