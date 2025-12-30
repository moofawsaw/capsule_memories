#!/bin/bash

# Asset Loading Test Script
# This script helps test the asset loading fix

set -e

echo "🧹 Cleaning previous builds..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🏗️  Building web app..."
flutter build web --release

echo "✅ Build complete!"
echo ""
echo "📋 Build verification:"
echo "Checking build/web directory..."

if [ -f "build/web/index.html" ]; then
    echo "  ✅ index.html exists"
else
    echo "  ❌ index.html missing"
    exit 1
fi

if [ -f "build/web/flutter_bootstrap.js" ]; then
    echo "  ✅ flutter_bootstrap.js exists"
else
    echo "  ⚠️  flutter_bootstrap.js missing (may be generated at runtime)"
fi

if [ -d "build/web/assets" ]; then
    echo "  ✅ assets directory exists"
    ASSET_COUNT=$(find build/web/assets -type f | wc -l)
    echo "     Found $ASSET_COUNT asset files"
else
    echo "  ❌ assets directory missing"
    exit 1
fi

echo ""
echo "🚀 To test locally, run:"
echo "   cd build/web && python3 -m http.server 8000"
echo "   Then open http://localhost:8000 in your browser"
echo ""
echo "🔍 Testing checklist:"
echo "   1. Open browser DevTools (F12)"
echo "   2. Check Console tab for errors"
echo "   3. Check Network tab - verify all assets load (200 status)"
echo "   4. Verify window.__flutter_base_href__ in console"
echo "   5. Check that all images/icons/fonts display correctly"
echo ""
echo "📖 See ASSET_LOADING_TEST_GUIDE.md for detailed testing instructions"

