//
//  DoseMateWidget.swift
//  DoseMateWidget
//
//  Created by bbdyno on 11/30/25.
//

import WidgetKit
import SwiftUI
import DMateResource

// MARK: - Widget Bundle

@main
struct DoseMateWidgetBundle: WidgetBundle {
    var body: some Widget {
        PillReminderWidget()
    }
}

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
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MedicationEntry>) -> Void) {
        let entry = createEntry()

        // 15분마다 업데이트
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    // MARK: - Data Loading

    /// 위젯 엔트리 생성 (실제 데이터 사용)
    private func createEntry() -> MedicationEntry {
        // 위젯 데이터 매니저에서 데이터 로드
        if let widgetData = WidgetDataManager.shared.getWidgetData() {
            // 실제 데이터 사용
            let medications = widgetData.medications.map { item in
                MedicationEntry.MedicationItem(
                    id: item.id,
                    name: item.name,
                    dosage: item.dosage,
                    scheduledTime: item.scheduledTime,
                    status: getStatusDisplayName(item.status),
                    statusColor: item.statusColor
                )
            }

            let nextDose = widgetData.nextDose.map { item in
                MedicationEntry.MedicationItem(
                    id: item.id,
                    name: item.name,
                    dosage: item.dosage,
                    scheduledTime: item.scheduledTime,
                    status: getStatusDisplayName(item.status),
                    statusColor: item.statusColor
                )
            }

            return MedicationEntry(
                date: widgetData.updatedAt,
                medications: medications,
                adherenceRate: widgetData.adherenceRate,
                nextDose: nextDose
            )
        } else {
            // 데이터가 없으면 샘플 데이터 사용
            print("[Widget] 위젯 데이터를 찾을 수 없어 샘플 데이터를 사용합니다.")
            return createSampleEntry()
        }
    }

    /// 샘플 엔트리 생성
    private func createSampleEntry() -> MedicationEntry {
        return MedicationEntry(
            date: Date(),
            medications: [
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
            ],
            adherenceRate: 0.75,
            nextDose: MedicationEntry.MedicationItem(
                id: UUID(),
                name: "아스피린",
                dosage: "100mg",
                scheduledTime: Date().addingTimeInterval(30 * 60),
                status: "대기",
                statusColor: .orange
            )
        )
    }

    /// 상태 표시 이름 변환
    private func getStatusDisplayName(_ status: String) -> String {
        switch status {
        case "taken": return DMateResourceStrings.Widget.Status.completed
        case "pending": return DMateResourceStrings.Widget.Status.pending
        case "skipped": return DMateResourceStrings.Widget.Status.skipped
        case "delayed": return DMateResourceStrings.Widget.Status.delayed
        case "snoozed": return DMateResourceStrings.Widget.Status.snoozed
        default: return status
        }
    }
}

// MARK: - Widget Views

/// 소형 위젯 뷰
struct SmallWidgetView: View {
    let entry: MedicationEntry

    var body: some View {
        if entry.medications.isEmpty {
            // 제로 케이스: 데이터 없음
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Image(systemName: "pill.circle")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                }

                VStack(spacing: 4) {
                    Text(DMateResourceStrings.Widget.noData)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(DMateResourceStrings.Widget.addInApp)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(16)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                // 헤더 - 아이콘과 준수율
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(adherenceColor.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: "pills.circle.fill")
                            .font(.title2)
                            .foregroundStyle(adherenceColor)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(entry.adherenceRate * 100))%")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(adherenceColor)

                        Text(DMateResourceStrings.Widget.adherenceRate)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // 다음 복약 정보
                if let next = entry.nextDose {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text(DMateResourceStrings.Widget.nextDose)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }

                        Text(next.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.caption2)
                                .foregroundColor(next.statusColor)

                            Text(formatTime(next.scheduledTime))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(next.statusColor)
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundColor(.green)

                        Text(DMateResourceStrings.Widget.allCompleteToday)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(16)
        }
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
        if entry.medications.isEmpty {
            // 제로 케이스: 데이터 없음
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "pill.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
                .padding(.leading, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text(DMateResourceStrings.Widget.noMedicationData)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(DMateResourceStrings.Widget.addMedicationsInApp)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    Spacer()
                }

                Spacer()
            }
            .frame(maxHeight: .infinity)
            .padding(16)
        } else {
            HStack(spacing: 16) {
                // 왼쪽: 준수율 원형 진행바
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.15), lineWidth: 10)

                        Circle()
                            .trim(from: 0, to: entry.adherenceRate)
                            .stroke(
                                adherenceColor,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            Image(systemName: "pills.fill")
                                .font(.title3)
                                .foregroundColor(adherenceColor)

                            Text("\(Int(entry.adherenceRate * 100))%")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(adherenceColor)
                        }
                    }
                    .frame(width: 80, height: 80)

                    Text("오늘 준수율")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 4)

                // 구분선
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1)
                    .padding(.vertical, 12)

                // 오른쪽: 오늘의 복약 리스트
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "list.bullet.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("오늘의 복약")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(entry.medications.count)건")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    ForEach(entry.medications.prefix(3)) { item in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(item.statusColor.opacity(0.2))
                                    .frame(width: 28, height: 28)

                                Image(systemName: statusIcon(for: item.status))
                                    .font(.caption)
                                    .foregroundColor(item.statusColor)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)

                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .font(.caption2)

                                    Text(formatTime(item.scheduledTime))
                                        .font(.caption2)
                                }
                                .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                    }

                    Spacer()
                }
                .padding(.trailing, 4)
            }
            .padding(16)
        }
    }

    private var adherenceColor: Color {
        if entry.adherenceRate >= 0.8 { return .green }
        else if entry.adherenceRate >= 0.5 { return .orange }
        else { return .red }
    }

    private func statusIcon(for status: String) -> String {
        switch status {
        case "완료": return "checkmark"
        case "대기": return "clock"
        default: return "exclamationmark"
        }
    }
}

