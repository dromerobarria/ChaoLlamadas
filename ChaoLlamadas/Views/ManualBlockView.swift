//
//  ManualBlockView.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 22-08-25.
//

import SwiftUI
import SwiftData
import TipKit

struct ManualBlockView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BlockedNumber.dateAdded, order: .reverse) private var blockedNumbers: [BlockedNumber]
    @StateObject private var callBlockingService = CallBlockingService.shared
    @StateObject private var tipManager = CallBlockingTipManager.shared
    
    @State private var showingAddNumber = false
    @State private var newPhoneNumber = ""
    @State private var blockReason = "Número bloqueado manualmente"
    @State private var pendingBlockedNumber: BlockedNumber?
    
    private let manualBlockingTip = ManualBlockingTip()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background - match exceptions style
                LinearGradient(
                    colors: [
                        Color.red.opacity(0.05),
                        Color.orange.opacity(0.05),
                        Color.pink.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Manual blocking tip
                    TipView(manualBlockingTip, arrowEdge: .top) { _ in
                        tipManager.markManualBlockingSeen()
                    }
                    .tipBackground(.red.opacity(0.1))
                    .padding(.horizontal, 20)
                    
                    // Info card - matching exceptions style
                    ManualBlockInfoCard()
                    
                    // Add number button - matching exceptions style
                    AddManualBlockButton {
                        showingAddNumber = true
                        tipManager.markManualBlockingSeen()
                    }
                    
                    // Manually blocked numbers list
                    if blockedNumbers.isEmpty {
                        ManualBlockEmptyStateView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(blockedNumbers) { blockedNumber in
                                    ManualBlockedNumberCard(
                                        blockedNumber: blockedNumber,
                                        onSync: syncBlockedNumbersToCallKit
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Bloqueo Manual")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .top) {
                // Floating status indicator positioned at the top
                if callBlockingService.registrationStatus != .idle {
                    CallKitStatusIndicator(
                        status: callBlockingService.registrationStatus,
                        message: callBlockingService.statusMessage
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .zIndex(1000)
                }
            }
            .sheet(isPresented: $showingAddNumber) {
                AddBlockedNumberSheet(
                    phoneNumber: $newPhoneNumber,
                    reason: $blockReason,
                    onSave: { number, reason in
                        addBlockedNumber(number, reason: reason)
                    }
                )
            }
            .onAppear {
                // Only sync if we have blocked numbers to avoid unnecessary reloads
                if !blockedNumbers.isEmpty {
                    syncBlockedNumbersToCallKit()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("DeleteAllManualNumbers"))) { _ in
                deleteAllManualNumbers()
            }
        }
    }
    
    private func addBlockedNumber(_ phoneNumber: String, reason: String) {
        let cleanNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        // Add +56 if not present
        let finalNumber = cleanNumber.hasPrefix("+56") ? cleanNumber : "+56\(cleanNumber)"
        
        let blockedNumber = BlockedNumber(
            phoneNumber: finalNumber,
            isBlocked: true,
            reason: reason
        )
        
        // Store the pending blocked number - don't add to UI yet
        pendingBlockedNumber = blockedNumber
        
        // Update CallKit extension with new blocked numbers immediately
        // First get the current active numbers, then add the new one
        let activeNumbers = blockedNumbers.filter { $0.isBlocked }.map { $0.phoneNumber }
        var allNumbers = Set(activeNumbers)
        allNumbers.insert(finalNumber) // Add the newly added number
        let uniqueNumbers = Array(allNumbers)
        
        print("🔄 [ManualBlock] Attempting to register \(finalNumber) with CallKit")
        callBlockingService.saveManuallyBlockedNumbers(uniqueNumbers)
        
        // Monitor the registration status
        monitorRegistrationStatus()
        
        // Reset form
        newPhoneNumber = ""
        blockReason = "Número bloqueado manualmente"
    }
    
    private func monitorRegistrationStatus() {
        // Use a timer to monitor the status changes
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            switch callBlockingService.registrationStatus {
            case .success:
                // Registration successful - add to SwiftData
                if let pendingNumber = pendingBlockedNumber {
                    modelContext.insert(pendingNumber)
                    do {
                        try modelContext.save()
                        print("✅ [ManualBlock] Successfully saved blocked number to SwiftData after CallKit success: \(pendingNumber.phoneNumber)")
                        
                        // Send notification that the number was blocked
                        CallMonitoringService.shared.sendNumberBlockedNotification(phoneNumber: pendingNumber.phoneNumber)
                    } catch {
                        print("❌ [ManualBlock] Error saving blocked number after CallKit success: \(error)")
                    }
                    pendingBlockedNumber = nil
                }
                timer.invalidate()
                
            case .failed:
                // Registration failed - don't add to SwiftData
                print("❌ [ManualBlock] CallKit registration failed - number not added to list")
                pendingBlockedNumber = nil
                timer.invalidate()
                
            case .idle:
                // Status returned to idle without success - treat as failure
                if pendingBlockedNumber != nil {
                    print("❌ [ManualBlock] CallKit registration returned to idle - treating as failure")
                    pendingBlockedNumber = nil
                    timer.invalidate()
                }
                
            case .registering:
                // Still registering - continue monitoring
                break
            }
        }
        
        // Safety timeout - don't monitor forever
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if pendingBlockedNumber != nil {
                print("⚠️ [ManualBlock] Registration monitoring timeout - cleaning up")
                pendingBlockedNumber = nil
            }
        }
    }
    
    private func syncBlockedNumbersToCallKit() {
        let activeNumbers = blockedNumbers.filter { $0.isBlocked }.map { $0.phoneNumber }
        // Remove duplicates
        let uniqueNumbers = Array(Set(activeNumbers))
        print("🔄 [ManualBlock] Syncing \(uniqueNumbers.count) numbers to CallKit: \(uniqueNumbers)")
        callBlockingService.saveManuallyBlockedNumbers(uniqueNumbers)
    }
    
    private func deleteAllManualNumbers() {
        print("🗑️ [ManualBlock] Deleting all manual numbers from SwiftData")
        
        // Delete all blocked numbers from SwiftData
        for blockedNumber in blockedNumbers {
            modelContext.delete(blockedNumber)
        }
        
        do {
            try modelContext.save()
            print("✅ [ManualBlock] All manual numbers deleted from SwiftData")
            
            // Sync empty list to CallKit
            callBlockingService.saveManuallyBlockedNumbers([])
        } catch {
            print("❌ [ManualBlock] Error deleting all manual numbers: \(error)")
        }
    }
}

