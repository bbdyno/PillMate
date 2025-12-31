//
//  HealthMetric.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation
import SwiftData
import SwiftUI
import DMateResource

/// 건강 지표를 저장하는 모델
@Model
final class HealthMetric {
    // MARK: - 기본 식별자
    
    /// 고유 식별자
    var id: UUID = UUID()
    
    // MARK: - 지표 정보
    
    /// 지표 타입
    var type: String = ""
    
    /// 값 (단일 값)
    var value: Double = 0
    
    /// 수축기 혈압 (혈압 타입일 때만 사용)
    var systolicValue: Double?
    
    /// 이완기 혈압 (혈압 타입일 때만 사용)
    var diastolicValue: Double?
    
    /// 단위
    var unit: String = ""
    
    // MARK: - 메타데이터
    
    /// 측정 일시
    var recordedAt: Date = Date()
    
    /// 메모
    var notes: String?
    
    /// 데이터 소스 (수동입력, HealthKit)
    var source: String = ""
    
    /// HealthKit 샘플 UUID (중복 방지용)
    var healthKitUUID: String?

    // MARK: - 관계

    /// 연관된 약물 (이 지표가 특정 약물과 관련있는 경우)
    var medication: Medication?

    // MARK: - 계산 속성
    
    /// 지표 타입 열거형
    var metricType: MetricType {
        get { MetricType(rawValue: type) ?? .weight }
        set { type = newValue.rawValue }
    }
    
    /// 데이터 소스 열거형
    var dataSource: DataSource {
        get { DataSource(rawValue: source) ?? .manual }
        set { source = newValue.rawValue }
    }
    
    /// 표시용 값 텍스트
    var displayValue: String {
        switch metricType {
        case .bloodPressure:
            if let sys = systolicValue, let dia = diastolicValue {
                return "\(Int(sys))/\(Int(dia))"
            }
            return "-"
        case .weight, .bloodGlucose, .hbA1C, .bodyTemperature:
            return String(format: "%.1f", value)
        case .oxygenSaturation:
            return String(format: "%.0f", value)
        case .waterIntake:
            return String(format: "%.0f", value)
        case .heartRate:
            return String(format: "%.0f", value)
        case .steps:
            return String(format: "%.0f", value)
        case .sleep:
            let hours = Int(value)
            let minutes = Int((value - Double(hours)) * 60)
            return "\(hours)시간 \(minutes)분"
        case .mood:
            return MoodLevel(rawValue: Int(value))?.emoji ?? "😐"
        }
    }
    
    /// 전체 표시 텍스트 (값 + 단위)
    var fullDisplayText: String {
        "\(displayValue) \(unit)"
    }
    
    /// 색상
    var color: Color {
        metricType.color
    }
    
    /// 아이콘
    var icon: String {
        metricType.icon
    }
    
    /// 혈압 상태 (혈압 타입일 때만)
    var bloodPressureStatus: BloodPressureStatus? {
        guard metricType == .bloodPressure,
              let sys = systolicValue,
              let dia = diastolicValue else { return nil }
        
        return BloodPressureStatus.status(systolic: sys, diastolic: dia)
    }
    
    /// 혈당 상태 (혈당 타입일 때만)
    var bloodGlucoseStatus: BloodGlucoseStatus? {
        guard metricType == .bloodGlucose else { return nil }
        return BloodGlucoseStatus.status(value: value)
    }
    
    // MARK: - 초기화
    
    /// 기본 초기화
    init(
        type: MetricType,
        value: Double,
        systolicValue: Double? = nil,
        diastolicValue: Double? = nil,
        unit: String? = nil,
        recordedAt: Date = Date(),
        notes: String? = nil,
        source: DataSource = .manual,
        healthKitUUID: String? = nil
    ) {
        self.id = UUID()
        self.type = type.rawValue
        self.value = value
        self.systolicValue = systolicValue
        self.diastolicValue = diastolicValue
        self.unit = unit ?? type.unit
        self.recordedAt = recordedAt
        self.notes = notes
        self.source = source.rawValue
        self.healthKitUUID = healthKitUUID
    }
    
    /// 혈압 초기화
    convenience init(
        bloodPressure systolic: Double,
        diastolic: Double,
        recordedAt: Date = Date(),
        notes: String? = nil,
        source: DataSource = .manual
    ) {
        self.init(
            type: .bloodPressure,
            value: systolic, // 주 값으로 수축기 사용
            systolicValue: systolic,
            diastolicValue: diastolic,
            recordedAt: recordedAt,
            notes: notes,
            source: source
        )
    }
    
