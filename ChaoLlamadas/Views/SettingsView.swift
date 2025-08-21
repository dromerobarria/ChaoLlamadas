//
//  SettingsView.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 20-08-25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var callBlockingService = CallBlockingService.shared
    @State private var is600BlockingEnabled = true
    @State private var showingSetup = false
    
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
                    Toggle(isOn: $is600BlockingEnabled) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(is600BlockingEnabled ? .green.opacity(0.2) : .gray.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: is600BlockingEnabled ? "shield.checkered" : "shield.slash")
                                    .font(.system(size: 18))
                                    .foregroundStyle(is600BlockingEnabled ? .green : .gray)
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
                    
                    if is600BlockingEnabled && !callBlockingService.isCallDirectoryEnabled {
                        SetupInstructionsCard()
                    }
                    
                    if is600BlockingEnabled {
                        Button(action: { showingSetup = true }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(.blue.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "gear")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Configurar CallKit")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text("Configurar bloqueo en iOS")
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
                callBlockingService.diagnoseSetup()
                callBlockingService.checkCallDirectoryStatus()
            }
            .sheet(isPresented: $showingSetup) {
                CallDirectorySetupView()
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

#Preview {
    SettingsView()
}