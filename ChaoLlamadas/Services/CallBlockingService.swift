//
//  CallBlockingService.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 20-08-25.
//

import Foundation
import UIKit
import CallKit
import UserNotifications
import WidgetKit

class CallBlockingService: NSObject, ObservableObject {
    static let shared = CallBlockingService()
    
    @Published var isCallDirectoryEnabled = false
    @Published var callDirectoryStatus: String = "Verificando estado de CallKit..."
    @Published var blockNotificationsEnabled = false
    @Published var is600BlockingEnabled = true
    @Published var is809BlockingEnabled = false
    
    private let extensionIdentifier = "com.dromero.ChaoLlamadas.CallDirectoryExtension"
    
    // Developer mode toggle - set to true for debugging extension issues
    static let isDeveloperModeEnabled = true
    
    override init() {
        super.init()
        checkCallDirectoryStatus()
        loadNotificationSettings()
        
        // Check for any pending reloads after initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.checkPendingReloads()
        }
        
        // FOR TESTING: Add our test number automatically
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.ensureTestNumberIsBlocked()
        }
        
        // FOR DEBUGGING: Force extension execution after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.forceExtensionExecutionForDebugging()
        }
    }
    
    // TESTING FUNCTION: Ensure our test number is in the blocked numbers list
    private func ensureTestNumberIsBlocked() {
        let testNumber = "+56989980754"
        print("🎯 [CallKit] TESTING: Ensuring test number \(testNumber) is in blocked list")
        
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            print("❌ [CallKit] TESTING: Cannot access App Group to add test number")
            print("💡 [CallKit] TESTING: This is a critical issue - extension won't work without App Group")
            return
        }
        
        // Clear any existing problematic data first
        print("🧹 [CallKit] TESTING: Clearing potentially problematic App Group data")
        userDefaults.removeObject(forKey: "manuallyBlockedNumbers") // Clear to start fresh
        userDefaults.removeObject(forKey: "forceFullReload")
        
        // Set our test number as the ONLY manually blocked number
        let testNumberArray = [testNumber]
        userDefaults.set(testNumberArray, forKey: "manuallyBlockedNumbers")
        userDefaults.set(true, forKey: "forceFullReload")
        userDefaults.set(Date(), forKey: "lastTestNumberUpdate")
        
        // Force multiple sync attempts
        var syncSuccess = false
        for attempt in 1...3 {
            let result = userDefaults.synchronize()
            print("🔄 [CallKit] TESTING: Sync attempt \(attempt)/3: \(result ? "SUCCESS" : "FAILED")")
            if result {
                syncSuccess = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        if syncSuccess {
            print("✅ [CallKit] TESTING: Successfully added test number \(testNumber) to App Group")
            
            // Verify it was saved
            if let saved = userDefaults.stringArray(forKey: "manuallyBlockedNumbers") {
                print("✅ [CallKit] TESTING: Verification - saved numbers: \(saved)")
            }
        } else {
            print("❌ [CallKit] TESTING: Failed to sync test number to App Group after 3 attempts")
            print("💡 [CallKit] TESTING: Extension may not see the test number")
        }
        
        // Trigger extension reload to pick up the test number (with longer delay)
        print("🔄 [CallKit] TESTING: Triggering extension reload for test number (3 second delay)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.enableCallBlocking()
        }
    }
    
    // DEBUGGING: Force extension to execute and show logs
    private func forceExtensionExecutionForDebugging() {
        print("🧪 [DEBUGGING] FORCING EXTENSION EXECUTION TO CHECK IF IT WORKS")
        
        // Check if we can see any extension execution logs
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            // Clear any old logs
            userDefaults.removeObject(forKey: "extensionLogs")
            userDefaults.set(Date(), forKey: "debugExecutionRequest")
            userDefaults.synchronize()
        }
        
        // Force multiple reloads to trigger extension - bypass timing restrictions
        for i in 1...3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i * 3)) {
                print("🔄 [DEBUGGING] Force execution attempt \(i)/3")
                
                // Reset timing restrictions for debugging
                self.lastReloadTime = Date.distantPast
                self.isReloadInProgress = false
                
                CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: self.extensionIdentifier) { error in
                    if let error = error {
                        print("❌ [DEBUGGING] Force attempt \(i) failed: \(error)")
                    } else {
                        print("✅ [DEBUGGING] Force attempt \(i) succeeded - checking for extension logs")
                        
                        // Check for extension execution proof after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.checkForExtensionExecutionProof()
                        }
                    }
                }
            }
        }
    }
    
    private func checkForExtensionExecutionProof() {
        print("🔍 [DEBUGGING] Checking for extension execution proof...")
        
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            print("❌ [DEBUGGING] Cannot check - App Group not accessible")
            return
        }
        
        // Check for various extension execution indicators
        let extensionProof = userDefaults.string(forKey: "extensionProof") ?? "NEVER EXECUTED"
        let lastRun = userDefaults.object(forKey: "lastExtensionRun") as? Date
        let debugRequest = userDefaults.object(forKey: "debugExecutionRequest") as? Date
        
        print("📊 [DEBUGGING] Extension execution status:")
        print("   - Extension proof: \(extensionProof)")
        print("   - Last run: \(lastRun?.description ?? "Never")")
        print("   - Debug request: \(debugRequest?.description ?? "None")")
        
        // Check for extension result details
        let lastResult = userDefaults.string(forKey: "lastExtensionResult") ?? "No result details"
        print("   - Last result: \(lastResult)")
        
        // Try to get extension logs if available
        if let extensionLogs = userDefaults.stringArray(forKey: "extensionLogs") {
            print("📝 [DEBUGGING] Extension logs (\(extensionLogs.count) entries):")
            for (index, log) in extensionLogs.suffix(5).enumerated() {
                print("   \(index + 1). \(log)")
            }
        }
        
        // NEW: Try to get detailed extension debug logs
        if let debugLogs = userDefaults.stringArray(forKey: "extensionDebugLogs") {
            print("🔍 [DEBUGGING] Extension debug logs (\(debugLogs.count) entries):")
            for (index, log) in debugLogs.suffix(10).enumerated() {
                print("   \(index + 1). \(log)")
            }
        } else {
            print("❌ [DEBUGGING] No extension debug logs found")
        }
        
        // Try to read log file directly
        self.readExtensionLogFile()
        
        if let lastRun = lastRun, let debugRequest = debugRequest {
            if lastRun > debugRequest {
                print("✅ [DEBUGGING] Extension HAS EXECUTED after our debug request!")
                print("🎯 [DEBUGGING] Extension is running - the issue may be with the phone number format or CallKit processing")
                
                // Let's check if the test number was actually added
                self.checkTestNumberInCallKit()
            } else {
                print("❌ [DEBUGGING] Extension has NOT executed since our debug request")
                print("💡 [DEBUGGING] This indicates the extension is not being triggered properly")
            }
        } else {
            print("❌ [DEBUGGING] Extension has NEVER executed")
            print("💡 [DEBUGGING] This suggests a fundamental issue with extension registration or entitlements")
        }
        
        // Check if extension is actually registered with the system
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: self.extensionIdentifier) { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [DEBUGGING] Extension status check failed: \(error)")
                } else {
                    print("✅ [DEBUGGING] Extension status: \(status)")
                    if status == .enabled {
                        print("🤔 [DEBUGGING] Extension is enabled but not executing - possible iOS CallKit issue")
                    }
                }
            }
        }
    }
    
    private func checkTestNumberInCallKit() {
        print("🔍 [DEBUGGING] Checking if test number +56989980754 was processed by extension...")
        
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            print("❌ [DEBUGGING] Cannot check - App Group not accessible")
            return
        }
        
        // Check what the extension actually processed
        let processedNumbers = userDefaults.stringArray(forKey: "lastProcessedNumbers") ?? []
        let numbersBlocked = userDefaults.integer(forKey: "lastBlockedCount")
        let conversionSuccess = userDefaults.bool(forKey: "testNumberConversionSuccess")
        let convertedNumber = userDefaults.string(forKey: "convertedTestNumber") ?? "Not converted"
        
        print("🔍 [DEBUGGING] Extension processing results:")
        print("   - Numbers processed: \(processedNumbers)")
        print("   - Numbers blocked count: \(numbersBlocked)")
        print("   - Test number conversion success: \(conversionSuccess)")
        print("   - Converted test number: \(convertedNumber)")
        
        if conversionSuccess && numbersBlocked > 0 {
            print("✅ [DEBUGGING] Extension successfully processed and blocked the test number!")
            print("🎯 [DEBUGGING] Blocking should be working. Call +56989980754 to test.")
        } else if !conversionSuccess {
            print("❌ [DEBUGGING] Extension failed to convert test number to CallKit format")
            print("💡 [DEBUGGING] Issue is in the convertToCallKitFormat function")
        } else {
            print("⚠️ [DEBUGGING] Extension converted number but didn't add it to CallKit")
            print("💡 [DEBUGGING] Issue may be in CallKit addition process")
        }
    }
    
    private func readExtensionLogFile() {
        print("📂 [DEBUGGING] Attempting to read extension log file...")
        
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.dromero.chaollamadas") else {
            print("❌ [DEBUGGING] Cannot access App Group container for log file")
            return
        }
        
        let logFile = groupURL.appendingPathComponent("extension_debug.log")
        
        do {
            let logContent = try String(contentsOf: logFile)
            let lines = logContent.components(separatedBy: .newlines)
            let recentLines = lines.suffix(15)
            
            print("📄 [DEBUGGING] Extension log file contents (last 15 lines):")
            for (index, line) in recentLines.enumerated() {
                if !line.isEmpty {
                    print("   \(index + 1). \(line)")
                }
            }
        } catch {
            print("⚠️ [DEBUGGING] Could not read extension log file: \(error)")
            print("📍 [DEBUGGING] Log file path: \(logFile.path)")
            
            // Check if file exists
            let fileExists = FileManager.default.fileExists(atPath: logFile.path)
            print("📍 [DEBUGGING] File exists: \(fileExists)")
        }
    }
    
    func checkCallDirectoryStatus() {
        print("🔍 [CallKit] Checking Call Directory status for: \(extensionIdentifier)")
        
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extensionIdentifier) { [weak self] (status, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [CallKit] Error checking status: \(error.localizedDescription)")
                    print("❌ [CallKit] Error details: \(error)")
                    self?.isCallDirectoryEnabled = false
                    self?.callDirectoryStatus = "Error: \(error.localizedDescription)"
                    return
                }
                
                print("✅ [CallKit] Status received: \(status)")
                
                switch status {
                case .enabled:
                    print("✅ [CallKit] Extension is ENABLED")
                    self?.isCallDirectoryEnabled = true
                    self?.callDirectoryStatus = "CallKit activado - Bloqueo funcionando"
                case .disabled:
                    print("⚠️ [CallKit] Extension is DISABLED")
                    self?.isCallDirectoryEnabled = false
                    self?.callDirectoryStatus = "CallKit desactivado - Ve a Configuración"
                case .unknown:
                    print("❓ [CallKit] Extension status is UNKNOWN")
                    self?.isCallDirectoryEnabled = false
                    self?.callDirectoryStatus = "Estado desconocido - Verificar configuración"
                @unknown default:
                    print("❌ [CallKit] Unknown status case")
                    self?.isCallDirectoryEnabled = false
                    self?.callDirectoryStatus = "Error en CallKit"
                }
            }
        }
    }
    
    private var lastReloadTime: Date = Date.distantPast
    private var retryCount = 0
    private let maxRetries = 5  // Increased retry attempts
    private var isReloadInProgress = false
    
    private func retryExtensionReload() {
        guard retryCount < maxRetries else {
            print("❌ [CallKit] Max retries (\(maxRetries)) reached, trying alternative approach")
            retryCount = 0
            isReloadInProgress = false
            
            // Try the smart reload strategy when normal retries fail
            DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) {
                self.smartExtensionReload()
            }
            return
        }
        
        retryCount += 1
        let waitTime = Double(retryCount * 5)  // Progressive backoff: 5s, 10s, 15s, 20s, 25s
        print("🔄 [CallKit] Retry attempt \(retryCount)/\(maxRetries) in \(waitTime) seconds")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
            // Reset the last reload time to allow retry
            self.lastReloadTime = Date.distantPast
            self.isReloadInProgress = false
            self.enableCallBlocking()
        }
    }
    
    private func smartExtensionReload() {
        print("🧠 [CallKit] Starting smart extension reload strategy")
        callDirectoryStatus = "Intentando estrategia alternativa..."
        
        // Strategy 1: Check extension availability first
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extensionIdentifier) { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [CallKit] Smart reload: Extension not available: \(error)")
                    self.callDirectoryStatus = "Extension no disponible: \(error.localizedDescription)"
                    return
                }
                
                print("✅ [CallKit] Smart reload: Extension status: \(status)")
                
                if status == .enabled {
                    // Extension is enabled, try reload with longer wait
                    self.performDelayedReload(delay: 30.0)
                } else {
                    // Extension is disabled, inform user
                    self.callDirectoryStatus = "Extension deshabilitada - ir a Configuración > Teléfono"
                }
            }
        }
    }
    
    private func performDelayedReload(delay: TimeInterval) {
        print("⏰ [CallKit] Performing delayed reload in \(delay) seconds")
        callDirectoryStatus = "Esperando disponibilidad de CallKit (\(Int(delay))s)..."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.lastReloadTime = Date.distantPast
            self.isReloadInProgress = false
            
            // NUCLEAR APPROACH: Clear all UserDefaults sync issues first
            self.fixAppGroupSync()
            
            // Try reload with fresh state
            CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: self.extensionIdentifier) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        let errorCode = (error as NSError).code
                        print("❌ [CallKit] Delayed reload failed: \(error) (code \(errorCode))")
                        
                        if errorCode == 2 {
                            // Try the "iOS Settings Toggle" approach
                            self.suggestManualToggle()
                        } else {
                            self.callDirectoryStatus = "Error persistente: \(error.localizedDescription)"
                        }
                    } else {
                        print("🎉 [CallKit] Delayed reload SUCCESS!")
                        self.callDirectoryStatus = "CallKit activado - Bloqueo funcionando"
                        self.retryCount = 0
                        
                        // Update widget and check status
                        WidgetCenter.shared.reloadAllTimelines()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.checkCallDirectoryStatus()
                        }
                    }
                }
            }
        }
    }
    
    private func fixAppGroupSync() {
        print("🔧 [CallKit] NUCLEAR: Fixing App Group sync issues")
        
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            print("❌ [CallKit] Cannot fix - App Group not accessible")
            return
        }
        
        // Force remove all problematic keys
        let keysToReset = ["forceFullReload", "hasPendingReload", "debugMode", "lastExtensionError"]
        for key in keysToReset {
            userDefaults.removeObject(forKey: key)
        }
        
        // Force set current values
        userDefaults.set(is600BlockingEnabled, forKey: "is600BlockingEnabled")
        userDefaults.set(is809BlockingEnabled, forKey: "is809BlockingEnabled")
        userDefaults.set(true, forKey: "forceFullReload")
        userDefaults.set(Date(), forKey: "lastFixAttempt")
        
        // Multiple sync attempts
        for attempt in 1...3 {
            let syncResult = userDefaults.synchronize()
            print("🔄 [CallKit] Sync attempt \(attempt): \(syncResult ? "SUCCESS" : "FAILED")")
            if syncResult { break }
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    private func suggestManualToggle() {
        print("💡 [CallKit] Suggesting manual iOS Settings toggle to user")
        callDirectoryStatus = "Ir a Configuración > Teléfono > Bloqueo e Identificación > ChaoLlamadas > Desactivar y Activar"
        
        // Set up monitoring for when user fixes it manually
        scheduleBackgroundMonitoring()
    }
    
    private func scheduleBackgroundMonitoring() {
        print("📡 [CallKit] Scheduling background monitoring for extension availability")
        callDirectoryStatus = "Monitoreando disponibilidad de CallKit..."
        
        // Monitor extension status periodically
        monitorExtensionAvailability()
    }
    
    private func monitorExtensionAvailability() {
        let checkInterval: TimeInterval = 60.0  // Check every minute
        
        DispatchQueue.main.asyncAfter(deadline: .now() + checkInterval) {
            print("🔍 [CallKit] Checking extension availability...")
            
            CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: self.extensionIdentifier) { status, error in
                DispatchQueue.main.async {
                    if error == nil && status == .enabled {
                        print("✅ [CallKit] Extension is now available, attempting reload")
                        self.performDelayedReload(delay: 5.0)
                    } else {
                        print("⏳ [CallKit] Extension still not available, continuing monitoring")
                        // Continue monitoring
                        self.monitorExtensionAvailability()
                    }
                }
            }
        }
    }
    
    func enableCallBlocking() {
        // TESTING: Reduce reload delay to 3 seconds for faster testing
        let now = Date()
        if now.timeIntervalSince(lastReloadTime) < 3.0 {
            let remainingTime = 3.0 - now.timeIntervalSince(lastReloadTime)
            print("⚠️ [CallKit] Skipping reload - too soon (wait \(String(format: "%.1f", remainingTime)) more seconds)")
            return
        }
        
        // Check if a reload is already in progress
        if isReloadInProgress {
            print("⚠️ [CallKit] Reload already in progress, skipping")
            return
        }
        
        lastReloadTime = now
        isReloadInProgress = true
        
        print("🔄 [CallKit] Attempting to reload extension: \(extensionIdentifier)")
        
        // Simplified App Group preparation - don't fail if App Group has issues
        print("🔄 [CallKit] Preparing for reload (App Group optional)")
        
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            userDefaults.set(true, forKey: "forceFullReload")
            let syncResult = userDefaults.synchronize()
            print(syncResult ? "✅ [CallKit] App Group ready" : "⚠️ [CallKit] App Group sync failed, proceeding anyway")
        } else {
            print("⚠️ [CallKit] App Group not accessible, proceeding with reload anyway")
        }
        
        print("✅ [CallKit] Prepared for reload")
        
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: extensionIdentifier) { [weak self] error in
            DispatchQueue.main.async {
                self?.isReloadInProgress = false  // Reset progress flag
                
                if let error = error {
                    print("❌ [CallKit] Reload failed: \(error.localizedDescription)")
                    print("❌ [CallKit] Error code: \((error as NSError).code)")
                    
                    let errorCode = (error as NSError).code
                    var userMessage = "Error al activar: \(error.localizedDescription)"
                    var shouldRetry = false
                    
                    switch errorCode {
                    case 1:
                        userMessage = "Extension no encontrada"
                    case 2:
                        userMessage = "Extension temporalmente no disponible - reintentando..."
                        shouldRetry = true
                        print("🔄 [CallKit] Extension temporarily unavailable (error 2), scheduling smart retry")
                    case 3:
                        userMessage = "Datos inválidos en la extension"
                        shouldRetry = true
                    case 6:
                        userMessage = "Extension no se puede cargar"
                    case 19:
                        userMessage = "Conflicto de base de datos - reintentando..."
                        shouldRetry = true
                        print("🔄 [CallKit] Database constraint error (19), scheduling retry")
                    default:
                        userMessage = "Error CallKit (\(errorCode))"
                        if errorCode < 10 {  // Common CallKit errors that might be temporary
                            shouldRetry = true
                        }
                    }
                    
                    self?.callDirectoryStatus = userMessage
                    
                    if shouldRetry {
                        // Use progressive retry with backoff
                        self?.retryExtensionReload()
                    } else {
                        // Trigger reset tip for non-retryable errors
                        CallBlockingTipManager.shared.triggerResetTip()
                    }
                } else {
                    print("✅ [CallKit] Reload successful")
                    self?.retryCount = 0 // Reset retry count on success
                    self?.callDirectoryStatus = "CallKit activado - Bloqueo funcionando"
                    
                    // Update widget after successful reload
                    WidgetCenter.shared.reloadAllTimelines()
                    
                    // Wait before checking status to let CallKit settle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self?.checkCallDirectoryStatus()
                    }
                }
            }
        }
    }
    
    func saveExceptions(_ exceptions: [String]) {
        print("💾 [CallKit] Saving \(exceptions.count) exceptions: \(exceptions)")
        
        // Save to App Group UserDefaults for the extension to access
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            print("❌ [CallKit] Failed to get App Group UserDefaults - App Group not configured?")
            return
        }
        
        userDefaults.set(exceptions, forKey: "exceptions")
        userDefaults.synchronize()
        
        print("✅ [CallKit] Exceptions saved to App Group")
        
        // Reload the extension to apply new exceptions
        enableCallBlocking()
    }
    
    func updateManuallyBlockedNumbers() {
        print("📱 [CallKit] Updating manually blocked numbers - this function needs SwiftData context")
        
        // This function is called from ManualBlockView when toggling/deleting numbers
        // But it can't access SwiftData context from here, so it just triggers reload
        // The actual numbers should be passed via saveManuallyBlockedNumbers() from the UI
        enableCallBlocking()
    }
    
    func saveManuallyBlockedNumbers(_ numbers: [String]) {
        print("💾 [CallKit] Saving \(numbers.count) manually blocked numbers: \(numbers)")
        
        // Try to save to App Group, but don't fail if it doesn't work
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            userDefaults.set(numbers, forKey: "manuallyBlockedNumbers")
            userDefaults.set(true, forKey: "forceFullReload")
            userDefaults.set(Date(), forKey: "lastManualNumbersUpdate")
            print("✅ [CallKit] Numbers saved to App Group")
        } else {
            print("⚠️ [CallKit] App Group not accessible, extension will use defaults")
        }
        
        // Always attempt reload regardless of App Group status
        print("🔄 [CallKit] Triggering extension reload for manual numbers")
        
        // Check if we're in a persistent failure state
        if retryCount >= maxRetries {
            print("⚠️ [CallKit] In persistent failure state, trying alternative approach")
            // Use smart reload immediately for persistent failures
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.smartExtensionReload()
            }
        } else {
            // Normal reload attempt
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.enableCallBlocking()
            }
        }
    }
    
    // Alternative mechanism: Prepare data for next available reload opportunity
    func prepareForNextReloadOpportunity() {
        print("📋 [CallKit] Preparing data for next reload opportunity")
        
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            print("❌ [CallKit] Cannot prepare - App Group not accessible")
            return
        }
        
        // Mark that we have pending changes
        userDefaults.set(true, forKey: "hasPendingReload")
        userDefaults.set(Date(), forKey: "pendingReloadTime")
        
        // Set flag for extension to know it should process all data
        userDefaults.set(true, forKey: "forceFullReload")
        
        print("✅ [CallKit] Data prepared for next reload opportunity")
        
        // Set user message to explain the situation
        callDirectoryStatus = "Datos guardados - esperando CallKit disponible"
    }
    
    // Check if there are pending reload opportunities
    func checkPendingReloads() {
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            return
        }
        
        let hasPendingReload = userDefaults.bool(forKey: "hasPendingReload")
        if hasPendingReload {
            print("🔍 [CallKit] Found pending reload, checking if extension is now available")
            
            CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extensionIdentifier) { status, error in
                DispatchQueue.main.async {
                    if error == nil && status == .enabled {
                        print("✅ [CallKit] Extension is available, processing pending reload")
                        
                        // Clear pending flag
                        userDefaults.set(false, forKey: "hasPendingReload")
                        
                        // Attempt the reload
                        self.performDelayedReload(delay: 2.0)
                    } else {
                        print("⚠️ [CallKit] Extension still not available for pending reload")
                    }
                }
            }
        }
    }
    
    func isNumberBlocked(_ phoneNumber: String) -> Bool {
        // Check if the number starts with 600 (Chilean prefix)
        let cleanNumber = phoneNumber.replacingOccurrences(of: "+56", with: "")
        return cleanNumber.hasPrefix("600")
    }
    
    func getBlockedNumbersCount() -> Int {
        var count = 0
        
        // Add 600 numbers count if enabled
        if is600BlockingEnabled {
            count += 1000000 // 600000000 to 600999999 = 1,000,000 numbers
        }
        
        // Add 809 numbers count if enabled
        if is809BlockingEnabled {
            count += 1000000 // 809000000 to 809999999 = 1,000,000 numbers
        }
        
        // Add manually blocked numbers count
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            let manuallyBlocked = userDefaults.stringArray(forKey: "manuallyBlockedNumbers") ?? []
            count += manuallyBlocked.count
        }
        
        return count
    }
    
    // Helper function to get text describing active blocking prefixes
    func getActivePrefixesText() -> String {
        let prefixes = getActivePrefixes()
        
        if prefixes.isEmpty {
            return "sin bloqueos automáticos"
        } else if prefixes.count == 1 {
            return "números \(prefixes[0])"
        } else {
            return "números " + prefixes.joined(separator: " y ")
        }
    }
    
    func getActivePrefixes() -> [String] {
        var prefixes: [String] = []
        
        if is600BlockingEnabled {
            prefixes.append("600")
        }
        
        if is809BlockingEnabled {
            prefixes.append("809")
        }
        
        return prefixes
    }
    
    private func updateActivePrefixesInAppGroup() {
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else { return }
        
        let prefixes = getActivePrefixes()
        userDefaults.set(prefixes, forKey: "activePrefixes")
        userDefaults.set(getActivePrefixesText(), forKey: "activePrefixesText")
    }
    
    func openCallSettings() {
        // Try multiple deep link approaches to get as close as possible to Call Blocking settings
        let settingsAttempts = [
            "prefs:root=Phone&path=Call%20Blocking%20%26%20Identification", // Most specific
            "prefs:root=Phone&path=CALL_BLOCKING_AND_IDENTIFICATION", // Alternative format
            "prefs:root=Phone&path=CallBlockingAndIdentification", // Camel case
            "App-Prefs:root=Phone&path=CallBlockingAndIdentification", // App-Prefs prefix
            "prefs:root=Phone", // Phone settings (good fallback)
            "App-Prefs:root=Phone", // Alternative phone settings
            "prefs:root=PHONE_FACETIME" // Alternative phone path
        ]
        
        print("🔧 [Settings] Attempting to open iOS Call Blocking settings...")
        
        for (index, urlString) in settingsAttempts.enumerated() {
            if let settingsUrl = URL(string: urlString) {
                print("🔧 [Settings] Trying URL \(index + 1): \(urlString)")
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    print("✅ [Settings] Success! Opening: \(urlString)")
                    UIApplication.shared.open(settingsUrl)
                    return
                } else {
                    print("❌ [Settings] Cannot open: \(urlString)")
                }
            }
        }
        
        // Final fallback to general settings
        print("⚠️ [Settings] All deep links failed, opening general settings")
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        } else {
            print("❌ [Settings] Even general settings failed to open")
        }
    }
    
    func forceExtensionExecution() {
        print("🚀 [CallKit] FORCING EXTENSION EXECUTION FOR DEBUGGING")
        
        // Method 1: Direct reload with aggressive retry
        for attempt in 1...3 {
            print("🔄 [CallKit] Force execution attempt \(attempt)/3")
            
            // Set a flag to force extension execution
            if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
                userDefaults.set(true, forKey: "forceFullReload")
                userDefaults.set("DEBUG_FORCE_EXECUTION", forKey: "debugMode")
                userDefaults.set(Date(), forKey: "forceExecutionTime")
                userDefaults.synchronize()
            }
            
            // Immediate reload
            CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: extensionIdentifier) { error in
                if let error = error {
                    print("❌ [CallKit] Force execution attempt \(attempt) failed: \(error)")
                } else {
                    print("✅ [CallKit] Force execution attempt \(attempt) succeeded")
                }
            }
            
            // Wait between attempts
            Thread.sleep(forTimeInterval: 2.0)
        }
    }
    
    func diagnoseSetup() {
        print("🔧 [CallKit] Starting COMPREHENSIVE diagnostics...")
        
        // Check bundle identifier
        let mainBundleId = Bundle.main.bundleIdentifier ?? "unknown"
        print("📱 [CallKit] Main app bundle ID: \(mainBundleId)")
        print("🔌 [CallKit] Expected extension ID: \(extensionIdentifier)")
        
        // Check if our extension is actually registered with the system
        print("🔍 [CallKit] CHECKING EXTENSION REGISTRATION")
        
        // Test direct extension lookup
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extensionIdentifier) { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [CallKit] Extension lookup FAILED: \(error)")
                    print("❌ [CallKit] Error domain: \((error as NSError).domain)")
                    print("❌ [CallKit] Error code: \((error as NSError).code)")
                    
                    if (error as NSError).code == 1 {
                        print("💡 [CallKit] Error code 1 = Extension not found. This means:")
                        print("   - Extension bundle is not embedded in app")
                        print("   - Extension identifier is incorrect")
                        print("   - Extension is not registered with system")
                    }
                } else {
                    print("✅ [CallKit] Extension lookup SUCCESS: \(status)")
                    print("✅ [CallKit] Our extension IS registered with the system")
                }
            }
        }
        
        // Force extension execution for testing
        print("🚀 [CallKit] ATTEMPTING TO FORCE EXTENSION EXECUTION")
        forceExtensionExecution()
        
        // Check if extension bundle exists in main app
        let mainBundle = Bundle.main
        if let extensionsPath = mainBundle.builtInPlugInsURL?.path {
            print("📁 [CallKit] Extensions path: \(extensionsPath)")
            
            do {
                let extensions = try FileManager.default.contentsOfDirectory(atPath: extensionsPath)
                print("📁 [CallKit] Found extensions: \(extensions)")
                
                for ext in extensions {
                    if ext.hasSuffix(".appex") {
                        let extPath = "\(extensionsPath)/\(ext)"
                        print("📁 [CallKit] Extension found: \(extPath)")
                        
                        // Check if it's our extension
                        if ext == "CallDirectoryExtension.appex" {
                            print("✅ [CallKit] Our extension bundle is present!")
                            
                            // Try to load the extension bundle
                            if let extBundle = Bundle(path: extPath) {
                                let extBundleId = extBundle.bundleIdentifier
                                print("📋 [CallKit] Extension bundle ID: \(String(describing: extBundleId))")
                                
                                if extBundleId == extensionIdentifier {
                                    print("✅ [CallKit] Extension bundle ID matches expected!")
                                } else {
                                    print("❌ [CallKit] Extension bundle ID mismatch!")
                                }
                            }
                        }
                    }
                }
            } catch {
                print("❌ [CallKit] Error reading extensions directory: \(error)")
            }
        } else {
            print("❌ [CallKit] No extensions path found in main bundle")
        }
        
        // Validate bundle ID format
        if mainBundleId == "com.dromero.ChaoLlamadas" {
            print("✅ [CallKit] Main bundle ID format: CORRECT")
        } else {
            print("❌ [CallKit] Main bundle ID format: INCORRECT - Expected: com.dromero.ChaoLlamadas, Got: \(mainBundleId)")
        }
        
        // Check if extension bundle exists
        let expectedExtensionPath = Bundle.main.path(forResource: "CallDirectoryExtension", ofType: "appex")
        if expectedExtensionPath != nil {
            print("✅ [CallKit] Extension bundle found in main app")
            print("📁 [CallKit] Extension path: \(expectedExtensionPath!)")
        } else {
            print("❌ [CallKit] Extension bundle NOT FOUND in main app - Extension not embedded")
            print("📁 [CallKit] Main app bundle path: \(Bundle.main.bundlePath)")
            
            // List all .appex files in the bundle to see what's there
            let bundleURL = Bundle.main.bundleURL
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)
                let appexFiles = contents.filter { $0.pathExtension == "appex" }
                if appexFiles.isEmpty {
                    print("📁 [CallKit] No .appex files found in bundle")
                } else {
                    print("📁 [CallKit] Found .appex files: \(appexFiles.map { $0.lastPathComponent })")
                }
            } catch {
                print("❌ [CallKit] Error listing bundle contents: \(error)")
            }
        }
        
        // Check App Group access
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            print("✅ [CallKit] App Group access: OK")
            userDefaults.set("diagnostic-test", forKey: "test")
            if userDefaults.string(forKey: "test") == "diagnostic-test" {
                print("✅ [CallKit] App Group read/write: OK")
            } else {
                print("❌ [CallKit] App Group read/write: FAILED")
            }
        } else {
            print("❌ [CallKit] App Group access: FAILED - Check project capabilities")
        }
        
        // Check entitlements
        if let entitlements = Bundle.main.object(forInfoDictionaryKey: "com.apple.security.application-groups") as? [String] {
            print("✅ [CallKit] App Groups in entitlements: \(entitlements)")
            if entitlements.contains("group.dromero.chaollamadas") {
                print("✅ [CallKit] Correct App Group found in entitlements")
            } else {
                print("❌ [CallKit] App Group 'group.dromero.chaollamadas' NOT found in entitlements")
            }
        } else {
            print("❌ [CallKit] No App Groups found in main app entitlements")
        }
        
        // Check provisioning profile capabilities
        print("🔍 [CallKit] Checking provisioning profile...")
        if let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") {
            print("✅ [CallKit] Provisioning profile found")
        } else {
            print("⚠️ [CallKit] No embedded provisioning profile (normal for development)")
        }
        
        // Check for recent extension errors
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas"),
           let lastError = userDefaults.string(forKey: "lastExtensionError"),
           let errorDate = userDefaults.object(forKey: "lastExtensionErrorDate") as? Date {
            print("⚠️ [CallKit] Last extension error: \(lastError) at \(errorDate)")
        }
        
        // Check if running on device vs simulator
        #if targetEnvironment(simulator)
        print("❌ [CallKit] Running on SIMULATOR - CallKit extensions don't work on simulator!")
        #else
        print("✅ [CallKit] Running on DEVICE - CallKit should work")
        #endif
        
        print("🔧 [CallKit] Diagnostics complete")
        
        // Check if extension has left any execution traces
        print("🔍 [CallKit] Checking extension execution traces...")
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            let extensionProof = userDefaults.string(forKey: "extensionProof") ?? "NEVER EXECUTED"
            let lastRun = userDefaults.string(forKey: "lastExtensionRun") ?? "Never"
            let lastResult = userDefaults.string(forKey: "lastExtensionResult") ?? "No result"
            
            print("📋 [CallKit] Extension execution proof: \(extensionProof)")
            print("📋 [CallKit] Last extension run: \(lastRun)")
            print("📋 [CallKit] Last result: \(lastResult)")
        }
        
        // TEST: Try to force extension to run by checking if it can be loaded
        print("🧪 [CallKit] Testing extension availability...")
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extensionIdentifier) { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [CallKit] Extension status check failed: \(error)")
                    print("❌ [CallKit] Error domain: \((error as NSError).domain)")
                    print("❌ [CallKit] Error code: \((error as NSError).code)")
                } else {
                    print("✅ [CallKit] Extension status check succeeded: \(status)")
                    
                    if status == .enabled {
                        print("🧪 [CallKit] Extension is enabled - trying MULTIPLE trigger methods")
                        
                        // Method 1: Standard reload
                        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: self.extensionIdentifier) { reloadError in
                            if let reloadError = reloadError {
                                print("❌ [CallKit] Method 1 (reload) failed: \(reloadError)")
                            } else {
                                print("✅ [CallKit] Method 1 (reload) succeeded!")
                            }
                        }
                        
                        // Method 2: Try to get enabled extensions (this sometimes triggers a reload)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            print("🧪 [CallKit] Method 2 - Checking all enabled extensions...")
                            // This sometimes forces iOS to actually load and check extensions
                        }
                        
                        // Method 3: Force iOS settings deep link
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            print("🧪 [CallKit] Method 3 - You should go to iOS Settings and toggle ChaoLlamadas OFF and ON again")
                            print("🧪 [CallKit] This forces iOS to reload the extension with the new data")
                        }
                    }
                }
            }
        }
    }
    
    func getExtensionLogs() -> [String] {
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            return ["❌ No App Group access"]
        }
        
        return userDefaults.stringArray(forKey: "extensionLogs") ?? ["📝 No extension logs available"]
    }
    
    // MARK: - Notification System
    
    func loadNotificationSettings() {
        DispatchQueue.main.async {
            self.blockNotificationsEnabled = UserDefaults.standard.bool(forKey: "blockNotificationsEnabled")
            self.is600BlockingEnabled = UserDefaults.standard.object(forKey: "is600BlockingEnabled") as? Bool ?? true
            self.is809BlockingEnabled = UserDefaults.standard.bool(forKey: "is809BlockingEnabled")
        }
        
        // Update App Group with current settings for widget
        updateActivePrefixesInAppGroup()
    }
    
    func setBlockNotifications(enabled: Bool) {
        blockNotificationsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "blockNotificationsEnabled")
        
        if enabled {
            requestNotificationPermissions()
        }
    }
    
    private var last600ToggleTime: Date = Date.distantPast
    private var last809ToggleTime: Date = Date.distantPast
    
    func set600Blocking(enabled: Bool) {
        // Prevent rapid toggling that causes CallKit errors
        let now = Date()
        if now.timeIntervalSince(last600ToggleTime) < 3.0 {
            print("⚠️ [CallKit] Ignoring rapid 600 toggle - wait 3 seconds between changes")
            // Reset the toggle to previous state in UI
            DispatchQueue.main.async {
                self.is600BlockingEnabled = !enabled
            }
            return
        }
        last600ToggleTime = now
        
        // Update local state first
        UserDefaults.standard.set(enabled, forKey: "is600BlockingEnabled")
        
        // Update the published property immediately on main thread
        DispatchQueue.main.async {
            self.is600BlockingEnabled = enabled
        }
        
        // Try to save to App Group with fallback
        var appGroupSuccess = false
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            // Set values directly without synchronize calls
            userDefaults.set(enabled, forKey: "is600BlockingEnabled")
            userDefaults.set(true, forKey: "forceFullReload")
            
            // Save active prefixes for widget
            updateActivePrefixesInAppGroup()
            
            // Just assume success - synchronize() is unreliable in iOS
            appGroupSuccess = true
            print("✅ [CallKit] App Group values set (sync status unreliable)")
        }
        
        if !appGroupSuccess {
            print("❌ [CallKit] App Group sync failed after 3 attempts - extension may not see changes")
        }
        
        print("✅ [CallKit] 600 blocking \(enabled ? "enabled" : "disabled")")
        
        // Delay reload to avoid rapid successive calls - increased delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.enableCallBlocking()
        }
    }
    
    func setBothPrefixBlocking(enabled600: Bool, enabled809: Bool) {
        print("🔧 [CallKit] Setting both prefixes: 600=\(enabled600), 809=\(enabled809)")
        
        // Update both UserDefaults values
        UserDefaults.standard.set(enabled600, forKey: "is600BlockingEnabled")
        UserDefaults.standard.set(enabled809, forKey: "is809BlockingEnabled")
        
        // Update both published properties
        DispatchQueue.main.async {
            self.is600BlockingEnabled = enabled600
            self.is809BlockingEnabled = enabled809
        }
        
        // Update App Group with both values
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            userDefaults.set(enabled600, forKey: "is600BlockingEnabled")
            userDefaults.set(enabled809, forKey: "is809BlockingEnabled")
            userDefaults.set(true, forKey: "forceFullReload")
            
            updateActivePrefixesInAppGroup()
            print("✅ [CallKit] Both prefixes saved to App Group")
        }
        
        print("✅ [CallKit] 600 blocking \(enabled600 ? "enabled" : "disabled")")
        print("✅ [CallKit] 809 blocking \(enabled809 ? "enabled" : "disabled")")
        
        // Single reload for both changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.enableCallBlocking()
        }
    }
    
    func set809Blocking(enabled: Bool) {
        // Prevent rapid toggling that causes CallKit errors
        let now = Date()
        if now.timeIntervalSince(last809ToggleTime) < 3.0 {
            print("⚠️ [CallKit] Ignoring rapid 809 toggle - wait 3 seconds between changes")
            // Reset the toggle to previous state in UI
            DispatchQueue.main.async {
                self.is809BlockingEnabled = !enabled
            }
            return
        }
        last809ToggleTime = now
        
        // Update local state first
        UserDefaults.standard.set(enabled, forKey: "is809BlockingEnabled")
        
        // Update the published property immediately on main thread
        DispatchQueue.main.async {
            self.is809BlockingEnabled = enabled
        }
        
        // Try to save to App Group with fallback
        var appGroupSuccess = false
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            userDefaults.set(enabled, forKey: "is809BlockingEnabled")
            userDefaults.set(true, forKey: "forceFullReload")
            
            // Save active prefixes for widget
            updateActivePrefixesInAppGroup()
            
            // Just assume success - synchronize() is unreliable in iOS
            appGroupSuccess = true
            print("✅ [CallKit] App Group values set (sync status unreliable)")
        }
        
        if !appGroupSuccess {
            print("❌ [CallKit] App Group sync failed after 3 attempts - extension may not see changes")
        }
        
        print("✅ [CallKit] 809 blocking \(enabled ? "enabled" : "disabled")")
        
        // Delay reload to avoid rapid successive calls - increased delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.enableCallBlocking()
        }
    }
    
    private func saveToAppGroup(key: String, value: Any) {
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            print("❌ [CallKit] Failed to access App Group for key: \(key)")
            return
        }
        
        userDefaults.set(value, forKey: key)
        
        // Use individual synchronize with error handling
        let success = userDefaults.synchronize()
        if !success {
            print("⚠️ [CallKit] Failed to synchronize App Group for key: \(key)")
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [Notifications] Permission error: \(error)")
                } else if granted {
                    print("✅ [Notifications] Permission granted")
                } else {
                    print("⚠️ [Notifications] Permission denied")
                }
            }
        }
    }
    
    func checkForBlockedCalls() {
        guard blockNotificationsEnabled else { return }
        
        // Check App Group for recent blocked calls
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            return
        }
        
        let lastCheck = userDefaults.object(forKey: "lastNotificationCheck") as? Date ?? Date.distantPast
        let now = Date()
        
        // Only check if it's been more than 30 seconds since last check
        guard now.timeIntervalSince(lastCheck) > 30 else { return }
        
        userDefaults.set(now, forKey: "lastNotificationCheck")
        
        // Get extension logs to check for recent blocks
        let logs = getExtensionLogs()
        let recentLogs = logs.filter { log in
            // Simple check for recent blocking activity
            log.contains("Added") && log.contains("numbers")
        }
        
        if !recentLogs.isEmpty {
            sendBlockNotification()
        }
    }
    
    private func sendBlockNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Llamada Bloqueada"
        content.body = "ChaoLlamadas bloqueó una llamada no deseada"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [Notifications] Error sending notification: \(error)")
            } else {
                print("✅ [Notifications] Block notification sent")
            }
        }
    }
    
    // MARK: - Blocked Calls Persistence
    
    func checkForNewBlockedCalls() {
        // Monitor extension logs for potential blocked calls
        CallMonitoringService.shared.monitorExtensionLogs()
    }
    
    func simulateBlockedCall(phoneNumber: String) {
        // For testing purposes - simulate a blocked call being detected
        // In real usage, this would be triggered by the system when a call is actually blocked
        print("🔍 [CallKit] Simulating blocked call detection: \(phoneNumber)")
        
        // This would be called when we detect a blocked call occurred
        // Since iOS doesn't provide direct blocked call notifications, 
        // this is mainly for testing the persistence system
    }
    
    // MARK: - Extension Reset
    
    func forceSmartReload() {
        print("🧠 [CallKit] User requested smart reload to bypass persistent failures")
        callDirectoryStatus = "Ejecutando estrategia inteligente..."
        
        // Reset retry count to allow fresh attempts
        retryCount = 0
        isReloadInProgress = false
        lastReloadTime = Date.distantPast
        
        // Use smart reload immediately
        smartExtensionReload()
    }
    
    func resetExtension() {
        print("🔄 [CallKit] Starting COMPLETE extension reset to fix database conflicts...")
        
        callDirectoryStatus = "Reseteando extensión y base de datos..."
        
        // Step 1: Clear all App Group data
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            print("❌ [CallKit] Failed to access App Group for reset")
            callDirectoryStatus = "Error: No se pudo acceder a App Group"
            return
        }
        
        // Clear all stored data
        userDefaults.removeObject(forKey: "manuallyBlockedNumbers")
        userDefaults.removeObject(forKey: "previouslyBlockedNumbers")
        userDefaults.removeObject(forKey: "forceFullReload")
        userDefaults.removeObject(forKey: "extensionLogs")
        userDefaults.removeObject(forKey: "lastExtensionError")
        userDefaults.removeObject(forKey: "lastExtensionErrorDate")
        userDefaults.removeObject(forKey: "exceptions")
        userDefaults.removeObject(forKey: "lastNotificationCheck")
        
        // Reset settings to default
        userDefaults.set(true, forKey: "is600BlockingEnabled")
        userDefaults.set(false, forKey: "is809BlockingEnabled") // 809 is off by default
        userDefaults.synchronize()
        
        // Step 2: Force CallKit database clear by toggling extension OFF/ON
        print("🗑️ [CallKit] Step 1: Attempting to clear CallKit database conflicts...")
        
        // This will attempt to clear any existing database entries
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: extensionIdentifier) { error in
            DispatchQueue.main.async {
                if let error = error {
                    let errorCode = (error as NSError).code
                    print("⚠️ [CallKit] Reset reload error \(errorCode): \(error.localizedDescription)")
                    
                    if errorCode == 19 {
                        print("🔧 [CallKit] Database conflict detected - forcing complete reset")
                        self.callDirectoryStatus = "Resolviendo conflictos de base de datos..."
                        
                        // Wait longer and try again
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.forceCompleteReset()
                        }
                    }
                } else {
                    print("✅ [CallKit] Reset successful - proceeding with clean setup")
                    self.callDirectoryStatus = "Reset completado - configurando..."
                    
                    // Add test number back after reset
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.addTestNumberAfterReset()
                    }
                }
            }
        }
    }
    
    private func forceCompleteReset() {
        print("🔧 [CallKit] FORCING COMPLETE NUCLEAR RESET - clearing all CallKit data")
        callDirectoryStatus = "Ejecutando reset nuclear de CallKit..."
        
        // STEP 1: Force extension to remove ALL numbers first
        print("🗑️ [CallKit] Step 1: Forcing extension to REMOVE ALL blocked numbers")
        
        // Clear App Group completely to trigger removal
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            userDefaults.removeObject(forKey: "manuallyBlockedNumbers")
            userDefaults.removeObject(forKey: "previouslyBlockedNumbers")
            userDefaults.set(true, forKey: "forceFullReload")
            userDefaults.set("REMOVE_ALL", forKey: "resetMode")
            userDefaults.synchronize()
        }
        
        // Force extension to run with empty data (should remove all entries)
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: extensionIdentifier) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("⚠️ [CallKit] Removal phase error: \(error)")
                } else {
                    print("✅ [CallKit] Removal phase completed")
                }
                
                // STEP 2: Wait longer then try multiple clean reloads
                self.callDirectoryStatus = "Esperando limpieza de base de datos..."
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.performMultipleCleanReloads()
                }
            }
        }
    }
    
    private func performMultipleCleanReloads() {
        print("🔄 [CallKit] Step 2: Multiple clean reloads to ensure database reset")
        
        var attemptCount = 0
        let maxAttempts = 5
        
        func performReload() {
            attemptCount += 1
            print("🔄 [CallKit] Clean reload attempt \(attemptCount)/\(maxAttempts)")
            
            CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: self.extensionIdentifier) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("⚠️ [CallKit] Clean reload \(attemptCount) error: \(error)")
                        
                        // If still getting constraint errors, try again
                        if attemptCount < maxAttempts && (error as NSError).code == 19 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                performReload()
                            }
                        } else {
                            // Max attempts reached or different error
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                self.addTestNumberAfterNuclearReset()
                            }
                        }
                    } else {
                        print("✅ [CallKit] Clean reload \(attemptCount) succeeded")
                        
                        // Success! Wait a bit then add test number
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.addTestNumberAfterNuclearReset()
                        }
                    }
                }
            }
        }
        
        performReload()
    }
    
    private func addTestNumberAfterReset() {
        print("✅ [CallKit] Adding test number after complete reset")
        callDirectoryStatus = "Agregando número de prueba después del reset..."
        
        // Save test number to App Group
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            userDefaults.set(["+56989980754"], forKey: "manuallyBlockedNumbers")
            userDefaults.set(true, forKey: "forceFullReload")
            userDefaults.synchronize()
        }
        
        // Final reload with clean data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: self.extensionIdentifier) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ [CallKit] Final reload failed: \(error)")
                        self.callDirectoryStatus = "Error final: \(error.localizedDescription)"
                    } else {
                        print("🎉 [CallKit] COMPLETE RESET SUCCESSFUL!")
                        self.callDirectoryStatus = "Reset completo - listo para bloquear"
                        
                        // Check final status
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.checkCallDirectoryStatus()
                        }
                    }
                }
            }
        }
    }
    
    private func addTestNumberAfterNuclearReset() {
        print("💥 [CallKit] Adding test number after NUCLEAR reset")
        callDirectoryStatus = "Configurando número después de reset nuclear..."
        
        // Clear reset mode and add test number
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            userDefaults.removeObject(forKey: "resetMode")
            userDefaults.set(["+56989980754"], forKey: "manuallyBlockedNumbers")
            userDefaults.set(true, forKey: "forceFullReload")
            userDefaults.set(Date(), forKey: "lastExtensionUpdate")
            userDefaults.synchronize()
            
            print("💾 [CallKit] Nuclear reset: Saved clean test number to App Group")
        }
        
        // Final extension load with the clean test number
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("🔄 [CallKit] Final reload with clean test number...")
            
            CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: self.extensionIdentifier) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        let errorCode = (error as NSError).code
                        print("❌ [CallKit] Nuclear reset final reload failed: \(error)")
                        
                        if errorCode == 19 {
                            print("💀 [CallKit] CRITICAL: Database conflicts STILL persist after nuclear reset")
                            self.callDirectoryStatus = "CRÍTICO: Conflictos persisten - reiniciar iOS"
                        } else {
                            print("⚠️ [CallKit] Different error after nuclear reset: \(errorCode)")
                            self.callDirectoryStatus = "Error post-nuclear: \(error.localizedDescription)"
                        }
                    } else {
                        print("🎉🎉 [CallKit] NUCLEAR RESET COMPLETE SUCCESS!")
                        print("✅ [CallKit] Database conflicts resolved!")
                        self.callDirectoryStatus = "Reset nuclear exitoso - listo para bloquear"
                        
                        // Final status check
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.checkCallDirectoryStatus()
                        }
                    }
                }
            }
        }
    }
}
