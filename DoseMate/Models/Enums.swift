//
//  Enums.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation
import SwiftUI

// MARK: - 스케줄 타입
/// 복약 스케줄의 유형을 정의합니다.
enum ScheduleType: String, Codable, CaseIterable, Identifiable {
    case daily = "daily"              // 매일
    case specificDays = "specificDays" // 특정 요일
    case interval = "interval"         // 간격 (맞춤)
    case asNeeded = "asNeeded"         // 필요시 (PRN)
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .daily: return DoseMateStrings.ScheduleType.daily
        case .specificDays: return DoseMateStrings.ScheduleType.specificDays
        case .interval: return DoseMateStrings.ScheduleType.interval
        case .asNeeded: return DoseMateStrings.ScheduleType.asNeeded
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "calendar"
        case .specificDays: return "calendar.badge.clock"
        case .interval: return "arrow.left.arrow.right"
        case .asNeeded: return "hand.raised"
        }
    }
    
    var description: String {
        switch self {
        case .daily: return DoseMateStrings.ScheduleType.dailyDesc
        case .specificDays: return DoseMateStrings.ScheduleType.specificDaysDesc
        case .interval: return DoseMateStrings.ScheduleType.intervalDesc
        case .asNeeded: return DoseMateStrings.ScheduleType.asNeededDesc
        }
    }
}

// MARK: - 복용 빈도
/// 하루 복용 횟수를 정의합니다.
enum Frequency: String, Codable, CaseIterable, Identifiable {
    case onceDaily = "onceDaily"           // 하루 1회
    case twiceDaily = "twiceDaily"         // 하루 2회
    case threeTimesDaily = "threeTimesDaily" // 하루 3회
    case fourTimesDaily = "fourTimesDaily"   // 하루 4회
    case custom = "custom"                   // 맞춤
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .onceDaily: return DoseMateStrings.Frequency.onceDaily
        case .twiceDaily: return DoseMateStrings.Frequency.twiceDaily
        case .threeTimesDaily: return DoseMateStrings.Frequency.threeTimesDaily
        case .fourTimesDaily: return DoseMateStrings.Frequency.fourTimesDaily
        case .custom: return DoseMateStrings.Frequency.custom
        }
    }
    
    var timesPerDay: Int {
        switch self {
        case .onceDaily: return 1
        case .twiceDaily: return 2
        case .threeTimesDaily: return 3
        case .fourTimesDaily: return 4
        case .custom: return 0
        }
    }
}

// MARK: - 복용 상태
/// 복약 기록의 상태를 정의합니다.
enum LogStatus: String, Codable, CaseIterable, Identifiable {
    case taken = "taken"       // 복용완료
    case skipped = "skipped"   // 건너뜀
    case delayed = "delayed"   // 지연
    case snoozed = "snoozed"   // 미루기
    case pending = "pending"   // 대기중
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .taken: return DoseMateStrings.Status.taken
        case .skipped: return DoseMateStrings.Status.skipped
        case .delayed: return DoseMateStrings.Status.delayed
        case .snoozed: return DoseMateStrings.Status.snoozed
        case .pending: return DoseMateStrings.Status.pending
        }
    }
    
    var icon: String {
        switch self {
        case .taken: return "checkmark.circle.fill"
        case .skipped: return "xmark.circle.fill"
        case .delayed: return "clock.badge.exclamationmark.fill"
        case .snoozed: return "bell.slash.fill"
        case .pending: return "circle"
        }
    }
    
    var color: Color {
        switch self {
        case .taken: return .green
        case .skipped: return .red
        case .delayed: return .orange
        case .snoozed: return .yellow
        case .pending: return .gray
        }
    }
}

