//
//  Enums.swift
//  PillMate
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
    case asNeeded = "asNeeded"         // 필요시 (PRN)
    case custom = "custom"             // 맞춤
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .daily: return "매일"
        case .specificDays: return "특정 요일"
        case .asNeeded: return "필요시 (PRN)"
        case .custom: return "맞춤"
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "calendar"
        case .specificDays: return "calendar.badge.clock"
        case .asNeeded: return "hand.raised"
        case .custom: return "slider.horizontal.3"
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
        case .onceDaily: return "하루 1회"
        case .twiceDaily: return "하루 2회"
        case .threeTimesDaily: return "하루 3회"
        case .fourTimesDaily: return "하루 4회"
        case .custom: return "맞춤"
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
        case .taken: return "복용완료"
        case .skipped: return "건너뜀"
        case .delayed: return "지연"
        case .snoozed: return "미루기"
        case .pending: return "대기중"
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
        case .weight: return "체중"
        case .bloodPressure: return "혈압"
        case .bloodGlucose: return "혈당"
        case .hbA1C: return "당화혈색소"
        case .waterIntake: return "수분 섭취"
        case .bodyTemperature: return "체온"
        case .oxygenSaturation: return "산소포화도"
        case .mood: return "기분"
        case .heartRate: return "심박수"
        case .steps: return "걸음수"
        case .sleep: return "수면"
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
        case .steps: return "걸음"
        case .sleep: return "시간"
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
        case .manual: return "수동 입력"
        case .healthKit: return "건강 앱"
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
        case .all: return "모든 알림"
        case .missedOnly: return "놓친 복약만"
        case .none: return "알림 없음"
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
        case .tablet: return "알약"
        case .capsule: return "캡슐"
        case .syrup: return "시럽"
        case .injection: return "주사"
        case .patch: return "패치"
        case .cream: return "크림/연고"
        case .inhaler: return "흡입기"
        case .drops: return "점안액/점이액"
        case .powder: return "가루약"
        case .other: return "기타"
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
        case .beforeMeal: return "식전"
        case .afterMeal: return "식후"
        case .withMeal: return "식사와 함께"
        case .anytime: return "식사와 무관"
        case .emptyStomach: return "공복"
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
        case .veryBad: return "매우 나쁨"
        case .bad: return "나쁨"
        case .neutral: return "보통"
        case .good: return "좋음"
        case .veryGood: return "매우 좋음"
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
        case .sunday: return "일"
        case .monday: return "월"
        case .tuesday: return "화"
        case .wednesday: return "수"
        case .thursday: return "목"
        case .friday: return "금"
        case .saturday: return "토"
        }
    }
    
    var fullName: String {
        switch self {
        case .sunday: return "일요일"
        case .monday: return "월요일"
        case .tuesday: return "화요일"
        case .wednesday: return "수요일"
        case .thursday: return "목요일"
        case .friday: return "금요일"
        case .saturday: return "토요일"
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
        case .morning: return "아침"
        case .afternoon: return "점심"
        case .evening: return "저녁"
        case .night: return "밤"
        case .bedtime: return "취침 전"
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
        case .fiveMinutes: return "5분"
        case .tenMinutes: return "10분"
        case .fifteenMinutes: return "15분"
        case .thirtyMinutes: return "30분"
        case .oneHour: return "1시간"
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
        case .week: return "1주"
        case .month: return "1개월"
        case .threeMonths: return "3개월"
        case .year: return "1년"
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
        case .white: return "흰색"
        case .yellow: return "노란색"
        case .orange: return "주황색"
        case .pink: return "분홍색"
        case .red: return "빨간색"
        case .brown: return "갈색"
        case .green: return "초록색"
        case .blue: return "파란색"
        case .purple: return "보라색"
        case .black: return "검정색"
        case .multicolor: return "여러색"
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
