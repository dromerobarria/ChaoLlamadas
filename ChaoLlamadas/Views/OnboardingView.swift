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
                    description: "🛡️ Tu aplicación para bloquear llamadas no deseadas de números 600 en Chile",
                    systemImage: "phone.badge.checkmark",
                    page: 0,
                    backgroundColor: .blue
                )
                .tag(0)
                
                OnboardingPageView(
                    title: "🇨🇱 Nueva Ley Chilena",
                    description: "⚖️ Según la nueva ley, los números que comienzan con 600 son utilizados por empresas para ventas telefónicas. Esta app los bloquea automáticamente.",
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
                    backgroundColor: .green,
                    isLast: true,
                    onComplete: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            hasCompletedOnboarding = true
                        }
                    }
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            VStack {
                Spacer()
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
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

#Preview {
    OnboardingView()
}