//
//  DataExportManager.swift
//  DoseMate
//
//  Created by bbdyno on 12/01/25.
//

import Foundation
import SwiftData
import UIKit

// MARK: - Export Data Structure

/// 내보내기 파일 최상위 구조
struct DoseMateExportData: Codable {
    let exportInfo: ExportInfo
    let data: ExportedData
}

/// 내보내기 정보
struct ExportInfo: Codable {
    let exportDate: Date
    let appVersion: String
    let deviceName: String
    let dataVersion: Int // 데이터 구조 버전 (마이그레이션용)
    
    static var current: ExportInfo {
        ExportInfo(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            deviceName: UIDevice.current.name,
            dataVersion: 1
        )
    }
}

/// 내보내기 데이터 컨테이너
struct ExportedData: Codable {
    let patients: [PatientDTO]
    let medications: [MedicationDTO]
    let schedules: [MedicationScheduleDTO]
    let logs: [MedicationLogDTO]
    let healthMetrics: [HealthMetricDTO]
    let appointments: [AppointmentDTO]
}

// MARK: - Data Transfer Objects (DTOs)

/// 환자 DTO
struct PatientDTO: Codable, Identifiable {
    let id: UUID
    let name: String
    let relationship: String
    let birthDate: Date?
    let profileColor: String
    let notes: String?
    let isActive: Bool
    let createdAt: Date
    
    init(from patient: Patient) {
        self.id = patient.id
        self.name = patient.name
        self.relationship = patient.relationship
        self.birthDate = patient.birthDate
        self.profileColor = patient.profileColor
        self.notes = patient.notes
        self.isActive = patient.isActive
        self.createdAt = patient.createdAt
    }
    
    func toModel() -> Patient {
        let patient = Patient(
            name: name,
            relationship: PatientRelationship(rawValue: relationship) ?? .other,
            birthDate: birthDate,
            profileColor: PatientColor(rawValue: profileColor) ?? .blue,
            notes: notes,
            isActive: isActive
        )
        return patient
    }
}

/// 약물 DTO
struct MedicationDTO: Codable, Identifiable {
    let id: UUID
    let name: String
    let dosage: String
    let strength: String
    let form: String
    let color: String
    let purpose: String
    let prescribingDoctor: String
    let sideEffects: String
    let precautions: String
    let stockCount: Int
    let lowStockThreshold: Int
    let createdAt: Date
    let isActive: Bool
    let notes: String?
    let patientId: UUID? // 환자 연결용
    
    init(from medication: Medication) {
        self.id = medication.id
        self.name = medication.name
        self.dosage = medication.dosage
        self.strength = medication.strength
        self.form = medication.form
        self.color = medication.color
        self.purpose = medication.purpose
        self.prescribingDoctor = medication.prescribingDoctor
        self.sideEffects = medication.sideEffects
        self.precautions = medication.precautions
        self.stockCount = medication.stockCount
        self.lowStockThreshold = medication.lowStockThreshold
        self.createdAt = medication.createdAt
        self.isActive = medication.isActive
        self.notes = medication.notes
        self.patientId = medication.patient?.id
    }
    
    func toModel() -> Medication {
        let medication = Medication(
            name: name,
            dosage: dosage,
            strength: strength,
            form: MedicationForm(rawValue: form) ?? .tablet,
            color: MedicationColor(rawValue: color) ?? .white,
            purpose: purpose,
            prescribingDoctor: prescribingDoctor,
            sideEffects: sideEffects,
            precautions: precautions,
            stockCount: stockCount,
            lowStockThreshold: lowStockThreshold,
            isActive: isActive,
            notes: notes
        )
        return medication
    }
}

/// 스케줄 DTO
struct MedicationScheduleDTO: Codable, Identifiable {
    let id: UUID
    let scheduleType: String
    let frequency: String
    let times: [Date]
    let specificDays: [Int]?
    let mealRelation: String
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
    let isTapering: Bool
    let taperingPlan: String?
    let customFrequency: String?
    let notificationEnabled: Bool
    let reminderMinutesBefore: Int
    let notes: String?
    let medicationId: UUID
    
