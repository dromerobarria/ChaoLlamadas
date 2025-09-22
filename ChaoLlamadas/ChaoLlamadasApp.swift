//
//  ChaoLlamadasApp.swift
//  ChaoLlamadas - RESTORED ORIGINAL UI
//
//  Created by Daniel Romero on 20-08-25.
//

import SwiftUI
import SwiftData
import TipKit
import UserNotifications

@main
struct ChaoLlamadasApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CallRecord.self,
            BlockedNumber.self,
            ExceptionNumber.self
        ])
        
        // Try App Group first, fallback to main container if permissions fail
        var modelConfiguration: ModelConfiguration
        
        // Create App Group directory structure if it doesn't exist
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.dromero.chaollamadas") {
            let appSupportURL = groupURL.appendingPathComponent("Library/Application Support")
            
            do {
                try FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
                print("📁 [CoreData] Created App Group directory structure: \(appSupportURL.path)")
            } catch {
                print("⚠️ [CoreData] Could not create App Group directories: \(error)")
            }
        }
        
        do {
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, groupContainer: .identifier("group.dromero.chaollamadas"))
            let testContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ [CoreData] Successfully created App Group container")
            return testContainer
        } catch {
            print("⚠️ [CoreData] App Group container failed: \(error)")
            print("🔄 [CoreData] Falling back to main app container")
            
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                let mainContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("✅ [CoreData] Successfully created main app container")
                return mainContainer
            } catch {
                print("❌ [CoreData] Could not create any ModelContainer: \(error)")
                fatalError("Could not create ModelContainer: \(error.localizedDescription)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    LiquidGlassTabView()
                } else {
                    OnboardingView()
                }
            }
            .onAppear {
                print("🚀 [App] ChaoLlamadas started - restored original UI")
                print("🎯 [App] 600 prefix blocking + manual numbers")
                print("🔧 [App] Minimal CallKit implementation")
                
                // Configure Tips
                try? Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
                
                // Initialize CallMonitoringService with model container
                CallMonitoringService.shared.setupModelContainer(sharedModelContainer)
                
                // Clear notification badge on app launch
                clearNotificationBadge()
                
                // Update blocked calls count on app launch
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    CallMonitoringService.shared.monitorExtensionLogs()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    // Clear badge when app becomes active (foreground)
                    clearNotificationBadge()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func clearNotificationBadge() {
        print("🏷️ [App] Clearing notification badge")
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("❌ [App] Failed to clear badge: \(error)")
            } else {
                print("✅ [App] Notification badge cleared successfully")
            }
        }
    }
}