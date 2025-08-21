//
//  LiquidGlassTabView.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 20-08-25.
//

import SwiftUI

struct LiquidGlassTabView: View {
    var body: some View {
        TabView {
            Tab("Bloqueados", systemImage: "shield.lefthalf.filled") {
                BlockedNumbersView()
            }
            
            Tab("Excepciones", systemImage: "checkmark.shield") {
                ExceptionsView()
            }
            
            Tab("Configuración", systemImage: "gear") {
                SettingsView()
            }
        }
        .tint(.blue)
    }
}

#Preview {
    LiquidGlassTabView()
}