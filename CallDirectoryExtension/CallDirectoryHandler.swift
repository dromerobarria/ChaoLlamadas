//
//  CallDirectoryHandler.swift
//  CallDirectoryExtension
//
//  Created by Daniel Romero on 21-08-25.
//

import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        print("🚀 [CallDirectoryExtension] Request started")
        print("📊 [CallDirectoryExtension] Is incremental: \(context.isIncremental)")
        
        context.delegate = self

        // Check whether this is an "incremental" data request. If so, only provide the set of phone number blocking
        // and identification entries which have been added or removed since the last time this extension's data was loaded.
        // But the extension must still be prepared to provide the full set of data at any time, so add all blocking
        // and identification phone numbers if the request is not incremental.
        if context.isIncremental {
            print("🔄 [CallDirectoryExtension] Processing incremental request")
            addOrRemoveIncrementalBlockingPhoneNumbers(to: context)
            addOrRemoveIncrementalIdentificationPhoneNumbers(to: context)
        } else {
            print("📋 [CallDirectoryExtension] Processing full request")
            addAllBlockingPhoneNumbers(to: context)
            addAllIdentificationPhoneNumbers(to: context)
        }

        print("✅ [CallDirectoryExtension] Request completed")
        context.completeRequest()
    }

    private func addAllBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        print("🚫 [CallDirectoryExtension] Adding blocking numbers for all 600 prefix numbers")
        
        // Load exceptions from App Group UserDefaults
        let exceptions = loadExceptions()
        print("📋 [CallDirectoryExtension] Loaded \(exceptions.count) exceptions: \(exceptions)")
        
        var blockedCount = 0
        var skippedCount = 0
        
        // Block all Chilean 600 numbers (600000000 to 600999999)
        // Numbers must be provided in numerically ascending order
        for number in 600000000...600999999 {
            let numberString = String(number)
            
            // Skip if number is in exceptions
            if !isNumberInExceptions(numberString, exceptions: exceptions) {
                // Format as full Chilean number: +56 + number
                let fullNumber = CXCallDirectoryPhoneNumber(56000000000 + number)
                context.addBlockingEntry(withNextSequentialPhoneNumber: fullNumber)
                blockedCount += 1
            } else {
                skippedCount += 1
            }
            
            // Log progress every 100k numbers
            if number % 100000 == 0 {
                print("📊 [CallDirectoryExtension] Progress: \(number - 600000000 + 1)/1000000 numbers processed")
            }
        }
        
        print("✅ [CallDirectoryExtension] Blocking complete: \(blockedCount) blocked, \(skippedCount) exceptions")
    }

    private func addOrRemoveIncrementalBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // Retrieve any changes to the set of phone numbers to block from data store. For optimal performance and memory usage when there are many phone numbers,
        // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
        let phoneNumbersToAdd: [CXCallDirectoryPhoneNumber] = [ 1_408_555_1234 ]
        for phoneNumber in phoneNumbersToAdd {
            context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
        }

        let phoneNumbersToRemove: [CXCallDirectoryPhoneNumber] = [ 1_800_555_5555 ]
        for phoneNumber in phoneNumbersToRemove {
            context.removeBlockingEntry(withPhoneNumber: phoneNumber)
        }

        // Record the most-recently loaded set of blocking entries in data store for the next incremental load...
    }

    private func addAllIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        print("📱 [CallDirectoryExtension] Adding identification labels for 600 numbers")
        
        // Identify common 600 patterns with descriptive labels
        let phoneNumbers: [CXCallDirectoryPhoneNumber] = [
            56600000000,  // Generic 600 start
            56600123456,  // Common telemarketing pattern
            56600800800,  // Common service pattern
            56600900900   // Common sales pattern
        ]
        let labels = [
            "Llamada Comercial 600",
            "Telemarketing",
            "Servicio Comercial", 
            "Ventas Telefónicas"
        ]
        
        print("📋 [CallDirectoryExtension] Identifying \(phoneNumbers.count) common 600 patterns")
        
        for (phoneNumber, label) in zip(phoneNumbers, labels) {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
            print("📱 [CallDirectoryExtension] Identified: +56\(phoneNumber - 56000000000) as '\(label)'")
        }
        
        print("✅ [CallDirectoryExtension] Identification complete - \(phoneNumbers.count) numbers identified")
    }

    private func addOrRemoveIncrementalIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // Retrieve any changes to the set of phone numbers to identify (and their identification labels) from data store. For optimal performance and memory usage when there are many phone numbers,
        // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
        let phoneNumbersToAdd: [CXCallDirectoryPhoneNumber] = [ 1_408_555_5678 ]
        let labelsToAdd = [ "New local business" ]

        for (phoneNumber, label) in zip(phoneNumbersToAdd, labelsToAdd) {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
        }

        let phoneNumbersToRemove: [CXCallDirectoryPhoneNumber] = [ 1_888_555_5555 ]

        for phoneNumber in phoneNumbersToRemove {
            context.removeIdentificationEntry(withPhoneNumber: phoneNumber)
        }

        // Record the most-recently loaded set of identification entries in data store for the next incremental load...
    }
    
    // MARK: - Helper Methods
    
    private func loadExceptions() -> [String] {
        print("📂 [CallDirectoryExtension] Loading exceptions from App Group")
        
        // Load exceptions from App Group UserDefaults
        guard let userDefaults = UserDefaults(suiteName: "group.dromeroChaoLlamadas.chaollamadas") else {
            print("❌ [CallDirectoryExtension] Failed to access App Group UserDefaults")
            return []
        }
        
        let exceptions = userDefaults.stringArray(forKey: "exceptions") ?? []
        print("✅ [CallDirectoryExtension] Loaded \(exceptions.count) exceptions from App Group")
        return exceptions
    }
    
    private func isNumberInExceptions(_ number: String, exceptions: [String]) -> Bool {
        for exception in exceptions {
            if exception.contains("*") {
                // Handle prefix exceptions (e.g., "600123*")
                let prefix = exception.replacingOccurrences(of: "*", with: "")
                if number.hasPrefix(prefix) {
                    return true
                }
            } else {
                // Handle exact number exceptions
                if number == exception {
                    return true
                }
            }
        }
        return false
    }

}

// MARK: - CXCallDirectoryExtensionContextDelegate
extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        print("❌ [CallDirectoryExtension] Request FAILED with error:")
        print("❌ [CallDirectoryExtension] Error: \(error.localizedDescription)")
        print("❌ [CallDirectoryExtension] Error code: \((error as NSError).code)")
        print("❌ [CallDirectoryExtension] Error domain: \((error as NSError).domain)")
        print("❌ [CallDirectoryExtension] Full error: \(error)")
        
        // Save error to App Group for main app to display
        if let userDefaults = UserDefaults(suiteName: "group.dromeroChaoLlamadas.chaollamadas") {
            userDefaults.set(error.localizedDescription, forKey: "lastExtensionError")
            userDefaults.set(Date(), forKey: "lastExtensionErrorDate")
            userDefaults.synchronize()
            print("💾 [CallDirectoryExtension] Error saved to App Group for main app")
        }
        
        // An error occurred while adding blocking or identification entries, check the NSError for details.
        // For Call Directory error codes, see the CXErrorCodeCallDirectoryManagerError enum in <CallKit/CXError.h>.
        //
        // This may be used to store the error details in a location accessible by the extension's containing app, so that the
        // app may be notified about errors which occurred while loading data even if the request to load data was initiated by
        // the user in Settings instead of via the app itself.
    }
}