//
//  DoseMateWidget.swift
//  DoseMateWidget
//
//  Created by bbdyno on 11/30/25.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

/// 위젯 타임라인 엔트리
struct MedicationEntry: TimelineEntry {
    let date: Date
    let medications: [MedicationItem]
    let adherenceRate: Double
    let nextDose: MedicationItem?
    
    struct MedicationItem: Identifiable {
        let id: UUID
        let name: String
        let dosage: String
        let scheduledTime: Date
        let status: String
        let statusColor: Color
    }
    
    /// 플레이스홀더용 샘플 엔트리
    static var placeholder: MedicationEntry {
        MedicationEntry(
            date: Date(),
            medications: [
                MedicationItem(
                    id: UUID(),
                    name: "아스피린",
                    dosage: "100mg",
                    scheduledTime: Date(),
                    status: "대기",
                    statusColor: .orange
                )
            ],
            adherenceRate: 0.85,
            nextDose: nil
        )
    }
}

// MARK: - Timeline Provider

/// 타임라인 프로바이더
struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> MedicationEntry {
        MedicationEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MedicationEntry) -> Void) {
        let entry = MedicationEntry(
            date: Date(),
            medications: getSampleMedications(),
            adherenceRate: 0.85,
            nextDose: nil
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MedicationEntry>) -> Void) {
        let entry = MedicationEntry(
            date: Date(),
            medications: getSampleMedications(),
            adherenceRate: calculateTodayAdherence(),
            nextDose: getNextDose()
        )
        
        // 15분마다 업데이트
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func getSampleMedications() -> [MedicationEntry.MedicationItem] {
        // 실제 구현에서는 App Group을 통해 SwiftData에서 데이터 로드
        // 여기서는 샘플 데이터 반환
        return [
            MedicationEntry.MedicationItem(
                id: UUID(),
                name: "아스피린",
                dosage: "100mg",
                scheduledTime: Date().addingTimeInterval(30 * 60),
                status: "대기",
                statusColor: .orange
            ),
            MedicationEntry.MedicationItem(
                id: UUID(),
                name: "메트포르민",
                dosage: "500mg",
                scheduledTime: Date().addingTimeInterval(-60 * 60),
                status: "완료",
                statusColor: .green
            )
        ]
    }
    
    private func calculateTodayAdherence() -> Double {
        // 실제 구현에서는 SwiftData에서 계산
        return 0.75
    }
    
    private func getNextDose() -> MedicationEntry.MedicationItem? {
        return MedicationEntry.MedicationItem(
            id: UUID(),
            name: "아스피린",
            dosage: "100mg",
            scheduledTime: Date().addingTimeInterval(30 * 60),
            status: "대기",
            statusColor: .orange
        )
    }
}

// MARK: - Widget Views

/// 소형 위젯 뷰
struct SmallWidgetView: View {
    let entry: MedicationEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 준수율
            HStack {
                Text("\(Int(entry.adherenceRate * 100))%")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(adherenceColor)
                
                Spacer()
                
                Image(systemName: "pill.fill")
                    .foregroundColor(.blue)
            }
            
            Text("오늘 준수율")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // 다음 복약
            if let next = entry.nextDose {
                VStack(alignment: .leading, spacing: 2) {
                    Text("다음 복약")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(next.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(formatTime(next.scheduledTime))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            } else {
                Text("오늘 복약 완료!")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
    
    private var adherenceColor: Color {
        if entry.adherenceRate >= 0.8 { return .green }
        else if entry.adherenceRate >= 0.5 { return .orange }
        else { return .red }
    }
}

/// 중형 위젯 뷰
struct MediumWidgetView: View {
    let entry: MedicationEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // 왼쪽: 준수율
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: entry.adherenceRate)
                        .stroke(adherenceColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(entry.adherenceRate * 100))%")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                }
                .frame(width: 60, height: 60)
                
                Text("준수율")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 오른쪽: 오늘의 복약
            VStack(alignment: .leading, spacing: 6) {
                Text("오늘의 복약")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(entry.medications.prefix(3)) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(item.statusColor)
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            
                            Text(formatTime(item.scheduledTime))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
        }
        .padding()
    }
    
    private var adherenceColor: Color {
        if entry.adherenceRate >= 0.8 { return .green }
        else if entry.adherenceRate >= 0.5 { return .orange }
        else { return .red }
    }
}

/// 대형 위젯 뷰
struct LargeWidgetView: View {
    let entry: MedicationEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                VStack(alignment: .leading) {
                    Text("복약 관리")
                        .font(.headline)
                    
                    Text(Date(), style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 준수율
                VStack {
                    Text("\(Int(entry.adherenceRate * 100))%")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(adherenceColor)
                    
                    Text("준수율")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // 복약 리스트
            VStack(spacing: 10) {
                ForEach(entry.medications) { item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(item.statusColor)
                            .frame(width: 10, height: 10)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(item.dosage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatTime(item.scheduledTime))
                                .font(.subheadline)
                            
                            Text(item.status)
                                .font(.caption)
                                .foregroundColor(item.statusColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Spacer()
            
            // 하단 힌트
            HStack {
                Image(systemName: "hand.tap.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("탭하여 앱 열기")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private var adherenceColor: Color {
        if entry.adherenceRate >= 0.8 { return .green }
        else if entry.adherenceRate >= 0.5 { return .orange }
        else { return .red }
    }
}

// MARK: - Widget Definition

/// 메인 위젯
struct PillReminderWidget: Widget {
    let kind: String = "PillReminderWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider()
        ) { entry in
            WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("복약 관리")
        .description("오늘의 복약 일정을 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// 위젯 엔트리 뷰
struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MedicationEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

enum Formatters {
    // MARK: - Date Formatters
    
    /// 시간 포맷터 (HH:mm)
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
}

func formatTime(_ date: Date) -> String {
    Formatters.time.string(from: date)
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    PillReminderWidget()
} timeline: {
    MedicationEntry.placeholder
}

#Preview(as: .systemMedium) {
    PillReminderWidget()
} timeline: {
    MedicationEntry.placeholder
}
