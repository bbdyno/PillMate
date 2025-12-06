//
//  Caregiver.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation
import SwiftData
import SwiftUI

/// 보호자 정보를 저장하는 모델
@Model
final class Caregiver {
    // MARK: - 기본 식별자
    
    /// 고유 식별자
    var id: UUID = UUID()
    
    // MARK: - 기본 정보
    
    /// 보호자 이름
    var name: String = ""
    
    /// 관계 (가족, 친구, 간병인 등)
    var relationship: String = ""
    
    /// 전화번호
    var phoneNumber: String = ""
    
    /// 이메일
    var email: String?
    
    // MARK: - 알림 설정
    
    /// 놓친 복약 시 알림 여부
    var shouldNotifyOnMissedDose: Bool = true
    
    /// 알림 설정 (모든 알림, 놓친 복약만, 없음)
    var notificationPreferences: String = ""
    
    /// 알림 지연 시간 (분) - 복용 예정 시간으로부터 몇 분 후 알림
    var notificationDelayMinutes: Int = 30
    
    // MARK: - 메타데이터
    
    /// 생성 일시
    var createdAt: Date = Date()
    
    /// 활성 상태
    var isActive: Bool = true
    
    /// 마지막 알림 발송 시간
    var lastNotifiedAt: Date?
    
    // MARK: - 계산 속성
    
    /// 알림 설정 열거형
    var notificationPreference: NotificationPreference {
        get { NotificationPreference(rawValue: notificationPreferences) ?? .missedOnly }
        set { notificationPreferences = newValue.rawValue }
    }
    
    /// 표시용 전화번호 (포맷팅)
    var formattedPhoneNumber: String {
        // 한국 전화번호 포맷팅
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if cleaned.count == 11 && cleaned.hasPrefix("010") {
            let index1 = cleaned.index(cleaned.startIndex, offsetBy: 3)
            let index2 = cleaned.index(cleaned.startIndex, offsetBy: 7)
            return "\(cleaned[..<index1])-\(cleaned[index1..<index2])-\(cleaned[index2...])"
        }
        
        return phoneNumber
    }
    
    /// 이니셜
    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    /// 전화 URL
    var phoneURL: URL? {
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return URL(string: "tel:\(cleaned)")
    }
    
    /// SMS URL
    var smsURL: URL? {
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return URL(string: "sms:\(cleaned)")
    }
    
    /// 이메일 URL
    var emailURL: URL? {
        guard let email = email else { return nil }
        return URL(string: "mailto:\(email)")
    }
    
    // MARK: - 초기화
    
    init(
        name: String,
        relationship: String,
        phoneNumber: String,
        email: String? = nil,
        shouldNotifyOnMissedDose: Bool = true,
        notificationPreference: NotificationPreference = .missedOnly,
        notificationDelayMinutes: Int = 30,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.relationship = relationship
        self.phoneNumber = phoneNumber
        self.email = email
        self.shouldNotifyOnMissedDose = shouldNotifyOnMissedDose
        self.notificationPreferences = notificationPreference.rawValue
        self.notificationDelayMinutes = notificationDelayMinutes
        self.createdAt = Date()
        self.isActive = isActive
    }
    
    // MARK: - 메서드
    
    /// 알림 발송 기록
    func recordNotification() {
        lastNotifiedAt = Date()
    }
    
    /// 알림 필요 여부 확인
    func shouldSendNotification(for missedTime: Date) -> Bool {
        guard isActive && shouldNotifyOnMissedDose else { return false }
        
        switch notificationPreference {
        case .none:
            return false
        case .missedOnly, .all:
            // 지연 시간 체크
            let delayedTime = missedTime.addingTimeInterval(TimeInterval(notificationDelayMinutes * 60))
            return Date() >= delayedTime
        }
    }
    
    /// 비활성화
    func deactivate() {
        isActive = false
    }
    
    /// 활성화
    func activate() {
        isActive = true
    }
}

// MARK: - 샘플 데이터
extension Caregiver {
    /// 미리보기용 샘플 데이터
    static var preview: Caregiver {
        Caregiver(
            name: "홍길동",
            relationship: CaregiverRelationship.spouse.rawValue,
            phoneNumber: "010-1234-5678",
            email: "family@example.com",
            shouldNotifyOnMissedDose: true
        )
    }
    
    /// 샘플 데이터 배열
    static var sampleData: [Caregiver] {
        [
            Caregiver(
                name: "홍길동",
                relationship: CaregiverRelationship.spouse.rawValue,
                phoneNumber: "010-1234-5678",
                email: "spouse@example.com"
            ),
            Caregiver(
                name: "김철수",
                relationship: CaregiverRelationship.child.rawValue,
                phoneNumber: "010-9876-5432",
                notificationPreference: .all
            ),
            Caregiver(
                name: "이영희",
                relationship: CaregiverRelationship.caregiver.rawValue,
                phoneNumber: "010-5555-5555",
                isActive: false
            )
        ]
    }
}

// MARK: - 관계 타입
/// 보호자와의 관계 유형
enum CaregiverRelationship: String, CaseIterable {
    case spouse = "배우자"
    case child = "자녀"
    case parent = "부모"
    case sibling = "형제/자매"
    case friend = "친구"
    case caregiver = "간병인"
    case other = "기타"
    
    var icon: String {
        switch self {
        case .spouse: return "heart.fill"
        case .child: return "figure.child"
        case .parent: return "figure.2.and.child.holdinghands"
        case .sibling: return "figure.2"
        case .friend: return "person.2.fill"
        case .caregiver: return "cross.case.fill"
        case .other: return "person.fill"
        }
    }
}
