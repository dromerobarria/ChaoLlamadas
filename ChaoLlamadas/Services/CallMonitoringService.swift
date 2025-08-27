//
//  CallMonitoringService.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 25-08-25.
//

import Foundation
import CallKit
import SwiftData
import UserNotifications
import WidgetKit

class CallMonitoringService: NSObject, ObservableObject {
    static let shared = CallMonitoringService()
    
    private var modelContainer: ModelContainer?
    private let callObserver = CXCallObserver()
    
    override init() {
        super.init()
        setupCallObserver()
    }
    
    func setupModelContainer(_ container: ModelContainer) {
        self.modelContainer = container
        print("📊 [CallMonitor] Model container configured")
    }
    
    private func setupCallObserver() {
        callObserver.setDelegate(self, queue: nil)
        print("📞 [CallMonitor] Call observer configured")
    }
    
    private func logBlockedCall(phoneNumber: String) {
        guard let modelContainer = modelContainer else {
            print("❌ [CallMonitor] No model container available")
            return
        }
        
        print("📝 [CallMonitor] Logging blocked call: \(phoneNumber)")
        
        let context = ModelContext(modelContainer)
        
        // Check if this call is already logged recently (within last 5 minutes)
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        let descriptor = FetchDescriptor<CallRecord>(
            predicate: #Predicate<CallRecord> { record in
                record.phoneNumber == phoneNumber && record.callDate > fiveMinutesAgo
            }
        )
        
        do {
            let recentCalls = try context.fetch(descriptor)
            if !recentCalls.isEmpty {
                print("📝 [CallMonitor] Call already logged recently, skipping duplicate")
                return
            }
        } catch {
            print("❌ [CallMonitor] Error checking for recent calls: \(error)")
        }
        
        // Create new call record
        let callRecord = CallRecord(
            phoneNumber: phoneNumber,
            callDate: Date(),
            wasBlocked: true,
            callDuration: 0,
            callerName: determineCallerName(phoneNumber: phoneNumber)
        )
        
        context.insert(callRecord)
        
