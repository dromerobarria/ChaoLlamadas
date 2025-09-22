//
//  BlockedNumbersView.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 20-08-25.
//

import SwiftUI
import SwiftData
import TipKit

// Helper struct to combine blocked calls and manually added numbers
struct BlockedItem: Identifiable {
    let id: String
    let phoneNumber: String
    let date: Date
    let type: BlockedItemType
    let callerName: String?
}

enum BlockedItemType {
    case actualCall
    case manuallyAdded
}

struct BlockedNumbersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CallRecord.callDate, order: .reverse) private var callRecords: [CallRecord]
    @Query(sort: \BlockedNumber.dateAdded, order: .reverse) private var blockedNumbers: [BlockedNumber]
    @StateObject private var callBlockingService = CallBlockingService.shared
    @StateObject private var tipManager = CallBlockingTipManager.shared
    @State private var showingSetup = false
    
    private let callKitSetupTip = CallKitSetupTip()
    private let blockingAppsWarningTip = BlockingAppsWarningTip()
    private let firstCallOnlyTip = FirstCallOnlyTip()
    
    var blockedCalls: [CallRecord] {
        callRecords.filter { $0.wasBlocked }
    }
    
    // Combine actual blocked calls and manually added numbers for display
    var allBlockedItems: [BlockedItem] {
        var items: [BlockedItem] = []
        
        // Add actual blocked calls
        for call in blockedCalls {
            items.append(BlockedItem(
                id: call.phoneNumber + String(call.callDate.timeIntervalSince1970),
                phoneNumber: call.phoneNumber,
                date: call.callDate,
                type: .actualCall,
                callerName: call.callerName
            ))
        }
        
        // Add manually blocked numbers (that haven't had actual calls blocked yet)
        for number in blockedNumbers where number.isBlocked {
            // Only add if there's no recent blocked call for this number
            let normalizedManual = number.phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
            let hasRecentCall = blockedCalls.contains { call in
                let normalizedCall = call.phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
                return normalizedCall.contains(normalizedManual) || normalizedManual.contains(normalizedCall)
            }
            
            if !hasRecentCall {
                items.append(BlockedItem(
                    id: "manual-" + number.phoneNumber,
                    phoneNumber: number.phoneNumber,
                    date: number.dateAdded,
                    type: .manuallyAdded,
                    callerName: nil
                ))
            }
        }
        
        return items.sorted { $0.date > $1.date }
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        
                        // Subtitle header to explain "last calls only"
                        VStack(spacing: 8) {
                            HStack {
                                Text("Últimas Llamadas Registradas")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Text("Solo se muestra la primera llamada bloqueada de cada número")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Header card with statistics
                        StatsCard()
                        
                        // Auto-block notice
                        AutoBlockNoticeCard()
                        
                        // First call only tip
                        TipView(firstCallOnlyTip, arrowEdge: .top)
                            .tipBackground(.regularMaterial)
                            .padding(.horizontal, 20)
                        
                        // Blocked items list (calls + manual numbers)
                        if allBlockedItems.isEmpty {
                            EmptyStateView()
                                .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(allBlockedItems) { item in
                                    BlockedItemCard(item: item)
                                }
                            }
                        }
                        
                        // Bottom padding for smaller devices
                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Llamadas Bloqueadas")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                setupSampleCallData()
                callBlockingService.checkForNewBlockedCalls()
            }
            .sheet(isPresented: $showingSetup) {
                CallDirectorySetupView()
            }
        }
    }
    
    private func openCallKitSettings() {
        callBlockingService.openCallSettings()
    }
    
    private func setupSampleCallData() {
        // Clear any old fake/sample data that might exist from previous versions
        clearFakeData()
    }
    
    private func clearFakeData() {
        // Remove any fake data that was added in previous versions
        let fakeNumbers = [
            "60012345678",
            "60087654321", 
            "60098765432",
            "60011223344",
            "60055667788",
            "60033445566",
            "60077889900"
        ]
        
        for call in callRecords {
            let cleanNumber = call.phoneNumber.replacingOccurrences(of: "+56", with: "")
            if fakeNumbers.contains(cleanNumber) {
                modelContext.delete(call)
            }
        }
        
        try? modelContext.save()
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
                    Text("\(callBlockingService.getBlockedNumbersCount())")
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
    @StateObject private var callBlockingService = CallBlockingService.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .font(.title2)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Bloqueo Automático")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text("Los \(callBlockingService.getActivePrefixesText()) son bloqueados automáticamente")
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
    @StateObject private var callBlockingService = CallBlockingService.shared
    
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
                
                Text(callBlockingService.getActivePrefixes().joined(separator: "+"))
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
    @StateObject private var callBlockingService = CallBlockingService.shared
    
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
                
                Text("Los \(callBlockingService.getActivePrefixesText()) se bloquearán automáticamente cuando intenten llamarte. Tu teléfono está protegido.")
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

struct BlockedItemCard: View {
    let item: BlockedItem
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(item.type == .actualCall ? .red.opacity(0.2) : .orange.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: item.type == .actualCall ? "phone.down.fill" : "shield.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(item.type == .actualCall ? .red : .orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(formatPhoneNumber(item.phoneNumber))
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(formatDate(item.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    if let callerName = item.callerName {
                        Text(callerName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(item.type == .actualCall ? "Llamada bloqueada" : "Número manual")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if item.type == .manuallyAdded {
                        Text("MANUAL")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        let cleaned = number.replacingOccurrences(of: "+56", with: "")
        if cleaned.count >= 9 {
            let firstPart = String(cleaned.prefix(1))
            let secondPart = String(cleaned.dropFirst(1).prefix(4))
            let thirdPart = String(cleaned.dropFirst(5).prefix(4))
            return "+56 \(firstPart) \(secondPart) \(thirdPart)"
        }
        return "+56 \(cleaned)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    BlockedNumbersView()
        .modelContainer(for: CallRecord.self, inMemory: true)
}