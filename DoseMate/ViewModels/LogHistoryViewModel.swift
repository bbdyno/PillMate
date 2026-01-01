//
//  LogHistoryViewModel.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation
import SwiftUI
import DMateDesignSystem
import DMateResource
import SwiftData

/// 복약 기록 필터
enum LogFilter: String, CaseIterable, Identifiable {
    case all
    case taken
    case skipped
    case delayed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return DMateResourceStrings.LogFilter.all
        case .taken: return DMateResourceStrings.LogFilter.taken
        case .skipped: return DMateResourceStrings.LogFilter.skipped
        case .delayed: return DMateResourceStrings.LogFilter.delayed
        }
    }
}

/// 복약 기록 ViewModel
@MainActor
@Observable
final class LogHistoryViewModel {
    // MARK: - Properties
    
    /// 복약 기록들
    var logs: [MedicationLog] = []
    
    /// 필터링된 기록들
    var filteredLogs: [MedicationLog] = []
    
    /// 선택된 날짜
    var selectedDate: Date = Date() {
        didSet {
            Task {
                await loadLogs()
            }
        }
    }
    
    /// 표시 월 (달력용)
    var displayMonth: Date = Date()
    
    /// 선택된 기간
    var selectedPeriod: StatisticsPeriod = .month {
        didSet {
            Task {
                await loadLogs()
            }
        }
    }
    
    /// 현재 필터
    var currentFilter: LogFilter = .all {
        didSet {
            applyFilter()
        }
    }
    
    /// 로딩 상태
    var isLoading: Bool = false
    
    /// 에러 메시지
    var errorMessage: String?
    
    /// 뷰 모드
    var viewMode: ViewMode = .calendar
    
    enum ViewMode: String, CaseIterable {
        case calendar = "달력"
        case list = "목록"

        var displayName: String {
            switch self {
            case .calendar: return DMateResourceStrings.ViewMode.calendar
            case .list: return DMateResourceStrings.ViewMode.list
            }
        }
    }
    
    /// 선택된 로그 (상세용)
    var selectedLog: MedicationLog?
    
    /// 공유 시트 표시
    var showShareSheet: Bool = false
    
    /// 내보내기 데이터
    var exportData: String = ""
    
    // MARK: - Statistics
    
    /// 전체 준수율
    var overallAdherenceRate: Double = 0.0
    
    /// 연속 달성 일수
    var consecutiveDays: Int = 0
    
    /// 복용 완료 수
    var takenCount: Int = 0
    
    /// 건너뛴 수
    var skippedCount: Int = 0
    
    /// 지연 수
    var delayedCount: Int = 0
    
    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Setup
    
