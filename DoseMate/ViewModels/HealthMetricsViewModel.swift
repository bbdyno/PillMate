//
//  HealthMetricsViewModel.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation
import SwiftUI
import DMateDesignSystem
import DMateResource
import SwiftData

/// 건강 지표 ViewModel
@MainActor
@Observable
final class HealthMetricsViewModel {
    // MARK: - Properties
    
    /// 최신 건강 지표들
    var latestMetrics: [MetricType: HealthMetric] = [:]
    
    /// 선택된 지표 타입의 히스토리
    var selectedMetricHistory: [HealthMetric] = []
    
    /// 선택된 지표 타입
    var selectedMetricType: MetricType? {
        didSet {
            if let type = selectedMetricType {
                Task {
                    await loadMetricHistory(for: type)
                }
            }
        }
    }
    
    /// 선택된 기간
    var selectedPeriod: StatisticsPeriod = .week {
        didSet {
            if let type = selectedMetricType {
                Task {
                    await loadMetricHistory(for: type)
                }
            }
        }
    }
    
    /// 로딩 상태
    var isLoading: Bool = false
    
    /// HealthKit 동기화 중
    var isSyncing: Bool = false
    
    /// 에러 메시지
    var errorMessage: String?
    
    /// 입력 시트 표시
    var showInputSheet: Bool = false
    
    /// 입력할 지표 타입
    var inputMetricType: MetricType?
    
    /// 입력 값
    var inputValue: String = ""
    
    /// 혈압 수축기 입력
    var inputSystolic: String = ""
    
    /// 혈압 이완기 입력
    var inputDiastolic: String = ""
    
    /// 기분 레벨
    var inputMoodLevel: MoodLevel = .neutral
    
    /// 메모
    var inputNotes: String = ""

    /// 선택된 약물 (건강 지표와 연관)
    var selectedMedication: Medication?

    /// 약물 목록
    var medications: [Medication] = []

    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    private let healthKitManager = HealthKitManager.shared
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Setup
    
    /// ModelContext 설정
    func setup(with context: ModelContext) {
        self.modelContext = context
        Task {
            await loadAllLatestMetrics()
            await loadMedications()
        }
    }

