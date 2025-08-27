//
//  CallBlockingTips.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 25-08-25.
//

import Foundation
import TipKit

// Tip for CallKit setup
struct CallKitSetupTip: Tip {
    var title: Text {
        Text("Activa el Bloqueo de Llamadas")
    }
    
    var message: Text? {
        Text("Debes activar ChaoLlamadas en Configuración > Teléfono > Bloqueo e Identificación de Llamadas para que funcione.")
    }
    
    var image: Image? {
        Image(systemName: "gear")
    }
    
    var actions: [Action] {
        [
            Action(
                id: "open-settings",
                title: "Abrir Configuración"
            )
        ]
    }
    
    var rules: [Rule] {
        [
            #Rule(Self.$hasSeenCallKitSetup) { $0 == false }
        ]
    }
    
    @Parameter
    static var hasSeenCallKitSetup: Bool = false
}

// Tip for manual blocking feature
struct ManualBlockingTip: Tip {
    var title: Text {
        Text("Bloquea Números Específicos")
    }
    
    var message: Text? {
        Text("Puedes bloquear números específicos además de los 600. Ve a la pestaña 'Bloqueo Manual' para agregar números.")
    }
    
    var image: Image? {
        Image(systemName: "plus.circle")
    }
    
    var rules: [Rule] {
        [
            #Rule(Self.$hasSeenManualBlocking) { $0 == false },
            #Rule(CallKitSetupTip.$hasSeenCallKitSetup) { $0 == true }
        ]
    }
    
    @Parameter
    static var hasSeenManualBlocking: Bool = false
}

// Tip warning about other blocking apps
struct BlockingAppsWarningTip: Tip {
    var title: Text {
        Text("⚠️ Otras Apps de Bloqueo")
    }
    
    var message: Text? {
        Text("Si tienes otras apps como TrueCaller activadas, pueden interferir con ChaoLlamadas. Desactívalas para mejor funcionamiento.")
    }
    
    var image: Image? {
        Image(systemName: "exclamationmark.triangle")
    }
    
    var actions: [Action] {
        [
            Action(
                id: "check-settings",
                title: "Revisar Configuración"
            )
        ]
    }
    
    var rules: [Rule] {
        [
            #Rule(Self.$hasSeenBlockingWarning) { $0 == false }
        ]
    }
    
    @Parameter
    static var hasSeenBlockingWarning: Bool = false
}

// Tip for extension reset when problems occur
struct ExtensionResetTip: Tip {
    var title: Text {
        Text("¿Problemas de Bloqueo?")
    }
    
    var message: Text? {
        Text("Si las llamadas no se están bloqueando, prueba usar 'Resetear Extensión' en Configuración.")
    }
    
    var image: Image? {
        Image(systemName: "arrow.clockwise.circle")
    }
    
    var rules: [Rule] {
        [
            #Rule(Self.$shouldShowResetTip) { $0 == true }
        ]
    }
    
    @Parameter
    static var shouldShowResetTip: Bool = false
}

// Manager class to handle tip logic
class CallBlockingTipManager: ObservableObject {
    static let shared = CallBlockingTipManager()
    
    private init() {
        setupTips()
    }
    
    func setupTips() {
        // Configure TipKit
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }
    
    func markCallKitSetupSeen() {
        CallKitSetupTip.hasSeenCallKitSetup = true
    }
    
    func markManualBlockingSeen() {
        ManualBlockingTip.hasSeenManualBlocking = true
    }
    
    func markBlockingWarningSeen() {
        BlockingAppsWarningTip.hasSeenBlockingWarning = true
    }
    
    func triggerResetTip() {
        ExtensionResetTip.shouldShowResetTip = true
    }
    
    func clearResetTip() {
        ExtensionResetTip.shouldShowResetTip = false
    }
    
    func resetAllTips() {
        try? Tips.resetDatastore()
        CallKitSetupTip.hasSeenCallKitSetup = false
        ManualBlockingTip.hasSeenManualBlocking = false
        BlockingAppsWarningTip.hasSeenBlockingWarning = false
        ExtensionResetTip.shouldShowResetTip = false
    }
}