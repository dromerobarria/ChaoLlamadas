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
        // Check if notifications are enabled
        let notificationsEnabled = UserDefaults.standard.bool(forKey: "blockNotificationsEnabled")
        guard notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Llamada Bloqueada"
        content.body = "ChaoLlamadas bloqueó una llamada de \(formatPhoneNumber(phoneNumber))"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "blocked-call-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [CallMonitor] Error sending notification: \(error)")
            } else {
                print("✅ [CallMonitor] Blocked call notification sent")
            }
        }
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        let cleaned = number.replacingOccurrences(of: "+56", with: "")
        if cleaned.count >= 9 {
            let firstPart = String(cleaned.prefix(1))
            let secondPart = String(cleaned.dropFirst(1).prefix(4))
            let thirdPart = String(cleaned.dropFirst(5).prefix(4))
            return "+56 \(firstPart) \(secondPart) \(thirdPart)"
        }
        return "+56 \(cleaned)"
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
        
        // Check if call was potentially blocked
        if call.hasEnded && !call.hasConnected {
            print("📞 [CallMonitor] Call ended without connecting - might have been blocked")
            print("🎯 [CallMonitor] This could be our test number +56989980754 if blocking is working")
            NSLog("🎯 POTENTIALLY BLOCKED CALL DETECTED")
        }
        
        if !call.hasEnded && !call.hasConnected {
            print("📞 [CallMonitor] Incoming call detected - checking if it gets blocked")
            NSLog("📞 INCOMING CALL - Testing blocking effectiveness")
        }
    }
}
