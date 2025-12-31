//
//  Patient.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

//  보호자(앱 사용자)가 관리하는 환자 목록
//  - "본인"은 patient == nil로 표현
//  - 다른 환자는 Patient 인스턴스로 관리
//

import Foundation
import SwiftData
import SwiftUI
import DMateResource

/// 피보호자(환자) 정보를 저장하는 모델
@Model
final class Patient {
    // MARK: - 기본 식별자
    
    var id: UUID = UUID()
    
    // MARK: - 기본 정보
    
    /// 환자 이름
    var name: String = ""
    
    /// 관계 (부모, 배우자, 자녀 등)
    var relationship: String = ""
    
    /// 생년월일
    var birthDate: Date?
    
    /// 프로필 색상 (구분용)
    var profileColor: String = ""
    
    /// 메모
    var notes: String?
    
    /// 프로필 이미지
    @Attribute(.externalStorage)
    var profileImageData: Data?
    
    // MARK: - 메타데이터
    
    /// 활성 상태
    var isActive: Bool = true
    
    /// 생성 일시
    var createdAt: Date = Date()
    
    // MARK: - 관계
    
    /// 이 환자의 약물 목록
    @Relationship(deleteRule: .cascade)
    var medications: [Medication] = []
    
    /// 이 환자의 진료 예약 목록
    @Relationship(deleteRule: .cascade)
    var appointments: [Appointment] = []
    
    // MARK: - 계산 속성
    
    /// 관계 열거형
    var relationshipType: PatientRelationship {
        PatientRelationship(rawValue: relationship) ?? .other
    }
    
    /// 프로필 색상 (SwiftUI Color)
    var color: Color {
        PatientColor(rawValue: profileColor)?.color ?? .blue
    }
    
    /// 이니셜
    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    /// 나이 (생년월일 기준)
    var age: Int? {
        guard let birthDate = birthDate else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year], from: birthDate, to: now)
        return components.year
    }
    
    /// 나이 표시 텍스트
    var ageText: String? {
        guard let age = age else { return nil }
        return "\(age)세"
    }
    
    /// 활성 약물 수
    var activeMedicationCount: Int {
        medications.filter { $0.isActive }.count
    }
    
    /// 오늘 복약 준수율
    var todayAdherenceRate: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        var totalLogs = 0
        var takenLogs = 0
        
        for medication in medications {
            let todayLogs = medication.logs.filter { log in
                log.scheduledTime >= today && log.scheduledTime < tomorrow
            }
            totalLogs += todayLogs.count
            takenLogs += todayLogs.filter { $0.status == LogStatus.taken.rawValue }.count
        }
        
        guard totalLogs > 0 else { return 0.0 }
        return Double(takenLogs) / Double(totalLogs)
    }
    
    /// 프로필 이미지
    var profileImage: UIImage? {
        guard let data = profileImageData else { return nil }
        return UIImage(data: data)
    }

    /// 본인 여부
    var isMyself: Bool {
        relationshipType == .myself
    }

    /// 표시 이름 (본인인 경우 "이름(나)" 형태)
    var displayName: String {
        if isMyself {
            return "\(name)(나)"
        }
        return name
    }
    
    // MARK: - 초기화
    
    init(
        name: String,
        relationship: PatientRelationship = .other,
        birthDate: Date? = nil,
        profileColor: PatientColor = .blue,
        notes: String? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.relationship = relationship.rawValue
        self.birthDate = birthDate
        self.profileColor = profileColor.rawValue
        self.notes = notes
        self.isActive = isActive
        self.createdAt = Date()
    }
    
    // MARK: - 메서드
    
    /// 프로필 이미지 설정
    func setProfileImage(_ image: UIImage, compressionQuality: CGFloat = 0.7) {
        profileImageData = image.jpegData(compressionQuality: compressionQuality)
    }
}

// MARK: - 환자 관계 타입

enum PatientRelationship: String, CaseIterable, Identifiable {
    case myself = "나"
    case parent = "부모님"
    case grandparent = "조부모님"
    case spouse = "배우자"
    case child = "자녀"
    case sibling = "형제/자매"
    case relative = "친척"
    case friend = "지인"
    case other = "기타"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .myself: return "person.fill"
        case .parent: return "figure.2.and.child.holdinghands"
        case .grandparent: return "figure.2"
        case .spouse: return "heart.fill"
        case .child: return "figure.child"
        case .sibling: return "person.2.fill"
        case .relative: return "person.3.fill"
        case .friend: return "person.crop.circle"
        case .other: return "person.fill.questionmark"
        }
    }

    var displayName: String {
        switch self {
        case .myself: return DMateResourceStrings.Patient.Relationship.myself
        case .parent: return DMateResourceStrings.Patient.Relationship.parent
        case .grandparent: return DMateResourceStrings.Patient.Relationship.grandparent
        case .spouse: return DMateResourceStrings.Patient.Relationship.spouse
        case .child: return DMateResourceStrings.Patient.Relationship.child
        case .sibling: return DMateResourceStrings.Patient.Relationship.sibling
        case .relative: return DMateResourceStrings.Patient.Relationship.relative
        case .friend: return DMateResourceStrings.Patient.Relationship.friend
        case .other: return DMateResourceStrings.Patient.Relationship.other
        }
    }
}

// MARK: - 환자 프로필 색상

enum PatientColor: String, CaseIterable, Identifiable {
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case purple = "purple"
    case pink = "pink"
    case red = "red"
    case teal = "teal"
    case indigo = "indigo"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }
    
    var displayName: String {
        switch self {
        case .blue: return DMateResourceStrings.Color.blue
        case .green: return DMateResourceStrings.Color.green
        case .orange: return DMateResourceStrings.Color.orange
        case .purple: return DMateResourceStrings.Color.purple
        case .pink: return DMateResourceStrings.Color.pink
        case .red: return DMateResourceStrings.Color.red
        case .teal: return DMateResourceStrings.Color.teal
        case .indigo: return DMateResourceStrings.Color.indigo
        }
    }
}

// MARK: - 샘플 데이터

extension Patient {
    static var preview: Patient {
        Patient(
            name: "김영수",
            relationship: .parent,
            birthDate: Calendar.current.date(byAdding: .year, value: -75, to: Date()),
            profileColor: .blue,
            notes: "고혈압, 당뇨 관리 중"
        )
    }
    
    static var sampleData: [Patient] {
        [
            Patient(
                name: "김영수",
                relationship: .parent,
                birthDate: Calendar.current.date(byAdding: .year, value: -75, to: Date()),
                profileColor: .blue
            ),
            Patient(
                name: "이순자",
                relationship: .parent,
                birthDate: Calendar.current.date(byAdding: .year, value: -72, to: Date()),
                profileColor: .pink
            ),
            Patient(
                name: "박지민",
                relationship: .child,
                birthDate: Calendar.current.date(byAdding: .year, value: -8, to: Date()),
                profileColor: .green
            )
        ]
    }
}
