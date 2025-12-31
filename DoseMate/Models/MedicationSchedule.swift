//
//  MedicationSchedule.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation
import SwiftData
import DMateResource

/// 복약 스케줄을 저장하는 모델
@Model
final class MedicationSchedule {
    // MARK: - 기본 식별자
    
    /// 고유 식별자
    var id: UUID = UUID()
    
    // MARK: - 관계
    
    /// 연관된 약물
    var medication: Medication?
    
    // MARK: - 스케줄 설정
    
    /// 스케줄 타입 (매일, 특정 요일, 필요시, 맞춤)
    var scheduleType: String = ""
    
    /// 복용 빈도 (하루 1회, 2회, 3회 등)
    var frequency: String = ""
    
    /// 복용 시간들 (JSON으로 저장)
    var timesData: Data?
    
    /// 특정 요일 (0=일요일, 1=월요일..., JSON으로 저장)
    var specificDaysData: Data?
    
    // MARK: - 기간 설정
    
    /// 시작일
    var startDate: Date = Date()
    
    /// 종료일 (nil이면 무기한)
    var endDate: Date?
    
    // MARK: - 감량 스케줄
    
    /// 감량 스케줄 여부
    var isTapering: Bool = false
    
    /// 감량 계획 설명
    var taperingPlan: String?
    
    // MARK: - 맞춤 설정
    
    /// 간격 일수 (N일마다 복용)
    var intervalDays: Int = 1
    
    /// 맞춤 주기 설명
    var customFrequency: String?
    
    /// 식사 관계
    var mealRelation: String = ""
    
    /// 활성 상태
    var isActive: Bool = true
    
    // MARK: - 알림 설정
    
    /// 알림 활성화 여부
    var notificationEnabled: Bool = true
    
    /// 알림 미리 알림 시간 (분 단위)
    var reminderMinutesBefore: Int = 0
    
    // MARK: - 메타데이터
    
    /// 생성 일시
    var createdAt: Date = Date()
    
    /// 수정 일시
    var updatedAt: Date = Date()
    
    /// 메모
    var notes: String?
    
    // MARK: - 계산 속성
    
    /// 스케줄 타입 열거형
    var scheduleTypeEnum: ScheduleType {
        get { ScheduleType(rawValue: scheduleType) ?? .daily }
        set { scheduleType = newValue.rawValue }
    }
    
    /// 복용 빈도 열거형
    var frequencyEnum: Frequency {
        get { Frequency(rawValue: frequency) ?? .onceDaily }
        set { frequency = newValue.rawValue }
    }
    
    /// 식사 관계 열거형
    var mealRelationEnum: MealRelation {
        get { MealRelation(rawValue: mealRelation) ?? .anytime }
        set { mealRelation = newValue.rawValue }
    }
    
