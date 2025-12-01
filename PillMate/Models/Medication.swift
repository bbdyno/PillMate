//
//  Medication.swift
//  PillMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation
import SwiftData
import SwiftUI

/// 약물 정보를 저장하는 모델
@Model
final class Medication {
    // MARK: - 기본 식별자
    
    /// 고유 식별자
    var id: UUID = UUID()
    
    // MARK: - 약물 기본 정보
    
    /// 약 이름
    var name: String = ""
    
    /// 용량 (예: "1정", "5mL")
    var dosage: String = ""
    
    /// 강도 (예: "500mg", "10mg")
    var strength: String = ""
    
    /// 약물 형태 (알약, 캡슐, 시럽 등)
    var form: String = ""
    
    /// 약물 색상
    var color: String = ""
    
    // MARK: - 의료 정보
    
    /// 복용 목적/질환
    var purpose: String = ""
    
    /// 처방 의사
    var prescribingDoctor: String = ""
    
    /// 부작용
    var sideEffects: String = ""
    
    /// 주의사항
    var precautions: String = ""
    
    // MARK: - 재고 관리
    
    /// 현재 재고 수량
    var stockCount: Int = 0
    
    /// 재고 부족 알림 기준 (기본값 5)
    var lowStockThreshold: Int = 5
    
    // MARK: - 메타데이터
    
    /// 생성 일시
    var createdAt: Date = Date()
    
    /// 약 사진 데이터
    @Attribute(.externalStorage)
    var imageData: Data?
    
    /// 활성 상태 (현재 복용 중인지)
    var isActive: Bool = true
    
    /// 메모
    var notes: String?
    
    // MARK: - 관계
    
    /// 이 약물을 복용하는 환자 (nil이면 "본인")
    var patient: Patient?
    
    /// 복약 스케줄 목록
    @Relationship(deleteRule: .cascade)
    var schedules: [MedicationSchedule] = []
    
    /// 복약 기록 목록
    @Relationship(deleteRule: .cascade)
    var logs: [MedicationLog] = []
    
    // MARK: - 계산 속성
    
    /// 재고 부족 여부
    var isLowStock: Bool {
        stockCount <= lowStockThreshold
    }
    
    /// 재고 없음 여부
    var isOutOfStock: Bool {
        stockCount <= 0
    }
    
    /// 약물 형태 열거형
    var medicationForm: MedicationForm {
        MedicationForm(rawValue: form) ?? .other
    }
    
    /// 약물 색상 열거형
    var medicationColor: MedicationColor {
        MedicationColor(rawValue: color) ?? .white
    }
    
    /// 활성 스케줄 목록
    var activeSchedules: [MedicationSchedule] {
        schedules.filter { $0.isActive }
    }
    
    /// UIImage로 변환된 약물 이미지
    var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
    
    /// 오늘의 복약 준수율 (0.0 ~ 1.0)
    var todayAdherenceRate: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let todayLogs = logs.filter { log in
            log.scheduledTime >= today && log.scheduledTime < tomorrow
        }
        
        guard !todayLogs.isEmpty else { return 0.0 }
        
        let takenCount = todayLogs.filter { $0.status == LogStatus.taken.rawValue }.count
        return Double(takenCount) / Double(todayLogs.count)
    }
    
    /// 다음 복용 예정 시간
    var nextDoseTime: Date? {
        let now = Date()
        var nextTime: Date?
        
        for schedule in schedules where schedule.isActive {
            if let times = schedule.scheduledTimes {
                for time in times {
                    if time > now {
                        if nextTime == nil || time < nextTime! {
                            nextTime = time
                        }
                    }
                }
            }
        }
        
        return nextTime
    }
    
    // MARK: - 초기화
    
    /// 기본 초기화
    init(
        name: String,
        dosage: String = "",
        strength: String = "",
        form: MedicationForm = .tablet,
        color: MedicationColor = .white,
        purpose: String = "",
        prescribingDoctor: String = "",
        sideEffects: String = "",
        precautions: String = "",
        stockCount: Int = 0,
        lowStockThreshold: Int = 5,
        imageData: Data? = nil,
        isActive: Bool = true,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.dosage = dosage
        self.strength = strength
        self.form = form.rawValue
        self.color = color.rawValue
        self.purpose = purpose
        self.prescribingDoctor = prescribingDoctor
        self.sideEffects = sideEffects
        self.precautions = precautions
        self.stockCount = stockCount
        self.lowStockThreshold = lowStockThreshold
        self.createdAt = Date()
        self.imageData = imageData
        self.isActive = isActive
        self.notes = notes
    }
    
    // MARK: - 메서드
    
    /// 재고 감소
    func decreaseStock(by amount: Int = 1) {
        stockCount = max(0, stockCount - amount)
    }
    
    /// 재고 추가
    func increaseStock(by amount: Int) {
        stockCount += amount
    }
    
    /// 이미지 설정
    func setImage(_ image: UIImage, compressionQuality: CGFloat = 0.7) {
        imageData = image.jpegData(compressionQuality: compressionQuality)
    }
    
    /// 복약 준수율 계산 (특정 기간)
    func adherenceRate(from startDate: Date, to endDate: Date) -> Double {
        let periodLogs = logs.filter { log in
            log.scheduledTime >= startDate && log.scheduledTime <= endDate
        }
        
        guard !periodLogs.isEmpty else { return 0.0 }
        
        let takenCount = periodLogs.filter { $0.status == LogStatus.taken.rawValue }.count
        return Double(takenCount) / Double(periodLogs.count)
    }
    
    /// 연속 복용 일수 계산
    func consecutiveDays() -> Int {
        let calendar = Calendar.current
        let sortedLogs = logs
            .filter { $0.status == LogStatus.taken.rawValue }
            .sorted { $0.scheduledTime > $1.scheduledTime }
        
        guard !sortedLogs.isEmpty else { return 0 }
        
        var consecutiveCount = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        let logDates = Set(sortedLogs.map { calendar.startOfDay(for: $0.scheduledTime) })
        
        while logDates.contains(currentDate) {
            consecutiveCount += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }
        
        return consecutiveCount
    }
}

// MARK: - 샘플 데이터
extension Medication {
    /// 미리보기용 샘플 데이터
    static var preview: Medication {
        Medication(
            name: "아스피린",
            dosage: "1정",
            strength: "100mg",
            form: .tablet,
            color: .white,
            purpose: "심장 건강",
            prescribingDoctor: "김의사",
            sideEffects: "위장 장애, 출혈 위험",
            precautions: "공복 복용 금지",
            stockCount: 28,
            lowStockThreshold: 7
        )
    }
    
    /// 샘플 데이터 배열
    static var sampleData: [Medication] {
        [
            Medication(
                name: "아스피린",
                dosage: "1정",
                strength: "100mg",
                form: .tablet,
                color: .white,
                purpose: "심장 건강",
                stockCount: 28
            ),
            Medication(
                name: "메트포르민",
                dosage: "1정",
                strength: "500mg",
                form: .tablet,
                color: .white,
                purpose: "당뇨병 관리",
                stockCount: 60
            ),
            Medication(
                name: "리시노프릴",
                dosage: "1정",
                strength: "10mg",
                form: .tablet,
                color: .pink,
                purpose: "고혈압 치료",
                stockCount: 3
            ),
            Medication(
                name: "오메프라졸",
                dosage: "1캡슐",
                strength: "20mg",
                form: .capsule,
                color: .purple,
                purpose: "위산 역류 치료",
                stockCount: 14
            )
        ]
    }
}