        do {
            try context.save()
            print("✅ [CallMonitor] Blocked call logged successfully")
            
            // Send notification if enabled
            sendBlockedCallNotification(phoneNumber: phoneNumber)
            
            // Update App Group with latest blocked call count
            updateBlockedCallCount()
        } catch {
            print("❌ [CallMonitor] Error saving blocked call: \(error)")
        }
    }
    
    private func determineCallerName(phoneNumber: String) -> String? {
        let cleaned = phoneNumber.replacingOccurrences(of: "+56", with: "")
        
        if cleaned.hasPrefix("600") {
            return "Número Comercial 600"
        }
        
        // Could add more caller identification logic here
        return nil
    }
    
    private func sendBlockedCallNotification(phoneNumber: String) {
        print("📱 [CallMonitor] Preparing to send blocked call notification for: \(phoneNumber)")
        
        // Check if notifications are enabled with improved detection
        let standardNotificationsEnabled = UserDefaults.standard.bool(forKey: "blockNotificationsEnabled")
        var appGroupNotificationsEnabled = false
        if let appGroupDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            appGroupNotificationsEnabled = appGroupDefaults.bool(forKey: "blockNotificationsEnabled")
        }
        
        let notificationsEnabled = standardNotificationsEnabled || appGroupNotificationsEnabled
        print("📱 [CallMonitor] Notification settings - Standard: \(standardNotificationsEnabled), AppGroup: \(appGroupNotificationsEnabled), Final: \(notificationsEnabled)")
        
        guard notificationsEnabled else {
            print("🔕 [CallMonitor] Notifications disabled - not sending notification")
            return
        }
        
        // Check notification permissions
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📱 [CallMonitor] Notification authorization status: \(settings.authorizationStatus.rawValue)")
            
            guard settings.authorizationStatus == .authorized else {
                print("❌ [CallMonitor] Notifications not authorized - cannot send notification")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "📵 Llamada Bloqueada"
            content.body = "ChaoLlamadas bloqueó una llamada de \(self.formatPhoneNumber(phoneNumber))"
            content.sound = .default
            content.badge = 1
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            let request = UNNotificationRequest(
                identifier: "blocked-call-\(Date().timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            print("📱 [CallMonitor] Scheduling notification: '\(content.title)' - '\(content.body)'")
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ [CallMonitor] Error sending notification: \(error)")
                } else {
                    print("✅ [CallMonitor] Blocked call notification sent successfully!")
                }
            }
        }
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        // Handle "Número desconocido" case
        if number == "Número desconocido" {
            return number
        }
        
        // Clean the number first
        let cleaned = number.replacingOccurrences(of: "+56", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        // Format Chilean phone numbers
        if cleaned.count >= 9 {
            let firstPart = String(cleaned.prefix(1))
            let secondPart = String(cleaned.dropFirst(1).prefix(4))
            let thirdPart = String(cleaned.dropFirst(5).prefix(4))
            return "+56 \(firstPart) \(secondPart) \(thirdPart)"
        }
        return "+56 \(cleaned)"
    }
    
    private func handlePotentialBlockedCall(callUUID: String) {
        print("🔔 [CallMonitor] Handling potential blocked call: \(callUUID)")
        
        // Check if notifications are enabled - with improved detection
        let standardNotificationsEnabled = UserDefaults.standard.bool(forKey: "blockNotificationsEnabled")
        print("🔍 [CallMonitor] Standard UserDefaults notification setting: \(standardNotificationsEnabled)")
        
        // Also check App Group UserDefaults as a fallback
        var appGroupNotificationsEnabled = false
        if let appGroupDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            appGroupNotificationsEnabled = appGroupDefaults.bool(forKey: "blockNotificationsEnabled")
            print("🔍 [CallMonitor] App Group notification setting: \(appGroupNotificationsEnabled)")
        }
        
        // Use either setting if enabled (OR logic)
        let notificationsEnabled = standardNotificationsEnabled || appGroupNotificationsEnabled
        print("🔍 [CallMonitor] Final notification enabled status: \(notificationsEnabled)")
        
        guard notificationsEnabled else {
            print("🔕 [CallMonitor] Notifications disabled in both locations, skipping blocked call notification")
            return
        }
        
        // Check if this looks like a blocked call by monitoring extension activity
        checkExtensionActivityForBlockedCall { [weak self] wasBlocked, phoneNumber in
            if wasBlocked {
                print("✅ [CallMonitor] Confirmed blocked call - sending notification")
                let notificationPhoneNumber = phoneNumber ?? "Número desconocido"
                print("📱 [CallMonitor] Notification will show phone number: '\(notificationPhoneNumber)'")
                self?.sendBlockedCallNotification(phoneNumber: notificationPhoneNumber)
                self?.logBlockedCallToDatabase(phoneNumber: phoneNumber)
            } else {
                print("🤔 [CallMonitor] Could not confirm blocked call, might be user rejection or network issue")
            }
        }
    }
    
    private func checkIfCallWasBlocked(callUUID: String) {
        print("🔍 [CallMonitor] Checking if call \(callUUID) was blocked")
        
        // Monitor for extension activity that indicates blocking
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkExtensionActivityForBlockedCall { wasBlocked, phoneNumber in
                if wasBlocked {
                    print("✅ [CallMonitor] Call \(callUUID) was confirmed blocked")
                } else {
                    print("❌ [CallMonitor] Call \(callUUID) was not blocked or could not be confirmed")
                }
            }
        }
    }
    
    private func checkExtensionActivityForBlockedCall(completion: @escaping (Bool, String?) -> Void) {
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            print("❌ [CallMonitor] Cannot check extension activity - App Group not accessible")
            completion(false, nil)
            return
        }
        
        // Check for recent extension activity
        let lastExtensionRun = userDefaults.object(forKey: "lastExtensionRun") as? Date ?? Date.distantPast
        let now = Date()
        
        // If extension ran recently (within last 10 seconds), likely processing a call
        if now.timeIntervalSince(lastExtensionRun) <= 10.0 {
            print("✅ [CallMonitor] Recent extension activity detected - likely blocked call")
            
            // Try to get the most recent blocked number from extension logs
            if let extensionLogs = userDefaults.stringArray(forKey: "extensionDebugLogs"), !extensionLogs.isEmpty {
                // Look for recent blocking activity in logs
                let recentLogs = extensionLogs.suffix(5)
                for log in recentLogs {
                    if log.contains("Manual number added") || log.contains("Adding to CallKit") {
                        // Extract phone number if possible
                        let phoneNumber = extractPhoneNumberFromLog(log)
                        completion(true, phoneNumber)
                        return
                    }
                }
            }
            
            // Extension was active but no specific number found
            completion(true, nil)
        } else {
            print("❌ [CallMonitor] No recent extension activity - call likely not blocked")
            completion(false, nil)
        }
    }
    
    private func extractPhoneNumberFromLog(_ log: String) -> String? {
        // Try to extract phone number from log entries like "Manual number added: +56XXXXXXXXX"
        let pattern = "\\+56[0-9]{8,9}"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: log.utf16.count)
        
        if let match = regex?.firstMatch(in: log, range: range) {
            let phoneNumber = String(log[Range(match.range, in: log)!])
            return phoneNumber
        }
        
        return nil
    }
    
    private func logBlockedCallToDatabase(phoneNumber: String?) {
        guard let phoneNumber = phoneNumber else { return }
        
        print("📝 [CallMonitor] Logging blocked call to database: \(phoneNumber)")
        logBlockedCall(phoneNumber: phoneNumber)
        updateBlockedCallCount()
    }
    
    private func updateBlockedCallCount() {
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            return
        }
        
        guard let modelContainer = modelContainer else { return }
        let context = ModelContext(modelContainer)
        
        do {
            let descriptor = FetchDescriptor<CallRecord>(
                predicate: #Predicate<CallRecord> { $0.wasBlocked == true }
            )
            let blockedCalls = try context.fetch(descriptor)
            
            userDefaults.set(blockedCalls.count, forKey: "totalBlockedCallsCount")
            userDefaults.synchronize()
            
            // Update widget
            WidgetCenter.shared.reloadAllTimelines()
            
            print("📊 [CallMonitor] Updated blocked calls count: \(blockedCalls.count)")
        } catch {
            print("❌ [CallMonitor] Error updating blocked calls count: \(error)")
        }
    }
    
    func monitorExtensionLogs() {
        // Monitor extension logs for blocked calls
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            return
        }
        
        let logs = userDefaults.stringArray(forKey: "extensionLogs") ?? []
        let lastProcessedIndex = UserDefaults.standard.integer(forKey: "lastProcessedLogIndex")
        
        // Process new logs
        for i in lastProcessedIndex..<logs.count {
            let log = logs[i]
            
            // Look for blocked call patterns in logs
            if log.contains("Added") && log.contains("numbers") {
                // This indicates the extension was activated
                checkForRecentBlockedCalls()
            }
        }
        
        UserDefaults.standard.set(logs.count, forKey: "lastProcessedLogIndex")
    }
    
    private func checkForRecentBlockedCalls() {
        // Since we can't directly detect individual blocked calls,
        // we'll create a placeholder entry when the extension runs
        // This is a limitation of iOS - CallKit doesn't provide direct blocked call notifications
        
        print("📞 [CallMonitor] Extension was active - potential blocked calls occurred")
        
        // We could create a generic "Blocked calls detected" entry
        // but this might create false positives, so we'll just update the monitoring
    }
}