    /// 복용 시간 배열
    var times: [Date] {
        get {
            guard let data = timesData else { return [] }
            return (try? JSONDecoder().decode([Date].self, from: data)) ?? []
        }
        set {
            timesData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// 특정 요일 배열
    var specificDays: [Int]? {
        get {
            guard let data = specificDaysData else { return nil }
            return try? JSONDecoder().decode([Int].self, from: data)
        }
        set {
            specificDaysData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// 오늘의 예정 시간들
    var scheduledTimes: [Date]? {
        guard isActive else { return nil }
        
        let calendar = Calendar.current
        let today = Date()
        
        // 시작일 이전이면 nil
        if today < startDate { return nil }
        
        // 종료일 이후면 nil
        if let endDate = endDate, today > endDate { return nil }
        
        // 간격 설정 체크
        if scheduleTypeEnum == .interval {
            let daysSinceStart = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: today)).day ?? 0
            
            // intervalDays로 나누어떨어지지 않으면 오늘은 복용일이 아님
            if daysSinceStart % intervalDays != 0 {
                return nil
            }
        }
        
        // 특정 요일 체크
        if scheduleTypeEnum == .specificDays {
            let todayWeekday = calendar.component(.weekday, from: today) - 1 // 0-based
            guard let days = specificDays, days.contains(todayWeekday) else {
                return nil
            }
        }
        
        // 필요시 복용은 예정 시간이 없음
        if scheduleTypeEnum == .asNeeded {
            return nil
        }
        
        // 시간들을 오늘 날짜로 변환
        return times.compactMap { time in
            var components = calendar.dateComponents([.hour, .minute], from: time)
            let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
            components.year = todayComponents.year
            components.month = todayComponents.month
            components.day = todayComponents.day
            return calendar.date(from: components)
        }.sorted()
    }
    
    /// 다음 복용 시간
    var nextScheduledTime: Date? {
        guard let times = scheduledTimes else { return nil }
        
        let now = Date()
        return times.first { $0 > now }
    }
    
    /// 스케줄 설명 텍스트
    var descriptionText: String {
        var description = ""
        
        switch scheduleTypeEnum {
        case .daily:
            description = DMateResourceStrings.ScheduleFrequency.daily
        case .specificDays:
            if let days = specificDays {
                let dayNames = days.map { Weekday(rawValue: $0)?.shortName ?? "" }.joined(separator: ", ")
                description = dayNames
            }
        case .interval:
            if intervalDays == 1 {
                description = DMateResourceStrings.ScheduleFrequency.daily
            } else if intervalDays == 7 {
                description = DMateResourceStrings.ScheduleFrequency.weekly
            } else if intervalDays == 14 {
                description = DMateResourceStrings.ScheduleFrequency.biweekly
            } else if intervalDays == 30 {
                description = DMateResourceStrings.ScheduleFrequency.monthly
            } else {
                description = "\(intervalDays)일마다"
            }
        case .asNeeded:
            description = DMateResourceStrings.ScheduleFrequency.asNeeded
        }
        
        let timesText = times.map { DateFormatter.shortTime.string(from: $0) }.joined(separator: ", ")
        if !timesText.isEmpty {
            description += " \(timesText)"
        }
        
        return description
    }
    
    /// 요일 이름 배열
    var dayNames: [String] {
        specificDays?.compactMap { Weekday(rawValue: $0)?.shortName } ?? []
    }
    
    // MARK: - 초기화
    
    init(
        scheduleType: ScheduleType = .daily,
        frequency: Frequency = .onceDaily,
        times: [Date] = [],
        specificDays: [Int]? = nil,
        intervalDays: Int = 1,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isTapering: Bool = false,
        taperingPlan: String? = nil,
        customFrequency: String? = nil,
        mealRelation: MealRelation = .anytime,
        isActive: Bool = true,
        notificationEnabled: Bool = true,
        reminderMinutesBefore: Int = 0,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.scheduleType = scheduleType.rawValue
        self.frequency = frequency.rawValue
        self.timesData = try? JSONEncoder().encode(times)
        self.specificDaysData = try? JSONEncoder().encode(specificDays)
        self.intervalDays = intervalDays
        self.startDate = startDate
        self.endDate = endDate
        self.isTapering = isTapering
        self.taperingPlan = taperingPlan
        self.customFrequency = customFrequency
        self.mealRelation = mealRelation.rawValue
        self.isActive = isActive
        self.notificationEnabled = notificationEnabled
        self.reminderMinutesBefore = reminderMinutesBefore
        self.createdAt = Date()
        self.updatedAt = Date()
        self.notes = notes
    }
    
    // MARK: - 메서드
    
    /// 스케줄 업데이트
    func update() {
        updatedAt = Date()
    }
    
    /// 특정 날짜의 예정 시간들 반환
    func scheduledTimes(for date: Date) -> [Date]? {
        guard isActive else { return nil }
        
        let calendar = Calendar.current
        
        // 시작일 이전이면 nil
        if date < startDate { return nil }
        
        // 종료일 이후면 nil
        if let endDate = endDate, date > endDate { return nil }
        
        // 간격 설정 체크
        if scheduleTypeEnum == .interval {
            let daysSinceStart = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: date)).day ?? 0
            
            // intervalDays로 나누어떨어지지 않으면 해당 날짜는 복용일이 아님
            if daysSinceStart % intervalDays != 0 {
                return nil
            }
        }
        
        // 특정 요일 체크
        if scheduleTypeEnum == .specificDays {
            let weekday = calendar.component(.weekday, from: date) - 1
            guard let days = specificDays, days.contains(weekday) else {
                return nil
            }
        }
        
        // 필요시 복용은 예정 시간이 없음
        if scheduleTypeEnum == .asNeeded {
            return nil
        }
        
        // 시간들을 해당 날짜로 변환
        return times.compactMap { time in
            var components = calendar.dateComponents([.hour, .minute], from: time)
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            components.year = dateComponents.year
            components.month = dateComponents.month
            components.day = dateComponents.day
            return calendar.date(from: components)
        }.sorted()
    }
    
