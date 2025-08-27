//
//  CommonIssuesView.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 27-08-25.
//

import SwiftUI

struct CommonIssuesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Problemas Comunes")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Soluciones a los problemas más frecuentes con el bloqueo de llamadas")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Issues list
                    LazyVStack(spacing: 12) {
                        CommonIssueCard(
                            title: "La app muestra 'Registrando número...' por mucho tiempo",
                            icon: "clock",
                            color: .orange,
                            steps: [
                                "1. Esto indica que iOS está limitando las actualizaciones de base de datos",
                                "2. Cierra la app ChaoLlamadas completamente",
                                "3. Espera 5 minutos antes de volver a abrirla",
                                "4. Evita agregar muchos números seguidos - añade uno, espera, luego otro",
                                "5. Si el problema persiste, reinicia tu iPhone"
                            ]
                        )
                        
                        CommonIssueCard(
                            title: "Error: 'Ha ocurrido un error no se ha podido registrar el número'",
                            icon: "xmark.circle",
                            color: .purple,
                            steps: [
                                "1. iOS ha temporalmente bloqueado las actualizaciones de CallKit",
                                "2. NO intentes agregar el número nuevamente de inmediato",
                                "3. Espera al menos 10 minutos",
                                "4. Ve a Configuración → 'Verificar Estado' para confirmar que todo funciona",
                                "5. Si el estado es bueno, intenta agregar el número nuevamente",
                                "6. Si persiste, usa el botón 'Resetear Números' en Configuración",
                                "7. Como último recurso, reinicia tu iPhone"
                            ]
                        )
                        
                        CommonIssueCard(
                            title: "Números siguen bloqueados después de eliminarlos",
                            icon: "exclamationmark.triangle.fill",
                            color: .red,
                            steps: [
                                "1. Este problema ocurre cuando CallKit tiene números 'pegados' en su base de datos",
                                "2. Ve a Configuración → toca el botón naranja 'Resetear Números'",
                                "3. Esto eliminará TODOS los números bloqueados y desactivará prefijos 600/809",
                                "4. Después del reset, reactive los prefijos que necesites",
                                "5. Agrega nuevamente los números manuales que quieras bloquear",
                                "6. Este reset limpia completamente la base de datos"
                            ]
                        )
                        
                        CommonIssueCard(
                            title: "La extensión no aparece en Configuración de iOS",
                            icon: "gear.badge.xmark",
                            color: .gray,
                            steps: [
                                "1. Asegúrate de tener la versión más reciente de ChaoLlamadas",
                                "2. Reinicia tu iPhone completamente",
                                "3. Ve a Configuración → General → Almacenamiento del iPhone",
                                "4. Busca ChaoLlamadas y verifica que esté instalada correctamente",
                                "5. Si no aparece, desinstala y reinstala la app",
                                "6. Después de reinstalar, espera 5 minutos antes de buscar la extensión"
                            ]
                        )
                        
                        CommonIssueCard(
                            title: "Límites de números y rendimiento",
                            icon: "chart.bar",
                            color: .indigo,
                            steps: [
                                "• Prefijo 600: Bloquea 1,000,000 números (600000000-600999999)",
                                "• Prefijo 809: Bloquea 1,000,000 números (809000000-809999999)", 
                                "• Total con ambos activados: 2,000,000 números bloqueados",
                                "• iOS tiene límite de memoria de ~12MB para extensiones",
                                "• En dispositivos antiguos (iPhone 6S/7) puede ser más lento",
                                "• Si tienes problemas de rendimiento, usa solo prefijo 600",
                                "• Los números manuales son adicionales a estos prefijos",
                                "• Considera desactivar 809 si no recibes llamadas internacionales"
                            ]
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Ayuda")
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

struct CommonIssueCard: View {
    let title: String
    let icon: String
    let color: Color
    let steps: [String]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - always visible
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(color)
                    }
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(steps, id: \.self) { step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(color)
                                .padding(.top, 1)
                            
                            Text(step)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        }
    }
}

#Preview {
    CommonIssuesView()
}
