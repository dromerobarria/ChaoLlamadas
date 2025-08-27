//
//  CallKitStatusIndicator.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 27-08-25.
//

import SwiftUI

struct CallKitStatusIndicator: View {
    let status: CallKitRegistrationStatus
    let message: String
    
    var body: some View {
        if status != .idle {
            HStack(spacing: 12) {
                statusIcon
                
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: status)
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .idle:
            EmptyView()
        case .registering:
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
        }
    }
    
    private var backgroundColor: Color {
        switch status {
        case .idle:
            return .clear
        case .registering:
            return .blue
        case .success:
            return .green
        case .failed:
            return .red
        }
    }
}

struct FloatingCallKitStatusView: View {
    @StateObject private var callBlockingService = CallBlockingService.shared
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if callBlockingService.registrationStatus != .idle {
                    CallKitStatusIndicator(
                        status: callBlockingService.registrationStatus,
                        message: callBlockingService.statusMessage
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 8) // Position below safe area
                    .zIndex(1000) // High z-index to appear above everything
                }
                
                Spacer()
            }
        }
        .allowsHitTesting(false) // Allow touches to pass through
    }
}

#Preview {
    VStack(spacing: 20) {
        CallKitStatusIndicator(
            status: .registering,
            message: "Registrando número..."
        )
        
        CallKitStatusIndicator(
            status: .success,
            message: "Número registrado"
        )
        
        CallKitStatusIndicator(
            status: .failed,
            message: "Ha ocurrido un error no se ha podido registrar el número"
        )
    }
    .padding()
}