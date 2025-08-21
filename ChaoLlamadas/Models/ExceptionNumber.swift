//
//  ExceptionNumber.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 20-08-25.
//

import Foundation
import SwiftData

@Model
final class ExceptionNumber {
    var phoneNumber: String
    var dateAdded: Date
    var note: String
    
    init(phoneNumber: String, note: String = "") {
        self.phoneNumber = phoneNumber
        self.dateAdded = Date()
        self.note = note
    }
}