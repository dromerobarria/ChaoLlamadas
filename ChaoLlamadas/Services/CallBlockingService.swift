//
//  CallBlockingService.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 20-08-25.
//

import Foundation
import UIKit
import CallKit

class CallBlockingService: NSObject, ObservableObject {
    static let shared = CallBlockingService()
    
    @Published var isCallDirectoryEnabled = false
    @Published var callDirectoryStatus: String = "Verificando estado de CallKit..."
    
    private let extensionIdentifier = "com.dromero.ChaoLlamadasCallExt"
    
    override init() {
        super.init()
        checkCallDirectoryStatus()
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
    
    func enableCallBlocking() {
        print("🔄 [CallKit] Attempting to reload extension: \(extensionIdentifier)")
        
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: extensionIdentifier) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [CallKit] Reload failed: \(error.localizedDescription)")
                    print("❌ [CallKit] Error code: \((error as NSError).code)")
                    print("❌ [CallKit] Error domain: \((error as NSError).domain)")
                    print("❌ [CallKit] Full error: \(error)")
                    
                    let errorCode = (error as NSError).code
                    var userMessage = "Error al activar: \(error.localizedDescription)"
                    
                    switch errorCode {
                    case 1:
                        userMessage = "Extension no encontrada - Verificar configuración del proyecto"
                    case 2:
                        userMessage = "Extension no válida - Revisar bundle identifier"
                    case 3:
                        userMessage = "Datos inválidos en la extension"
                    case 6:
                        userMessage = "Extension no se puede cargar - Verificar App Groups y entitlements"
                    default:
                        userMessage = "Error CallKit (\(errorCode)): \(error.localizedDescription)"
                    }
                    
                    self?.callDirectoryStatus = userMessage
                } else {
                    print("✅ [CallKit] Reload successful")
                    self?.checkCallDirectoryStatus()
                }
            }
        }
    }
    
    func saveExceptions(_ exceptions: [String]) {
        print("💾 [CallKit] Saving \(exceptions.count) exceptions: \(exceptions)")
        
        // Save to App Group UserDefaults for the extension to access
        guard let userDefaults = UserDefaults(suiteName: "group.dromeroChaoLlamadas.chaollamadas") else {
            print("❌ [CallKit] Failed to get App Group UserDefaults - App Group not configured?")
            return
        }
        
        userDefaults.set(exceptions, forKey: "exceptions")
        userDefaults.synchronize()
        
        print("✅ [CallKit] Exceptions saved to App Group")
        
        // Reload the extension to apply new exceptions
        enableCallBlocking()
    }
    
    func isNumberBlocked(_ phoneNumber: String) -> Bool {
        // Check if the number starts with 600 (Chilean prefix)
        let cleanNumber = phoneNumber.replacingOccurrences(of: "+56", with: "")
        return cleanNumber.hasPrefix("600")
    }
    
    func getBlockedNumbersCount() -> Int {
        // 600000000 to 600999999 = 1,000,000 numbers
        return 1000000
    }
    
    func openCallSettings() {
        // Open iOS Settings > Phone > Call Blocking & Identification
        if let settingsUrl = URL(string: "App-Prefs:Phone") {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
                return
            }
        }
        
        // Fallback to general settings
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func diagnoseSetup() {
        print("🔧 [CallKit] Starting diagnostics...")
        
        // Check bundle identifier
        let mainBundleId = Bundle.main.bundleIdentifier ?? "unknown"
        print("📱 [CallKit] Main app bundle ID: \(mainBundleId)")
        print("🔌 [CallKit] Expected extension ID: \(extensionIdentifier)")
        
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
        } else {
            print("❌ [CallKit] Extension bundle NOT FOUND in main app - Extension not embedded")
        }
        
        // Check App Group access
        if let userDefaults = UserDefaults(suiteName: "group.dromeroChaoLlamadas.chaollamadas") {
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
            if entitlements.contains("group.dromeroChaoLlamadas.chaollamadas") {
                print("✅ [CallKit] Correct App Group found in entitlements")
            } else {
                print("❌ [CallKit] App Group 'group.dromeroChaoLlamadas.chaollamadas' NOT found in entitlements")
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
        if let userDefaults = UserDefaults(suiteName: "group.dromeroChaoLlamadas.chaollamadas"),
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
    }
}