    /// 약물 목록 로드
    func loadMedications() async {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<Medication>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.name)]
        )

        do {
            medications = try context.fetch(descriptor)
        } catch {
            print("Failed to load medications: \(error)")
        }
    }
    
    // MARK: - Data Loading
    
    /// 모든 최신 지표 로드
    func loadAllLatestMetrics() async {
        guard let context = modelContext else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        for type in MetricType.allCases {
            let typeString = type.rawValue
            let predicate = #Predicate<HealthMetric> { $0.type == typeString }
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
    
    /// 특정 지표의 히스토리 로드
    func loadMetricHistory(for type: MetricType) async {
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
        
        let typeString = type.rawValue
        let predicate = #Predicate<HealthMetric> { metric in
            metric.type == typeString &&
            metric.recordedAt >= startDate &&
            metric.recordedAt <= now
        }
        
        let descriptor = FetchDescriptor<HealthMetric>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.recordedAt)]
        )
        
        do {
            selectedMetricHistory = try context.fetch(descriptor)
        } catch {
            errorMessage = "건강 지표를 불러오는데 실패했습니다."
        }
    }
    
    // MARK: - HealthKit Sync
    
    /// HealthKit에서 데이터 동기화
    func syncFromHealthKit() async {
        isSyncing = true
        defer { isSyncing = false }
        
        // 권한 요청
        do {
            try await healthKitManager.requestAuthorization()
        } catch {
            errorMessage = "건강 앱 권한을 얻는데 실패했습니다."
            return
        }
        
        // 각 지표별 동기화
        await syncWeight()
        await syncBloodPressure()
        await syncBloodGlucose()
        await syncHeartRate()
        await syncOxygenSaturation()
        await syncBodyTemperature()
        await syncWaterIntake()
        await syncSteps()
        await syncSleep()
        
        await loadAllLatestMetrics()
    }
    
    /// HealthKit 권한 요청만 수행
    func requestHealthKitPermission() async {
        do {
            try await healthKitManager.requestAuthorization()
        } catch {
            errorMessage = "건강 앱 권한을 얻는데 실패했습니다."
        }
    }

    /// 권한이 있는 상태에서 동기화만 수행
    func syncAuthorized() async {
        isSyncing = true
        defer { isSyncing = false }
        await healthKitManager.syncHealthData()
        await loadAllLatestMetrics()
    }
    
    private func syncWeight() async {
        if let value = await healthKitManager.fetchLatestWeight() {
            await saveMetricIfNewer(type: .weight, value: value, source: .healthKit)
        }
    }
    
    private func syncBloodPressure() async {
        if let bp = await healthKitManager.fetchLatestBloodPressure() {
            await saveBloodPressureIfNewer(systolic: bp.systolic, diastolic: bp.diastolic, source: .healthKit)
        }
    }
    
    private func syncBloodGlucose() async {
        if let value = await healthKitManager.fetchLatestBloodGlucose() {
            await saveMetricIfNewer(type: .bloodGlucose, value: value, source: .healthKit)
        }
    }
    
    private func syncHeartRate() async {
        if let value = await healthKitManager.fetchLatestHeartRate() {
            await saveMetricIfNewer(type: .heartRate, value: value, source: .healthKit)
        }
    }
    
    private func syncOxygenSaturation() async {
        if let value = await healthKitManager.fetchLatestOxygenSaturation() {
            await saveMetricIfNewer(type: .oxygenSaturation, value: value, source: .healthKit)
        }
    }
    
    private func syncBodyTemperature() async {
        if let value = await healthKitManager.fetchLatestBodyTemperature() {
            await saveMetricIfNewer(type: .bodyTemperature, value: value, source: .healthKit)
        }
    }
    
    private func syncWaterIntake() async {
        if let value = await healthKitManager.fetchWaterIntake(for: Date()) {
            await saveMetricIfNewer(type: .waterIntake, value: value, source: .healthKit)
        }
    }
    
    private func syncSteps() async {
        if let value = await healthKitManager.fetchSteps(for: Date()) {
            await saveMetricIfNewer(type: .steps, value: value, source: .healthKit)
        }
    }
    
    private func syncSleep() async {
        if let value = await healthKitManager.fetchSleepData(for: Date()) {
            await saveMetricIfNewer(type: .sleep, value: value, source: .healthKit)
        }
    }
    
    private func saveMetricIfNewer(type: MetricType, value: Double, source: DataSource) async {
        guard let context = modelContext else { return }
        
        // 최신 데이터와 비교
        if let existing = latestMetrics[type] {
            // 이미 같은 값이 있으면 스킵
            if existing.value == value && Calendar.current.isDateInToday(existing.recordedAt) {
                return
            }
        }
        
        let metric = HealthMetric(type: type, value: value, source: source)
        context.insert(metric)
        try? context.save()
    }
    
    private func saveBloodPressureIfNewer(systolic: Double, diastolic: Double, source: DataSource) async {
        guard let context = modelContext else { return }
        
        if let existing = latestMetrics[.bloodPressure] {
            if existing.systolicValue == systolic &&
               existing.diastolicValue == diastolic &&
               Calendar.current.isDateInToday(existing.recordedAt) {
                return
            }
        }
        
        let metric = HealthMetric(bloodPressure: systolic, diastolic: diastolic, source: source)
        context.insert(metric)
        try? context.save()
    }
    
    // MARK: - Manual Input
    
    /// 입력 시트 열기
    func openInputSheet(for type: MetricType) {
        inputMetricType = type

        // 최신 값이 있으면 기본값으로 설정, 없으면 0
        if let latestMetric = latestMetrics[type] {
            switch type {
            case .bloodPressure:
                inputSystolic = latestMetric.systolicValue.map { String(Int($0)) } ?? "0"
                inputDiastolic = latestMetric.diastolicValue.map { String(Int($0)) } ?? "0"
                inputValue = ""
            case .mood:
                inputMoodLevel = MoodLevel(rawValue: Int(latestMetric.value)) ?? .neutral
                inputValue = ""
                inputSystolic = ""
                inputDiastolic = ""
            default:
                inputValue = String(Int(latestMetric.value))
                inputSystolic = ""
                inputDiastolic = ""
            }
        } else {
            // 기본값 0
            inputValue = "0"
            inputSystolic = "0"
            inputDiastolic = "0"
            inputMoodLevel = .neutral
        }

        inputNotes = ""
        selectedMedication = nil
        showInputSheet = true
    }

    /// 특정 지표 타입과 관련된 약물 목록
    func relatedMedications(for type: MetricType) -> [Medication] {
        medications.filter { medication in
            medication.relatedMetricTypes.contains(type)
        }
    }
    
    /// 지표 저장
    func saveMetric() async {
        guard let context = modelContext,
              let type = inputMetricType else { return }
        
        let metric: HealthMetric
        
        switch type {
        case .bloodPressure:
            guard let systolic = Double(inputSystolic),
                  let diastolic = Double(inputDiastolic) else {
                errorMessage = "올바른 값을 입력해주세요."
                return
            }
            metric = HealthMetric(
                bloodPressure: systolic,
                diastolic: diastolic,
                notes: inputNotes.isEmpty ? nil : inputNotes,
                source: .manual
            )
            
        case .mood:
            metric = HealthMetric(
                mood: inputMoodLevel,
                notes: inputNotes.isEmpty ? nil : inputNotes
            )
            
        default:
            guard let value = Double(inputValue) else {
                errorMessage = "올바른 값을 입력해주세요."
                return
            }
            metric = HealthMetric(
                type: type,
                value: value,
                notes: inputNotes.isEmpty ? nil : inputNotes,
                source: .manual
            )
        }

        // 선택된 약물 연결
        metric.medication = selectedMedication

        context.insert(metric)
        
        do {
            try context.save()
            
            // HealthKit에 저장 (지원하는 타입만)
            if type.supportsHealthKit && type != .mood {
                try? await healthKitManager.saveHealthMetric(metric)
            }
            
            await loadAllLatestMetrics()
            
            if let selected = selectedMetricType {
                await loadMetricHistory(for: selected)
            }
            
            showInputSheet = false
        } catch {
            errorMessage = "저장에 실패했습니다."
        }
    }
    
    /// 지표 삭제
    func deleteMetric(_ metric: HealthMetric) async {
        guard let context = modelContext else { return }
        
        context.delete(metric)
        try? context.save()
        
        await loadAllLatestMetrics()
        
        if let type = selectedMetricType {
            await loadMetricHistory(for: type)
        }
    }
    
    // MARK: - Computed Properties
    
    /// 지원하는 지표 타입들
    var supportedMetricTypes: [MetricType] {
        MetricType.allCases
    }
    
    /// HealthKit 지원 지표들
    var healthKitMetricTypes: [MetricType] {
        MetricType.allCases.filter { $0.supportsHealthKit }
    }
    
    /// 차트 데이터
    var chartData: [(date: Date, value: Double)] {
        selectedMetricHistory.map { (date: $0.recordedAt, value: $0.value) }
    }
    
    /// 혈압 차트 데이터
    var bloodPressureChartData: [(date: Date, systolic: Double, diastolic: Double)] {
        selectedMetricHistory.compactMap { metric in
            guard let sys = metric.systolicValue,
                  let dia = metric.diastolicValue else { return nil }
            return (date: metric.recordedAt, systolic: sys, diastolic: dia)
        }
    }
    
    /// 평균값
    var averageValue: Double? {
        guard !selectedMetricHistory.isEmpty else { return nil }
        let sum = selectedMetricHistory.reduce(0.0) { $0 + $1.value }
        return sum / Double(selectedMetricHistory.count)
    }
    
    /// 최대값
    var maxValue: Double? {
        selectedMetricHistory.map { $0.value }.max()
    }
    
    /// 최소값
    var minValue: Double? {
        selectedMetricHistory.map { $0.value }.min()
    }
}

