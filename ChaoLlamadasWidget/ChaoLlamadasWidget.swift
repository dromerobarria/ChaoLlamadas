//
//  ChaoLlamadasWidget.swift
//  ChaoLlamadasWidget
//
//  Created by Daniel Romero on 27-08-25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        // Provide a realistic placeholder for when the widget is loading
        SimpleEntry(date: Date(), blockedCallsCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        // For snapshot in widget gallery, show current data
        let entry = SimpleEntry(date: Date(), blockedCallsCount: getBlockedCallsCount())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let blockedCallsCount = getBlockedCallsCount()
        
        // Create timeline following Apple's recommendations
        var entries: [SimpleEntry] = []
        
        // Add current entry
        entries.append(SimpleEntry(date: currentDate, blockedCallsCount: blockedCallsCount))
        
        // Add entries for the next few hours to maintain freshness
        for hourOffset in 1...6 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            // Refetch data for each future entry in case it changes
            let futureCount = getBlockedCallsCount()
            entries.append(SimpleEntry(date: entryDate, blockedCallsCount: futureCount))
        }
        
        // Set next refresh in 1 hour to balance freshness with battery life
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextRefresh))
        completion(timeline)
    }
    
    private func getBlockedCallsCount() -> Int {
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            return 0
        }
        
        return userDefaults.integer(forKey: "totalBlockedCallsCount")
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let blockedCallsCount: Int
}

struct ChaoLlamadasWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with app branding
            HStack {
                Image(systemName: "shield.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                
                Spacer()
                
                Text("ChaoLlamadas")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)
            
            Spacer()
            
            // Main content - blocked calls count
            VStack(spacing: 2) {
                Text("\(entry.blockedCallsCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.8)
                    .accessibilityLabel("\(entry.blockedCallsCount) llamadas bloqueadas")
                
                Text(entry.blockedCallsCount == 1 ? "Bloqueada" : "Bloqueadas")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                
                Text("Activo")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
        .padding(16)
        .background {
            if #available(iOS 17.0, *) {
                ContainerRelativeShape()
                    .fill(.regularMaterial)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ChaoLlamadas. \(entry.blockedCallsCount) llamadas bloqueadas. Protección activa.")
    }
}

struct MediumWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Main metric
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "shield.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                    
                    Text("ChaoLlamadas")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.blockedCallsCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .accessibilityLabel("\(entry.blockedCallsCount) llamadas bloqueadas")
                    
                    Text(entry.blockedCallsCount == 1 ? "Llamada Bloqueada" : "Llamadas Bloqueadas")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Spacer()
            
            // Right side - Status and info
            VStack(alignment: .trailing, spacing: 12) {
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        
                        Text("Protección Activa")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.down.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                        
                        Text(getActivePrefixesText() + " + Manual")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(formatLastUpdate())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(16)
        .background {
            if #available(iOS 17.0, *) {
                ContainerRelativeShape()
                    .fill(.regularMaterial)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ChaoLlamadas. \(entry.blockedCallsCount) llamadas bloqueadas. Protección activa. \(formatLastUpdate())")
    }
    
    private func formatLastUpdate() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Actualizado: \(formatter.string(from: entry.date))"
    }
    
    private func getActivePrefixesText() -> String {
        guard let userDefaults = UserDefaults(suiteName: "group.dromero.chaollamadas") else {
            return "600"  // Default fallback
        }
        
        let is600Enabled = userDefaults.bool(forKey: "is600BlockingEnabled")
        let is809Enabled = userDefaults.bool(forKey: "is809BlockingEnabled")
        
        var prefixes: [String] = []
        if is600Enabled { prefixes.append("600") }
        if is809Enabled { prefixes.append("809") }
        
        if prefixes.isEmpty {
            return "Sin prefijos"
        } else if prefixes.count == 1 {
            return prefixes[0]
        } else {
            return prefixes.joined(separator: "+")
        }
    }
}

struct ChaoLlamadasWidget: Widget {
    let kind: String = "ChaoLlamadasWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                ChaoLlamadasWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                ChaoLlamadasWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Llamadas Bloqueadas")
        .description("Muestra el número total de llamadas spam bloqueadas por ChaoLlamadas")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    ChaoLlamadasWidget()
} timeline: {
    SimpleEntry(date: .now, blockedCallsCount: 42)
    SimpleEntry(date: .now, blockedCallsCount: 127)
}