// MARK: - 건강 지표 타입
/// 측정 가능한 건강 지표의 종류를 정의합니다.
enum MetricType: String, Codable, CaseIterable, Identifiable {
    case weight = "weight"                     // 체중
    case bloodPressure = "bloodPressure"       // 혈압
    case bloodGlucose = "bloodGlucose"         // 혈당
    case hbA1C = "hbA1C"                       // 당화혈색소
    case waterIntake = "waterIntake"           // 수분 섭취
    case bodyTemperature = "bodyTemperature"   // 체온
    case oxygenSaturation = "oxygenSaturation" // 산소포화도 (SpO2)
    case mood = "mood"                         // 기분
    case heartRate = "heartRate"               // 심박수
    case steps = "steps"                       // 걸음수
    case sleep = "sleep"                       // 수면
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .weight: return DoseMateStrings.MetricType.weight
        case .bloodPressure: return DoseMateStrings.MetricType.bloodPressure
        case .bloodGlucose: return DoseMateStrings.MetricType.bloodGlucose
        case .hbA1C: return DoseMateStrings.MetricType.hba1c
        case .waterIntake: return DoseMateStrings.MetricType.waterIntake
        case .bodyTemperature: return DoseMateStrings.MetricType.bodyTemperature
        case .oxygenSaturation: return DoseMateStrings.MetricType.oxygenSaturation
        case .mood: return DoseMateStrings.MetricType.mood
        case .heartRate: return DoseMateStrings.MetricType.heartRate
        case .steps: return DoseMateStrings.MetricType.steps
        case .sleep: return DoseMateStrings.MetricType.sleep
        }
    }
    
    var unit: String {
        switch self {
        case .weight: return "kg"
        case .bloodPressure: return "mmHg"
        case .bloodGlucose: return "mg/dL"
        case .hbA1C: return "%"
        case .waterIntake: return "mL"
        case .bodyTemperature: return "°C"
        case .oxygenSaturation: return "%"
        case .mood: return ""
        case .heartRate: return "BPM"
        case .steps: return DoseMateStrings.MetricUnit.steps
        case .sleep: return DoseMateStrings.MetricUnit.hours
        }
    }
    
    var icon: String {
        switch self {
        case .weight: return "scalemass"
        case .bloodPressure: return "heart.fill"
        case .bloodGlucose: return "drop.fill"
        case .hbA1C: return "percent"
        case .waterIntake: return "drop.triangle.fill"
        case .bodyTemperature: return "thermometer"
        case .oxygenSaturation: return "lungs.fill"
        case .mood: return "face.smiling"
        case .heartRate: return "heart.text.square"
        case .steps: return "figure.walk"
        case .sleep: return "bed.double.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .weight: return .blue
        case .bloodPressure: return .red
        case .bloodGlucose: return .purple
        case .hbA1C: return .orange
        case .waterIntake: return .cyan
        case .bodyTemperature: return .yellow
        case .oxygenSaturation: return .teal
        case .mood: return .pink
        case .heartRate: return .red
        case .steps: return .green
        case .sleep: return .indigo
        }
    }
    
    /// HealthKit 동기화 지원 여부
    var supportsHealthKit: Bool {
        switch self {
        case .mood: return false
        default: return true
        }
    }
}

// MARK: - 데이터 소스
/// 건강 데이터의 출처를 정의합니다.
enum DataSource: String, Codable, CaseIterable, Identifiable {
    case manual = "manual"       // 수동 입력
    case healthKit = "healthKit" // HealthKit
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .manual: return DoseMateStrings.DataSource.manual
        case .healthKit: return DoseMateStrings.DataSource.healthApp
        }
    }
    
    var icon: String {
        switch self {
        case .manual: return "hand.point.up.left"
        case .healthKit: return "heart.fill"
        }
    }
}

// MARK: - 알림 설정
/// 보호자 알림 설정을 정의합니다.
enum NotificationPreference: String, Codable, CaseIterable, Identifiable {
    case all = "all"             // 모든 알림
    case missedOnly = "missedOnly" // 놓친 복약만
    case none = "none"           // 알림 없음
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return DoseMateStrings.NotificationPref.all
        case .missedOnly: return DoseMateStrings.NotificationPref.missedOnly
        case .none: return DoseMateStrings.NotificationPref.none
        }
    }
}

