# Widget Setup Instructions

## Required Xcode Configuration

### 1. Widget Target
- Target Name: `ChaoLlamadasWidget`
- Bundle ID: `com.dromero.ChaoLlamadas.ChaoLlamadasWidget` 
- Type: Widget Extension
- Configuration Intent: NO (unchecked)

### 2. App Groups Capability
The widget target needs the same App Groups capability as the main app:
- `group.dromero.chaollamadas`

### 3. Files in Widget Target
Ensure these files are included in the ChaoLlamadasWidget target:
- ✅ ChaoLlamadasWidget.swift
- ✅ ChaoLlamadasWidgetBundle.swift  
- ✅ Info.plist

### 4. Build Settings
- iOS Deployment Target: Same as main app
- Swift Language Version: Swift 5

### 5. Testing
1. Build and run the main app first
2. Long press on home screen
3. Tap "+" to add widgets
4. Search for "ChaoLlamadas"
5. Add widget to home screen

### Troubleshooting

**Widget doesn't appear in picker:**
- Ensure widget target is properly configured
- Check App Groups capability is enabled
- Verify bundle identifier is correct
- Clean build folder (⌘+Shift+K) and rebuild

**Widget shows "Unable to Load":**
- Check App Groups suite name matches exactly
- Ensure UserDefaults keys are being set by main app
- Verify widget has access to shared container

**Data not updating:**
- Main app needs to call `WidgetCenter.shared.reloadAllTimelines()` when data changes
- Check App Group UserDefaults are being written correctly