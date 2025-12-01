//
//  StatisticsView.swift
//  PillMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import SwiftData
import Charts

/// 통계 화면
struct StatisticsView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Query private var logs: [MedicationLog]
    @Query private var medications: [Medication]
    
    @State private var selectedPeriod: StatisticsPeriod = .week
    @State private var selectedMedication: Medication?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 기간 선택
                    periodSelector
                    
                    // 전체 준수율
                    overallAdherenceCard
                    
                    // 일별 준수율 차트
                    dailyAdherenceChart
                    
                    // 약물별 준수율
                    medicationAdherenceSection
                    
                    // 통계 요약
                    statisticsSummary
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("통계")
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        Picker("기간", selection: $selectedPeriod) {
            ForEach(StatisticsPeriod.allCases) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Overall Adherence Card
    
    private var overallAdherenceCard: some View {
        VStack(spacing: 16) {
            Text("전체 복약 준수율")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                
                Circle()
                    .trim(from: 0, to: overallAdherenceRate)
                    .stroke(
                        adherenceColor(for: overallAdherenceRate),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: overallAdherenceRate)
                
                VStack(spacing: 4) {
                    Text("\(Int(overallAdherenceRate * 100))%")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    
                    Text(adherenceMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 180, height: 180)
            
            // 상세 통계
            HStack(spacing: 30) {
                VStack {
                    Text("\(takenCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("복용")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(delayedCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("지연")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(skippedCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("건너뜀")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Daily Adherence Chart
    
    private var dailyAdherenceChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("일별 복약 현황")
                .font(.headline)
            
            if dailyData.isEmpty {
                Text("데이터가 없습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                Chart {
                    ForEach(dailyData, id: \.date) { data in
                        BarMark(
                            x: .value("날짜", data.date, unit: .day),
                            y: .value("복용", data.taken)
                        )
                        .foregroundStyle(.green)
                        
                        BarMark(
                            x: .value("날짜", data.date, unit: .day),
                            y: .value("지연", data.delayed)
                        )
                        .foregroundStyle(.orange)
                        
                        BarMark(
                            x: .value("날짜", data.date, unit: .day),
                            y: .value("건너뜀", data.skipped)
                        )
                        .foregroundStyle(.red)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day())
                    }
                }
                
                // 범례
                HStack(spacing: 16) {
                    legendItem(color: .green, label: "복용")
                    legendItem(color: .orange, label: "지연")
                    legendItem(color: .red, label: "건너뜀")
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Medication Adherence Section
    
    private var medicationAdherenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("약물별 준수율")
                .font(.headline)
            
            if medications.isEmpty {
                Text("등록된 약물이 없습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(medications.filter { $0.isActive }) { medication in
                    let rate = adherenceRate(for: medication)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(medication.name)
                                .fontWeight(.medium)
                            
                            Text(medication.dosage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // 프로그레스 바
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(adherenceColor(for: rate))
                                    .frame(width: geometry.size.width * rate)
                            }
                        }
                        .frame(width: 100, height: 8)
                        
                        Text("\(Int(rate * 100))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(adherenceColor(for: rate))
                            .frame(width: 50, alignment: .trailing)
                    }
                    .padding(.vertical, 8)
                    
                    if medication.id != medications.filter({ $0.isActive }).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Statistics Summary
    
    private var statisticsSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("요약")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                summaryCard(
                    icon: "flame.fill",
                    color: .orange,
                    value: "\(consecutiveDays)",
                    label: "연속 달성"
                )
                
                summaryCard(
                    icon: "pills.fill",
                    color: .blue,
                    value: "\(totalDoses)",
                    label: "총 복용 횟수"
                )
                
                summaryCard(
                    icon: "clock.fill",
                    color: .purple,
                    value: averageDelayText,
                    label: "평균 지연 시간"
                )
                
                summaryCard(
                    icon: "calendar",
                    color: .green,
                    value: "\(perfectDays)",
                    label: "완벽한 날"
                )
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
    
    private func summaryCard(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var filteredLogs: [MedicationLog] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch selectedPeriod {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: now)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
        }
        
        return logs.filter { $0.scheduledTime >= startDate && $0.scheduledTime <= now }
    }
    
    private var overallAdherenceRate: Double {
        let pastLogs = filteredLogs.filter { $0.scheduledTime <= Date() }
        guard !pastLogs.isEmpty else { return 0 }
        
        let completed = pastLogs.filter { $0.logStatus == .taken || $0.logStatus == .delayed }
        return Double(completed.count) / Double(pastLogs.count)
    }
    
    private var takenCount: Int {
        filteredLogs.filter { $0.logStatus == .taken }.count
    }
    
    private var delayedCount: Int {
        filteredLogs.filter { $0.logStatus == .delayed }.count
    }
    
    private var skippedCount: Int {
        filteredLogs.filter { $0.logStatus == .skipped }.count
    }
    
    private var adherenceMessage: String {
        if overallAdherenceRate >= 0.9 {
            return "훌륭해요!"
        } else if overallAdherenceRate >= 0.7 {
            return "잘하고 있어요"
        } else if overallAdherenceRate >= 0.5 {
            return "조금 더 노력해보세요"
        } else {
            return "복약 습관을 개선해보세요"
        }
    }
    
    private var dailyData: [(date: Date, taken: Int, delayed: Int, skipped: Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredLogs) { log in
            calendar.startOfDay(for: log.scheduledTime)
        }
        
        return grouped.map { date, logs in
            (
                date: date,
                taken: logs.filter { $0.logStatus == .taken }.count,
                delayed: logs.filter { $0.logStatus == .delayed }.count,
                skipped: logs.filter { $0.logStatus == .skipped }.count
            )
        }
        .sorted { $0.date < $1.date }
    }
    
    private func adherenceRate(for medication: Medication) -> Double {
        let medicationLogs = filteredLogs.filter { $0.medication?.id == medication.id && $0.scheduledTime <= Date() }
        guard !medicationLogs.isEmpty else { return 0 }
        
        let completed = medicationLogs.filter { $0.logStatus == .taken || $0.logStatus == .delayed }
        return Double(completed.count) / Double(medicationLogs.count)
    }
    
    private func adherenceColor(for rate: Double) -> Color {
        if rate >= 0.8 { return .green }
        else if rate >= 0.5 { return .orange }
        else { return .red }
    }
    
    private var consecutiveDays: Int {
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: Date())
        var count = 0
        
        while true {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            let dayLogs = logs.filter {
                calendar.isDate($0.scheduledTime, inSameDayAs: currentDate) && $0.scheduledTime <= Date()
            }
            
            guard !dayLogs.isEmpty else { break }
            
            let allCompleted = dayLogs.allSatisfy { $0.logStatus == .taken || $0.logStatus == .delayed }
            if allCompleted {
                count += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = prev
            } else {
                break
            }
        }
        
        return count
    }
    
    private var totalDoses: Int {
        filteredLogs.filter { $0.logStatus == .taken || $0.logStatus == .delayed }.count
    }
    
    private var averageDelayText: String {
        let delayedLogs = filteredLogs.filter { $0.isDelayed }
        guard !delayedLogs.isEmpty else { return "-" }
        
        let totalDelay = delayedLogs.compactMap { $0.minutesDelayed }.reduce(0, +)
        let average = totalDelay / delayedLogs.count
        
        if average < 60 {
            return "\(average)분"
        } else {
            return "\(average / 60)시간"
        }
    }
    
    private var perfectDays: Int {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredLogs.filter { $0.scheduledTime <= Date() }) { log in
            calendar.startOfDay(for: log.scheduledTime)
        }
        
        return grouped.values.filter { dayLogs in
            dayLogs.allSatisfy { $0.logStatus == .taken }
        }.count
    }
}

// MARK: - Preview

#Preview {
    StatisticsView()
        .modelContainer(for: [MedicationLog.self, Medication.self], inMemory: true)
}