// MARK: - 약물 형태
/// 약물의 형태를 정의합니다.
enum MedicationForm: String, Codable, CaseIterable, Identifiable {
    case tablet = "tablet"         // 알약
    case capsule = "capsule"       // 캡슐
    case syrup = "syrup"           // 시럽
    case injection = "injection"   // 주사
    case patch = "patch"           // 패치
    case cream = "cream"           // 크림/연고
    case inhaler = "inhaler"       // 흡입기
    case drops = "drops"           // 점안액/점이액
    case powder = "powder"         // 가루약
    case other = "other"           // 기타
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .tablet: return DoseMateStrings.MedicationForm.tablet
        case .capsule: return DoseMateStrings.MedicationForm.capsule
        case .syrup: return DoseMateStrings.MedicationForm.syrup
        case .injection: return DoseMateStrings.MedicationForm.injection
        case .patch: return DoseMateStrings.MedicationForm.patch
        case .cream: return DoseMateStrings.MedicationForm.cream
        case .inhaler: return DoseMateStrings.MedicationForm.inhaler
        case .drops: return DoseMateStrings.MedicationForm.drops
        case .powder: return DoseMateStrings.MedicationForm.powder
        case .other: return DoseMateStrings.MedicationForm.other
        }
    }
    
    var icon: String {
        switch self {
        case .tablet: return "pill.fill"
        case .capsule: return "capsule.fill"
        case .syrup: return "waterbottle.fill"
        case .injection: return "syringe.fill"
        case .patch: return "bandage.fill"
        case .cream: return "tube.fill"
        case .inhaler: return "wind"
        case .drops: return "drop.fill"
        case .powder: return "sparkles"
        case .other: return "cross.case.fill"
        }
    }
}

// MARK: - 식사 관계
/// 약물 복용과 식사의 관계를 정의합니다.
enum MealRelation: String, Codable, CaseIterable, Identifiable {
    case beforeMeal = "beforeMeal"   // 식전
    case afterMeal = "afterMeal"     // 식후
    case withMeal = "withMeal"       // 식사와 함께
    case anytime = "anytime"         // 식사와 무관
    case emptyStomach = "emptyStomach" // 공복
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .beforeMeal: return DoseMateStrings.MealRelation.beforeMeal
        case .afterMeal: return DoseMateStrings.MealRelation.afterMeal
        case .withMeal: return DoseMateStrings.MealRelation.withMeal
        case .anytime: return DoseMateStrings.MealRelation.anytime
        case .emptyStomach: return DoseMateStrings.MealRelation.emptyStomach
        }
    }
    
    var icon: String {
        switch self {
        case .beforeMeal: return "arrow.left.to.line"
        case .afterMeal: return "arrow.right.to.line"
        case .withMeal: return "fork.knife"
        case .anytime: return "clock"
        case .emptyStomach: return "circle.dashed"
        }
    }
}

// MARK: - 기분 레벨
/// 기분 상태의 레벨을 정의합니다.
enum MoodLevel: Int, Codable, CaseIterable, Identifiable {
    case veryBad = 1
    case bad = 2
    case neutral = 3
    case good = 4
    case veryGood = 5
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .veryBad: return DoseMateStrings.MoodLevel.veryBad
        case .bad: return DoseMateStrings.MoodLevel.bad
        case .neutral: return DoseMateStrings.MoodLevel.neutral
        case .good: return DoseMateStrings.MoodLevel.good
        case .veryGood: return DoseMateStrings.MoodLevel.veryGood
        }
    }
    
    var emoji: String {
        switch self {
        case .veryBad: return "😢"
        case .bad: return "😕"
        case .neutral: return "😐"
        case .good: return "🙂"
        case .veryGood: return "😄"
        }
    }
    
    var color: Color {
        switch self {
        case .veryBad: return .red
        case .bad: return .orange
        case .neutral: return .yellow
        case .good: return .mint
        case .veryGood: return .green
        }
    }
}