    init(from schedule: MedicationSchedule) {
        self.id = schedule.id
        self.scheduleType = schedule.scheduleType
        self.frequency = schedule.frequency
        self.times = schedule.times
        self.specificDays = schedule.specificDays
        self.mealRelation = schedule.mealRelation
        self.startDate = schedule.startDate
        self.endDate = schedule.endDate
        self.isActive = schedule.isActive
        self.isTapering = schedule.isTapering
        self.taperingPlan = schedule.taperingPlan
        self.customFrequency = schedule.customFrequency
        self.notificationEnabled = schedule.notificationEnabled
        self.reminderMinutesBefore = schedule.reminderMinutesBefore
        self.notes = schedule.notes
        self.medicationId = schedule.medication?.id ?? UUID()
    }
    
    func toModel() -> MedicationSchedule {
        let schedule = MedicationSchedule(
            scheduleType: ScheduleType(rawValue: scheduleType) ?? .daily,
            frequency: Frequency(rawValue: frequency) ?? .onceDaily,
            times: times,
            specificDays: specificDays,
            startDate: startDate,
            endDate: endDate,
            isTapering: isTapering,
            taperingPlan: taperingPlan,
            customFrequency: customFrequency,
            mealRelation: MealRelation(rawValue: mealRelation) ?? .anytime,
            isActive: isActive,
            notificationEnabled: notificationEnabled,
            reminderMinutesBefore: reminderMinutesBefore,
            notes: notes
        )
        return schedule
    }
}

/// 복약 기록 DTO
struct MedicationLogDTO: Codable, Identifiable {
    let id: UUID
    let scheduledTime: Date
    let actualTime: Date?
    let status: String
    let notes: String?
    let snoozeCount: Int
    let lastSnoozeTime: Date?
    let syncedToHealthKit: Bool
    let createdAt: Date
    let medicationId: UUID
    
    init(from log: MedicationLog) {
        self.id = log.id
        self.scheduledTime = log.scheduledTime
        self.actualTime = log.actualTime
        self.status = log.status
        self.notes = log.notes
        self.snoozeCount = log.snoozeCount
        self.lastSnoozeTime = log.lastSnoozeTime
        self.syncedToHealthKit = log.syncedToHealthKit
        self.createdAt = log.createdAt
        self.medicationId = log.medication?.id ?? UUID()
    }
    
    func toModel() -> MedicationLog {
        let log = MedicationLog(
            scheduledTime: scheduledTime,
            actualTime: actualTime,
            status: LogStatus(rawValue: status) ?? .pending,
            notes: notes,
            snoozeCount: snoozeCount,
            lastSnoozeTime: lastSnoozeTime,
            syncedToHealthKit: syncedToHealthKit
        )
        return log
    }
}

/// 건강 지표 DTO
struct HealthMetricDTO: Codable, Identifiable {
    let id: UUID
    let type: String
    let value: Double
    let systolicValue: Double?
    let diastolicValue: Double?
    let unit: String
    let recordedAt: Date
    let notes: String?
    let source: String
    
    init(from metric: HealthMetric) {
        self.id = metric.id
        self.type = metric.type
        self.value = metric.value
        self.systolicValue = metric.systolicValue
        self.diastolicValue = metric.diastolicValue
        self.unit = metric.unit
        self.recordedAt = metric.recordedAt
        self.notes = metric.notes
        self.source = metric.source
    }
    
    func toModel() -> HealthMetric {
        let metric = HealthMetric(
            type: MetricType(rawValue: type) ?? .weight,
            value: value,
            systolicValue: systolicValue,
            diastolicValue: diastolicValue,
            unit: unit,
            recordedAt: recordedAt,
            notes: notes,
            source: DataSource(rawValue: source) ?? .manual
        )
        return metric
    }
}

/// 진료 예약 DTO
struct AppointmentDTO: Codable, Identifiable {
    let id: UUID
    let doctorName: String
    let specialty: String?
    let appointmentDate: Date
    let location: String?
    let notes: String?
    let notificationEnabled: Bool
    let notificationMinutesBefore: Int
    let isCompleted: Bool
    let createdAt: Date
    let patientId: UUID?
    
    init(from appointment: Appointment) {
        self.id = appointment.id
        self.doctorName = appointment.doctorName
        self.specialty = appointment.specialty
        self.appointmentDate = appointment.appointmentDate
        self.location = appointment.location
        self.notes = appointment.notes
        self.notificationEnabled = appointment.notificationEnabled
        self.notificationMinutesBefore = appointment.notificationMinutesBefore
        self.isCompleted = appointment.isCompleted
        self.createdAt = appointment.createdAt
        self.patientId = appointment.patient?.id
    }
    