    func setup(with context: ModelContext) {
        self.modelContext = context
        Task {
            await loadLogs()
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
        
        // 기간에 따른 시작 날짜 계산
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
        
        let predicate = #Predicate<MedicationLog> { log in
            log.scheduledTime >= startDate && log.scheduledTime <= now
        }
        
        let descriptor = FetchDescriptor<MedicationLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.scheduledTime, order: .reverse)]
        )
        
        do {
            logs = try context.fetch(descriptor)
            applyFilter()
            calculateStatistics()
        } catch {
            errorMessage = DMateResourceStrings.Error.loadLogsFailed
        }
    }
    
    /// 특정 날짜의 기록 로드
    func loadLogsForDate(_ date: Date) -> [MedicationLog] {
        let calendar = Calendar.current
        return logs.filter { calendar.isDate($0.scheduledTime, inSameDayAs: date) }
            .sorted { $0.scheduledTime < $1.scheduledTime }
    }
    
    // MARK: - Filtering
    
    /// 필터 적용
    private func applyFilter() {
        switch currentFilter {
        case .all:
            filteredLogs = logs
        case .taken:
            filteredLogs = logs.filter { $0.logStatus == .taken }
        case .skipped:
            filteredLogs = logs.filter { $0.logStatus == .skipped }
        case .delayed:
            filteredLogs = logs.filter { $0.logStatus == .delayed }
        }
    }
    
    // MARK: - Statistics
    
    /// 통계 계산
    private func calculateStatistics() {
        let pastLogs = logs.filter { $0.scheduledTime <= Date() }
        
        guard !pastLogs.isEmpty else {
            overallAdherenceRate = 0.0
            takenCount = 0
            skippedCount = 0
            delayedCount = 0
            consecutiveDays = 0
            return
        }
        
        takenCount = pastLogs.filter { $0.logStatus == .taken }.count
        skippedCount = pastLogs.filter { $0.logStatus == .skipped }.count
        delayedCount = pastLogs.filter { $0.logStatus == .delayed }.count
        
        let completedCount = takenCount + delayedCount
        overallAdherenceRate = Double(completedCount) / Double(pastLogs.count)
        
        consecutiveDays = calculateConsecutiveDays()
    }
    
    /// 연속 일수 계산
    private func calculateConsecutiveDays() -> Int {
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: Date())
        var count = 0
        
        while true {
            let dayLogs = loadLogsForDate(currentDate)
            
            guard !dayLogs.isEmpty else { break }
            
            let allCompleted = dayLogs.allSatisfy { log in
                log.logStatus == .taken || log.logStatus == .delayed
            }
            
            if allCompleted {
                count += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
            } else {
                break
            }
        }
        
        return count
    }
    
    // MARK: - Calendar Helpers
    
    /// 날짜에 로그가 있는지 확인
    func hasLogsForDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return logs.contains { calendar.isDate($0.scheduledTime, inSameDayAs: date) }
    }
    
    /// 날짜의 상태 색상
    func colorForDate(_ date: Date) -> Color {
        let dayLogs = loadLogsForDate(date)
        
        guard !dayLogs.isEmpty else { return .clear }
        
        let pastLogs = dayLogs.filter { $0.scheduledTime <= Date() }
        
        guard !pastLogs.isEmpty else { return .gray.opacity(0.3) }
        
        let allCompleted = pastLogs.allSatisfy { log in
            log.logStatus == .taken || log.logStatus == .delayed
        }
        
        if allCompleted {
            return .green
        } else if pastLogs.contains(where: { $0.logStatus == .skipped }) {
            return .red
        } else {
            return .orange
        }
    }
    
    /// 이전 달로 이동
    func previousMonth() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: -1, to: displayMonth) {
            displayMonth = newDate
        }
    }
    
    /// 다음 달로 이동
    func nextMonth() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: 1, to: displayMonth) {
            displayMonth = newDate
        }
    }
    
    /// 오늘로 이동
    func goToToday() {
        displayMonth = Date()
        selectedDate = Date()
    }
    
    // MARK: - Export
    
    /// CSV 내보내기
    func exportToCSV() -> String {
        var csv = "\(DMateResourceStrings.CsvHeader.medicationLog)\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        for log in filteredLogs {
            let date = dateFormatter.string(from: log.scheduledTime)
            let time = timeFormatter.string(from: log.scheduledTime)
            let medicationName = log.medication?.name ?? ""
            let dosage = log.medication?.dosage ?? ""
            let status = log.logStatus.displayName
            let actualTime = log.actualTime.map { timeFormatter.string(from: $0) } ?? ""
            let notes = log.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            csv += "\(date),\(time),\(medicationName),\(dosage),\(status),\(actualTime),\(notes)\n"
        }
        
        return csv
    }
    
    /// 공유 준비
    func prepareExport() {
        exportData = exportToCSV()
        showShareSheet = true
    }
    
    // MARK: - Computed Properties
    
    /// 날짜별 그룹화된 로그
    var logsByDate: [(date: Date, logs: [MedicationLog])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredLogs) { log in
            calendar.startOfDay(for: log.scheduledTime)
        }
        
        return grouped
            .map { (date: $0.key, logs: $0.value.sorted { $0.scheduledTime < $1.scheduledTime }) }
            .sorted { $0.date > $1.date }
    }
    
    /// 선택된 날짜의 로그
    var selectedDateLogs: [MedicationLog] {
        loadLogsForDate(selectedDate)
    }
    
    /// 빈 상태 여부
    var isEmpty: Bool {
        logs.isEmpty
    }
    
    /// 필터링된 빈 상태 여부
    var isFilteredEmpty: Bool {
        filteredLogs.isEmpty && !logs.isEmpty
    }
    
    /// 현재 달의 날짜들
    var datesInMonth: [Date] {
        let calendar = Calendar.current
        return calendar.datesInMonth(for: displayMonth)
    }
    
    /// 표시 월 텍스트
    var displayMonthText: String {
        Formatters.monthYear.string(from: displayMonth)
    }
}
