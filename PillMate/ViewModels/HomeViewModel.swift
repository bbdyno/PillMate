//
//  HomeViewModel.swift
//  PillMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

/// 홈 화면 ViewModel
@MainActor
@Observable
final class HomeViewModel {
    // MARK: - Properties
    
    /// 등록된 환자 목록
    var patients: [Patient] = []
    
    /// 선택된 환자 (nil이면 "본인")
    var selectedPatient: Patient?
    
    /// 오늘의 복약 기록들
    var todayLogs: [MedicationLog] = []
    
    /// 다음 복약 기록
    var nextLog: MedicationLog?
    
    /// 오늘 복약 준수율
    var todayAdherenceRate: Double = 0.0
    
    /// 이번주 복약 준수율
    var weekAdherenceRate: Double = 0.0
    
    /// 이번달 복약 준수율
    var monthAdherenceRate: Double = 0.0
    
    /// 연속 복약 일수
    var consecutiveDays: Int = 0
    
    /// 재고 부족 약물들
    var lowStockMedications: [Medication] = []
    
    /// 오늘의 진료 예약
    var todayAppointments: [Appointment] = []
    
    /// 로딩 상태
    var isLoading: Bool = false
    
    /// 에러 메시지
    var errorMessage: String?
    
    /// 선택된 로그 (상세 보기용)
    var selectedLog: MedicationLog?
    
    /// 복용 완료 처리 중인 로그 ID
    var processingLogId: UUID?
    
    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Setup
    
    /// ModelContext 설정
    func setup(with context: ModelContext) {
        self.modelContext = context
        Task {
            await loadPatients()
            await loadData()
        }
    }
    
    // MARK: - Patient Management
    
    /// 환자 목록 로드
    func loadPatients() async {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Patient>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        patients = (try? context.fetch(descriptor)) ?? []
    }
    
    /// 환자 선택
    func selectPatient(_ patient: Patient?) {
        selectedPatient = patient
        Task {
            await loadData()
        }
    }
    
    /// 선택된 환자 이름
    var selectedPatientName: String {
        selectedPatient?.name ?? "본인"
    }
    
    /// 선택된 환자 색상
    var selectedPatientColor: Color {
        selectedPatient?.color ?? .blue
    }
    
    // MARK: - Data Loading
    
