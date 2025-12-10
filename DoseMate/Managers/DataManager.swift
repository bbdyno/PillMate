//
//  DataManager.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

/// SwiftData 작업을 관리하는 싱글톤 매니저
@MainActor
final class DataManager: ObservableObject {
    // MARK: - Singleton
    
    static let shared = DataManager()
    
    // MARK: - Properties
    
    /// SwiftData 컨테이너
    let container: ModelContainer
    
    /// 메인 컨텍스트
    var context: ModelContext {
        container.mainContext
    }
    
    // MARK: - Initialization
    
    private init() {
        do {
            // App Group을 사용하여 위젯과 데이터 공유
            let appGroupIdentifier = "group.com.bbdyno.app.doseMate"
            guard let groupContainerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupIdentifier
            ) else {
                fatalError("App Group 컨테이너를 찾을 수 없습니다. Entitlements를 확인하세요.")
            }

            // MigrationPlan과 함께 컨테이너 생성
            let schema = Schema(versionedSchema: DoseMateSchemaV3.self)
            let storeURL = groupContainerURL.appendingPathComponent("DoseMate.sqlite")
            let config = ModelConfiguration(
                url: storeURL,
                cloudKitDatabase: .automatic
            )

            container = try ModelContainer(
                for: schema,
                migrationPlan: DoseMateSchemaHistory.self,
                configurations: [config]
            )

            print("DataManager SwiftData 컨테이너 초기화 완료: \(groupContainerURL.path)")
        } catch let error as NSError {
            print("DataManager ModelContainer 생성 실패: \(error)")
            print("- 오류 도메인: \(error.domain)")
            print("- 오류 코드: \(error.code)")
            print("- 상세 정보: \(error.userInfo)")
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // MARK: - CRUD Operations - Medication
    
    /// 약물 추가
    func addMedication(_ medication: Medication) {
        context.insert(medication)
        save()
    }
    
    /// 약물 삭제
    func deleteMedication(_ medication: Medication) {
        context.delete(medication)
        save()
    }
    
    /// 모든 약물 가져오기
    func fetchAllMedications() -> [Medication] {
        let descriptor = FetchDescriptor<Medication>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch medications: \(error)")
            return []
        }
    }
    