// MARK: - 요일
/// 요일을 정의합니다 (0 = 일요일).
enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    
    var id: Int { rawValue }
    
    var shortName: String {
        switch self {
        case .sunday: return DoseMateStrings.Weekday.sunShort
        case .monday: return DoseMateStrings.Weekday.monShort
        case .tuesday: return DoseMateStrings.Weekday.tueShort
        case .wednesday: return DoseMateStrings.Weekday.wedShort
        case .thursday: return DoseMateStrings.Weekday.thuShort
        case .friday: return DoseMateStrings.Weekday.friShort
        case .saturday: return DoseMateStrings.Weekday.satShort
        }
    }
    
    var fullName: String {
        switch self {
        case .sunday: return DoseMateStrings.Weekday.sunday
        case .monday: return DoseMateStrings.Weekday.monday
        case .tuesday: return DoseMateStrings.Weekday.tuesday
        case .wednesday: return DoseMateStrings.Weekday.wednesday
        case .thursday: return DoseMateStrings.Weekday.thursday
        case .friday: return DoseMateStrings.Weekday.friday
        case .saturday: return DoseMateStrings.Weekday.saturday
        }
    }
}

// MARK: - 시간대
/// 하루의 시간대를 정의합니다.
enum TimeOfDay: String, Codable, CaseIterable, Identifiable {
    case morning = "morning"     // 아침
    case afternoon = "afternoon" // 점심
    case evening = "evening"     // 저녁
    case night = "night"         // 밤
    case bedtime = "bedtime"     // 취침 전
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .morning: return DoseMateStrings.TimeOfDay.morning
        case .afternoon: return DoseMateStrings.TimeOfDay.afternoon
        case .evening: return DoseMateStrings.TimeOfDay.evening
        case .night: return DoseMateStrings.TimeOfDay.night
        case .bedtime: return DoseMateStrings.TimeOfDay.bedtime
        }
    }
    
    var defaultTime: DateComponents {
        switch self {
        case .morning: return DateComponents(hour: 8, minute: 0)
        case .afternoon: return DateComponents(hour: 12, minute: 0)
        case .evening: return DateComponents(hour: 18, minute: 0)
        case .night: return DateComponents(hour: 21, minute: 0)
        case .bedtime: return DateComponents(hour: 22, minute: 30)
        }
    }
    
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.fill"
        case .bedtime: return "bed.double.fill"
        }
    }
}

// MARK: - 스누즈 옵션
/// 알림 미루기 옵션을 정의합니다.
enum SnoozeOption: Int, CaseIterable, Identifiable {
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .fiveMinutes: return DoseMateStrings.SnoozeOption.fiveMinutes
        case .tenMinutes: return DoseMateStrings.SnoozeOption.tenMinutes
        case .fifteenMinutes: return DoseMateStrings.SnoozeOption.fifteenMinutes
        case .thirtyMinutes: return DoseMateStrings.SnoozeOption.thirtyMinutes
        case .oneHour: return DoseMateStrings.SnoozeOption.oneHour
        }
    }
}

// MARK: - 통계 기간
/// 통계 조회 기간을 정의합니다.
enum StatisticsPeriod: String, CaseIterable, Identifiable {
    case week = "week"
    case month = "month"
    case threeMonths = "threeMonths"
    case year = "year"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .week: return DoseMateStrings.StatisticsPeriod.week
        case .month: return DoseMateStrings.StatisticsPeriod.month
        case .threeMonths: return DoseMateStrings.StatisticsPeriod.threeMonths
        case .year: return DoseMateStrings.StatisticsPeriod.year
        }
    }
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        }
    }
}