    func toModel() -> Appointment {
        let appointment = Appointment(
            doctorName: doctorName,
            specialty: specialty,
            appointmentDate: appointmentDate,
            location: location,
            notes: notes,
            notificationEnabled: notificationEnabled,
            notificationMinutesBefore: notificationMinutesBefore,
            isCompleted: isCompleted
        )
        return appointment
    }
}

// MARK: - Data Export Manager

/// 데이터 내보내기/가져오기 관리자
@MainActor
final class DataExportManager {
    
    // MARK: - Singleton
    
    static let shared = DataExportManager()
    private init() {}
    
    // MARK: - Export
    
    /// 모든 데이터를 JSON으로 내보내기
    func exportAllData(context: ModelContext) async throws -> Data {
        // 모든 데이터 fetch
        let patients = try context.fetch(FetchDescriptor<Patient>())
        let medications = try context.fetch(FetchDescriptor<Medication>())
        let schedules = try context.fetch(FetchDescriptor<MedicationSchedule>())
        let logs = try context.fetch(FetchDescriptor<MedicationLog>())
        let healthMetrics = try context.fetch(FetchDescriptor<HealthMetric>())
        let appointments = try context.fetch(FetchDescriptor<Appointment>())
        
        // DTO로 변환
        let exportedData = ExportedData(
            patients: patients.map { PatientDTO(from: $0) },
            medications: medications.map { MedicationDTO(from: $0) },
            schedules: schedules.map { MedicationScheduleDTO(from: $0) },
            logs: logs.map { MedicationLogDTO(from: $0) },
            healthMetrics: healthMetrics.map { HealthMetricDTO(from: $0) },
            appointments: appointments.map { AppointmentDTO(from: $0) },
        )
        
        let exportData = DoseMateExportData(
            exportInfo: .current,
            data: exportedData
        )
        
        // JSON으로 인코딩
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(exportData)
    }
    
    /// 내보내기 파일 URL 생성
    func createExportFile(data: Data) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        
        let fileName = "DoseMate_Backup_\(dateString).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try data.write(to: tempURL)
        return tempURL
    }
    
    // MARK: - Import
    
    /// JSON 파일에서 데이터 가져오기
    func importData(from url: URL, context: ModelContext, mergeStrategy: ImportMergeStrategy = .replace) async throws -> ImportResult {
        // 파일 읽기
        let data = try Data(contentsOf: url)
        
        // JSON 디코딩
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importedData = try decoder.decode(DoseMateExportData.self, from: data)
        
        // 버전 확인
        guard importedData.exportInfo.dataVersion <= 1 else {
            throw DataExportError.unsupportedVersion(importedData.exportInfo.dataVersion)
        }
        
        // 기존 데이터 처리
        if mergeStrategy == .replace {
            try await deleteAllData(context: context)
        }
        
        var result = ImportResult()
        
        // ID 매핑 (기존 ID -> 새 모델)
        var patientIdMap: [UUID: Patient] = [:]
        var medicationIdMap: [UUID: Medication] = [:]
        
        // 1. 환자 가져오기
        for dto in importedData.data.patients {
            let patient = dto.toModel()
            context.insert(patient)
            patientIdMap[dto.id] = patient
            result.patientsImported += 1
        }
        
        // 2. 약물 가져오기
        for dto in importedData.data.medications {
            let medication = dto.toModel()
            
            // 환자 연결
            if let patientId = dto.patientId,
               let patient = patientIdMap[patientId] {
                medication.patient = patient
            }
            
            context.insert(medication)
            medicationIdMap[dto.id] = medication
            result.medicationsImported += 1
        }
        
        // 3. 스케줄 가져오기
        for dto in importedData.data.schedules {
            let schedule = dto.toModel()
            
            // 약물 연결
            if let medication = medicationIdMap[dto.medicationId] {
                schedule.medication = medication
                medication.schedules.append(schedule)
            }
            
            context.insert(schedule)
            result.schedulesImported += 1
        }
        
        // 4. 복약 기록 가져오기
        for dto in importedData.data.logs {
            let log = dto.toModel()
            
            // 약물 연결
            if let medication = medicationIdMap[dto.medicationId] {
                log.medication = medication
                medication.logs.append(log)
            }
            
            context.insert(log)
            result.logsImported += 1
        }
        
        // 5. 건강 지표 가져오기
        for dto in importedData.data.healthMetrics {
            let metric = dto.toModel()
            context.insert(metric)
            result.healthMetricsImported += 1
        }
        
        // 6. 진료 예약 가져오기
        for dto in importedData.data.appointments {
            let appointment = dto.toModel()
            
            // 환자 연결
            if let patientId = dto.patientId,
               let patient = patientIdMap[patientId] {
                appointment.patient = patient
            }
            
            context.insert(appointment)
            result.appointmentsImported += 1
        }
        
        // 저장
        try context.save()
        
        return result
    }
    
    /// 모든 데이터 삭제
    private func deleteAllData(context: ModelContext) async throws {
        // 순서 중요: 관계가 있는 것부터 삭제
        try context.delete(model: MedicationLog.self)
        try context.delete(model: MedicationSchedule.self)
        try context.delete(model: Medication.self)
        try context.delete(model: HealthMetric.self)
        try context.delete(model: Appointment.self)
        try context.delete(model: Patient.self)
        
        try context.save()
    }
    
    // MARK: - Validation
    
    /// 가져오기 파일 유효성 검사
    func validateImportFile(at url: URL) throws -> ImportValidationResult {
        let data = try Data(contentsOf: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importedData = try decoder.decode(DoseMateExportData.self, from: data)
        
        return ImportValidationResult(
            isValid: true,
            exportDate: importedData.exportInfo.exportDate,
            appVersion: importedData.exportInfo.appVersion,
            deviceName: importedData.exportInfo.deviceName,
            patientCount: importedData.data.patients.count,
            medicationCount: importedData.data.medications.count,
            scheduleCount: importedData.data.schedules.count,
            logCount: importedData.data.logs.count,
            healthMetricCount: importedData.data.healthMetrics.count,
            appointmentCount: importedData.data.appointments.count
        )
    }
}

