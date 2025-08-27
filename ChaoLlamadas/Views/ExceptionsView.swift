//
//  ExceptionsView.swift
//  ChaoLlamadas
//
//  Created by Daniel Romero on 20-08-25.
//

import SwiftUI
import SwiftData

struct ExceptionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exceptions: [ExceptionNumber]
    @StateObject private var callBlockingService = CallBlockingService.shared
    @State private var showingAddException = false
    @State private var newPhoneNumber = ""
    @State private var newNote = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.05),
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Info card
                    InfoCard()
                    
                    // Add button
                    AddExceptionButton {
                        showingAddException = true
                    }
                    
                    // Exceptions list
                    if exceptions.isEmpty {
                        EmptyExceptionsView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(exceptions) { exception in
                                    ExceptionCard(exception: exception) {
                                        deleteException(exception)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Excepciones")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddException) {
                AddExceptionSheet(
                    phoneNumber: $newPhoneNumber,
                    note: $newNote,
                    onSave: addException,
                    onCancel: {
                        showingAddException = false
                        newPhoneNumber = ""
                        newNote = ""
                    }
                )
            }
        }
    }
    
    private func addException() {
        guard !newPhoneNumber.isEmpty else { return }
        
        // Prevent adding 600 or 809 prefixes as exceptions since they're managed separately
        if isBlockedPrefix(newPhoneNumber) {
            // Show error or just return - these prefixes are managed by the automatic blocking system
            return
        }
        
        let exception = ExceptionNumber(phoneNumber: newPhoneNumber, note: newNote)
        modelContext.insert(exception)
        
        try? modelContext.save()
        
        // Update CallKit extension with new exceptions
        updateCallKitExceptions()
        
        showingAddException = false
        newPhoneNumber = ""
        newNote = ""
    }
    
    private func isBlockedPrefix(_ phoneNumber: String) -> Bool {
        let cleanNumber = phoneNumber.replacingOccurrences(of: "+56", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        // Check if number starts with 600 or 809
        return cleanNumber.hasPrefix("600") || cleanNumber.hasPrefix("809")
    }
    
    private func deleteException(_ exception: ExceptionNumber) {
        modelContext.delete(exception)
        try? modelContext.save()
        
        // Update CallKit extension with updated exceptions
        updateCallKitExceptions()
    }
    
    private func updateCallKitExceptions() {
        let exceptionNumbers = exceptions.map { $0.phoneNumber }
        callBlockingService.saveExceptions(exceptionNumbers)
    }
}

struct InfoCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.shield")
                .font(.title2)
                .foregroundStyle(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Números Permitidos")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text("Agrega números específicos que sí quieres que puedan llamarte, como tu banco o clínica")
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

struct AddExceptionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label("Agregar Excepción", systemImage: "plus")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal, 20)
    }
}

struct ExceptionCard: View {
    let exception: ExceptionNumber
    let onDelete: () -> Void
    
    var isPrefix: Bool {
        exception.phoneNumber.contains("*")
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Status icon
            ZStack {
                Circle()
                    .fill(.green.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: isPrefix ? "number.circle.fill" : "phone.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.green)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Phone number
                Text(formatPhoneNumber(exception.phoneNumber))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                // Type indicator
                HStack(spacing: 4) {
                    if isPrefix {
                        Text("Prefijo permitido")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Text("Número específico")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                
                // Note
                if !exception.note.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(exception.note)
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
                    Text("Agregado: \(exception.dateAdded, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                // Status indicator
                VStack(spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 18))
                    
                    Text("PERMITIDO")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.green)
                }
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundStyle(.red)
                        .padding(4)
                        .background(.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.green.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        if number.contains("*") {
            let prefix = number.replacingOccurrences(of: "*", with: "")
            return "+56 \(prefix)***"
        }
        
        let cleaned = number.replacingOccurrences(of: "+56", with: "")
        if cleaned.count >= 9 {
            let firstPart = String(cleaned.prefix(3))
            let secondPart = String(cleaned.dropFirst(3).prefix(3))
            let thirdPart = String(cleaned.dropFirst(6).prefix(3))
            return "+56 \(firstPart) \(secondPart) \(thirdPart)"
        }
        return "+56 \(cleaned)"
    }
}

struct EmptyExceptionsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            VStack(spacing: 12) {
                Text("Sin Excepciones")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("¿Hay algún número específico que sí quieres que te llame? Agrégalo como excepción.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 8) {
                Text("Ejemplos:")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                
                VStack(spacing: 4) {
                    Text("Tu banco • Clínica médica • Empresa donde trabajas")
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

struct AddExceptionSheet: View {
    @Binding var phoneNumber: String
    @Binding var note: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var selectedMode = 0 // 0: Specific number, 1: Prefix
    @State private var prefix = "601" // Changed from 600 to avoid blocked prefix
    @State private var specificNumber = ""
    @State private var showingPrefixError = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(.green.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.green)
                        }
                        
                        Text("Agregar Excepción")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Permite que ciertos números específicos puedan llamarte")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Mode Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tipo de Excepción")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Picker("Mode", selection: $selectedMode) {
                            Text("Número Específico").tag(0)
                            Text("Prefijo Completo").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 4)
                    }
                    .padding(20)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    
                    // Input Section
                    VStack(alignment: .leading, spacing: 20) {
                        if selectedMode == 0 {
                            // Specific Number Input
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
                                    
                                    TextField("987654321", text: $specificNumber)
                                        .font(.title2)
                                        .keyboardType(.phonePad)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                }
                                
                                Text("Ejemplo: 987654321 (no usar 600 o 809)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            // Prefix Input
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Prefijo")
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
                                    
                                    TextField("601123", text: $prefix)
                                        .font(.title2)
                                        .keyboardType(.phonePad)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    
                                    Text("***")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.blue)
                                }
                                
                                Text("Permitirá todos los números que empiecen con este prefijo")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        // Note Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nota (Opcional)")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            TextField("Ej: Mi banco, clínica médica, etc.", text: $note)
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
                        Color.green.opacity(0.05),
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            .navigationTitle("Nueva Excepción")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        // Set the phoneNumber based on selected mode
                        let numberToCheck = selectedMode == 0 ? specificNumber : prefix
                        
                        // Check for blocked prefixes (600 or 809)
                        if isRestrictedPrefix(numberToCheck) {
                            showingPrefixError = true
                            return
                        }
                        
                        if selectedMode == 0 {
                            phoneNumber = specificNumber
                        } else {
                            phoneNumber = prefix + "*" // Use * to indicate prefix
                        }
                        onSave()
                    }
                    .disabled(selectedMode == 0 ? specificNumber.isEmpty : prefix.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .alert("Prefijo No Permitido", isPresented: $showingPrefixError) {
                Button("OK") { }
            } message: {
                Text("Los números 600 y 809 son gestionados automáticamente por el sistema de bloqueo. Para permitir un número específico de estos prefijos, configúralo en las opciones de bloqueo automático.")
            }
        }
    }
    
    private func isRestrictedPrefix(_ number: String) -> Bool {
        let cleanNumber = number.replacingOccurrences(of: "+56", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        // Check if number starts with 600 or 809
        return cleanNumber.hasPrefix("600") || cleanNumber.hasPrefix("809")
    }
}

#Preview {
    ExceptionsView()
        .modelContainer(for: ExceptionNumber.self, inMemory: true)
}