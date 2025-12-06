//
//  Appointment.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation
import SwiftData
import SwiftUI

/// 진료 예약을 저장하는 모델
@Model
final class Appointment {
    // MARK: - 기본 식별자
    
    /// 고유 식별자
    var id: UUID = UUID()
    
    // MARK: - 진료 정보
    
    /// 의사 이름
    var doctorName: String = ""
    
    /// 진료과
    var specialty: String?
    
    /// 예약 일시
    var appointmentDate: Date = Date()
    
    /// 장소
    var location: String?
    
    /// 메모
    var notes: String?
    
    // MARK: - 관계
    
    /// 이 예약의 환자 (nil이면 "본인")
    var patient: Patient?
    
    // MARK: - 메타데이터
    
    /// 생성 일시
    var createdAt: Date = Date()
    
    /// 알림 설정 여부
    var notificationEnabled: Bool = true
    
    /// 알림 시간 (예약 전 분 단위)
    var notificationMinutesBefore: Int = 60
    
    /// 완료 여부
    var isCompleted: Bool = false
    
    // MARK: - 계산 속성
    
    /// 예약까지 남은 시간
    var timeUntilAppointment: TimeInterval {
        appointmentDate.timeIntervalSinceNow
    }
    
    /// 예정된 예약인지 (아직 지나지 않음)
    var isUpcoming: Bool {
        appointmentDate > Date() && !isCompleted
    }
    
    /// 지난 예약인지
    var isPast: Bool {
        appointmentDate <= Date() || isCompleted
    }
    
    /// 오늘 예약인지
    var isToday: Bool {
        Calendar.current.isDateInToday(appointmentDate)
    }
    
    /// 이번 주 예약인지
    var isThisWeek: Bool {
        Calendar.current.isDate(appointmentDate, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// 남은 시간 텍스트
    var timeRemainingText: String? {
        guard isUpcoming else { return nil }
        
        let seconds = timeUntilAppointment
        
        if seconds < 3600 {
            return "\(Int(seconds / 60))분 후"
        } else if seconds < 86400 {
            return "\(Int(seconds / 3600))시간 후"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)일 후"
        }
    }
    
    /// 표시용 날짜 텍스트
    var dateDisplayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        
        if isToday {
            formatter.dateFormat = "오늘 a h:mm"
        } else if Calendar.current.isDateInTomorrow(appointmentDate) {
            formatter.dateFormat = "내일 a h:mm"
        } else if isThisWeek {
            formatter.dateFormat = "EEEE a h:mm"
        } else {
            formatter.dateFormat = "M월 d일 (E) a h:mm"
        }
        
        return formatter.string(from: appointmentDate)
    }
    
    // MARK: - 초기화
    
    init(
        doctorName: String,
        specialty: String? = nil,
        appointmentDate: Date,
        location: String? = nil,
        notes: String? = nil,
        notificationEnabled: Bool = true,
        notificationMinutesBefore: Int = 60,
        isCompleted: Bool = false
    ) {
        self.id = UUID()
        self.doctorName = doctorName
        self.specialty = specialty
        self.appointmentDate = appointmentDate
        self.location = location
        self.notes = notes
        self.createdAt = Date()
        self.notificationEnabled = notificationEnabled
        self.notificationMinutesBefore = notificationMinutesBefore
        self.isCompleted = isCompleted
    }
    
    // MARK: - 메서드
    
    /// 완료 처리
    func markAsCompleted() {
        isCompleted = true
    }
}

// MARK: - 샘플 데이터
extension Appointment {
    /// 미리보기용 샘플 데이터
    static var preview: Appointment {
        Appointment(
            doctorName: "김의사",
            specialty: "내과",
            appointmentDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            location: "서울대학교병원 본관 3층",
            notes: "혈액 검사 결과 확인"
        )
    }
    
    /// 오늘 예약 샘플
    static var todayPreview: Appointment {
        Appointment(
            doctorName: "박의사",
            specialty: "심장내과",
            appointmentDate: Calendar.current.date(byAdding: .hour, value: 3, to: Date())!,
            location: "세브란스병원"
        )
    }
    
    /// 샘플 데이터 배열
    static var sampleData: [Appointment] {
        let calendar = Calendar.current
        
        return [
            Appointment(
                doctorName: "김의사",
                specialty: "내과",
                appointmentDate: calendar.date(byAdding: .hour, value: 3, to: Date())!,
                location: "서울아산병원",
                notes: "정기 검진"
            ),
            Appointment(
                doctorName: "이의사",
                specialty: "심장내과",
                appointmentDate: calendar.date(byAdding: .day, value: 5, to: Date())!,
                location: "삼성서울병원"
            ),
            Appointment(
                doctorName: "박의사",
                specialty: "피부과",
                appointmentDate: calendar.date(byAdding: .day, value: -2, to: Date())!,
                isCompleted: true
            )
        ]
    }
}