// MARK: - 약 색상
/// 약물의 색상을 정의합니다.
enum MedicationColor: String, Codable, CaseIterable, Identifiable {
    case white = "white"
    case yellow = "yellow"
    case orange = "orange"
    case pink = "pink"
    case red = "red"
    case brown = "brown"
    case green = "green"
    case blue = "blue"
    case purple = "purple"
    case black = "black"
    case multicolor = "multicolor"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .white: return DoseMateStrings.MedicationColor.white
        case .yellow: return DoseMateStrings.MedicationColor.yellow
        case .orange: return DoseMateStrings.MedicationColor.orange
        case .pink: return DoseMateStrings.MedicationColor.pink
        case .red: return DoseMateStrings.MedicationColor.red
        case .brown: return DoseMateStrings.MedicationColor.brown
        case .green: return DoseMateStrings.MedicationColor.green
        case .blue: return DoseMateStrings.MedicationColor.blue
        case .purple: return DoseMateStrings.MedicationColor.purple
        case .black: return DoseMateStrings.MedicationColor.black
        case .multicolor: return DoseMateStrings.MedicationColor.multicolor
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .white: return .white
        case .yellow: return .yellow
        case .orange: return .orange
        case .pink: return .pink
        case .red: return .red
        case .brown: return .brown
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .black: return .black
        case .multicolor: return .gray
        }
    }

    /// Alias for swiftUIColor
    var color: Color {
        swiftUIColor
    }
}

// MARK: - 약물 카테고리
/// 약물의 치료 목적/카테고리를 정의합니다.
enum MedicationCategory: String, Codable, CaseIterable, Identifiable {
    case cardiovascular = "cardiovascular"         // 심혈관계 (혈압약 등)
    case diabetes = "diabetes"                     // 당뇨병
    case respiratory = "respiratory"               // 호흡기
    case pain = "pain"                            // 진통제
    case gastrointestinal = "gastrointestinal"    // 소화기계
    case mental = "mental"                        // 정신건강
    case antibiotic = "antibiotic"                // 항생제
    case vitamin = "vitamin"                      // 비타민/보충제
    case thyroid = "thyroid"                      // 갑상선
    case other = "other"                          // 기타

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cardiovascular: return DoseMateStrings.MedicationCategory.cardiovascular
        case .diabetes: return DoseMateStrings.MedicationCategory.diabetes
        case .respiratory: return DoseMateStrings.MedicationCategory.respiratory
        case .pain: return DoseMateStrings.MedicationCategory.pain
        case .gastrointestinal: return DoseMateStrings.MedicationCategory.gastrointestinal
        case .mental: return DoseMateStrings.MedicationCategory.mental
        case .antibiotic: return DoseMateStrings.MedicationCategory.antibiotic
        case .vitamin: return DoseMateStrings.MedicationCategory.vitamin
        case .thyroid: return DoseMateStrings.MedicationCategory.thyroid
        case .other: return DoseMateStrings.MedicationCategory.other
        }
    }

    var icon: String {
        switch self {
        case .cardiovascular: return "heart.fill"
        case .diabetes: return "drop.fill"
        case .respiratory: return "lungs.fill"
        case .pain: return "bolt.fill"
        case .gastrointestinal: return "stomach.fill"
        case .mental: return "brain.fill"
        case .antibiotic: return "cross.fill"
        case .vitamin: return "leaf.fill"
        case .thyroid: return "circle.hexagongrid.fill"
        case .other: return "pill.fill"
        }
    }

    /// 이 카테고리와 관련된 건강 지표 타입들
    var relatedMetricTypes: [MetricType] {
        switch self {
        case .cardiovascular:
            return [.bloodPressure, .heartRate]
        case .diabetes:
            return [.bloodGlucose, .hbA1C, .weight]
        case .respiratory:
            return [.oxygenSaturation]
        case .pain:
            return [.mood]
        case .gastrointestinal:
            return [.weight, .mood]
        case .mental:
            return [.mood, .sleep]
        case .antibiotic:
            return [.bodyTemperature]
        case .vitamin:
            return [.weight]
        case .thyroid:
            return [.weight, .heartRate]
        case .other:
            return []
        }
    }

    /// 주요 건강 지표 (첫 번째)
    var primaryMetricType: MetricType? {
        relatedMetricTypes.first
    }
}
