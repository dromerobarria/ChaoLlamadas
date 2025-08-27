//
//  OnboardingView.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 20-08-25.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        ZStack {
            // Liquid glass background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1),
                    Color.pink.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                OnboardingPageView(
                    title: "📱 ¡Bienvenido a ChaoLlamadas!",
                    description: "🛡️ Tu aplicación para bloquear llamadas no deseadas de números 600 o 809 en Chile",
                    systemImage: "phone.badge.checkmark",
                    page: 0,
                    backgroundColor: .blue
                )
                .tag(0)
                
                OnboardingPageView(
                    title: "🇨🇱 Nueva Ley Chilena",
                    description: "⚖️ Según la nueva ley, los números que comienzan con 600 o 809 son utilizados por empresas para ventas telefónicas. Esta app los bloquea automáticamente.",
                    systemImage: "shield.checkered",
                    page: 1,
                    backgroundColor: .purple
                )
                .tag(1)
                
                OnboardingPageView(
                    title: "🎛️ Control Total",
                    description: "✅ Gestiona excepciones, revisa números bloqueados y mantén el control total de tus llamadas.",
                    systemImage: "slider.horizontal.3",
                    page: 2,
                    backgroundColor: .green
                )
                .tag(2)
                
                PrefixSelectionOnboardingView(
                    page: 3,
                    onComplete: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            hasCompletedOnboarding = true
                        }
                    }
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            VStack {
                Spacer()
                
                // Custom page indicator - hide on last page
                if currentPage < 3 {
                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.primary : Color.primary.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

struct OnboardingPageView: View {
    let title: String
    let description: String
    let systemImage: String
    let page: Int
    var backgroundColor: Color = .blue
    var isLast: Bool = false
    var onComplete: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon with liquid glass effect
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .shadow(color: backgroundColor.opacity(0.3), radius: 15, x: 0, y: 8)
                
                Circle()
                    .fill(backgroundColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: systemImage)
                    .font(.system(size: 50))
                    .foregroundStyle(backgroundColor)
            }
            
            VStack(spacing: 20) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if isLast {
                Button(action: {
                    onComplete?()
                }) {
                    HStack(spacing: 8) {
                        Text("🚀 Comenzar")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [backgroundColor, backgroundColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(color: backgroundColor.opacity(0.4), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 40)
                }
            }
            
            Spacer()
        }
    }
}

struct PrefixSelectionOnboardingView: View {
    @StateObject private var callBlockingService = CallBlockingService.shared
    @State private var is600Enabled = true  // Default to enabled
    @State private var is809Enabled = false // Default to disabled
    let page: Int
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Icon with liquid glass effect
                ZStack {
                    Circle()
                        .fill(.orange.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .background(
                            Circle()
                                .fill(.orange.opacity(0.1))
                                .frame(width: 120, height: 120)
                        )
                    
                    Image(systemName: "phone.connection")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)
                }
                
                VStack(spacing: 16) {
                    Text("📞 Configuración Inicial")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                    
                    Text("Selecciona qué tipos de números deseas bloquear automáticamente:")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 30)
                }
                
                VStack(spacing: 12) {
                    // 600 prefix toggle
                    PrefixToggleRow(
                        prefix: "600",
                        title: "Números 600 (Chile)",
                        description: "Números comerciales y de telemarketing que fueron solicitadas",
                        isEnabled: $is600Enabled,
                        color: .blue
                    )
                    
                    // 809 prefix toggle  
                    PrefixToggleRow(
                        prefix: "809",
                        title: "Números 809 ",
                        description: "Se utiliza para identificar llamadas no deseadas, como telemarketing o campañas publicitarias no autorizadas",
                        isEnabled: $is809Enabled,
                        color: .orange
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Finish button
                Button(action: {
                    // Save both settings at once to avoid rate limiting issues
                    print("🔧 [Onboarding] Saving settings: 600=\(is600Enabled), 809=\(is809Enabled)")
                    callBlockingService.setBothPrefixBlocking(enabled600: is600Enabled, enabled809: is809Enabled)
                    onComplete()
                }) {
                    HStack {
                        Text("Finalizar Configuración")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                colors: [.orange, .red.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                    )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
            .onAppear {
                // Initialize local state from service
                is600Enabled = callBlockingService.is600BlockingEnabled
                is809Enabled = callBlockingService.is809BlockingEnabled
            }
        }
    }
}

struct PrefixToggleRow: View {
    let prefix: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isEnabled ? color.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(prefix)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(isEnabled ? color : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .tint(color)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(isEnabled ? color.opacity(0.08) : Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isEnabled ? color.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

#Preview {
    OnboardingView()
}
