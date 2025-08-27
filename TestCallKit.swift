// Apple's Official CallKit Sample - Minimal Test
// Based on: https://developer.apple.com/documentation/callkit/cxcalldirectoryprovider

import CallKit
import Foundation

class MinimalCallDirectoryHandler: CXCallDirectoryProvider {
    
    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        NSLog("🧪 MINIMAL TEST EXTENSION STARTING")
        
        context.delegate = self
        
        if context.isIncremental {
            // For incremental, add the test number
            addIncrementalBlockingPhoneNumbers(to: context)
        } else {
            // For full, add the test number  
            addAllBlockingPhoneNumbers(to: context)
        }
        
        context.completeRequest()
        NSLog("🧪 MINIMAL TEST EXTENSION COMPLETED")
    }
    
    private func addAllBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        NSLog("🧪 Adding blocking numbers - FULL request")
        
        // Test number in E.164 format (international standard)
        let phoneNumber: CXCallDirectoryPhoneNumber = 56976055667
        
        NSLog("🧪 Blocking number: %lld", Int64(phoneNumber))
        context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
        NSLog("🧪 Number added to CallKit successfully")
    }
    
    private func addIncrementalBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        NSLog("🧪 Adding blocking numbers - INCREMENTAL request") 
        
        // Same as full for testing
        let phoneNumber: CXCallDirectoryPhoneNumber = 56976055667
        
        NSLog("🧪 Blocking number: %lld", Int64(phoneNumber))
        context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
        NSLog("🧪 Number added to CallKit successfully")
    }
}

extension MinimalCallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        NSLog("🧪 MINIMAL TEST FAILED: %@", error.localizedDescription)
    }
}