    /// 다음 7일 일정 미리보기
    func previewNextSevenDays() -> [(date: Date, times: [Date])] {
        var preview: [(date: Date, times: [Date])] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today),
                  let times = scheduledTimes(for: date), !times.isEmpty else {
                continue
            }
            preview.append((date: date, times: times))
        }
        
        return preview
    }
    
    /// 시간 추가
    func addTime(_ time: Date) {
        var currentTimes = times
        currentTimes.append(time)
        times = currentTimes.sorted()
        update()
    }
    
    /// 시간 제거
    func removeTime(at index: Int) {
        var currentTimes = times
        guard index < currentTimes.count else { return }
        currentTimes.remove(at: index)
        times = currentTimes
        update()
    }
    
    /// 요일 토글
    func toggleDay(_ weekday: Int) {
        var currentDays = specificDays ?? []
        if currentDays.contains(weekday) {
            currentDays.removeAll { $0 == weekday }
        } else {
            currentDays.append(weekday)
            currentDays.sort()
        }
        specificDays = currentDays.isEmpty ? nil : currentDays
        update()
    }
    
    /// 빈도에 따른 기본 시간 설정
    func setDefaultTimes(for frequency: Frequency) {
        var defaultTimes: [Date] = []
        
        switch frequency {
        case .onceDaily:
            defaultTimes = [createTime(hour: 8, minute: 0)]
        case .twiceDaily:
            defaultTimes = [
                createTime(hour: 8, minute: 0),
                createTime(hour: 20, minute: 0)
            ]
        case .threeTimesDaily:
            defaultTimes = [
                createTime(hour: 8, minute: 0),
                createTime(hour: 13, minute: 0),
                createTime(hour: 20, minute: 0)
            ]
        case .fourTimesDaily:
            defaultTimes = [
                createTime(hour: 8, minute: 0),
                createTime(hour: 12, minute: 0),
                createTime(hour: 18, minute: 0),
                createTime(hour: 22, minute: 0)
            ]
        case .custom:
            break
        }
        
        times = defaultTimes
        update()
    }
    
    /// 시간 생성 헬퍼
    private func createTime(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? Date()
    }
}

// MARK: - 샘플 데이터
extension MedicationSchedule {
    /// 미리보기용 샘플 데이터
    static var preview: MedicationSchedule {
        let schedule = MedicationSchedule(
            scheduleType: .daily,
            frequency: .twiceDaily,
            startDate: Date()
        )
        schedule.setDefaultTimes(for: .twiceDaily)
        return schedule
    }
    
    /// 특정 요일 샘플
    static var specificDaysPreview: MedicationSchedule {
        let schedule = MedicationSchedule(
            scheduleType: .specificDays,
            frequency: .onceDaily,
            specificDays: [1, 3, 5], // 월, 수, 금
            startDate: Date()
        )
        schedule.setDefaultTimes(for: .onceDaily)
        return schedule
    }
}
