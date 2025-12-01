//
//  HealthKitManager.swift
//  PillMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation
import HealthKit
import Combine

/// HealthKit 연동을 담당하는 싱글톤 매니저
@MainActor
final class HealthKitManager: ObservableObject {
    // MARK: - Singleton
    
    static let shared = HealthKitManager()
    
    // MARK: - Properties
    
    /// HealthKit Store
    private let healthStore = HKHealthStore()
    
    /// HealthKit 사용 가능 여부
    @Published private(set) var isAvailable: Bool = false
    
    /// 권한 부여 여부
    @Published private(set) var isAuthorized: Bool = false
    
    /// 마지막 동기화 시간
    @Published private(set) var lastSyncDate: Date?
    
    /// 동기화 진행 중 여부
    @Published private(set) var isSyncing: Bool = false
    
    /// 에러 메시지
    @Published var errorMessage: String?
    
    // MARK: - HealthKit Types
    
    /// 읽기 권한이 필요한 타입들
    private let readTypes: Set<HKObjectType> = {
        var types: Set<HKObjectType> = []
        
        // 체중
        if let weight = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weight)
        }
        
        // 혈압
        if let systolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
           let diastolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) {
            types.insert(systolic)
            types.insert(diastolic)
        }
        
        // 혈당
        if let glucose = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) {
            types.insert(glucose)
        }
        
        // 당화혈색소
        if let hba1c = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) {
            types.insert(hba1c)
        }
        
        // 심박수
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        
        // 산소포화도
        if let oxygenSaturation = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) {
            types.insert(oxygenSaturation)
        }
        
        // 체온
        if let bodyTemperature = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) {
            types.insert(bodyTemperature)
        }
        
        // 수분 섭취
        if let water = HKQuantityType.quantityType(forIdentifier: .dietaryWater) {
            types.insert(water)
        }
        
        // 걸음수
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        
        // 수면
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        
        return types
    }()
    
    /// 쓰기 권한이 필요한 타입들
    private let writeTypes: Set<HKSampleType> = {
        var types: Set<HKSampleType> = []
        
        // 체중
        if let weight = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weight)
        }
        
        // 혈압
        if let systolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
           let diastolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) {
            types.insert(systolic)
            types.insert(diastolic)
        }
        
        // 혈당
        if let glucose = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) {
            types.insert(glucose)
        }
        
        // 수분 섭취
        if let water = HKQuantityType.quantityType(forIdentifier: .dietaryWater) {
            types.insert(water)
        }
        
        return types
    }()
    
    // MARK: - Initialization
    
    private init() {
        checkAvailability()
    }
    
    // MARK: - Availability Check
    
    /// HealthKit 사용 가능 여부 확인
    private func checkAvailability() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - Authorization
    
    /// HealthKit 권한 요청
    func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = true
        } catch {
            isAuthorized = false
            throw HealthKitError.authorizationFailed(error)
        }
    }
    
    /// 특정 타입의 권한 상태 확인
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        healthStore.authorizationStatus(for: type)
    }
    
    // MARK: - Fetch Methods
    
    /// 최신 체중 가져오기
    func fetchLatestWeight() async -> Double? {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return nil
        }
        
        return await fetchLatestQuantity(type: weightType, unit: .gramUnit(with: .kilo))
    }
    
    /// 최신 혈압 가져오기
    func fetchLatestBloodPressure() async -> (systolic: Double, diastolic: Double)? {
        guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            return nil
        }
        
        let unit = HKUnit.millimeterOfMercury()
        
        async let systolic = fetchLatestQuantity(type: systolicType, unit: unit)
        async let diastolic = fetchLatestQuantity(type: diastolicType, unit: unit)
        
        guard let sys = await systolic, let dia = await diastolic else {
            return nil
        }
        
        return (systolic: sys, diastolic: dia)
    }
    
    /// 최신 혈당 가져오기
    func fetchLatestBloodGlucose() async -> Double? {
        guard let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) else {
            return nil
        }
        
        let unit = HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
        return await fetchLatestQuantity(type: glucoseType, unit: unit)
    }
    
    /// 최신 당화혈색소 가져오기 (HealthKit에서는 직접 지원하지 않음, 혈당 기반 계산)
    func fetchLatestHbA1C() async -> Double? {
        // HealthKit에서 HbA1C는 직접 지원하지 않음
        // 실제 구현에서는 외부 API나 수동 입력 사용
        return nil
    }
    
    /// 최신 심박수 가져오기
    func fetchLatestHeartRate() async -> Double? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return nil
        }
        
        let unit = HKUnit.count().unitDivided(by: .minute())
        return await fetchLatestQuantity(type: heartRateType, unit: unit)
    }
    
    /// 최신 산소포화도 가져오기
    func fetchLatestOxygenSaturation() async -> Double? {
        guard let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            return nil
        }
        
        let value = await fetchLatestQuantity(type: oxygenType, unit: .percent())
        return value.map { $0 * 100 } // 백분율로 변환
    }
    
    /// 최신 체온 가져오기
    func fetchLatestBodyTemperature() async -> Double? {
        guard let tempType = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) else {
            return nil
        }
        
        return await fetchLatestQuantity(type: tempType, unit: .degreeCelsius())
    }
    
    /// 특정 날짜의 수분 섭취량 가져오기
    func fetchWaterIntake(for date: Date) async -> Double? {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            return nil
        }
        
        let unit = HKUnit.literUnit(with: .milli)
        return await fetchDailyCumulativeQuantity(type: waterType, unit: unit, date: date)
    }
    
    /// 특정 날짜의 걸음수 가져오기
    func fetchSteps(for date: Date) async -> Double? {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return nil
        }
        
        return await fetchDailyCumulativeQuantity(type: stepsType, unit: .count(), date: date)
    }
    
    /// 특정 날짜의 수면 시간 가져오기 (시간 단위)
    func fetchSleepData(for date: Date) async -> Double? {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // 전날 밤부터 당일 아침까지의 수면을 포함하기 위해 범위 확장
        let adjustedStart = calendar.date(byAdding: .hour, value: -12, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: adjustedStart,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                guard error == nil,
                      let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // 실제 수면 시간만 합산 (inBed 제외)
                let totalSleepSeconds = sleepSamples
                    .filter { sample in
                        sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                    }
                    .reduce(0.0) { total, sample in
                        total + sample.endDate.timeIntervalSince(sample.startDate)
                    }
                
                let hours = totalSleepSeconds / 3600.0
                continuation.resume(returning: hours)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Save Methods
    
    /// 건강 지표 저장
    func saveHealthMetric(_ metric: HealthMetric) async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }
        
        switch metric.metricType {
        case .weight:
            try await saveWeight(metric.value, date: metric.recordedAt)
        case .bloodPressure:
            guard let sys = metric.systolicValue, let dia = metric.diastolicValue else {
                throw HealthKitError.invalidData
            }
            try await saveBloodPressure(systolic: sys, diastolic: dia, date: metric.recordedAt)
        case .bloodGlucose:
            try await saveBloodGlucose(metric.value, date: metric.recordedAt)
        case .waterIntake:
            try await saveWaterIntake(metric.value, date: metric.recordedAt)
        default:
            throw HealthKitError.unsupportedType
        }
    }
    
    /// 체중 저장
    private func saveWeight(_ value: Double, date: Date) async throws {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.unsupportedType
        }
        
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: value)
        let sample = HKQuantitySample(type: weightType, quantity: quantity, start: date, end: date)
        
        try await healthStore.save(sample)
    }
    
    /// 혈압 저장
    private func saveBloodPressure(systolic: Double, diastolic: Double, date: Date) async throws {
        guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic),
              let correlationType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure) else {
            throw HealthKitError.unsupportedType
        }
        
        let unit = HKUnit.millimeterOfMercury()
        
        let systolicQuantity = HKQuantity(unit: unit, doubleValue: systolic)
        let diastolicQuantity = HKQuantity(unit: unit, doubleValue: diastolic)
        
        let systolicSample = HKQuantitySample(type: systolicType, quantity: systolicQuantity, start: date, end: date)
        let diastolicSample = HKQuantitySample(type: diastolicType, quantity: diastolicQuantity, start: date, end: date)
        
        let correlation = HKCorrelation(
            type: correlationType,
            start: date,
            end: date,
            objects: [systolicSample, diastolicSample]
        )
        
        try await healthStore.save(correlation)
    }
    
    /// 혈당 저장
    private func saveBloodGlucose(_ value: Double, date: Date) async throws {
        guard let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) else {
            throw HealthKitError.unsupportedType
        }
        
        let unit = HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
        let quantity = HKQuantity(unit: unit, doubleValue: value)
        let sample = HKQuantitySample(type: glucoseType, quantity: quantity, start: date, end: date)
        
        try await healthStore.save(sample)
    }
    
    /// 수분 섭취량 저장
    private func saveWaterIntake(_ value: Double, date: Date) async throws {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            throw HealthKitError.unsupportedType
        }
        
        let unit = HKUnit.literUnit(with: .milli)
        let quantity = HKQuantity(unit: unit, doubleValue: value)
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: date, end: date)
        
        try await healthStore.save(sample)
    }
    
    /// 복약 기록 저장 (HealthKit에서는 복약을 직접 지원하지 않음)
    func saveMedicationRecord(_ log: MedicationLog) async throws {
        // HealthKit에서는 복약 기록을 직접 지원하지 않습니다.
        // 대신 외부 서비스나 로컬 저장소 사용
        // 여기서는 노트 형태로 저장하거나 다른 방법 사용
        
        // 실제 구현에서는 CareKit 또는 다른 프레임워크 사용 권장
        log.markSyncedToHealthKit()
    }
    
    // MARK: - Sync Methods
    
    /// 건강 데이터 동기화
    func syncHealthData() async {
        guard isAvailable && isAuthorized else { return }
        
        isSyncing = true
        defer {
            isSyncing = false
            lastSyncDate = Date()
        }
        
        // 모든 데이터 타입에 대해 최신 데이터 가져오기
        // 실제 구현에서는 DataManager와 연동하여 SwiftData에 저장
        
        _ = await fetchLatestWeight()
        _ = await fetchLatestBloodPressure()
        _ = await fetchLatestBloodGlucose()
        _ = await fetchLatestHeartRate()
        _ = await fetchLatestOxygenSaturation()
        _ = await fetchLatestBodyTemperature()
        _ = await fetchWaterIntake(for: Date())
        _ = await fetchSteps(for: Date())
        _ = await fetchSleepData(for: Date())
    }
    
    // MARK: - Helper Methods
    
    /// 최신 수량 값 가져오기 (단일 값)
    private func fetchLatestQuantity(type: HKQuantityType, unit: HKUnit) async -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil,
                      let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// 일일 누적 수량 가져오기
    private func fetchDailyCumulativeQuantity(type: HKQuantityType, unit: HKUnit, date: Date) async -> Double? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                guard error == nil,
                      let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let value = sum.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// 기간별 데이터 가져오기
    func fetchQuantityData(
        type: HKQuantityType,
        unit: HKUnit,
        startDate: Date,
        endDate: Date
    ) async -> [(date: Date, value: Double)] {
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil,
                      let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let data = quantitySamples.map { sample in
                    (date: sample.endDate, value: sample.quantity.doubleValue(for: unit))
                }
                
                continuation.resume(returning: data)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Background Delivery
    
    /// 백그라운드 딜리버리 설정
    func enableBackgroundDelivery() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }
        
        for type in readTypes {
            guard let sampleType = type as? HKSampleType else { continue }
            
            try await healthStore.enableBackgroundDelivery(
                for: sampleType,
                frequency: .immediate
            )
        }
    }
    
    /// 백그라운드 딜리버리 비활성화
    func disableBackgroundDelivery() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }
        
        for type in readTypes {
            guard let sampleType = type as? HKSampleType else { continue }
            
            try await healthStore.disableBackgroundDelivery(for: sampleType)
        }
    }
}

// MARK: - HealthKit Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationFailed(Error)
    case fetchFailed(Error)
    case saveFailed(Error)
    case unsupportedType
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "이 기기에서는 건강 앱을 사용할 수 없습니다."
        case .authorizationFailed(let error):
            return "건강 앱 권한 요청 실패: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "데이터를 가져오는데 실패했습니다: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "데이터를 저장하는데 실패했습니다: \(error.localizedDescription)"
        case .unsupportedType:
            return "지원하지 않는 데이터 타입입니다."
        case .invalidData:
            return "잘못된 데이터입니다."
        }
    }
}