    /// 활성 약물만 가져오기
    func fetchActiveMedications() -> [Medication] {
        let predicate = #Predicate<Medication> { $0.isActive }
        let descriptor = FetchDescriptor<Medication>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch active medications: \(error)")
            return []
        }
    }
    
    /// 재고 부족 약물 가져오기
    func fetchLowStockMedications() -> [Medication] {
        let descriptor = FetchDescriptor<Medication>(
            sortBy: [SortDescriptor(\.stockCount)]
        )
        
        do {
            let medications = try context.fetch(descriptor)
            return medications.filter { $0.isLowStock }
        } catch {
            print("Failed to fetch low stock medications: \(error)")
            return []
        }
    }
    
    /// ID로 약물 찾기
    func findMedication(by id: UUID) -> Medication? {
        let predicate = #Predicate<Medication> { $0.id == id }
        let descriptor = FetchDescriptor<Medication>(predicate: predicate)
        
        do {
            return try context.fetch(descriptor).first
        } catch {
            print("Failed to find medication: \(error)")
            return nil
        }
    }
    
    /// 약물 검색
    func searchMedications(query: String) -> [Medication] {
        guard !query.isEmpty else { return fetchAllMedications() }
        
        let predicate = #Predicate<Medication> { medication in
            medication.name.localizedStandardContains(query) ||
            medication.purpose.localizedStandardContains(query)
        }
        
        let descriptor = FetchDescriptor<Medication>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to search medications: \(error)")
            return []
        }
    }
    
    // MARK: - CRUD Operations - Schedule
    
    /// 스케줄 추가
    func addSchedule(_ schedule: MedicationSchedule, to medication: Medication) {
        schedule.medication = medication
        context.insert(schedule)
        save()
    }
    
    /// 스케줄 삭제
    func deleteSchedule(_ schedule: MedicationSchedule) {
        context.delete(schedule)
        save()
    }
    
    /// 활성 스케줄 가져오기
    func fetchActiveSchedules() -> [MedicationSchedule] {
        let predicate = #Predicate<MedicationSchedule> { $0.isActive }
        let descriptor = FetchDescriptor<MedicationSchedule>(predicate: predicate)
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch active schedules: \(error)")
            return []
        }
    }
    
    // MARK: - CRUD Operations - Log
    
    /// 복약 기록 추가
    func addLog(_ log: MedicationLog, medication: Medication, schedule: MedicationSchedule?) {
        log.medication = medication
        log.schedule = schedule
        context.insert(log)
        save()
    }
    
    /// 오늘의 복약 기록 가져오기
    func fetchTodayLogs() -> [MedicationLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = #Predicate<MedicationLog> { log in
            log.scheduledTime >= today && log.scheduledTime < tomorrow
        }
        
        let descriptor = FetchDescriptor<MedicationLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.scheduledTime)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch today's logs: \(error)")
            return []
        }
    }
    
    /// 특정 날짜의 복약 기록 가져오기
    func fetchLogs(for date: Date) -> [MedicationLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<MedicationLog> { log in
            log.scheduledTime >= startOfDay && log.scheduledTime < endOfDay
        }
        
        let descriptor = FetchDescriptor<MedicationLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.scheduledTime)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch logs: \(error)")
            return []
        }
    }
    
    /// 기간별 복약 기록 가져오기
    func fetchLogs(from startDate: Date, to endDate: Date) -> [MedicationLog] {
        let predicate = #Predicate<MedicationLog> { log in
            log.scheduledTime >= startDate && log.scheduledTime <= endDate
        }
        
        let descriptor = FetchDescriptor<MedicationLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.scheduledTime)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch logs: \(error)")
            return []
        }
    }
    
    /// ID로 로그 찾기
    func findLog(by id: UUID) -> MedicationLog? {
        let predicate = #Predicate<MedicationLog> { $0.id == id }
        let descriptor = FetchDescriptor<MedicationLog>(predicate: predicate)
        
        do {
            return try context.fetch(descriptor).first
        } catch {
            print("Failed to find log: \(error)")
            return nil
        }
    }
    
    // MARK: - CRUD Operations - Health Metric
    
    /// 건강 지표 추가
    func addHealthMetric(_ metric: HealthMetric) {
        context.insert(metric)
        save()
    }
    
    /// 건강 지표 삭제
    func deleteHealthMetric(_ metric: HealthMetric) {
        context.delete(metric)
        save()
    }
    
    /// 특정 타입의 건강 지표 가져오기
    func fetchHealthMetrics(type: MetricType, limit: Int? = nil) -> [HealthMetric] {
        let typeString = type.rawValue
        let predicate = #Predicate<HealthMetric> { $0.type == typeString }
        
        var descriptor = FetchDescriptor<HealthMetric>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch health metrics: \(error)")
            return []
        }
    }
    
    /// 특정 기간의 건강 지표 가져오기
    func fetchHealthMetrics(type: MetricType, from startDate: Date, to endDate: Date) -> [HealthMetric] {
        let typeString = type.rawValue
        let predicate = #Predicate<HealthMetric> { metric in
            metric.type == typeString &&
            metric.recordedAt >= startDate &&
            metric.recordedAt <= endDate
        }
        
        let descriptor = FetchDescriptor<HealthMetric>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.recordedAt)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch health metrics: \(error)")
            return []
        }
    }
    
    /// 최신 건강 지표 가져오기
    func fetchLatestHealthMetric(type: MetricType) -> HealthMetric? {
        return fetchHealthMetrics(type: type, limit: 1).first
    }
    
    // MARK: - CRUD Operations - Appointment
    
    /// 진료 예약 추가
    func addAppointment(_ appointment: Appointment) {
        context.insert(appointment)
        save()
    }
    
    /// 진료 예약 삭제
    func deleteAppointment(_ appointment: Appointment) {
        context.delete(appointment)
        save()
    }
    
    /// 예정된 진료 예약 가져오기
    func fetchUpcomingAppointments() -> [Appointment] {
        let now = Date()
        let predicate = #Predicate<Appointment> { appointment in
            appointment.appointmentDate > now && !appointment.isCompleted
        }
        
        let descriptor = FetchDescriptor<Appointment>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.appointmentDate)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch appointments: \(error)")
            return []
        }
    }
    
    /// 모든 진료 예약 가져오기
    func fetchAllAppointments() -> [Appointment] {
        let descriptor = FetchDescriptor<Appointment>(
            sortBy: [SortDescriptor(\.appointmentDate, order: .reverse)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch appointments: \(error)")
            return []
        }
    }
    
    // MARK: - Statistics
    
    /// 오늘 복약 준수율 계산
    func calculateTodayAdherenceRate() -> Double {
        let logs = fetchTodayLogs()
        guard !logs.isEmpty else { return 0.0 }
        
        let completedLogs = logs.filter { $0.logStatus == .taken || $0.logStatus == .delayed }
        return Double(completedLogs.count) / Double(logs.count)
    }
    
    /// 기간별 복약 준수율 계산
    func calculateAdherenceRate(from startDate: Date, to endDate: Date) -> Double {
        let logs = fetchLogs(from: startDate, to: endDate)
        guard !logs.isEmpty else { return 0.0 }
        
        let completedLogs = logs.filter { $0.logStatus == .taken || $0.logStatus == .delayed }
        return Double(completedLogs.count) / Double(logs.count)
    }
    
    /// 연속 복약 일수 계산
    func calculateConsecutiveDays() -> Int {
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: Date())
        var consecutiveCount = 0
        
        while true {
            let logs = fetchLogs(for: currentDate)
            
            // 로그가 없으면 종료
            guard !logs.isEmpty else { break }
            
            // 모든 로그가 완료되었는지 확인
            let allCompleted = logs.allSatisfy { $0.logStatus == .taken || $0.logStatus == .delayed }
            
            if allCompleted {
                consecutiveCount += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
            } else {
                break
            }
        }
        
        return consecutiveCount
    }
    
    // MARK: - Daily Log Generation
    
    /// 오늘의 복약 기록 생성
    func generateTodayLogs() {
        let schedules = fetchActiveSchedules()
        let existingLogs = fetchTodayLogs()
        
        for schedule in schedules {
            guard let medication = schedule.medication,
                  let times = schedule.scheduledTimes else { continue }
            
            for time in times {
                // 이미 해당 시간에 로그가 있는지 확인
                let exists = existingLogs.contains { log in
                    log.schedule?.id == schedule.id &&
                    Calendar.current.isDate(log.scheduledTime, equalTo: time, toGranularity: .minute)
                }
                
                if !exists {
                    let log = MedicationLog(scheduledTime: time)
                    addLog(log, medication: medication, schedule: schedule)
                }
            }
        }
    }
    
    // MARK: - Save

    /// 변경사항 저장
    func save() {
        do {
            try context.save()

            // 위젯 데이터 업데이트
            Task { @MainActor in
                WidgetDataUpdater.shared.updateWidgetData()
            }
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    // MARK: - Data Export
    
    /// 복약 기록 CSV 내보내기
    func exportLogsToCSV(from startDate: Date, to endDate: Date) -> String {
        let logs = fetchLogs(from: startDate, to: endDate)
        var csv = "날짜,시간,약물명,용량,상태,실제복용시간,메모\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        for log in logs {
            let date = dateFormatter.string(from: log.scheduledTime)
            let time = timeFormatter.string(from: log.scheduledTime)
            let medicationName = log.medication?.name ?? ""
            let dosage = log.medication?.dosage ?? ""
            let status = log.logStatus.displayName
            let actualTime = log.actualTime.map { timeFormatter.string(from: $0) } ?? ""
            let notes = log.notes ?? ""
            
            csv += "\(date),\(time),\(medicationName),\(dosage),\(status),\(actualTime),\(notes)\n"
        }
        
        return csv
    }
    
    // MARK: - Sample Data
    
    /// 샘플 데이터 생성 (개발용)
    func createSampleData() {
        // 약물 추가
        for medication in Medication.sampleData {
            addMedication(medication)
            
            // 스케줄 추가
            let schedule = MedicationSchedule.preview
            addSchedule(schedule, to: medication)
        }
        
        // 진료 예약 추가
        for appointment in Appointment.sampleData {
            addAppointment(appointment)
        }
        
        // 오늘의 로그 생성
        generateTodayLogs()
    }
    
    /// 모든 데이터 삭제 (개발용)
    func deleteAllData() {
        do {
            try context.delete(model: MedicationLog.self)
            try context.delete(model: MedicationSchedule.self)
            try context.delete(model: Medication.self)
            try context.delete(model: HealthMetric.self)
            try context.delete(model: Appointment.self)
            save()
        } catch {
            print("Failed to delete all data: \(error)")
        }
    }
}
