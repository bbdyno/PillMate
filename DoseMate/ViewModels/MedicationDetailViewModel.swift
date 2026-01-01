//
//  MedicationDetailViewModel.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation
import SwiftUI
import DMateDesignSystem
import DMateResource
import SwiftData

/// 약물 상세 ViewModel
@MainActor
@Observable
final class MedicationDetailViewModel {
    // MARK: - Properties
    
    /// 약물
    var medication: Medication
    
    /// 복약 기록들
    var logs: [MedicationLog] = []
    
    /// 선택된 기간
    var selectedPeriod: StatisticsPeriod = .week {
        didSet {
            Task {
                await loadLogs()
                calculateStatistics()
            }
        }
    }
    
    /// 일간 준수율
    var dailyAdherenceRate: Double = 0.0
    
    /// 주간 준수율
    var weeklyAdherenceRate: Double = 0.0
    
    /// 월간 준수율
    var monthlyAdherenceRate: Double = 0.0
    
    /// 연속 복용 일수
    var consecutiveDays: Int = 0
    
    /// 로딩 상태
    var isLoading: Bool = false
    
    /// 에러 메시지
    var errorMessage: String?
    
    /// 편집 모드
    var isEditing: Bool = false
    
    /// 재고 추가 시트 표시
    var showStockSheet: Bool = false
    
    /// 재고 추가량
    var stockToAdd: Int = 0
    
    /// 삭제 확인 표시
    var showDeleteConfirmation: Bool = false
    
    /// 스케줄 추가 시트 표시
    var showAddScheduleSheet: Bool = false
    
    /// 선택된 날짜 (달력)
    var selectedDate: Date = Date()
    
    /// 뷰 모드 (달력/리스트)
    var viewMode: ViewMode = .calendar

    enum ViewMode: String, CaseIterable {
        case calendar
        case list

        var displayName: String {
            switch self {
            case .calendar: return DMateResourceStrings.ViewMode.calendar
            case .list: return DMateResourceStrings.ViewMode.list
            }
        }
    }

    /// 최신 건강 지표들
    var latestMetrics: [MetricType: HealthMetric] = [:]

    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init(medication: Medication) {
        self.medication = medication
    }
    
    // MARK: - Setup
    
    /// ModelContext 설정
    func setup(with context: ModelContext) {
        self.modelContext = context
        Task {
            await loadLogs()
            await loadLatestMetrics()
            calculateStatistics()
        }
    }

    /// 최신 건강 지표 로드
    func loadLatestMetrics() async {
        guard let context = modelContext else { return }

        for type in medication.relatedMetricTypes {
            let typeString = type.rawValue
            let medicationId = medication.id

            let predicate = #Predicate<HealthMetric> { metric in
                metric.type == typeString &&
                metric.medication?.id == medicationId
            }

            var descriptor = FetchDescriptor<HealthMetric>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
            )
            descriptor.fetchLimit = 1

