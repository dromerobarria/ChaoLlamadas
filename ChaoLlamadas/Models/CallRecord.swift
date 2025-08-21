//
//  CallRecord.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 20-08-25.
//

import Foundation
import SwiftData

@Model
final class CallRecord {
    var phoneNumber: String
    var callDate: Date
    var callTime: Date
    var wasBlocked: Bool
    var callDuration: TimeInterval // 0 if blocked
    var callerName: String?
    
    init(phoneNumber: String, callDate: Date = Date(), wasBlocked: Bool = true, callDuration: TimeInterval = 0, callerName: String? = nil) {
        self.phoneNumber = phoneNumber
        self.callDate = callDate
        self.callTime = callDate
        self.wasBlocked = wasBlocked
        self.callDuration = callDuration
        self.callerName = callerName
    }
    
    var formattedPhoneNumber: String {
        let cleaned = phoneNumber.replacingOccurrences(of: "+56", with: "")
        if cleaned.count >= 9 {
            let firstPart = String(cleaned.prefix(3))
            let secondPart = String(cleaned.dropFirst(3).prefix(3))
            let thirdPart = String(cleaned.dropFirst(6).prefix(3))
            return "+56 \(firstPart) \(secondPart) \(thirdPart)"
        }
        return "+56 \(cleaned)"
    }
    
    var isSpamNumber: Bool {
        let cleaned = phoneNumber.replacingOccurrences(of: "+56", with: "")
        return cleaned.hasPrefix("600")
    }
}