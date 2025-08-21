//
//  AppInfoView.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 20-08-25.
//

import SwiftUI

struct AppInfoView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon and version
                    AppHeaderCard()
                    
                    // Features section
                    FeaturesSectionCard()
                    
                    // Legal information
                    LegalSectionCard()
                    
                    // Support section
                    SupportSectionCard()
                    
                    // Developer info
                    DeveloperCard()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Space for tab bar
            }
            .navigationTitle("Información")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct AppHeaderCard: View {
    var body: some View {
        VStack(spacing: 16) {
            // App icon placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.blue.gradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: "phone.badge.xmark")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text("ChaoLlamadas")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Versión 1.0.0")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text("Bloquea llamadas spam de números 600 automáticamente")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

struct FeaturesSectionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Características")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                FeatureRow(
                    icon: "shield.checkered",
                    title: "Bloqueo Automático",
                    description: "Bloquea todos los números 600 automáticamente"
                )
                
                FeatureRow(
                    icon: "phone.badge.checkmark",
                    title: "Lista de Excepciones",
                    description: "Permite números específicos que quieras recibir"
                )
                
                FeatureRow(
                    icon: "list.bullet",
                    title: "Historial de Bloqueos",
                    description: "Ve todos los números que han sido bloqueados"
                )
                
                FeatureRow(
                    icon: "gear",
                    title: "Fácil Configuración",
                    description: "Configuración simple y automática"
                )
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

struct LegalSectionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Información Legal")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ley de Protección al Consumidor")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("Esta aplicación cumple con la legislación chilena respecto al uso de números 600 para ventas telefónicas. Los números con este prefijo son utilizados exclusivamente por empresas para ofertas comerciales.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Uso Responsable")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("La aplicación bloquea números automáticamente. Si necesitas recibir llamadas de algún número 600 específico, puedes agregarlo a la lista de excepciones.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

struct SupportSectionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Soporte")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                SupportRow(
                    icon: "questionmark.circle",
                    title: "Preguntas Frecuentes",
                    action: {}
                )
                
                SupportRow(
                    icon: "envelope",
                    title: "Contactar Soporte",
                    action: {}
                )
                
                SupportRow(
                    icon: "star",
                    title: "Calificar App",
                    action: {}
                )
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

struct SupportRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(.primary)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct DeveloperCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Desarrollado en Chile 🇨🇱")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Text("© 2025 ChaoLlamadas. Todos los derechos reservados.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    AppInfoView()
}