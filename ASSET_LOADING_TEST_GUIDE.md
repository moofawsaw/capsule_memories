# Asset Loading Fix - Testing Guide

## Problem Summary
The app was experiencing asset loading failures, specifically:
- `AssetManifest.bin.json` could not be loaded
- Static assets (icons, fonts, images) failing to render
- Issue persisted even after rollback

## Solution Implemented

### 1. Dynamic Base Href Configuration
- Added JavaScript to dynamically calculate and set the base href
- Handles cases where `$FLUTTER_BASE_HREF` placeholder isn't replaced during build
- Automatically detects if running in iframe or subdirectory
- Ensures base href always ends with `/` for proper path resolution

### 2. Error Handling
- Added comprehensive error listeners for asset loading failures
- Catches both script errors and unhandled promise rejections
- Logs detailed error information for debugging
- Prevents default error handling that could break the app

### 3. Loading State Management
- Added 30-second timeout to prevent permanent loading state
- Improved loader removal logic with safety checks

## How to Test

### Prerequisites
1. Ensure you have Flutter SDK installed
2. Run `flutter pub get` to ensure all dependencies are installed
3. Clear any previous builds: `flutter clean`

### Test 1: Local Development Build
```bash
# Build for web
flutter build web

# Serve the build locally
cd build/web
python3 -m http.server 8000
# Or use any local server

# Open in browser
# Navigate to http://localhost:8000
```

**Expected Results:**
- ✅ App loads without asset errors
- ✅ All icons and images display correctly
- ✅ Fonts render properly
- ✅ No console errors about AssetManifest
- ✅ Check browser console for `window.__flutter_base_href__` value

### Test 2: Preview/Iframe Environment
```bash
# Build for web with base href
flutter build web --base-href="/"

# Or if deploying to subdirectory
flutter build web --base-href="/your-subdirectory/"
```

**Testing in Preview:**
1. Deploy the build to your preview environment
2. Open browser DevTools (F12)
3. Check Console tab for:
   - No errors about `AssetManifest.bin.json`
   - `window.__flutter_base_href__` should show correct path
   - All assets should load successfully

**Expected Results:**
- ✅ No "Unable to load asset" errors
- ✅ All static assets visible
- ✅ Fonts render correctly
- ✅ Icons display properly

### Test 3: Network Tab Verification
1. Open browser DevTools → Network tab
2. Reload the page
3. Filter by "JS" or "Other"
4. Verify these files load successfully:
   - `flutter_bootstrap.js` (200 status)
   - `main.dart.js` (200 status)
   - `AssetManifest.bin.json` (200 status)
   - `FontManifest.json` (200 status)
   - All asset files in `assets/` directory

**Expected Results:**
- ✅ All files return 200 (OK) status
- ✅ No 404 (Not Found) errors
- ✅ No CORS errors

### Test 4: Console Error Check
1. Open browser DevTools → Console tab
2. Clear console
3. Reload the page
4. Check for any errors

**Expected Results:**
- ✅ No red error messages
- ✅ If errors appear, they should be caught and logged with `[Asset Load Error]` prefix
- ✅ No unhandled promise rejections

### Test 5: Visual Verification
Check these UI elements load correctly:
- [ ] App logo/icon
- [ ] All custom icons (heart, share, etc.)
- [ ] User avatars
- [ ] Memory images
- [ ] Font styles (Plus Jakarta Sans, Roboto, etc.)
- [ ] Background images
- [ ] Loading spinners

### Test 6: Different Base Paths
Test with different deployment scenarios:

```bash
# Root deployment
flutter build web --base-href="/"

# Subdirectory deployment
flutter build web --base-href="/app/"

# Custom path
flutter build web --base-href="/capsule-memories/"
```

For each build, verify assets load correctly.

## Debugging Tips

### If assets still fail to load:

1. **Check Base Href:**
   ```javascript
   // In browser console
   console.log(window.__flutter_base_href__);
   console.log(document.querySelector('base')?.href);
   ```

2. **Verify Asset Paths:**
   ```javascript
   // Check if AssetManifest exists
   fetch('AssetManifest.bin.json')
     .then(r => r.json())
     .then(console.log)
     .catch(console.error);
   ```

3. **Check Build Output:**
   ```bash
   # Verify build/web directory contains:
   ls build/web/
   # Should see:
   # - index.html
   # - flutter_bootstrap.js
   # - main.dart.js
   # - AssetManifest.bin.json
   # - assets/ directory
   ```

4. **Clear Browser Cache:**
   - Hard refresh: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)
   - Or clear browser cache completely

5. **Check CORS Settings:**
   - If deploying to different domain, ensure CORS headers are set
   - Check server configuration allows asset file types

## Common Issues and Solutions

### Issue: Base href not set correctly
**Solution:** The JavaScript in index.html should automatically detect and set it. Check console for `window.__flutter_base_href__`.

### Issue: Assets 404 errors
**Solution:** 
- Verify `flutter build web` completed successfully
- Check that `build/web/assets/` directory exists
- Ensure `pubspec.yaml` assets section is correct

### Issue: CORS errors
**Solution:**
- Configure server to allow asset file types
- Check if running in iframe with different origin

### Issue: AssetManifest.bin.json not found
**Solution:**
- Rebuild: `flutter clean && flutter build web`
- Verify build/web directory is not corrupted
- Check file permissions

## Verification Checklist

Before marking as fixed, verify:
- [ ] App loads without asset errors in console
- [ ] All images/icons display correctly
- [ ] Fonts render properly
- [ ] Works in local development
- [ ] Works in preview/iframe environment
- [ ] Works with different base href paths
- [ ] No 404 errors in Network tab
- [ ] Error handling catches and logs issues gracefully

## Additional Notes

- The fix is backward compatible - if `$FLUTTER_BASE_HREF` is properly replaced during build, it will use that value
- The dynamic base href calculation is a fallback for preview environments
- Error handling prevents the app from breaking completely if assets fail to load
- 30-second timeout ensures users don't see a permanent loading state