// MARK: - CXCallObserverDelegate
extension CallMonitoringService: CXCallObserverDelegate {
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        print("📞 [CallMonitor] Call state changed: \(call.uuid), connected: \(call.hasConnected), ended: \(call.hasEnded)")
        
        // DETAILED CALL LOGGING FOR DEBUG
        print("🔍 [CallMonitor] CALL DETAILS:")
        print("   🆔 Call UUID: \(call.uuid)")
        print("   ✅ Has Connected: \(call.hasConnected)")
        print("   ❌ Has Ended: \(call.hasEnded)")
        print("   📊 Is Outgoing: \(call.isOutgoing)")
        print("   🔄 Is On Hold: \(call.isOnHold)")
        
        // Unfortunately, in newer iOS versions, CXCall doesn't expose phone numbers
        // This is a privacy/security limitation - apps can't see the phone numbers
        NSLog("🔍 CALL UUID: %@ | Connected: %@ | Ended: %@", 
              call.uuid.uuidString, 
              call.hasConnected ? "YES" : "NO",
              call.hasEnded ? "YES" : "NO")
        
        // Enhanced blocked call detection
        if call.hasEnded && !call.hasConnected && !call.isOutgoing {
            print("📞 [CallMonitor] Incoming call ended without connecting - likely blocked!")
            print("🎯 [CallMonitor] Triggering blocked call notification check")
            NSLog("🎯 BLOCKED CALL DETECTED - UUID: %@", call.uuid.uuidString)
            
            // Trigger notification for blocked call (delayed to allow extension processing)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.handlePotentialBlockedCall(callUUID: call.uuid.uuidString)
            }
        }
        
        if !call.hasEnded && !call.hasConnected && !call.isOutgoing {
            print("📞 [CallMonitor] Incoming call detected - monitoring for blocking")
            NSLog("📞 INCOMING CALL - UUID: %@", call.uuid.uuidString)
            
            // Start monitoring this call for potential blocking
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.checkIfCallWasBlocked(callUUID: call.uuid.uuidString)
            }
        }
    }
}
