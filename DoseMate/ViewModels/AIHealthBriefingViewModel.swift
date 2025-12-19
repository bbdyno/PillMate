//
//  AIHealthBriefingViewModel.swift
//  DoseMate
//
//  Created by bbdyno on 12/16/25.
//

import SwiftUI
import DMateDesignSystem
import DMateResource
import SwiftData
import HealthKit

@Observable
class AIHealthBriefingViewModel {
    // MARK: - Properties

    private var modelContext: ModelContext?
    private let healthKitManager = HealthKitManager.shared

    var isLoading: Bool = false
    var errorMessage: String?
    var hasHealthData: Bool = false
    var isAuthorized: Bool = false

    // 건강 데이터
    var todaySteps: Int = 0
    var todayDistance: Double = 0 // km
    var todayActiveEnergy: Double = 0 // kcal
    var averageStepsLastWeek: Int = 0
    var heartRate: Int? = nil

    // AI 브리핑
    var briefingText: String = ""
    var recommendations: [ActivityRecommendation] = []
    var isGenerating: Bool = false

    // MARK: - Setup

    func setup(with context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Health Data

    /// HealthKit 권한 요청
    @MainActor
    func requestHealthKitPermission() async {
        do {
            try await healthKitManager.requestAuthorization()
            isAuthorized = healthKitManager.isAuthorized

            if isAuthorized {
                await loadHealthData()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 건강 데이터 로드
    @MainActor
    func loadHealthData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // 오늘 걸음 수
            if let steps = try await fetchTodaySteps() {
                todaySteps = Int(steps)
            }

            // 오늘 이동 거리
            if let distance = try await fetchTodayDistance() {
                todayDistance = distance
            }

            // 오늘 활동 에너지
            if let energy = try await fetchTodayActiveEnergy() {
                todayActiveEnergy = energy
            }

            // 최근 7일 평균 걸음 수
            if let avgSteps = try await fetchAverageStepsLastWeek() {
                averageStepsLastWeek = Int(avgSteps)
            }

            // 최근 심박수
            if let hr = try await fetchLatestHeartRate() {
                heartRate = Int(hr)
            }

            // 데이터가 하나라도 있으면 hasHealthData = true
            hasHealthData = todaySteps > 0 || todayDistance > 0 || todayActiveEnergy > 0 || averageStepsLastWeek > 0

            // AI 브리핑 생성
            if hasHealthData {
                await generateBriefing()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - HealthKit Queries

    private func fetchTodaySteps() async throws -> Double? {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let sum = result?.sumQuantity()?.doubleValue(for: HKUnit.count())
                continuation.resume(returning: sum)
            }

            healthKitManager.healthStore.execute(query)
        }
    }

    private func fetchTodayDistance() async throws -> Double? {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let sum = result?.sumQuantity()?.doubleValue(for: HKUnit.meterUnit(with: .kilo))
                continuation.resume(returning: sum)
            }

            healthKitManager.healthStore.execute(query)
        }
    }

    private func fetchTodayActiveEnergy() async throws -> Double? {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let sum = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie())
                continuation.resume(returning: sum)
            }

            healthKitManager.healthStore.execute(query)
        }
    }

    private func fetchAverageStepsLastWeek() async throws -> Double? {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return nil }

        let calendar = Calendar.current
        let now = Date()
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return nil }

        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                if let sum = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) {
                    let average = sum / 7.0
                    continuation.resume(returning: average)
                } else {
                    continuation.resume(returning: nil)
                }
            }

            healthKitManager.healthStore.execute(query)
        }
    }

    private func fetchLatestHeartRate() async throws -> Double? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                if let sample = samples?.first as? HKQuantitySample {
                    let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    continuation.resume(returning: value)
                } else {
                    continuation.resume(returning: nil)
                }
            }

            healthKitManager.healthStore.execute(query)
        }
    }

    // MARK: - AI Briefing

    /// AI 브리핑 생성 (로컬 모델 사용)
    @MainActor
    func generateBriefing() async {
        isGenerating = true
        defer { isGenerating = false }

        // 간단한 규칙 기반 브리핑 (FoundationModels는 iOS 18.2+에서만 사용 가능하므로 fallback)
        generateRuleBasedBriefing()
    }

    /// 규칙 기반 브리핑 생성
    private func generateRuleBasedBriefing() {
        var briefing = ""
        var recs: [ActivityRecommendation] = []

        // 걸음 수 분석
        if todaySteps < 5000 {
            briefing += NSLocalizedString("ai.briefing.low_steps", comment: "")
            recs.append(ActivityRecommendation(
                type: .walking,
                title: NSLocalizedString("ai.recommendation.walking_title", comment: ""),
                description: NSLocalizedString("ai.recommendation.walking_description", comment: ""),
                icon: "figure.walk",
                color: .green
            ))
        } else if todaySteps >= 10000 {
            briefing += NSLocalizedString("ai.briefing.great_steps", comment: "")
        } else {
            briefing += NSLocalizedString("ai.briefing.good_steps", comment: "")
        }

        // 활동 에너지 분석
        if todayActiveEnergy < 200 {
            recs.append(ActivityRecommendation(
                type: .running,
                title: NSLocalizedString("ai.recommendation.running_title", comment: ""),
                description: NSLocalizedString("ai.recommendation.running_description", comment: ""),
                icon: "figure.run",
                color: .orange
            ))
        }

        // 평균 대비 분석
        if averageStepsLastWeek > 0 {
            let percentage = (Double(todaySteps) / Double(averageStepsLastWeek)) * 100
            if percentage < 80 {
                briefing += " " + NSLocalizedString("ai.briefing.below_average", comment: "")
            } else if percentage > 120 {
                briefing += " " + NSLocalizedString("ai.briefing.above_average", comment: "")
            }
        }

        // 기본 추천
        if recs.isEmpty {
            recs.append(ActivityRecommendation(
                type: .exercise,
                title: NSLocalizedString("ai.recommendation.exercise_title", comment: ""),
                description: NSLocalizedString("ai.recommendation.exercise_description", comment: ""),
                icon: "figure.strengthtraining.traditional",
                color: .blue
            ))
        }

        briefingText = briefing
        recommendations = recs
    }
}

// MARK: - Activity Recommendation Model

struct ActivityRecommendation: Identifiable {
    let id = UUID()
    let type: ActivityType
    let title: String
    let description: String
    let icon: String
    let color: Color

    enum ActivityType {
        case walking
        case running
        case exercise
    }
}