    /// 기분 초기화
    convenience init(
        mood: MoodLevel,
        recordedAt: Date = Date(),
        notes: String? = nil
    ) {
        self.init(
            type: .mood,
            value: Double(mood.rawValue),
            recordedAt: recordedAt,
            notes: notes,
            source: .manual
        )
    }
}

// MARK: - 혈압 상태
enum BloodPressureStatus: String {
    case normal = "정상"
    case elevated = "주의"
    case highStage1 = "1기 고혈압"
    case highStage2 = "2기 고혈압"
    case crisis = "고혈압 위기"
    case low = "저혈압"
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .elevated: return .yellow
        case .highStage1: return .orange
        case .highStage2: return .red
        case .crisis: return .purple
        case .low: return .blue
        }
    }

    var displayName: String {
        switch self {
        case .normal: return DMateResourceStrings.BloodPressureStatus.normal
        case .elevated: return DMateResourceStrings.BloodPressureStatus.elevated
        case .highStage1: return DMateResourceStrings.BloodPressureStatus.stage1
        case .highStage2: return DMateResourceStrings.BloodPressureStatus.stage2
        case .crisis: return DMateResourceStrings.BloodPressureStatus.crisis
        case .low: return DMateResourceStrings.BloodPressureStatus.low
        }
    }

    static func status(systolic: Double, diastolic: Double) -> BloodPressureStatus {
        if systolic < 90 || diastolic < 60 {
            return .low
        } else if systolic >= 180 || diastolic >= 120 {
            return .crisis
        } else if systolic >= 140 || diastolic >= 90 {
            return .highStage2
        } else if systolic >= 130 || diastolic >= 80 {
            return .highStage1
        } else if systolic >= 120 && diastolic < 80 {
            return .elevated
        } else {
            return .normal
        }
    }
}

// MARK: - 혈당 상태
enum BloodGlucoseStatus: String {
    case low = "저혈당"
    case normal = "정상"
    case prediabetes = "전당뇨"
    case diabetes = "당뇨"
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .normal: return .green
        case .prediabetes: return .orange
        case .diabetes: return .red
        }
    }

    var displayName: String {
        switch self {
        case .low: return DMateResourceStrings.BloodGlucoseStatus.low
        case .normal: return DMateResourceStrings.BloodGlucoseStatus.normal
        case .prediabetes: return DMateResourceStrings.BloodGlucoseStatus.prediabetes
        case .diabetes: return DMateResourceStrings.BloodGlucoseStatus.diabetes
        }
    }

    // 공복 혈당 기준
    static func status(value: Double) -> BloodGlucoseStatus {
        if value < 70 {
            return .low
        } else if value < 100 {
            return .normal
        } else if value < 126 {
            return .prediabetes
        } else {
            return .diabetes
        }
    }
}

// MARK: - 샘플 데이터
extension HealthMetric {
    /// 미리보기용 샘플 데이터
    static var preview: HealthMetric {
        HealthMetric(
            type: .weight,
            value: 70.5,
            recordedAt: Date()
        )
    }
    
    /// 혈압 샘플
    static var bloodPressurePreview: HealthMetric {
        HealthMetric(
            bloodPressure: 120,
            diastolic: 80
        )
    }
    
    /// 혈당 샘플
    static var bloodGlucosePreview: HealthMetric {
        HealthMetric(
            type: .bloodGlucose,
            value: 95
        )
    }
    
    /// 샘플 데이터 배열
    static var sampleData: [HealthMetric] {
        let calendar = Calendar.current
        var samples: [HealthMetric] = []
        
        // 최근 7일 체중 데이터
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -day, to: Date()) {
                samples.append(HealthMetric(
                    type: .weight,
                    value: 70.0 + Double.random(in: -1...1),
                    recordedAt: date
                ))
            }
        }
        
        // 최근 7일 혈압 데이터
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -day, to: Date()) {
                samples.append(HealthMetric(
                    bloodPressure: 115 + Double.random(in: -10...15),
                    diastolic: 75 + Double.random(in: -5...10),
                    recordedAt: date
                ))
            }
        }
        
        // 오늘의 걸음수
        samples.append(HealthMetric(
            type: .steps,
            value: Double(Int.random(in: 5000...12000)),
            recordedAt: Date(),
            source: .healthKit
        ))
        
        // 오늘의 심박수
        samples.append(HealthMetric(
            type: .heartRate,
            value: Double(Int.random(in: 60...80)),
            recordedAt: Date(),
            source: .healthKit
        ))
        
        return samples
    }
}
