//
//  BlockedNumber.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 20-08-25.
//

import Foundation
import SwiftData

@Model
final class BlockedNumber {
    var phoneNumber: String
    var isBlocked: Bool
    var dateAdded: Date
    var reason: String
    
    init(phoneNumber: String, isBlocked: Bool = true, reason: String = "Número 600 bloqueado automáticamente") {
        self.phoneNumber = phoneNumber
        self.isBlocked = isBlocked
        self.dateAdded = Date()
        self.reason = reason
    }
}