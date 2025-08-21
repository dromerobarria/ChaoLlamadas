//
//  String+Localization.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 20-08-25.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}