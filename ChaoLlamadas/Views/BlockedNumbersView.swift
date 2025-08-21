//
//  BlockedNumbersView.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 20-08-25.
//

import SwiftUI
import SwiftData

struct BlockedNumbersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CallRecord.callDate, order: .reverse) private var callRecords: [CallRecord]
    @StateObject private var callBlockingService = CallBlockingService.shared
    @State private var showingSetup = false
    
    var blockedCalls: [CallRecord] {
        callRecords.filter { $0.wasBlocked }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.red.opacity(0.05),
                        Color.orange.opacity(0.05),
                        Color.blue.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Setup button if not enabled
                    if !callBlockingService.isCallDirectoryEnabled {
                        SetupPromptCard {
                            showingSetup = true
                        }
                    }
                    
                    // Header card with statistics
                    StatsCard()
                    
                    // Auto-block notice
                    AutoBlockNoticeCard()
                    
                    // Blocked calls list
                    if blockedCalls.isEmpty {
                        EmptyStateView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(blockedCalls) { call in
                                    BlockedCallCard(call: call)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Llamadas Bloqueadas")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                setupSampleCallData()
            }
            .sheet(isPresented: $showingSetup) {
                CallDirectorySetupView()
            }
        }
    }
    
    private func setupSampleCallData() {
        // Add sample call data if none exists
        if callRecords.isEmpty {
            let sampleCalls = [
                CallRecord(phoneNumber: "60012345678", callDate: Date().addingTimeInterval(-3600), wasBlocked: true, callerName: "Telemarketing"),
                CallRecord(phoneNumber: "60087654321", callDate: Date().addingTimeInterval(-7200), wasBlocked: true, callerName: "Ventas"),
                CallRecord(phoneNumber: "60098765432", callDate: Date().addingTimeInterval(-10800), wasBlocked: true, callerName: "Promociones"),
                CallRecord(phoneNumber: "60011223344", callDate: Date().addingTimeInterval(-14400), wasBlocked: true, callerName: "Ofertas"),
                CallRecord(phoneNumber: "60055667788", callDate: Date().addingTimeInterval(-18000), wasBlocked: true, callerName: "Marketing"),
                CallRecord(phoneNumber: "60033445566", callDate: Date().addingTimeInterval(-21600), wasBlocked: true, callerName: "Encuestas"),
                CallRecord(phoneNumber: "60077889900", callDate: Date().addingTimeInterval(-25200), wasBlocked: true, callerName: "Productos")
            ]
            
            for call in sampleCalls {
                modelContext.insert(call)
            }
            
            try? modelContext.save()
        }
    }
}

struct SetupPromptCard: View {
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Configuración Requerida")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Habilita el bloqueo de llamadas en Configuración de iOS")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Configurar", action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(16)
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
}

struct StatsCard: View {
    @StateObject private var callBlockingService = CallBlockingService.shared
    @Query private var callRecords: [CallRecord]
    
    var blockedCallsToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        return callRecords.filter { call in
            call.wasBlocked && call.callDate >= today && call.callDate < tomorrow
        }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Protección Activa")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("Sistema de bloqueo automático")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "shield.checkered")
                    .font(.title2)
                    .foregroundStyle(.green)
            }
            .padding(.bottom, 16)
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(blockedCallsToday)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Bloqueadas hoy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("1M+")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Total en lista")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        }
        .padding(.horizontal, 20)
    }
}

struct AutoBlockNoticeCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .font(.title2)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Bloqueo Automático 600")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text("Todos los números que empiecen con 600 son bloqueados automáticamente según la ley chilena")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.opacity(0.1))
        }
        .padding(.horizontal, 20)
    }
}

struct BlockedCallCard: View {
    let call: CallRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: "phone.down.circle.fill")
                .font(.title2)
                .foregroundStyle(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                // Phone number
                Text(call.formattedPhoneNumber)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                // Caller name or type
                if let callerName = call.callerName {
                    Text(callerName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Date and time
                HStack(spacing: 8) {
                    Text(call.callDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(call.callTime, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Bloqueado")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.green)
                
                Text("600")
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            VStack(spacing: 12) {
                Text("Protección Activa")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text("Los números 600 se bloquearán automáticamente cuando intenten llamarte. Tu teléfono está protegido.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Text("Las llamadas spam aparecerán aquí cuando sean bloqueadas")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .padding(.horizontal, 20)
    }
}

#Preview {
    BlockedNumbersView()
        .modelContainer(for: CallRecord.self, inMemory: true)
}