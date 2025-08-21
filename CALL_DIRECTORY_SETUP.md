# CallKit Error Code 6 - Troubleshooting Guide

## Current Status
- ✅ Running on real device
- ✅ Extension embedded in main app
- ✅ App Groups configured in both targets
- ✅ Bundle ID: com.dromero.ChaoLlamadas.CallDirectoryExtension
- ❌ Error Code 6: Extension loading failed

## Common Causes for Error Code 6

### 1. **Deployment Target Mismatch**
Check in Xcode:
- Main app deployment target: iOS 17.0
- Extension deployment target: **MUST BE SAME OR LOWER**
- If extension is iOS 17.0 and main app is 16.0 → Error

### 2. **Missing Call Directory Entitlement**
In CallDirectoryExtension target:
- Go to Signing & Capabilities
- Check if "Call Directory" capability is added
- If not, add it manually

### 3. **Team/Provisioning Profile Mismatch**
Both targets must have:
- Same development team
- Compatible provisioning profiles
- App Groups enabled in Apple Developer Portal

### 4. **Extension Info.plist Issues**
Check CallDirectoryExtension/Info.plist:
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.callkit.call-directory</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).CallDirectoryHandler</string>
</dict>
```

### 5. **Code Signing Issues**
- Clean build folder (Cmd+Shift+K)
- Delete derived data
- Rebuild both targets
- Check for code signing errors in build log

## Quick Fixes to Try

### Fix 1: Lower Extension Deployment Target
1. Select CallDirectoryExtension target
2. Build Settings → Deployment → iOS Deployment Target
3. Set to iOS 16.0 or lower
4. Clean and rebuild

### Fix 2: Add Call Directory Capability
1. Select CallDirectoryExtension target
2. Signing & Capabilities → + Capability
3. Search "Call Directory" and add it
4. Rebuild

### Fix 3: Reset Code Signing
1. Both targets → Signing & Capabilities
2. Uncheck "Automatically manage signing"
3. Recheck "Automatically manage signing"
4. Rebuild

### Fix 4: Simplify Extension Code
Temporarily replace CallDirectoryHandler with minimal code to test loading.

## Next Steps
Run the app again and check for these specific logs to identify which fix is needed.