#!/bin/bash

# ChaoLlamadas - Build and Run Script
# This script builds and runs the ChaoLlamadas iOS app

echo "🔨 Building ChaoLlamadas..."

# Clean build
xcodebuild -project ChaoLlamadas.xcodeproj -scheme ChaoLlamadas clean

# Build for simulator
xcodebuild -project ChaoLlamadas.xcodeproj \
    -scheme ChaoLlamadas \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' \
    build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📱 You can now run the app from Xcode or use:"
    echo "xcodebuild -project ChaoLlamadas.xcodeproj -scheme ChaoLlamadas -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' test"
else
    echo "❌ Build failed!"
    exit 1
fi