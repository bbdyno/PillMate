//
//  MedicationLog.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation
import SwiftData
import SwiftUI
import DMateResource

/// 복약 기록을 저장하는 모델
@Model
final class MedicationLog {
    // MARK: - 기본 식별자
    
    /// 고유 식별자
    var id: UUID = UUID()
    
    // MARK: - 관계
    
    /// 연관된 약물
    var medication: Medication?
    
    /// 연관된 스케줄
    var schedule: MedicationSchedule?

    /// 복약 후 기록된 건강 지표들
    @Relationship(deleteRule: .nullify)
    var healthMetrics: [HealthMetric] = []

    // MARK: - 시간 정보
    
    /// 예정 시간
    var scheduledTime: Date = Date()
    
    /// 실제 복용 시간
    var actualTime: Date?
    
    // MARK: - 상태
    
    /// 복용 상태 (복용완료, 건너뜀, 지연, 미루기, 대기중)
    var status: String = ""
    
    // MARK: - 메타데이터
    
    /// 메모
    var notes: String?
    
    /// 생성 일시
    var createdAt: Date = Date()
    
    /// 스누즈 횟수
    var snoozeCount: Int = 0
    
    /// 마지막 스누즈 시간
    var lastSnoozeTime: Date?
    
    /// HealthKit에 동기화 여부
    var syncedToHealthKit: Bool = false
    
    // MARK: - 계산 속성
    
    /// 복용 상태 열거형
    var logStatus: LogStatus {
        get { LogStatus(rawValue: status) ?? .pending }
        set { status = newValue.rawValue }
    }
    
    /// 지연 여부
    var isDelayed: Bool {
        guard let actualTime = actualTime else { return false }
        let delayThreshold: TimeInterval = 30 * 60 // 30분
        return actualTime.timeIntervalSince(scheduledTime) > delayThreshold
    }
    
    /// 복용까지 걸린 시간 (분)
    var minutesDelayed: Int? {
        guard let actualTime = actualTime else { return nil }
        let seconds = actualTime.timeIntervalSince(scheduledTime)
        return Int(seconds / 60)
    }
    
    /// 상태 색상
    var statusColor: Color {
        logStatus.color
    }
    
    /// 상태 아이콘
    var statusIcon: String {
        logStatus.icon
    }
    
    /// 표시용 시간 텍스트
    var timeDisplayText: String {
        let formatter = DateFormatter.shortTime
        var text = formatter.string(from: scheduledTime)
        
        if let actual = actualTime, logStatus == .taken {
            text += " → \(formatter.string(from: actual))"
        }
        
        return text
    }
    
    /// 예정 시간 경과 여부
    var isPastDue: Bool {
        logStatus == .pending && scheduledTime < Date()
    }
    
    /// 남은 시간 (초)
    var secondsUntilDue: TimeInterval? {
        guard logStatus == .pending else { return nil }
        return scheduledTime.timeIntervalSinceNow
    }
    
    /// 남은 시간 텍스트
    var timeRemainingText: String? {
        guard let seconds = secondsUntilDue else { return nil }

        if seconds < 0 {
            let overdue = abs(seconds)
            if overdue < 60 {
                return DMateResourceStrings.Time.now
            } else if overdue < 3600 {
                return DMateResourceStrings.Time.minutesOverdue(Int(overdue / 60))
            } else {
                return DMateResourceStrings.Time.hoursOverdue(Int(overdue / 3600))
            }
        } else {
            if seconds < 60 {
                return DMateResourceStrings.Time.shortly
            } else if seconds < 3600 {
                return DMateResourceStrings.Time.minutesRemaining(Int(seconds / 60))
            } else {
                return DMateResourceStrings.Time.hoursRemaining(Int(seconds / 3600))
            }
        }
    }
    
    // MARK: - 초기화
    
    init(
        scheduledTime: Date,
        actualTime: Date? = nil,
        status: LogStatus = .pending,
        notes: String? = nil,
        snoozeCount: Int = 0,
        lastSnoozeTime: Date? = nil,
        syncedToHealthKit: Bool = false
    ) {
        self.id = UUID()
        self.scheduledTime = scheduledTime
        self.actualTime = actualTime
        self.status = status.rawValue
        self.notes = notes
        self.createdAt = Date()
        self.snoozeCount = snoozeCount
        self.lastSnoozeTime = lastSnoozeTime
        self.syncedToHealthKit = syncedToHealthKit
    }
    
    // MARK: - 메서드
    
    /// 복용 완료 처리
    func markAsTaken(at time: Date = Date(), notes: String? = nil) {
        actualTime = time
        logStatus = isDelayed ? .delayed : .taken
        if let notes = notes {
            self.notes = notes
        }
        
        // 재고 감소
        medication?.decreaseStock()
    }
    
    /// 건너뛰기 처리
    func markAsSkipped(reason: String? = nil) {
        logStatus = .skipped
        actualTime = Date()
        if let reason = reason {
            notes = reason
        }
    }
    
    /// 스누즈 처리
    func snooze(minutes: Int) {
        logStatus = .snoozed
        snoozeCount += 1
        lastSnoozeTime = Date()
        
        // 새로운 예정 시간 설정
        if let newTime = Calendar.current.date(byAdding: .minute, value: minutes, to: Date()) {
            scheduledTime = newTime
        }
    }
    
    /// 대기 상태로 리셋
    func resetToPending() {
        logStatus = .pending
        actualTime = nil
    }
    
    /// HealthKit 동기화 완료 표시
    func markSyncedToHealthKit() {
        syncedToHealthKit = true
    }
}

// MARK: - 샘플 데이터
extension MedicationLog {
    /// 미리보기용 샘플 데이터
    static var preview: MedicationLog {
        MedicationLog(
            scheduledTime: Date(),
            status: .pending
        )
    }
    
    /// 완료된 로그 샘플
    static var takenPreview: MedicationLog {
        let log = MedicationLog(
            scheduledTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
            actualTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
            status: .taken
        )
        return log
    }
    
    /// 건너뛴 로그 샘플
    static var skippedPreview: MedicationLog {
        MedicationLog(
            scheduledTime: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!,
            status: .skipped,
            notes: "부작용으로 인해 건너뜀"
        )
    }
    
    /// 오늘의 샘플 로그들
    static var todaySamples: [MedicationLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return [
            MedicationLog(
                scheduledTime: calendar.date(byAdding: .hour, value: 8, to: today)!,
                actualTime: calendar.date(byAdding: DateComponents(hour: 8, minute: 5), to: today)!,
                status: .taken
            ),
            MedicationLog(
                scheduledTime: calendar.date(byAdding: .hour, value: 12, to: today)!,
                status: .pending
            ),
            MedicationLog(
                scheduledTime: calendar.date(byAdding: .hour, value: 18, to: today)!,
                status: .pending
            )
        ]
    }
}