// MARK: - Supporting Types

/// 가져오기 병합 전략
enum ImportMergeStrategy {
    case replace  // 기존 데이터 삭제 후 가져오기
    case merge    // 기존 데이터와 병합 (중복 시 새 데이터 우선)
}

/// 가져오기 결과
struct ImportResult {
    var patientsImported: Int = 0
    var medicationsImported: Int = 0
    var schedulesImported: Int = 0
    var logsImported: Int = 0
    var healthMetricsImported: Int = 0
    var appointmentsImported: Int = 0
    var caregiversImported: Int = 0
    
    var totalCount: Int {
        patientsImported + medicationsImported + schedulesImported +
        logsImported + healthMetricsImported + appointmentsImported + caregiversImported
    }
    
    var summary: String {
        """
        환자: \(patientsImported)건
        약물: \(medicationsImported)건
        스케줄: \(schedulesImported)건
        복약 기록: \(logsImported)건
        건강 지표: \(healthMetricsImported)건
        진료 예약: \(appointmentsImported)건
        보호자: \(caregiversImported)건
        """
    }
}

/// 가져오기 파일 유효성 검사 결과
struct ImportValidationResult {
    let isValid: Bool
    let exportDate: Date
    let appVersion: String
    let deviceName: String
    let patientCount: Int
    let medicationCount: Int
    let scheduleCount: Int
    let logCount: Int
    let healthMetricCount: Int
    let appointmentCount: Int
    
    var totalCount: Int {
        patientCount + medicationCount + scheduleCount +
        logCount + healthMetricCount + appointmentCount
    }
}

/// 데이터 내보내기/가져오기 에러
enum DataExportError: LocalizedError {
    case exportFailed(String)
    case importFailed(String)
    case invalidFileFormat
    case unsupportedVersion(Int)
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .exportFailed(let message):
            return "내보내기 실패: \(message)"
        case .importFailed(let message):
            return "가져오기 실패: \(message)"
        case .invalidFileFormat:
            return "올바르지 않은 파일 형식입니다."
        case .unsupportedVersion(let version):
            return "지원하지 않는 데이터 버전입니다. (버전: \(version))"
        case .fileNotFound:
            return "파일을 찾을 수 없습니다."
        }
    }
}
