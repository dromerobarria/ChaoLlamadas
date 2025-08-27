//
//  CallDirectorySetupView.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 20-08-25.
//

import SwiftUI

struct CallDirectorySetupView: View {
    @StateObject private var callBlockingService = CallBlockingService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showExtensionLogs = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: callBlockingService.isCallDirectoryEnabled ? "checkmark.shield" : "exclamationmark.shield")
                            .font(.system(size: 40))
                            .foregroundStyle(callBlockingService.isCallDirectoryEnabled ? .green : .orange)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Configuración de Bloqueo")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(callBlockingService.callDirectoryStatus)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Status card
                StatusCard(
                    isEnabled: callBlockingService.isCallDirectoryEnabled,
                    status: callBlockingService.callDirectoryStatus
                )
                
                // Debug section - Extension execution status
                ExtensionDebugCard()
                
                // Instructions
                if !callBlockingService.isCallDirectoryEnabled {
                    InstructionsCard()
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    if !callBlockingService.isCallDirectoryEnabled {
                        Button(action: {
                            callBlockingService.openCallSettings()
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Abrir Configuración")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                    }
                    
                    Button(action: {
                        callBlockingService.checkCallDirectoryStatus()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Verificar Estado")
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    
                    Button(action: {
                        callBlockingService.diagnoseSetup()
                    }) {
                        HStack {
                            Image(systemName: "stethoscope")
                            Text("Diagnosticar Problemas")
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    
                    Button(action: {
                        callBlockingService.enableCallBlocking()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle")
                            Text("Forzar Recarga Extension")
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    
                    Button(action: {
                        clearAllCallKitData()
                    }) {
                        HStack {
                            Image(systemName: "trash.circle")
                            Text("Limpiar CallKit Cache")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    
                    Button(action: {
                        showExtensionLogs.toggle()
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Ver Logs Extension")
                        }
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(20)
            .navigationTitle("Configurar Bloqueo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showExtensionLogs) {
                ExtensionLogsView()
            }
        }
    }
    
    private func clearAllCallKitData() {
        print("🧹 [CallKit] Clearing all CallKit data and cache")
        
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            print("❌ [CallKit] Failed to access App Group")
            return
        }
        
        // Clear all stored data
        userDefaults.removeObject(forKey: "manuallyBlockedNumbers")
        userDefaults.removeObject(forKey: "previouslyBlockedNumbers")
        userDefaults.removeObject(forKey: "forceFullReload")
        userDefaults.removeObject(forKey: "extensionLogs")
        userDefaults.removeObject(forKey: "lastExtensionError")
        userDefaults.removeObject(forKey: "lastExtensionErrorDate")
        userDefaults.synchronize()
        
        print("✅ [CallKit] All CallKit data cleared")
        
        // Force a reload to reset everything
        callBlockingService.enableCallBlocking()
    }
    
}

struct ExtensionLogsView: View {
    @StateObject private var callBlockingService = CallBlockingService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(callBlockingService.getExtensionLogs(), id: \.self) { log in
                        Text(log)
                            .font(.caption)
                            .padding(.horizontal)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Extension Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatusCard: View {
    let isEnabled: Bool
    let status: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(isEnabled ? .green : .red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isEnabled ? "Bloqueo Activo" : "Bloqueo Inactivo")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(status)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

struct InstructionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cómo Habilitar el Bloqueo")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                InstructionStep(
                    number: "1",
                    title: "Abrir Configuración",
                    description: "Toca el botón para ir a Configuración de iOS"
                )
                
                InstructionStep(
                    number: "2",
                    title: "Buscar 'Teléfono'",
                    description: "Ve a Configuración > Teléfono > Bloqueo e Identificación de Llamadas"
                )
                
                InstructionStep(
                    number: "3",
                    title: "Activar ChaoLlamadas",
                    description: "CRÍTICO: Activa el interruptor junto a 'ChaoLlamadas' - Sin esto NO funcionará el bloqueo"
                )
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

struct InstructionStep: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.blue)
                    .frame(width: 24, height: 24)
                
                Text(number)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

struct ExtensionDebugCard: View {
    @State private var extensionRunCount = 0
    @State private var lastRunTime: Date?
    @State private var extensionProof = "No ejecutada aún"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "ladybug")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text("Estado de Extension")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: refreshStatus) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Ejecuciones:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(extensionRunCount)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(extensionRunCount > 0 ? .green : .red)
                }
                
                if let lastRunTime = lastRunTime {
                    HStack {
                        Text("Última ejecución:")
                            .font(.caption)
                        Spacer()
                        Text(lastRunTime.formatted(.dateTime.hour().minute().second()))
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Text(extensionProof)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .onAppear {
            refreshStatus()
        }
    }
    
    private func refreshStatus() {
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            extensionProof = "Error: App Group no accesible"
            return
        }
        
        extensionRunCount = userDefaults.integer(forKey: "extensionRunCount")
        lastRunTime = userDefaults.object(forKey: "lastExtensionRunTime") as? Date
        extensionProof = userDefaults.string(forKey: "extensionProof") ?? "No ejecutada aún"
    }
}

#Preview {
    CallDirectorySetupView()
}