struct ManualBlockInfoCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.raised.circle.fill")
                .font(.title2)
                .foregroundStyle(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Números Bloqueados")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text("Agrega números específicos que quieras bloquear manualmente")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
}

struct AddManualBlockButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label("Bloquear Número Específico", systemImage: "plus")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.red)
        .padding(.horizontal, 20)
    }
}

struct ManualBlockedNumberCard: View {
    let blockedNumber: BlockedNumber
    let onSync: () -> Void
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 16) {
            // Top section with icon and info
            HStack(spacing: 16) {
                // Status icon - matching exceptions style
                ZStack {
                    Circle()
                        .fill(blockedNumber.isBlocked ? .red.opacity(0.2) : .gray.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: blockedNumber.isBlocked ? "hand.raised.circle.fill" : "hand.raised.slash.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(blockedNumber.isBlocked ? .red : .gray)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Phone number
                    Text(formatPhoneNumber(blockedNumber.phoneNumber))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    // Status indicator
                    HStack(spacing: 4) {
                        Text(blockedNumber.isBlocked ? "Bloqueado activamente" : "Pausado")
                            .font(.caption)
                            .foregroundStyle(blockedNumber.isBlocked ? .red : .orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(blockedNumber.isBlocked ? .red.opacity(0.1) : .orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        Spacer()
                    }
                    
                    // Reason
                    if !blockedNumber.reason.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(blockedNumber.reason)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    // Date added
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Agregado: \(blockedNumber.dateAdded, style: .date)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Bottom section with action buttons
            HStack(spacing: 12) {
                // Toggle button (pause/resume)
                Button(action: toggleBlockStatus) {
                    HStack(spacing: 8) {
                        Image(systemName: blockedNumber.isBlocked ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(blockedNumber.isBlocked ? "Pausar" : "Activar")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(blockedNumber.isBlocked ? .orange : .green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(blockedNumber.isBlocked ? .orange.opacity(0.1) : .green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(blockedNumber.isBlocked ? .orange.opacity(0.3) : .green.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Delete button
                Button(action: deleteBlockedNumber) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Eliminar")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.red.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(blockedNumber.isBlocked ? .red.opacity(0.2) : .gray.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
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
    
    private func toggleBlockStatus() {
        blockedNumber.isBlocked.toggle()
        
        do {
            try modelContext.save()
            onSync()
        } catch {
            print("❌ [ManualBlock] Error toggling block status: \(error)")
        }
    }
    
    private func deleteBlockedNumber() {
        modelContext.delete(blockedNumber)
        
        do {
            try modelContext.save()
            onSync()
        } catch {
            print("❌ [ManualBlock] Error deleting blocked number: \(error)")
        }
    }
}

struct ManualBlockEmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.raised.circle")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            
            VStack(spacing: 12) {
                Text("Sin Números Bloqueados")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Agrega números específicos que quieras bloquear manualmente. Estos se suman al bloqueo automático.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 8) {
                Text("Ejemplos:")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
                
                VStack(spacing: 4) {
                    Text("Números spam • Ventas no deseadas • Robocalls")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.top, 40)
        .padding(.horizontal, 20)
    }
}

struct AddBlockedNumberSheet: View {
    @Binding var phoneNumber: String
    @Binding var reason: String
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var isValidNumber = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header - matching exceptions style
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(.red.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "hand.raised.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.red)
                        }
                        
                        Text("Bloquear Número")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Este número será bloqueado automáticamente cuando intente llamarte")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Input Section - matching exceptions style
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Número de Teléfono")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            HStack(spacing: 8) {
                                Text("+56")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.quaternary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                
                                TextField("987654321", text: $phoneNumber)
                                    .font(.title2)
                                    .keyboardType(.phonePad)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    .onChange(of: phoneNumber) { _, newValue in
                                        validatePhoneNumber(newValue)
                                    }
                            }
                            
                            Text("Formato: 987654321 o 9 8765 4321")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Reason Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Motivo (Opcional)")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            TextField("Ej: Spam, ventas no deseadas, etc.", text: $reason)
                                .font(.body)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(20)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background {
                LinearGradient(
                    colors: [
                        Color.red.opacity(0.05),
                        Color.orange.opacity(0.05),
                        Color.pink.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            .navigationTitle("Bloquear Número")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bloquear") {
                        onSave(phoneNumber, reason)
                        dismiss()
                    }
                    .disabled(!isValidNumber)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func validatePhoneNumber(_ number: String) {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "+56", with: "")
        
        // Chilean phone numbers are 9 digits (cell) or 8 digits (landline)
        isValidNumber = cleaned.count >= 8 && cleaned.count <= 9 && cleaned.allSatisfy { $0.isNumber }
    }
}

#Preview {
    ManualBlockView()
        .modelContainer(for: [BlockedNumber.self, CallRecord.self], inMemory: true)
}