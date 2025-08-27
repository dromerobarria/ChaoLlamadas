//
//  SettingsView.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 20-08-25.
//

import SwiftUI
import TipKit

struct SettingsView: View {
    @StateObject private var callBlockingService = CallBlockingService.shared
    @StateObject private var tipManager = CallBlockingTipManager.shared
    @State private var showingSetup = false
    @State private var showingBlockingDisabledAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // App Header Section
                Section {
                    AppHeaderSettingsCard()
                } header: {
                    Text("Aplicación")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .listRowBackground(Color.clear)
                
                // Blocking Settings Section
                Section {
                    Toggle(isOn: $callBlockingService.is600BlockingEnabled) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(callBlockingService.is600BlockingEnabled ? .green.opacity(0.2) : .gray.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: callBlockingService.is600BlockingEnabled ? "shield.checkered" : "shield.slash")
                                    .font(.system(size: 18))
                                    .foregroundStyle(callBlockingService.is600BlockingEnabled ? .green : .gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bloquear Números 600")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text(callBlockingService.callDirectoryStatus)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(.blue)
                    .onChange(of: callBlockingService.is600BlockingEnabled) { oldValue, newValue in
                        // Only call if actually different (prevents loops)
                        if oldValue != newValue {
                            callBlockingService.set600Blocking(enabled: newValue)
                        }
                    }
                    
                    // 809 prefix blocking toggle
                    Toggle(isOn: $callBlockingService.is809BlockingEnabled) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(callBlockingService.is809BlockingEnabled ? .orange.opacity(0.2) : .gray.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: callBlockingService.is809BlockingEnabled ? "shield.checkered" : "shield.slash")
                                    .font(.system(size: 18))
                                    .foregroundStyle(callBlockingService.is809BlockingEnabled ? .orange : .gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bloquear Números 809")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("República Dominicana y llamadas internacionales")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(.orange)
                    .onChange(of: callBlockingService.is809BlockingEnabled) { oldValue, newValue in
                        // Only call if actually different (prevents loops)
                        if oldValue != newValue {
                            callBlockingService.set809Blocking(enabled: newValue)
                        }
                    }
                    
                    // Notification Settings
                    Toggle(isOn: $callBlockingService.blockNotificationsEnabled) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(.blue.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notificar Llamadas Bloqueadas")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Recibe una notificación cuando se bloquee una llamada")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(.blue)
                    .onChange(of: callBlockingService.blockNotificationsEnabled) { _, newValue in
                        callBlockingService.setBlockNotifications(enabled: newValue)
                    }
                    
                    // Setup instructions for all users
                    CallKitSetupInstructionsCard()
                    
                    // Warning about other blocking apps
                    BlockingAppsWarningCard()
                    
                } header: {
                    Text("Bloqueo de Llamadas")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                
                // Legal Section
                Section {
                    SettingsLinkRow(
                        icon: "book",
                        iconColor: .green,
                        title: "Términos de Servicio",
                        subtitle: "Leer términos legales",
                        action: { openTerms() }
                    )
                    
                    SettingsLinkRow(
                        icon: "shield",
                        iconColor: .purple,
                        title: "Política de Privacidad",
                        subtitle: "Cómo protegemos tus datos",
                        action: { openPrivacy() }
                    )
                } header: {
                    Text("Legal")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                // About Section
                Section {
                    VStack(spacing: 12) {
                        Text("Desarrollado en Chile")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Text("© 2025 ChaoLlamadas v1.0.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } header: {
                    Text("Acerca de")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.large)
            .background {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.05),
                        Color.pink.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            .onAppear {
                callBlockingService.checkCallDirectoryStatus()
                
                // Check if blocking is disabled and show alert
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if !callBlockingService.isCallDirectoryEnabled {
                        showingBlockingDisabledAlert = true
                    }
                }
            }
            .sheet(isPresented: $showingSetup) {
                CallDirectorySetupView()
            }
            .alert("Bloqueo de Llamadas Desactivado", isPresented: $showingBlockingDisabledAlert) {
                Button("Ir a Configuración") {
                    callBlockingService.openCallSettings()
                }
                Button("Más Tarde", role: .cancel) { }
            } message: {
                Text("El bloqueo de llamadas no está activo. Para bloquear llamadas spam, necesitas activar ChaoLlamadas en Configuración > Teléfono > Bloqueo e Identificación de Llamadas.")
            }
        }
    }
    
    
    private func openTerms() {
        if let url = URL(string: "https://www.termsfeed.com/live/296676f8-8464-4179-9162-9cedee2ec225") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPrivacy() {
        if let url = URL(string: "https://www.termsfeed.com/live/8b822ef5-e37f-447a-9f82-ebad204541d9") {
            UIApplication.shared.open(url)
        }
    }
    
}

struct AppHeaderSettingsCard: View {
    var body: some View {
        HStack(spacing: 16) {
            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.blue.gradient)
                    .frame(width: 60, height: 60)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "phone.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("ChaoLlamadas")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Bloquea llamadas spam automáticamente")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

struct SettingsLinkRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct CallKitSetupInstructionsCard: View {
    @StateObject private var callBlockingService = CallBlockingService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: callBlockingService.isCallDirectoryEnabled ? "checkmark.circle.fill" : "info.circle.fill")
                    .foregroundStyle(callBlockingService.isCallDirectoryEnabled ? .green : .blue)
                    .font(.title2)
                
                Text(callBlockingService.isCallDirectoryEnabled ? "Configuración Completa" : "Configuración Requerida")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            
            if !callBlockingService.isCallDirectoryEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Para activar el bloqueo de llamadas, sigue estos pasos:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        StepRow(number: "1", text: "Ve a Configuración de iOS")
                        StepRow(number: "2", text: "Toca \"Teléfono\"")
                        StepRow(number: "3", text: "Toca \"Bloqueo e Identificación de Llamadas\"")
                        StepRow(number: "4", text: "Activa el interruptor de \"ChaoLlamadas\"")
                    }
                    
                    Button(action: {
                        callBlockingService.openCallSettings()
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Abrir Configuración de iOS")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.top, 8)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    
                    Text("El bloqueo de llamadas está activo y funcionando correctamente")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(callBlockingService.isCallDirectoryEnabled ? .green.opacity(0.1) : .blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(callBlockingService.isCallDirectoryEnabled ? .green.opacity(0.3) : .blue.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SetupInstructionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.title2)
                
                Text("Configuración Requerida")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Para activar el bloqueo de llamadas, sigue estos pasos:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    StepRow(number: "1", text: "Ve a Configuración de iOS")
                    StepRow(number: "2", text: "Toca \"Teléfono\"")
                    StepRow(number: "3", text: "Toca \"Bloqueo e Identificación de Llamadas\"")
                    StepRow(number: "4", text: "Activa el interruptor de \"ChaoLlamadas\"")
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    
                    Text("Una vez activado, todas las llamadas 600 serán bloqueadas automáticamente")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct StepRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.blue)
                    .frame(width: 24, height: 24)
                
                Text(number)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

struct BlockingAppsWarningCard: View {
    @AppStorage("hasSeenBlockingAppsWarning") private var hasSeenWarning = false
    
    var body: some View {
        if !hasSeenWarning {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Otras Apps de Bloqueo")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Text("Si tienes TrueCaller u otras apps de bloqueo activadas, pueden interferir con ChaoLlamadas. Desactívalas en Configuración > Teléfono > Bloqueo e Identificación")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                
                Button("Entendido") {
                    hasSeenWarning = true
                }
                .font(.caption)
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.orange.opacity(0.1))
            }
        }
    }
}


#Preview {
    SettingsView()
}
