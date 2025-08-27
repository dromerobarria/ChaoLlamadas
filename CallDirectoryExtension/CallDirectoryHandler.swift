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
        // MAXIMUM VISIBILITY - Multiple logging methods to ensure we see this
        let pid = getpid()
        let timestamp = Date()
        let timestampString = DateFormatter.debugTimestamp.string(from: timestamp)
        
        // MULTIPLE LOGGING METHODS for maximum visibility
        writeExtensionLog("🚀🚀🚀 ChaoLlamadas EXTENSION STARTING PID:\(pid) at \(timestampString)")
        writeExtensionLog("📱 Extension process started - iOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
        
        // NSLog for Console.app visibility
        NSLog("🚀🚀🚀 ChaoLlamadas EXTENSION STARTING PID:%d", pid)
        
        print("🚀🚀🚀 ChaoLlamadas EXTENSION STARTING PID:\(pid) 🚀🚀🚀")
        print("🚀🚀🚀 ChaoLlamadas EXTENSION STARTING 🚀🚀🚀")
        
        // Log system info
        let processInfo = ProcessInfo.processInfo
        print("📊 ChaoLlamadas Extension - iOS \(processInfo.operatingSystemVersionString) PID:\(pid)")
        
        // Set delegate with error handling
        context.delegate = self
        print("✅ Delegate set successfully")
        
        // Enhanced error handling around CallKit processing
        do {
            print("🎯 Starting CallKit processing...")
            
            // Use proper CallKit implementation based on the request type
            if context.isIncremental {
                print("🔄 Processing incremental request")
                NSLog("🔄 ChaoLlamadas: Processing incremental request")
                
                addOrRemoveIncrementalBlockingPhoneNumbers(to: context)
                print("✅ Incremental blocking completed")
                
                addOrRemoveIncrementalIdentificationPhoneNumbers(to: context)
                print("✅ Incremental identification completed")
            } else {
                print("📞 Processing full request")
                NSLog("📞 ChaoLlamadas: Processing full request")
                
                addAllBlockingPhoneNumbers(to: context)
                print("✅ Full blocking completed")
                
                addAllIdentificationPhoneNumbers(to: context)
                print("✅ Full identification completed")
            }
            
            print("🎉 All CallKit processing completed successfully")
            NSLog("🎉 ChaoLlamadas: All processing completed successfully")
            
        } catch let error as NSError {
            print("💥 FATAL ERROR during CallKit processing:")
            print("💥 Error: \(error)")
            print("💥 Code: \(error.code)")
            print("💥 Domain: \(error.domain)")
            print("💥 Description: \(error.localizedDescription)")
            
            NSLog("💥 ChaoLlamadas FATAL ERROR: %@", error.localizedDescription)
            NSLog("💥 Error code: %ld, domain: %@", error.code, error.domain)
            
            context.cancelRequest(withError: error)
            return
            
        } catch {
            print("💥 UNKNOWN ERROR during CallKit processing: \(error)")
            NSLog("💥 ChaoLlamadas UNKNOWN ERROR: %@", error.localizedDescription)
            
            context.cancelRequest(withError: error)
            return
        }
        
        // Save execution proof - simplified to avoid App Group sync issues
        print("💾 Extension executed successfully at \(timestamp.description)")
        print("💾 Extension executed successfully - blocking is active!")
        
        // Save execution proof to App Group for debugging
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            userDefaults.set("EXTENSION EXECUTED", forKey: "extensionProof")
            userDefaults.set(timestamp, forKey: "lastExtensionRun")
            userDefaults.set("Extension executed at \(timestamp.description)", forKey: "lastExtensionResult")
            
            // Save detailed processing results for main app to read  
            userDefaults.set([], forKey: "lastProcessedNumbers") // Will be updated during processing
            
            print("✅ [Extension] Saved execution proof and processing details to App Group")
        } else {
            print("❌ [Extension] Could not save execution proof - App Group not accessible")
        }
        
        print("🏁 COMPLETING REQUEST")
        writeExtensionLog("🏁 COMPLETING REQUEST - Extension finishing successfully")
        NSLog("🏁 ChaoLlamadas: COMPLETING REQUEST")
        
        context.completeRequest()
        
        print("✅ REQUEST COMPLETED")
        NSLog("✅ ChaoLlamadas: REQUEST COMPLETED") 
        NSLog("🎉 ChaoLlamadas Extension: Extension completed successfully")
        writeExtensionLog("✅ REQUEST COMPLETED - Extension execution finished")
    }

    private func addAllBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        let timestamp = DateFormatter.debugTimestamp.string(from: Date())
        print("🚫 [\(timestamp)] PRODUCTION MODE: Full blocking system active")
        print("🚫 [CallDirectoryExtension] Processing user preferences and manual numbers")
        logExtensionActivity("PRODUCTION MODE: Full blocking system")
        
        // FIRST: Clear any existing entries to avoid Error 19 (UNIQUE constraint failed)  
        print("🗑️ [\(timestamp)] STEP 0: Clearing existing CallKit entries to prevent duplicates")
        print("🧹 [\(timestamp)] Preparing clean slate for blocking entries")
        
        // PRODUCTION MODE: Try App Group first, fallback to defaults if needed
        var is600BlockingEnabled = true  // Default enabled
        var is809BlockingEnabled = false // Default disabled
        var exceptions: [String] = []
        var manuallyBlocked: [String] = []
        
        // Try to load from App Group with enhanced fallback handling
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            // CHECK FOR COMPLETE RESET FLAG FIRST
            let forceCompleteReset = userDefaults.bool(forKey: "forceCompleteReset")
            print("🔍 [\(timestamp)] Checking forceCompleteReset flag: \(forceCompleteReset)")
            
            if forceCompleteReset {
                print("💥 [\(timestamp)] COMPLETE RESET REQUESTED - Clearing ALL CallKit entries")
                writeExtensionLog("💥 COMPLETE RESET: Clearing all CallKit entries")
                NSLog("💥 ChaoLlamadas: COMPLETE RESET - Clearing all CallKit entries")
                
                // Clear ALL entries from CallKit database
                print("🗑️ [\(timestamp)] Calling removeAllBlockingEntries()")
                context.removeAllBlockingEntries()
                print("🗑️ [\(timestamp)] Calling removeAllIdentificationEntries()")
                context.removeAllIdentificationEntries()
                
                // Clear the reset flag
                userDefaults.set(false, forKey: "forceCompleteReset")
                userDefaults.synchronize()
                
                print("✅ [\(timestamp)] COMPLETE RESET FINISHED - All entries cleared from CallKit")
                writeExtensionLog("✅ COMPLETE RESET FINISHED - CallKit database cleared")
                NSLog("✅ ChaoLlamadas: COMPLETE RESET FINISHED - All CallKit entries cleared")
                
                logExtensionActivity("Complete reset executed - all CallKit entries cleared")
                return // Exit early - nothing else to do
            } else {
                print("ℹ️ [\(timestamp)] No reset requested - proceeding with normal operation")
            }
            
            is600BlockingEnabled = userDefaults.object(forKey: "is600BlockingEnabled") as? Bool ?? true
            is809BlockingEnabled = userDefaults.bool(forKey: "is809BlockingEnabled")
            exceptions = userDefaults.stringArray(forKey: "exceptions") ?? []
            
            // ENHANCED: Try primary method first, then fallback method
            manuallyBlocked = loadManualNumbersWithFallback(userDefaults: userDefaults)
            
            print("✅ [\(timestamp)] Loaded settings from App Group: 600=\(is600BlockingEnabled), 809=\(is809BlockingEnabled), exceptions=\(exceptions.count), manual=\(manuallyBlocked.count)")
        } else {
            print("⚠️ [\(timestamp)] App Group not accessible - using default settings: 600=\(is600BlockingEnabled), 809=\(is809BlockingEnabled)")
        }
        
        print("📊 [\(timestamp)] FINAL CONFIG: 600=\(is600BlockingEnabled), 809=\(is809BlockingEnabled), exceptions=\(exceptions.count), manual=\(manuallyBlocked.count)")
        writeExtensionLog("📊 CONFIG: 600=\(is600BlockingEnabled), 809=\(is809BlockingEnabled), exceptions=\(exceptions.count), manual=\(manuallyBlocked.count)")
        
        // Collect all numbers to block in a sorted array
        var numbersToBlock: [CXCallDirectoryPhoneNumber] = []
        var blockedCount = 0
        var skippedCount = 0
        
        // STEP 1: Add 600 prefix numbers if enabled
        if is600BlockingEnabled {
            print("📞 [\(timestamp)] STEP 1: Adding 600 prefix numbers (600000000-600999999)")
            writeExtensionLog("📞 STEP 1: Processing 600 prefix numbers")
            
            // Generate all 600 prefix numbers: 56600000000 to 56600999999 (E.164 format)
            let baseNumber: CXCallDirectoryPhoneNumber = 56600000000 // +56 600 000000 in E.164
            let rangeSize = 1000000 // 600000000 to 600999999 = 1 million numbers
            
            for i in 0..<rangeSize {
                let phoneNumber = baseNumber + CXCallDirectoryPhoneNumber(i)
                
                // Check if this number is in exceptions
                let phoneNumberString = "+56600" + String(format: "%06d", i)
                if !exceptions.contains(phoneNumberString) {
                    numbersToBlock.append(phoneNumber)
                    blockedCount += 1
                } else {
                    skippedCount += 1
                }
                
                // Log progress every 100k numbers
                if i > 0 && i % 100000 == 0 {
                    print("📊 [\(timestamp)] 600 Progress: \(i)/\(rangeSize) processed")
                }
            }
            
            print("✅ [\(timestamp)] 600 COMPLETE: Added \(blockedCount) numbers, skipped \(skippedCount) exceptions")
            writeExtensionLog("✅ 600 COMPLETE: \(blockedCount) numbers, \(skippedCount) exceptions")
        } else {
            print("⚠️ [\(timestamp)] 600 prefix blocking is DISABLED")
            writeExtensionLog("⚠️ 600 prefix blocking is DISABLED")
        }
        
        // STEP 2: Add 809 prefix numbers if enabled
        if is809BlockingEnabled {
            print("📞 [\(timestamp)] STEP 2: Adding 809 prefix numbers (809000000-809999999)")
            writeExtensionLog("📞 STEP 2: Processing 809 prefix numbers")
            
            var blocked809Count = 0
            var skipped809Count = 0
            
            // Generate all 809 prefix numbers: 56809000000 to 56809999999 (E.164 format)
            let baseNumber809: CXCallDirectoryPhoneNumber = 56809000000 // +56 809 000000 in E.164
            let rangeSize809 = 1000000 // 809000000 to 809999999 = 1 million numbers
            
            for i in 0..<rangeSize809 {
                let phoneNumber = baseNumber809 + CXCallDirectoryPhoneNumber(i)
                
                // Check if this number is in exceptions
                let phoneNumberString = "+56809" + String(format: "%06d", i)
                if !exceptions.contains(phoneNumberString) {
                    numbersToBlock.append(phoneNumber)
                    blocked809Count += 1
                } else {
                    skipped809Count += 1
                }
                
                // Log progress every 100k numbers
                if i > 0 && i % 100000 == 0 {
                    print("📊 [\(timestamp)] 809 Progress: \(i)/\(rangeSize809) processed")
                }
            }
            
            print("✅ [\(timestamp)] 809 COMPLETE: Added \(blocked809Count) numbers, skipped \(skipped809Count) exceptions")
            writeExtensionLog("✅ 809 COMPLETE: \(blocked809Count) numbers, \(skipped809Count) exceptions")
            blockedCount += blocked809Count
            skippedCount += skipped809Count
        } else {
            print("⚠️ [\(timestamp)] 809 prefix blocking is DISABLED")
            writeExtensionLog("⚠️ 809 prefix blocking is DISABLED")
        }
        
        // STEP 3A: Clear previously blocked manual numbers that are no longer active
        clearInactiveManualNumbers(context: context, currentNumbers: manuallyBlocked, timestamp: timestamp)
        
        // STEP 3B: Add currently active manually blocked numbers
        print("🔧 [\(timestamp)] STEP 3: Processing \(manuallyBlocked.count) manually blocked numbers")
        writeExtensionLog("🔧 STEP 3: Processing \(manuallyBlocked.count) manual numbers")
        
        var manualBlockedCount = 0
        var manualFailedCount = 0
        
        for (index, numberString) in manuallyBlocked.enumerated() {
            print("🔢 [\(timestamp)] Processing manual number \(index + 1): \(numberString)")
            
            if let phoneNumber = convertToCallKitFormat(numberString) {
                // Clear any existing entry for this number first
                context.removeBlockingEntry(withPhoneNumber: phoneNumber)
                context.removeIdentificationEntry(withPhoneNumber: phoneNumber)
                
                // Check if it's not already in prefix ranges (avoid duplicates)
                let isInPrefixRange = (is600BlockingEnabled && phoneNumber >= 56600000000 && phoneNumber <= 56600999999) ||
                                    (is809BlockingEnabled && phoneNumber >= 56809000000 && phoneNumber <= 56809999999)
                
                if !isInPrefixRange {
                    numbersToBlock.append(phoneNumber)
                    manualBlockedCount += 1
                    print("✅ [\(timestamp)] Manual number added: \(numberString) -> \(phoneNumber)")
                    
                    writeExtensionLog("✅ Manual: \(numberString) -> \(phoneNumber)")
                } else {
                    print("⚠️ [\(timestamp)] Manual number \(numberString) already covered by prefix blocking, skipping")
                }
            } else {
                print("❌ [\(timestamp)] Failed to convert manual number: \(numberString)")
                manualFailedCount += 1
            }
        }
        
        print("✅ [\(timestamp)] MANUAL NUMBERS COMPLETE: Added \(manualBlockedCount), failed \(manualFailedCount)")
        writeExtensionLog("✅ MANUAL COMPLETE: \(manualBlockedCount) added, \(manualFailedCount) failed")
        
        // Save processing results for debugging
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            userDefaults.set(manualFailedCount == 0, forKey: "manualConversionSuccess")
            userDefaults.set(manualBlockedCount, forKey: "manualBlockedCount")
            userDefaults.set(manuallyBlocked, forKey: "lastProcessedNumbers")
        }
        
        // STEP 4: Sort all numbers and add to CallKit
        print("📋 [\(timestamp)] STEP 4: Sorting and adding \(numbersToBlock.count) total numbers to CallKit")
        writeExtensionLog("📋 STEP 4: Adding \(numbersToBlock.count) numbers to CallKit")
        
        // Sort numbers in ascending order (required by CallKit)
        numbersToBlock.sort()
        
        if numbersToBlock.isEmpty {
            print("⚠️ [\(timestamp)] NO NUMBERS TO BLOCK!.")
            print("🔍 [\(timestamp)] DIAGNOSIS: Extension is running but no valid numbers to add")
        } else {
            print("🎯 [\(timestamp)] ADDING NUMBERS TO CALLKIT:")
            print("📊 [\(timestamp)] Total numbers to add: \(numbersToBlock.count)")
            
            for (index, phoneNumber) in numbersToBlock.enumerated() {
                print("📵 [\(timestamp)] Adding to CallKit #\(index + 1): \(phoneNumber)")
                writeExtensionLog("📵 Adding to CallKit #\(index + 1): \(phoneNumber)")
                
                // Add with error detection (CallKit will throw if there are issues)
                context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
                
                print("✅ [\(timestamp)] Successfully added: \(phoneNumber)")
                writeExtensionLog("✅ Successfully added: \(phoneNumber)")
            }
            
            print("🎉 [\(timestamp)] ALL \(numbersToBlock.count) NUMBERS ADDED TO CALLKIT!")
            writeExtensionLog("🎉 ALL \(numbersToBlock.count) NUMBERS ADDED TO CALLKIT!")
            NSLog("🎉 ChaoLlamadas Extension: Added %d numbers to CallKit successfully", numbersToBlock.count)
        }
        
        let totalBlocked = blockedCount + manualBlockedCount
        print("🎉 [\(timestamp)] BLOCKING COMPLETE: \(totalBlocked) total numbers blocked (600: \(is600BlockingEnabled ? blockedCount : 0), 809: \(is809BlockingEnabled ? (blockedCount - (is600BlockingEnabled ? blockedCount : 0)) : 0), manual: \(manualBlockedCount))")
        writeExtensionLog("🎉 COMPLETE: \(totalBlocked) total blocked")
        
        // Save final blocking count and state to App Group for debugging and incremental updates
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            userDefaults.set(numbersToBlock.count, forKey: "lastBlockedCount")
            
            // IMPORTANT: Store current manual numbers as "previous" for next incremental update
            userDefaults.set(manuallyBlocked, forKey: "previousManuallyBlockedNumbers")
            print("💾 [\(timestamp)] Stored \(manuallyBlocked.count) manual numbers as 'previous' state for incremental updates")
            
            userDefaults.synchronize()
            print("💾 [\(timestamp)] Saved blocking state to App Group")
        }
        
        logExtensionActivity("PRODUCTION MODE - Blocking complete: \(totalBlocked) numbers (600: \(is600BlockingEnabled), 809: \(is809BlockingEnabled), manual: \(manualBlockedCount))")
    }
    
    private func addOrRemoveIncrementalBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        let timestamp = DateFormatter.debugTimestamp.string(from: Date())
        print("🔄 [\(timestamp)] INCREMENTAL UPDATE: Processing incremental changes")
        writeExtensionLog("🔄 INCREMENTAL: Starting incremental blocking update")
        
        // Load current and previous numbers from App Group
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            print("❌ [\(timestamp)] App Group not accessible - falling back to full reload")
            addAllBlockingPhoneNumbers(to: context)
            return
        }
        
        // Get current manually blocked numbers
        let currentManual = loadManualNumbersWithFallback(userDefaults: userDefaults)
        
        // Get previously blocked numbers for comparison
        let previousManual = userDefaults.stringArray(forKey: "previousManuallyBlockedNumbers") ?? []
        
        // Calculate changes
        let currentSet = Set(currentManual)
        let previousSet = Set(previousManual)
        
        let numbersToAdd = currentSet.subtracting(previousSet)
        let numbersToRemove = previousSet.subtracting(currentSet)
        
        print("📊 [\(timestamp)] INCREMENTAL ANALYSIS:")
        print("   Current manual: \(currentManual.count)")
        print("   Previous manual: \(previousManual.count)")
        print("   To add: \(numbersToAdd.count)")
        print("   To remove: \(numbersToRemove.count)")
        
        writeExtensionLog("📊 INCREMENTAL: Add \(numbersToAdd.count), Remove \(numbersToRemove.count)")
        
        // Remove numbers first (important for avoiding conflicts)
        for numberString in numbersToRemove {
            if let phoneNumber = convertToCallKitFormat(numberString) {
                print("🗑️ [\(timestamp)] Removing from CallKit: \(phoneNumber) (\(numberString))")
                context.removeBlockingEntry(withPhoneNumber: phoneNumber)
                writeExtensionLog("🗑️ REMOVED: \(phoneNumber)")
            } else {
                print("❌ [\(timestamp)] Failed to convert for removal: \(numberString)")
            }
        }
        
        // Add new numbers
        for numberString in numbersToAdd {
            if let phoneNumber = convertToCallKitFormat(numberString) {
                print("➕ [\(timestamp)] Adding to CallKit: \(phoneNumber) (\(numberString))")
                context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
                writeExtensionLog("➕ ADDED: \(phoneNumber)")
            } else {
                print("❌ [\(timestamp)] Failed to convert for adding: \(numberString)")
            }
        }
        
        // Update the "previous" state for next incremental update
        userDefaults.set(currentManual, forKey: "previousManuallyBlockedNumbers")
        
        print("✅ [\(timestamp)] INCREMENTAL UPDATE COMPLETE: Added \(numbersToAdd.count), Removed \(numbersToRemove.count)")
        writeExtensionLog("✅ INCREMENTAL COMPLETE: +\(numbersToAdd.count) -\(numbersToRemove.count)")
        
        logExtensionActivity("Incremental update: +\(numbersToAdd.count) -\(numbersToRemove.count)")
    }

    private func addAllIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        let timestamp = DateFormatter.debugTimestamp.string(from: Date())
        print("📱 [\(timestamp)] IDENTIFICATION PROCESS STARTING")
        print("📱 [CallDirectoryExtension] Adding caller identification labels")
        logExtensionActivity("Starting to add caller identification labels")
        
        // ENHANCED: Clear existing identification entries systematically to prevent Error 19
        print("🧹 [\(timestamp)] ENHANCED clearing of existing identification entries to prevent Error 19")
        
        // Clear any previously identified manual numbers first
        clearPreviousIdentificationEntries(context: context, timestamp: timestamp)
        
        // Load manually blocked numbers from App Group with enhanced fallback
        var manuallyBlocked: [String] = []
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            manuallyBlocked = loadManualNumbersWithFallback(userDefaults: userDefaults)
            print("✅ [\(timestamp)] Loaded \(manuallyBlocked.count) manual numbers for identification")
        } else {
            print("⚠️ [\(timestamp)] App Group not accessible - no identification labels will be added")
        }
        
        var identificationNumbers: [(CXCallDirectoryPhoneNumber, String)] = []
        
        print("🏷️ [\(timestamp)] Processing \(manuallyBlocked.count) numbers for identification")
        
        // Add labels for manually blocked numbers with enhanced error prevention
        for (index, numberString) in manuallyBlocked.enumerated() {
            let labelTimestamp = DateFormatter.debugTimestamp.string(from: Date())
            print("🔖 [\(labelTimestamp)] Labeling #\(index + 1): '\(numberString)'")
            
            if let phoneNumber = convertToCallKitFormat(numberString) {
                // CRUCIAL: Clear any existing entry for this specific number before adding
                print("🧹 [\(labelTimestamp)] Clearing existing identification for \(phoneNumber)")
                context.removeIdentificationEntry(withPhoneNumber: phoneNumber)
                
                // Label for manually blocked numbers
                let label = "📵 Spam Bloqueado"
                identificationNumbers.append((phoneNumber, label))
                
                print("🏷️ [\(labelTimestamp)] Prepared label: \(phoneNumber) -> '\(label)'")
            } else {
                print("❌ [\(labelTimestamp)] Failed to convert manual number for identification: '\(numberString)'")
            }
        }
        
        // Skip 600 number identification for debugging - focus only on manual numbers
        print("🔧 [CallDirectoryExtension] DEBUG MODE: Skipping 600 number identification")
        
        // Sort by phone number (CallKit requirement)
        identificationNumbers.sort { $0.0 < $1.0 }
        
        let submitLabelTimestamp = DateFormatter.debugTimestamp.string(from: Date())
        print("🎯 [\(submitLabelTimestamp)] Submitting \(identificationNumbers.count) identification entries to CallKit")
        print("📱 [CallDirectoryExtension] Adding \(identificationNumbers.count) identification entries")
        
        // Add all identification entries to CallKit with detailed logging
        for (index, (phoneNumber, label)) in identificationNumbers.enumerated() {
            print("📋 [\(submitLabelTimestamp)] ID Entry #\(index + 1): \(phoneNumber) = '\(label)'")
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
        }
        
        let completeLabelTimestamp = DateFormatter.debugTimestamp.string(from: Date())
        print("🏁 [\(completeLabelTimestamp)] IDENTIFICATION COMPLETE: \(identificationNumbers.count) labels submitted")
        print("✅ [CallDirectoryExtension] Identification complete - added \(identificationNumbers.count) labels")
        logExtensionActivity("Identification complete - added \(identificationNumbers.count) labels")
    }

    private func addOrRemoveIncrementalIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // FORCE FULL IDENTIFICATION PROCESS - even for incremental requests  
        print("🔄 INCREMENTAL REQUEST - FORCING FULL IDENTIFICATION PROCESS")
        print("🔄 [CallDirectoryExtension] Incremental identification - FORCING full identification process")
        
        // Run the full identification process to ensure labels are added
        addAllIdentificationPhoneNumbers(to: context)
    }
    
    // MARK: - Helper Methods
    
    private func loadExceptions() -> [String] {
        print("📂 [CallDirectoryExtension] Loading exceptions from App Group")
        
        // Load exceptions from App Group UserDefaults
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            print("❌ [CallDirectoryExtension] Failed to access App Group UserDefaults")
            return []
        }
        
        let exceptions = userDefaults.stringArray(forKey: "exceptions") ?? []
        print("✅ [CallDirectoryExtension] Loaded \(exceptions.count) exceptions from App Group")
        return exceptions
    }
    
    private func loadManuallyBlockedNumbers() -> [String] {
        print("📂 [CallDirectoryExtension] Loading manually blocked numbers from App Group")
        
        // ALWAYS include test number for debugging regardless of App Group status
        var numbersToBlock = ["+56976055667"]
        print("🔧 [CallDirectoryExtension] DEBUG MODE: Always including test number: +56976055667")
        
        // Try to load additional numbers from App Group (but don't fail if it doesn't work)
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            let appGroupNumbers = userDefaults.stringArray(forKey: "manuallyBlockedNumbers") ?? []
            print("📋 [CallDirectoryExtension] App Group found \(appGroupNumbers.count) additional numbers: \(appGroupNumbers)")
            
            // Add unique numbers from App Group
            for number in appGroupNumbers {
                if !numbersToBlock.contains(number) {
                    numbersToBlock.append(number)
                    print("➕ [CallDirectoryExtension] Added manual number: \(number)")
                } else {
                    print("⚠️ [CallDirectoryExtension] Number already in list: \(number)")
                }
            }
        } else {
            print("⚠️ [CallDirectoryExtension] App Group not accessible - using hardcoded test number only")
        }
        
        print("✅ [CallDirectoryExtension] Total numbers to block: \(numbersToBlock.count) - \(numbersToBlock)")
        return numbersToBlock
    }
    
    private func loadPreviouslyBlockedNumbers() -> [String] {
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            return []
        }
        
        return userDefaults.stringArray(forKey: "previouslyBlockedNumbers") ?? []
    }
    
    private func savePreviouslyBlockedNumbers(_ numbers: [String]) {
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            return
        }
        
        userDefaults.set(numbers, forKey: "previouslyBlockedNumbers")
        userDefaults.synchronize()
        print("💾 [CallDirectoryExtension] Saved \(numbers.count) numbers for next incremental update")
    }
    
    private func checkForceFullReload() -> Bool {
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            return false
        }
        
        return userDefaults.bool(forKey: "forceFullReload")
    }
    
    private func clearForceFullReload() {
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            return
        }
        
        userDefaults.removeObject(forKey: "forceFullReload")
        userDefaults.synchronize()
        print("🧹 [CallDirectoryExtension] Cleared force full reload flag")
    }
    
    private func load600BlockingSetting() -> Bool {
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            let is600Enabled = userDefaults.object(forKey: "is600BlockingEnabled") as? Bool ?? true
            print("🔍 [CallDirectoryExtension] 600 blocking setting: \(is600Enabled)")
            logExtensionActivity("600 blocking setting loaded: \(is600Enabled)")
            return is600Enabled
        } else {
            print("⚠️ [CallDirectoryExtension] App Group not accessible for 600 setting - defaulting to enabled")
            logExtensionActivity("App Group not accessible - defaulting to 600 blocking enabled")
            return true // Default to enabled if App Group fails
        }
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
    
    // MARK: - Logging Helper
    
    // FILE-BASED LOGGING for extension debugging
    private func writeExtensionLog(_ message: String) {
        let timestamp = DateFormatter.debugTimestamp.string(from: Date())
        let logMessage = "[\(timestamp)] \(message)"
        
        // Try to write to App Group container first
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.dromero.chaollamadas") {
            let logFile = groupURL.appendingPathComponent("extension_debug.log")
            
            // Create directory if needed
            try? FileManager.default.createDirectory(at: groupURL, withIntermediateDirectories: true, attributes: nil)
            
            // Append log message
            if let data = (logMessage + "\n").data(using: .utf8) {
                if FileManager.default.fileExists(atPath: logFile.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                } else {
                    try? data.write(to: logFile)
                }
            }
        }
        
        // Also save to UserDefaults as backup
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            var logs = userDefaults.stringArray(forKey: "extensionDebugLogs") ?? []
            logs.append(logMessage)
            // Keep only last 50 messages to avoid memory issues
            if logs.count > 50 {
                logs = Array(logs.suffix(50))
            }
            userDefaults.set(logs, forKey: "extensionDebugLogs")
        }
    }
    
    // MARK: - Enhanced Manual Number Management
    
    private func clearInactiveManualNumbers(context: CXCallDirectoryExtensionContext, currentNumbers: [String], timestamp: String) {
        print("🧹 [\(timestamp)] Clearing previously blocked manual numbers that are no longer active")
        
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            print("⚠️ [\(timestamp)] Cannot clear inactive numbers - App Group not accessible")
            return
        }
        
        // Get previously processed numbers
        let previousNumbers = userDefaults.stringArray(forKey: "lastProcessedNumbers") ?? []
        
        // Find numbers that were previously blocked but are no longer in current list
        let removedNumbers = previousNumbers.filter { !currentNumbers.contains($0) }
        
        if !removedNumbers.isEmpty {
            print("🗑️ [\(timestamp)] Found \(removedNumbers.count) numbers to remove: \(removedNumbers)")
            
            for numberString in removedNumbers {
                if let phoneNumber = convertToCallKitFormat(numberString) {
                    print("🗑️ [\(timestamp)] Removing inactive number: \(numberString) -> \(phoneNumber)")
                    
                    // Remove both blocking and identification entries
                    context.removeBlockingEntry(withPhoneNumber: phoneNumber)
                    context.removeIdentificationEntry(withPhoneNumber: phoneNumber)
                } else {
                    print("⚠️ [\(timestamp)] Failed to convert removed number: \(numberString)")
                }
            }
            
            print("✅ [\(timestamp)] Cleared \(removedNumbers.count) inactive manual numbers")
        } else {
            print("ℹ️ [\(timestamp)] No inactive manual numbers to clear")
        }
        
        // Also clear fallback method numbers that are no longer active
        let useFallback = userDefaults.bool(forKey: "useFallbackNumbers")
        if useFallback {
            let fallbackTotal = userDefaults.integer(forKey: "manualNumbersTotal")
            var fallbackNumbers: [String] = []
            
            for i in 0..<fallbackTotal {
                if let number = userDefaults.string(forKey: "manual_\(i)") {
                    fallbackNumbers.append(number)
                }
            }
            
            let removedFallbackNumbers = fallbackNumbers.filter { !currentNumbers.contains($0) }
            if !removedFallbackNumbers.isEmpty {
                print("🗑️ [\(timestamp)] Clearing \(removedFallbackNumbers.count) inactive fallback numbers")
                for numberString in removedFallbackNumbers {
                    if let phoneNumber = convertToCallKitFormat(numberString) {
                        context.removeBlockingEntry(withPhoneNumber: phoneNumber)
                        context.removeIdentificationEntry(withPhoneNumber: phoneNumber)
                    }
                }
            }
        }
    }
    
    // MARK: - Enhanced Error 19 Prevention
    
    private func clearPreviousIdentificationEntries(context: CXCallDirectoryExtensionContext, timestamp: String) {
        print("🧹 [\(timestamp)] Starting systematic identification entry cleanup")
        
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            print("⚠️ [\(timestamp)] Cannot clear previous entries - App Group not accessible")
            return
        }
        
        // Method 1: Clear previously processed manual numbers
        let previouslyProcessed = userDefaults.stringArray(forKey: "lastProcessedNumbers") ?? []
        print("🧹 [\(timestamp)] Clearing \(previouslyProcessed.count) previously processed numbers")
        
        for numberString in previouslyProcessed {
            if let phoneNumber = convertToCallKitFormat(numberString) {
                print("🧹 [\(timestamp)] Clearing previous identification for \(phoneNumber)")
                context.removeIdentificationEntry(withPhoneNumber: phoneNumber)
            }
        }
        
        // Method 2: Try fallback method numbers if they exist
        let useFallback = userDefaults.bool(forKey: "useFallbackNumbers")
        if useFallback {
            let totalCount = userDefaults.integer(forKey: "manualNumbersTotal")
            print("🧹 [\(timestamp)] Clearing \(totalCount) fallback numbers")
            
            for i in 0..<totalCount {
                if let numberString = userDefaults.string(forKey: "manual_\(i)"),
                   let phoneNumber = convertToCallKitFormat(numberString) {
                    print("🧹 [\(timestamp)] Clearing fallback identification for \(phoneNumber)")
                    context.removeIdentificationEntry(withPhoneNumber: phoneNumber)
                }
            }
        }
        
        print("✅ [\(timestamp)] Systematic identification cleanup completed")
    }
    
    // MARK: - Enhanced Manual Numbers Loading
    
    private func loadManualNumbersWithFallback(userDefaults: UserDefaults) -> [String] {
        print("📥 [Extension] Loading manual numbers with enhanced fallback support")
        
        // METHOD 1: Try primary array method
        if let primaryNumbers = userDefaults.stringArray(forKey: "manuallyBlockedNumbers"), !primaryNumbers.isEmpty {
            print("✅ [Extension] Primary method successful: \(primaryNumbers.count) numbers")
            return primaryNumbers
        }
        
        // METHOD 2: Check if fallback method is enabled and try individual keys
        let useFallback = userDefaults.bool(forKey: "useFallbackNumbers")
        if useFallback {
            print("🔄 [Extension] Primary method failed, trying fallback with individual keys")
            
            let totalCount = userDefaults.integer(forKey: "manualNumbersTotal")
            if totalCount > 0 {
                var fallbackNumbers: [String] = []
                
                for i in 0..<totalCount {
                    if let number = userDefaults.string(forKey: "manual_\(i)") {
                        fallbackNumbers.append(number)
                        print("📥 [Extension] Loaded fallback number \(i + 1): \(number)")
                    } else {
                        print("❌ [Extension] Failed to load fallback number \(i)")
                        break
                    }
                }
                
                if fallbackNumbers.count == totalCount {
                    print("✅ [Extension] Fallback method successful: \(fallbackNumbers.count) numbers")
                    return fallbackNumbers
                } else {
                    print("⚠️ [Extension] Fallback method partial: \(fallbackNumbers.count)/\(totalCount) numbers")
                    return fallbackNumbers
                }
            }
        }
        
        print("❌ [Extension] Both primary and fallback methods failed - no manual numbers")
        return []
    }
    
    private func logExtensionActivity(_ message: String) {
        // Always print to console for visibility - skip App Group logging to avoid sync issues
        print("📝 [CallDirectoryExtension] \(message)")
        print("📝 ChaoLlamadas Extension: \(message)")
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
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
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
    
    // Convert a Chilean phone number string to CXCallDirectoryPhoneNumber format
    private func convertToCallKitFormat(_ phoneNumber: String) -> CXCallDirectoryPhoneNumber? {
        print("🔢 [Extension] Converting number: '\(phoneNumber)'")
        NSLog("🔢 ChaoLlamadas: Converting number: %@", phoneNumber)
        
        // Clean the number by removing common formatting characters
        let cleanNumber = phoneNumber
            .replacingOccurrences(of: "+56", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        print("🔢 [Extension] Cleaned number: '\(cleanNumber)' (length: \(cleanNumber.count))")
        NSLog("🔢 ChaoLlamadas: Cleaned number: %@ (length: %ld)", cleanNumber, cleanNumber.count)
        
        // Validate the number format - Chilean mobile numbers are 9 digits, landlines are 8
        guard cleanNumber.count == 8 || cleanNumber.count == 9 else {
            print("❌ [Extension] Invalid length: \(cleanNumber.count) digits (expected 8 or 9)")
            NSLog("❌ ChaoLlamadas: Invalid length: %ld digits", cleanNumber.count)
            return nil
        }
        
        guard cleanNumber.allSatisfy({ $0.isNumber }) else {
            print("❌ [Extension] Invalid number format - contains non-digits")
            NSLog("❌ ChaoLlamadas: Invalid number format - contains non-digits")
            return nil
        }
        
        // Ensure we can convert to Int64 and it's in valid range
        guard let number = Int64(cleanNumber), number > 0 else {
            print("❌ [Extension] Failed to convert '\(cleanNumber)' to valid Int64")
            NSLog("❌ ChaoLlamadas: Failed to convert to Int64: %@", cleanNumber)
            return nil
        }
        
        // Create full Chilean number with country code (+56)
        let fullNumber = CXCallDirectoryPhoneNumber(56000000000 + number)
        
        print("✅ [Extension] Conversion successful: '\(phoneNumber)' -> \(fullNumber)")
        NSLog("✅ ChaoLlamadas: Conversion successful: %@ -> %lld", phoneNumber, fullNumber)
        
        // Validate the final number is reasonable
        guard fullNumber >= 56000000000 && fullNumber <= 56999999999 else {
            print("❌ [Extension] Generated invalid full number: \(fullNumber)")
            NSLog("❌ ChaoLlamadas: Generated invalid full number: %lld", fullNumber)
            return nil
        }
        
        return fullNumber
    }
}

// MARK: - Debug Helpers
extension DateFormatter {
    static let debugTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