            if let metrics = try? context.fetch(descriptor),
               let latest = metrics.first {
                latestMetrics[type] = latest
            }
        }
    }
    
    // MARK: - Data Loading
    
    /// 복약 기록 로드
    func loadLogs() async {
        guard let context = modelContext else { return }
        
        isLoading = true
        defer { isLoading = false }
        
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
        
        let medicationId = medication.id
        let predicate = #Predicate<MedicationLog> { log in
            log.medication?.id == medicationId &&
            log.scheduledTime >= startDate &&
            log.scheduledTime <= now
        }
        
        let descriptor = FetchDescriptor<MedicationLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.scheduledTime, order: .reverse)]
        )
        
        do {
            logs = try context.fetch(descriptor)
        } catch {
            errorMessage = "복약 기록을 불러오는데 실패했습니다."
        }
    }
    
    /// 통계 계산
    private func calculateStatistics() {
        let calendar = Calendar.current
        let now = Date()
        
        // 일간 준수율
        let todayStart = calendar.startOfDay(for: now)
        let todayLogs = logs.filter { $0.scheduledTime >= todayStart }
        dailyAdherenceRate = calculateRate(for: todayLogs)
        
        // 주간 준수율
        let weekStart = calendar.date(byAdding: .day, value: -7, to: now)!
        let weekLogs = logs.filter { $0.scheduledTime >= weekStart }
        weeklyAdherenceRate = calculateRate(for: weekLogs)
        
        // 월간 준수율
        let monthStart = calendar.date(byAdding: .month, value: -1, to: now)!
        let monthLogs = logs.filter { $0.scheduledTime >= monthStart }
        monthlyAdherenceRate = calculateRate(for: monthLogs)
        
        // 연속 복용 일수
        consecutiveDays = medication.consecutiveDays()
    }
    
    /// 준수율 계산
    private func calculateRate(for logs: [MedicationLog]) -> Double {
        let pastLogs = logs.filter { $0.scheduledTime <= Date() }
        guard !pastLogs.isEmpty else { return 0.0 }
        
        let completedCount = pastLogs.filter { log in
            log.logStatus == .taken || log.logStatus == .delayed
        }.count
        
        return Double(completedCount) / Double(pastLogs.count)
    }
    
    // MARK: - Actions
    
    /// 재고 추가
    func addStock() async {
        guard stockToAdd > 0 else { return }
        
        medication.increaseStock(by: stockToAdd)
        try? modelContext?.save()
        stockToAdd = 0
        showStockSheet = false
    }
    
    /// 재고 사용
    func useStock(amount: Int = 1) {
        medication.decreaseStock(by: amount)
        try? modelContext?.save()
    }
    
    /// 약물 삭제
    func deleteMedication() async {
        guard let context = modelContext else { return }
        
        // 관련 알림 취소
        let schedules = medication.schedules
        for schedule in schedules {
            await NotificationManager.shared.cancelNotification(for: schedule)
        }
        
        context.delete(medication)
        try? context.save()
    }
    
    /// 활성/비활성 토글
    func toggleActive() async {
        medication.isActive.toggle()
        
        if !medication.isActive {
            // 알림 취소
            let schedules = medication.schedules
            for schedule in schedules {
                await NotificationManager.shared.cancelNotification(for: schedule)
            }
        }
        
        try? modelContext?.save()
    }
    
    /// 스케줄 추가
    func addSchedule(_ schedule: MedicationSchedule) async {
        guard let context = modelContext else { return }
        
        schedule.medication = medication
        context.insert(schedule)
        
        do {
            try context.save()
            // 알림 설정
            try await NotificationManager.shared.scheduleNotification(for: schedule)
        } catch {
            errorMessage = "스케줄 추가에 실패했습니다."
        }
    }
    
    /// 스케줄 삭제
    func deleteSchedule(_ schedule: MedicationSchedule) async {
        guard let context = modelContext else { return }
        
        await NotificationManager.shared.cancelNotification(for: schedule)
        context.delete(schedule)
        
        try? context.save()
    }
    
    /// 데이터 새로고침
    func refresh() async {
        await loadLogs()
        calculateStatistics()
    }
    
    // MARK: - Computed Properties
    
    /// 활성 스케줄
    var activeSchedules: [MedicationSchedule] {
        medication.schedules.filter { $0.isActive } ?? []
    }
    
    /// 선택된 날짜의 로그
    var logsForSelectedDate: [MedicationLog] {
        let calendar = Calendar.current
        return logs.filter { calendar.isDate($0.scheduledTime, inSameDayAs: selectedDate) }
    }
    
    /// 날짜별 로그 그룹
    var logsByDate: [(date: Date, logs: [MedicationLog])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: logs) { log in
            calendar.startOfDay(for: log.scheduledTime)
        }
        
        return grouped
            .map { (date: $0.key, logs: $0.value.sorted { $0.scheduledTime > $1.scheduledTime }) }
            .sorted { $0.date > $1.date }
    }
    
    /// 복용 완료 로그 수
    var completedLogsCount: Int {
        logs.filter { $0.logStatus == .taken || $0.logStatus == .delayed }.count
    }
    
    /// 건너뛴 로그 수
    var skippedLogsCount: Int {
        logs.filter { $0.logStatus == .skipped }.count
    }
    
    /// 전체 로그 수
    var totalLogsCount: Int {
        logs.count
    }
    
    /// 달력 표시용 날짜별 상태
    func statusForDate(_ date: Date) -> LogStatus? {
        let calendar = Calendar.current
        let dayLogs = logs.filter { calendar.isDate($0.scheduledTime, inSameDayAs: date) }
        
        guard !dayLogs.isEmpty else { return nil }
        
        let allTaken = dayLogs.allSatisfy { $0.logStatus == .taken || $0.logStatus == .delayed }
        let allSkipped = dayLogs.allSatisfy { $0.logStatus == .skipped }
        let hasPending = dayLogs.contains { $0.logStatus == .pending }
        
        if allTaken {
            return .taken
        } else if allSkipped {
            return .skipped
        } else if hasPending {
            return .pending
        } else {
            return .delayed
        }
    }
    
    /// 날짜에 로그가 있는지 확인
    func hasLogsForDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return logs.contains { calendar.isDate($0.scheduledTime, inSameDayAs: date) }
    }
}