/// 대형 위젯 뷰
struct LargeWidgetView: View {
    let entry: MedicationEntry

    var body: some View {
        if entry.medications.isEmpty {
            // 제로 케이스: 데이터 없음
            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "pill.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                }

                VStack(spacing: 8) {
                    Text("복약 데이터가 없습니다")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("DoseMate 앱에서 약물을 추가하고\n복약 일정을 관리하세요")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }

                Spacer()

                HStack {
                    Image(systemName: "hand.tap.fill")
                        .font(.caption)

                    Text("탭하여 앱 열기")
                        .font(.caption)
                        .fontWeight(.medium)

                    Spacer()
                }
                .foregroundColor(.secondary)
            }
            .padding(16)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                // 헤더
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "pills.circle.fill")
                                .font(.title3)
                                .foregroundColor(adherenceColor)

                            Text("복약 관리")
                                .font(.headline)
                                .fontWeight(.bold)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.caption2)

                            Text(Date(), style: .date)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    // 준수율 카드
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(adherenceColor.opacity(0.2))
                                .frame(width: 60, height: 60)

                            VStack(spacing: 2) {
                                Text("\(Int(entry.adherenceRate * 100))%")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(adherenceColor)

                                Text("준수율")
                                    .font(.system(size: 9))
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // 구분선
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)

                // 복약 리스트
                VStack(spacing: 12) {
                    ForEach(entry.medications) { item in
                        HStack(spacing: 12) {
                            // 상태 아이콘
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(item.statusColor.opacity(0.15))
                                    .frame(width: 44, height: 44)

                                Image(systemName: statusIcon(for: item.status))
                                    .font(.title3)
                                    .foregroundColor(item.statusColor)
                            }

                            // 약물 정보
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)

                                HStack(spacing: 4) {
                                    Image(systemName: "pill")
                                        .font(.caption2)

                                    Text(item.dosage)
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }

                            Spacer()

                            // 시간 및 상태
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .font(.caption2)

                                    Text(formatTime(item.scheduledTime))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }

                                Text(item.status)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(item.statusColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(item.statusColor.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                Spacer()

                // 하단 힌트
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .font(.caption)

                    Text("탭하여 앱 열기")
                        .font(.caption)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(entry.medications.count)건의 복약")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
                .foregroundColor(.secondary)
            }
            .padding(16)
        }
    }

    private var adherenceColor: Color {
        if entry.adherenceRate >= 0.8 { return .green }
        else if entry.adherenceRate >= 0.5 { return .orange }
        else { return .red }
    }

    private func statusIcon(for status: String) -> String {
        switch status {
        case "완료": return "checkmark.circle.fill"
        case "대기": return "clock.badge.exclamationmark"
        default: return "exclamationmark.triangle.fill"
        }
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
                .containerBackground(for: .widget) {
                    let adherenceColor: Color = {
                        if entry.adherenceRate >= 0.8 { return .green }
                        else if entry.adherenceRate >= 0.5 { return .orange }
                        else { return .red }
                    }()

                    LinearGradient(
                        colors: [
                            adherenceColor.opacity(0.12),
                            adherenceColor.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName(DMateResourceStrings.Widget.configurationDisplayName)
        .description(DMateResourceStrings.Widget.configurationDescription)
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

    private var adherenceColor: Color {
        if entry.adherenceRate >= 0.8 { return .green }
        else if entry.adherenceRate >= 0.5 { return .orange }
        else { return .red }
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
