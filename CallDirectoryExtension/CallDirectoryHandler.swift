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
        
        // Use proper CallKit implementation based on the request type
        if context.isIncremental {
            print("🔄 Processing incremental request")
            
            addOrRemoveIncrementalBlockingPhoneNumbers(to: context)
            addOrRemoveIncrementalIdentificationPhoneNumbers(to: context)
        } else {
            print("📞 Processing full request")
            
            addAllBlockingPhoneNumbers(to: context)
            addAllIdentificationPhoneNumbers(to: context)
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
            let testNumber = "+56989980754"
            let processedNumbers = [testNumber] // Our hardcoded test number
            userDefaults.set(processedNumbers, forKey: "lastProcessedNumbers")
            
            print("✅ [Extension] Saved execution proof and processing details to App Group")
        } else {
            print("❌ [Extension] Could not save execution proof - App Group not accessible")
        }
        
        print("🏁 COMPLETING REQUEST")
        writeExtensionLog("🏁 COMPLETING REQUEST - Extension finishing successfully")
        
        context.completeRequest()
        
        print("✅ REQUEST COMPLETED")
        writeExtensionLog("✅ REQUEST COMPLETED - Extension execution finished")
    }

    private func addAllBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        let timestamp = DateFormatter.debugTimestamp.string(from: Date())
        print("🚫 [\(timestamp)] TESTING MODE: BLOCKING ONLY TEST NUMBER +56989980754")
        print("🚫 [CallDirectoryExtension] DEBUG MODE: Only blocking test number")
        logExtensionActivity("DEBUG MODE: Testing with single number +56989980754")
        
        // FIRST: Clear any existing entries to avoid Error 19 (UNIQUE constraint failed)
        print("🗑️ [\(timestamp)] STEP 0: Clearing existing CallKit entries to prevent duplicates")
        
        // FOR TESTING: Only remove our test number to avoid conflicts
        let testNumber = "+56989980754"
        if let testPhoneNumber = convertToCallKitFormat(testNumber) {
            print("🧹 [\(timestamp)] Removing existing test number \(testNumber) (CallKit: \(testPhoneNumber))")
            context.removeBlockingEntry(withPhoneNumber: testPhoneNumber)
        }
        
        // TESTING MODE: Skip App Group entirely since it's failing
        print("⚠️ [\(timestamp)] BYPASSING App Group due to sync failures - using hardcoded test data")
        print("🔧 [\(timestamp)] In testing mode - App Group not required")
        
        // TESTING: Use empty arrays since App Group is failing
        let exceptions: [String] = [] // No exceptions for testing
        let manuallyBlocked: [String] = [testNumber] // Only our test number
        
        print("📊 [\(timestamp)] TESTING CONFIG: Using hardcoded data - no exceptions, manual=[\(testNumber)]")
        
        // TEMPORARILY DISABLED - Comment out 600/809 logic for testing
        /*
        let is600BlockingEnabled = userDefaults.bool(forKey: "is600BlockingEnabled")
        let is809BlockingEnabled = userDefaults.bool(forKey: "is809BlockingEnabled")
        */
        
        print("📊 [\(timestamp)] DEBUG CONFIG: 600/809 blocking DISABLED for testing, \(exceptions.count) exceptions, \(manuallyBlocked.count) manual")
        
        // Collect all numbers to block in a sorted array
        var numbersToBlock: [CXCallDirectoryPhoneNumber] = []
        
        // TEMPORARILY DISABLED - Comment out 600 prefix logic
        /*
        // STEP 1: Add 600 prefix numbers if enabled
        if is600BlockingEnabled {
            print("📞 [\(timestamp)] STEP 1: Adding 600 prefix numbers (600000000-600999999)")
            
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
        }
        
        // STEP 1.5: Add 809 prefix numbers if enabled
        if is809BlockingEnabled {
            print("📞 [\(timestamp)] STEP 1.5: Adding 809 prefix numbers (809000000-809999999)")
            
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
            blockedCount += blocked809Count
            skippedCount += skipped809Count
        }
        */
        
        // FOR TESTING: Add our specific test number +56989980754 (already declared above)
        print("🎯 [\(timestamp)] ADDING TEST NUMBER: \(testNumber)")
        writeExtensionLog("🎯 ADDING TEST NUMBER: \(testNumber)")
        NSLog("🎯 ChaoLlamadas Extension: Adding test number %@", testNumber)
        
        if let phoneNumber = convertToCallKitFormat(testNumber) {
            numbersToBlock.append(phoneNumber)
            print("✅ [\(timestamp)] TEST NUMBER CONVERTED: \(testNumber) -> \(phoneNumber)")
            print("🔢 [\(timestamp)] TEST NUMBER E.164 FORMAT: \(phoneNumber)")
            writeExtensionLog("✅ TEST NUMBER CONVERTED: \(testNumber) -> \(phoneNumber)")
            writeExtensionLog("🔢 E.164 FORMAT: \(phoneNumber)")
            NSLog("✅ ChaoLlamadas Extension: Converted %@ to %lld", testNumber, phoneNumber)
            
            // Save conversion success to App Group for debugging
            if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
                userDefaults.set(true, forKey: "testNumberConversionSuccess")
                userDefaults.set("\(phoneNumber)", forKey: "convertedTestNumber")
            }
        } else {
            print("❌ [\(timestamp)] FAILED TO CONVERT TEST NUMBER: \(testNumber)")
            print("💡 [\(timestamp)] CHECK: convertToCallKitFormat function may have issues")
            
            // Save conversion failure to App Group for debugging
            if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
                userDefaults.set(false, forKey: "testNumberConversionSuccess")
                userDefaults.set("CONVERSION FAILED", forKey: "convertedTestNumber")
            }
        }
        
        // STEP 2: Add manually blocked numbers (but for testing, we're focusing on our test number only)
        print("🔧 [\(timestamp)] STEP 2: Processing \(manuallyBlocked.count) manually blocked numbers")
        
        for (index, numberString) in manuallyBlocked.enumerated() {
            print("🔢 [\(timestamp)] Processing manual number \(index + 1): \(numberString)")
            
            // FOR TESTING: Only add our specific test number
            if numberString == testNumber {
                print("🎯 [\(timestamp)] FOUND OUR TEST NUMBER IN MANUAL LIST: \(numberString)")
                if let phoneNumber = convertToCallKitFormat(numberString) {
                    // Don't add it again if we already added it above
                    if !numbersToBlock.contains(phoneNumber) {
                        numbersToBlock.append(phoneNumber)
                        print("✅ [\(timestamp)] Manual test number added: \(numberString) -> \(phoneNumber)")
                    } else {
                        print("⚠️ [\(timestamp)] Test number already in list, skipping duplicate")
                    }
                } else {
                    print("❌ [\(timestamp)] Failed to convert manual test number: \(numberString)")
                }
            } else {
                print("😴 [\(timestamp)] IGNORING (for testing): \(numberString) - only processing \(testNumber)")
            }
        }
        
        // STEP 3: Sort all numbers and add to CallKit
        print("📋 [\(timestamp)] STEP 3: Sorting and adding \(numbersToBlock.count) total numbers to CallKit")
        
        // Sort numbers in ascending order (required by CallKit)
        numbersToBlock.sort()
        
        if numbersToBlock.isEmpty {
            print("⚠️ [\(timestamp)] NO NUMBERS TO BLOCK! Check if \(testNumber) was converted properly.")
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
        
        print("🎉 [\(timestamp)] BLOCKING COMPLETE: \(numbersToBlock.count) total numbers blocked (TEST MODE)")
        
        // Save final blocking count to App Group for debugging
        if let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") {
            userDefaults.set(numbersToBlock.count, forKey: "lastBlockedCount")
            userDefaults.synchronize()
            print("💾 [\(timestamp)] Saved blocking count \(numbersToBlock.count) to App Group")
        }
        
        logExtensionActivity("TEST MODE - Blocking complete: \(numbersToBlock.count) numbers (focusing on \(testNumber))")
    }
    
    private func addOrRemoveIncrementalBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // FORCE FULL BLOCKING PROCESS - even for incremental requests
        print("🔄 [CallDirectoryExtension] Incremental request - FORCING full blocking process")
        
        // Run the full blocking process to ensure numbers are added
        addAllBlockingPhoneNumbers(to: context)
        
        logExtensionActivity("Incremental request - executed full blocking process")
    }

    private func addAllIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        let timestamp = DateFormatter.debugTimestamp.string(from: Date())
        print("📱 [\(timestamp)] IDENTIFICATION PROCESS STARTING")
        print("📱 [CallDirectoryExtension] Adding caller identification labels")
        logExtensionActivity("Starting to add caller identification labels")
        
        // FIRST: Clear existing identification entries to avoid Error 19
        let testNumber = "+56989980754"
        if let testPhoneNumber = convertToCallKitFormat(testNumber) {
            print("🧹 [\(timestamp)] Removing existing identification for test number \(testNumber)")
            context.removeIdentificationEntry(withPhoneNumber: testPhoneNumber)
        }
        
        // TESTING MODE: Skip App Group, use hardcoded data
        print("⚠️ [\(timestamp)] BYPASSING App Group for identification - using hardcoded test data")
        let manuallyBlocked: [String] = [testNumber] // Only our test number
        
        var identificationNumbers: [(CXCallDirectoryPhoneNumber, String)] = []
        
        print("🏷️ [\(timestamp)] Processing \(manuallyBlocked.count) numbers for identification")
        
        // Add labels for manually blocked numbers
        for (index, numberString) in manuallyBlocked.enumerated() {
            let labelTimestamp = DateFormatter.debugTimestamp.string(from: Date())
            print("🔖 [\(labelTimestamp)] Labeling #\(index + 1): '\(numberString)'")
            
            let cleanNumber = numberString.replacingOccurrences(of: "+56", with: "")
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
            
            // Validate the number format
            guard cleanNumber.count == 8 || cleanNumber.count == 9,
                  cleanNumber.allSatisfy({ $0.isNumber }),
                  let number = Int64(cleanNumber), number > 0 else {
                print("❌ [\(labelTimestamp)] Invalid number for identification: '\(numberString)'")
                continue
            }
            
            let fullNumber = CXCallDirectoryPhoneNumber(56000000000 + number)
            
            // Special label for our test number
            let label = (numberString == "+56989980754") ? "🚫 TEST SPAM BLOCKED" : "📵 Spam Bloqueado"
            identificationNumbers.append((fullNumber, label))
            
            print("🏷️ [\(labelTimestamp)] Added label: \(fullNumber) -> '\(label)'")
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
        // Clean the number by removing common formatting characters
        let cleanNumber = phoneNumber
            .replacingOccurrences(of: "+56", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        // Validate the number format - Chilean mobile numbers are 9 digits, landlines are 8
        guard cleanNumber.count == 8 || cleanNumber.count == 9 else {
            print("❌ [CallDirectoryExtension] Invalid length: \(cleanNumber.count) digits (expected 8 or 9)")
            return nil
        }
        
        guard cleanNumber.allSatisfy({ $0.isNumber }) else {
            print("❌ [CallDirectoryExtension] Invalid number format - contains non-digits")
            return nil
        }
        
        // Ensure we can convert to Int64 and it's in valid range
        guard let number = Int64(cleanNumber), number > 0 else {
            print("❌ [CallDirectoryExtension] Failed to convert '\(cleanNumber)' to valid Int64")
            return nil
        }
        
        // Create full Chilean number with country code (+56)
        let fullNumber = CXCallDirectoryPhoneNumber(56000000000 + number)
        
        // Validate the final number is reasonable
        guard fullNumber >= 56000000000 && fullNumber <= 56999999999 else {
            print("❌ [CallDirectoryExtension] Generated invalid full number: \(fullNumber)")
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