    /// 모든 데이터 로드
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        await generateTodayLogsIfNeeded()
        await loadTodayLogs()
        await loadStatistics()
        await loadLowStockMedications()
        await loadTodayAppointments()
        findNextLog()
    }
    
    /// 오늘의 복약 기록 생성 (필요시)
    private func generateTodayLogsIfNeeded() async {
        guard let context = modelContext else { return }
        
        // 활성 스케줄 가져오기 (선택된 환자의 약물만)
        let scheduleDescriptor = FetchDescriptor<MedicationSchedule>(
            predicate: #Predicate { $0.isActive }
        )
        
        guard let schedules = try? context.fetch(scheduleDescriptor) else { return }
        
        // 선택된 환자의 스케줄만 필터링
        let filteredSchedules = schedules.filter { schedule in
            guard let medication = schedule.medication else { return false }
            if let selected = selectedPatient {
                return medication.patient?.id == selected.id
            } else {
                return medication.patient == nil
            }
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // 오늘의 기존 로그 확인
        let logDescriptor = FetchDescriptor<MedicationLog>(
            predicate: #Predicate { log in
                log.scheduledTime >= today && log.scheduledTime < tomorrow
            }
        )
        
        let existingLogs = (try? context.fetch(logDescriptor)) ?? []
        
        for schedule in filteredSchedules {
            guard let medication = schedule.medication,
                  let times = schedule.scheduledTimes else { continue }
            
            for time in times {
                // 이미 해당 시간에 로그가 있는지 확인
                let exists = existingLogs.contains { log in
                    log.schedule?.id == schedule.id &&
                    calendar.isDate(log.scheduledTime, equalTo: time, toGranularity: .minute)
                }
                
                if !exists {
                    let log = MedicationLog(scheduledTime: time)
                    log.medication = medication
                    log.schedule = schedule
                    context.insert(log)
                }
            }
        }
        
        try? context.save()
    }
    
    /// 오늘의 복약 기록 로드
    private func loadTodayLogs() async {
        guard let context = modelContext else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let descriptor = FetchDescriptor<MedicationLog>(
            predicate: #Predicate { log in
                log.scheduledTime >= today && log.scheduledTime < tomorrow
            },
            sortBy: [SortDescriptor(\.scheduledTime)]
        )
        
        do {
            let allLogs = try context.fetch(descriptor)
            
            // 선택된 환자의 로그만 필터링
            todayLogs = allLogs.filter { log in
                guard let medication = log.medication else { return false }
                if let selected = selectedPatient {
                    return medication.patient?.id == selected.id
                } else {
                    return medication.patient == nil
                }
            }
        } catch {
            errorMessage = "복약 기록을 불러오는데 실패했습니다."
        }
    }
    
    /// 통계 로드
    private func loadStatistics() async {
        guard let context = modelContext else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // 오늘 준수율
        let todayStart = calendar.startOfDay(for: now)
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart)!
        
        todayAdherenceRate = calculateAdherenceRate(
            context: context,
            from: todayStart,
            to: todayEnd
        )
        
        // 이번주 준수율
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        
        weekAdherenceRate = calculateAdherenceRate(
            context: context,
            from: weekStart,
            to: min(weekEnd, now)
        )
        
        // 이번달 준수율
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        
        monthAdherenceRate = calculateAdherenceRate(
            context: context,
            from: monthStart,
            to: min(monthEnd, now)
        )
        
        // 연속 일수
        consecutiveDays = calculateConsecutiveDays(context: context)
    }
    
    /// 준수율 계산
    private func calculateAdherenceRate(context: ModelContext, from startDate: Date, to endDate: Date) -> Double {
        let predicate = #Predicate<MedicationLog> { log in
            log.scheduledTime >= startDate && log.scheduledTime < endDate
        }
        
        let descriptor = FetchDescriptor<MedicationLog>(predicate: predicate)
        
        guard let allLogs = try? context.fetch(descriptor), !allLogs.isEmpty else {
            return 0.0
        }
        
        // 선택된 환자의 로그만 필터링
        let logs = allLogs.filter { log in
            guard let medication = log.medication else { return false }
            if let selected = selectedPatient {
                return medication.patient?.id == selected.id
            } else {
                return medication.patient == nil
            }
        }
        
        guard !logs.isEmpty else { return 0.0 }
        
        // 대기 중인 미래 로그는 제외
        let pastLogs = logs.filter { $0.scheduledTime <= Date() }
        guard !pastLogs.isEmpty else { return 1.0 }
        
        let completedLogs = pastLogs.filter { log in
            log.logStatus == .taken || log.logStatus == .delayed
        }
        
        return Double(completedLogs.count) / Double(pastLogs.count)
    }
    
    /// 연속 일수 계산
    private func calculateConsecutiveDays(context: ModelContext) -> Int {
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: Date())
        var count = 0
        
        while true {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            
            let predicate = #Predicate<MedicationLog> { log in
                log.scheduledTime >= currentDate && log.scheduledTime < nextDay
            }
            
            let descriptor = FetchDescriptor<MedicationLog>(predicate: predicate)
            
            guard let allLogs = try? context.fetch(descriptor), !allLogs.isEmpty else {
                break
            }
            
            // 선택된 환자의 로그만 필터링
            let logs = allLogs.filter { log in
                guard let medication = log.medication else { return false }
                if let selected = selectedPatient {
                    return medication.patient?.id == selected.id
                } else {
                    return medication.patient == nil
                }
            }
            
            guard !logs.isEmpty else { break }
            
            let allCompleted = logs.allSatisfy { log in
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
    
    /// 재고 부족 약물 로드
    private func loadLowStockMedications() async {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Medication>(
            predicate: #Predicate { $0.isActive }
        )
        
        guard let allMedications = try? context.fetch(descriptor) else { return }
        
        // 선택된 환자의 약물만 필터링
        let medications = allMedications.filter { medication in
            if let selected = selectedPatient {
                return medication.patient?.id == selected.id
            } else {
                return medication.patient == nil
            }
        }
        
        lowStockMedications = medications.filter { $0.isLowStock }
    }
    
    /// 오늘의 진료 예약 로드
    private func loadTodayAppointments() async {
        guard let context = modelContext else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let descriptor = FetchDescriptor<Appointment>(
            predicate: #Predicate { appointment in
                appointment.appointmentDate >= today &&
                appointment.appointmentDate < tomorrow &&
                !appointment.isCompleted
            },
            sortBy: [SortDescriptor(\.appointmentDate)]
        )
        
        let allAppointments = (try? context.fetch(descriptor)) ?? []
        
        // 선택된 환자의 예약만 필터링
        todayAppointments = allAppointments.filter { appointment in
            if let selected = selectedPatient {
                return appointment.patient?.id == selected.id
            } else {
                return appointment.patient == nil
            }
        }
    }
    
    /// 다음 복약 찾기
    private func findNextLog() {
        let now = Date()
        nextLog = todayLogs
            .filter { $0.logStatus == .pending && $0.scheduledTime > now }
            .min { $0.scheduledTime < $1.scheduledTime }
    }
    
    // MARK: - Actions
    
    /// 복용 완료 처리
    func markAsTaken(_ log: MedicationLog) async {
        processingLogId = log.id
        
        defer { processingLogId = nil }
        
        log.markAsTaken()
        
        // 재고 감소는 markAsTaken 내부에서 처리됨
        
        try? modelContext?.save()
        
        await loadData()
        
        // 햅틱 피드백
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// 건너뛰기 처리
    func markAsSkipped(_ log: MedicationLog, reason: String? = nil) async {
        processingLogId = log.id
        
        defer { processingLogId = nil }
        
        log.markAsSkipped(reason: reason)
        
        try? modelContext?.save()
        
        await loadData()
    }
    
    /// 스누즈 처리
    func snooze(_ log: MedicationLog, minutes: Int) async {
        processingLogId = log.id
        
        defer { processingLogId = nil }
        
        log.snooze(minutes: minutes)
        
        // 알림 재설정
        do {
            try await NotificationManager.shared.snoozeNotification(for: log, minutes: minutes)
        } catch {
            errorMessage = "알림 설정에 실패했습니다."
        }
        
        try? modelContext?.save()
        
        await loadData()
    }
    
    /// 데이터 새로고침
    func refresh() async {
        await loadData()
    }
    
    // MARK: - Computed Properties
    
    /// 대기 중인 복약 수
    var pendingLogsCount: Int {
        todayLogs.filter { $0.logStatus == .pending && $0.scheduledTime <= Date() }.count
    }
    
    /// 완료된 복약 수
    var completedLogsCount: Int {
        todayLogs.filter { $0.logStatus == .taken || $0.logStatus == .delayed }.count
    }
    
    /// 총 복약 수
    var totalLogsCount: Int {
        todayLogs.count
    }
    
    /// 다음 복약까지 남은 시간 (초)
    var secondsUntilNextDose: TimeInterval? {
        nextLog?.scheduledTime.timeIntervalSinceNow
    }
    
    /// 다음 복약까지 남은 시간 텍스트
    var timeUntilNextDoseText: String? {
        guard let seconds = secondsUntilNextDose, seconds > 0 else { return nil }
        return formatTimeRemaining(seconds)
    }
    
    /// 복약 완료 여부
    var isAllCompleted: Bool {
        let pastLogs = todayLogs.filter { $0.scheduledTime <= Date() }
        guard !pastLogs.isEmpty else { return true }
        return pastLogs.allSatisfy { $0.logStatus == .taken || $0.logStatus == .delayed }
    }
    
    /// 시간대별 그룹화된 로그
    var groupedLogs: [(title: String, logs: [MedicationLog])] {
        let calendar = Calendar.current
        
        var morning: [MedicationLog] = []
        var afternoon: [MedicationLog] = []
        var evening: [MedicationLog] = []
        var night: [MedicationLog] = []
        
        for log in todayLogs {
            let hour = calendar.component(.hour, from: log.scheduledTime)
            
            switch hour {
            case 5..<12:
                morning.append(log)
            case 12..<17:
                afternoon.append(log)
            case 17..<21:
                evening.append(log)
            default:
                night.append(log)
            }
        }
        
        var groups: [(title: String, logs: [MedicationLog])] = []
        
        if !morning.isEmpty {
            groups.append(("아침", morning))
        }
        if !afternoon.isEmpty {
            groups.append(("점심", afternoon))
        }
        if !evening.isEmpty {
            groups.append(("저녁", evening))
        }
        if !night.isEmpty {
            groups.append(("밤", night))
        }
        
        return groups
    }
}
