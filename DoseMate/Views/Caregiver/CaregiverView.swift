//
//  CaregiverView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import SwiftData

/// 보호자 관리 화면
struct CaregiverView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Caregiver.name) private var caregivers: [Caregiver]
    
    @State private var showAddSheet = false
    @State private var selectedCaregiver: Caregiver?
    @State private var showDeleteConfirmation = false
    @State private var caregiverToDelete: Caregiver?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if caregivers.isEmpty {
                    emptyStateView
                } else {
                    caregiverList
                }
            }
            .background(Color.appBackground)
            .navigationTitle("보호자")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddCaregiverView { caregiver in
                    modelContext.insert(caregiver)
                    try? modelContext.save()
                }
            }
            .sheet(item: $selectedCaregiver) { caregiver in
                EditCaregiverView(caregiver: caregiver) {
                    try? modelContext.save()
                }
            }
            .alert("보호자 삭제", isPresented: $showDeleteConfirmation) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    if let caregiver = caregiverToDelete {
                        modelContext.delete(caregiver)
                        try? modelContext.save()
                    }
                }
            } message: {
                Text("이 보호자를 삭제하시겠습니까?")
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("등록된 보호자가 없습니다")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("보호자를 추가하여\n복약 미이행 시 알림을 받게 하세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showAddSheet = true
            } label: {
                Label("보호자 추가", systemImage: "plus")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Caregiver List
    
    private var caregiverList: some View {
        List {
            Section {
                ForEach(caregivers) { caregiver in
                    CaregiverRow(caregiver: caregiver)
                        .onTapGesture {
                            selectedCaregiver = caregiver
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                caregiverToDelete = caregiver
                                showDeleteConfirmation = true
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                            
                            Button {
                                caregiver.isActive.toggle()
                                try? modelContext.save()
                            } label: {
                                Label(
                                    caregiver.isActive ? "비활성화" : "활성화",
                                    systemImage: caregiver.isActive ? "bell.slash" : "bell"
                                )
                            }
                            .tint(caregiver.isActive ? .orange : .green)
                        }
                        .swipeActions(edge: .leading) {
                            if let url = caregiver.phoneURL {
                                Button {
                                    UIApplication.shared.open(url)
                                } label: {
                                    Label("전화", systemImage: "phone.fill")
                                }
                                .tint(.green)
                            }
                            
                            if let url = caregiver.smsURL {
                                Button {
                                    UIApplication.shared.open(url)
                                } label: {
                                    Label("문자", systemImage: "message.fill")
                                }
                                .tint(.blue)
                            }
                        }
                }
            } footer: {
                Text("복약을 놓치면 설정된 시간 후 보호자에게 알림이 전송됩니다.")
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Caregiver Row

struct CaregiverRow: View {
    let caregiver: Caregiver
    
    var body: some View {
        HStack(spacing: 12) {
            // 이니셜 아바타
            Text(caregiver.initials)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(caregiver.isActive ? Color.blue : Color.gray)
                .clipShape(Circle())
            
            // 정보
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(caregiver.name)
                        .fontWeight(.medium)
                    
                    if !caregiver.isActive {
                        Text("비활성")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Text(caregiver.relationship)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                let phone = caregiver.formattedPhoneNumber
                Text(phone)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 알림 설정 표시
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: caregiver.isActive ? "bell.fill" : "bell.slash")
                    .foregroundColor(caregiver.isActive ? .blue : .gray)
                
                Text("\(caregiver.notificationDelayMinutes)분 후")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(caregiver.isActive ? 1 : 0.6)
    }
}

// MARK: - Add Caregiver View

struct AddCaregiverView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (Caregiver) -> Void
    
    @State private var name = ""
    @State private var relationship = CaregiverRelationship.caregiver
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var shouldNotifyOnMissedDose = true
    @State private var notificationPreference: NotificationPreference = .missedOnly
    @State private var notificationDelayMinutes = 30
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // 기본 정보
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("기본 정보")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)

                        VStack(spacing: AppSpacing.sm) {
                            // 이름
                            TextField("이름 *", text: $name)
                                .textFieldStyle(.plain)
                                .padding(AppSpacing.md)
                                .background(AppColors.background)
                                .cornerRadius(AppRadius.md)

                            // 관계 선택
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text("관계")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: AppSpacing.xs) {
                                    ForEach(CaregiverRelationship.allCases) { rel in
                                        Button {
                                            relationship = rel
                                        } label: {
                                            VStack(spacing: 4) {
                                                Image(systemName: rel.icon)
                                                    .font(.caption)
                                                Text(rel.displayName)
                                                    .font(AppTypography.caption)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, AppSpacing.sm)
                                            .background(relationship == rel ? AppColors.primary.opacity(0.15) : AppColors.background)
                                            .foregroundColor(relationship == rel ? AppColors.primary : AppColors.textSecondary)
                                            .cornerRadius(AppRadius.md)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppRadius.md)
                                                    .stroke(relationship == rel ? AppColors.primary.opacity(0.5) : AppColors.divider, lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .cardStyle()
                    }

                    // 연락처
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("연락처")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)

                        VStack(spacing: AppSpacing.sm) {
                            // 전화번호
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.primary)
                                    .frame(width: 32)

                                TextField("전화번호", text: $phoneNumber)
                                    .keyboardType(.phonePad)
                                    .textFieldStyle(.plain)
                            }
                            .padding(AppSpacing.md)
                            .background(AppColors.background)
                            .cornerRadius(AppRadius.md)

                            // 이메일
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.primary)
                                    .frame(width: 32)

                                TextField("이메일 (선택)", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .textFieldStyle(.plain)
                            }
                            .padding(AppSpacing.md)
                            .background(AppColors.background)
                            .cornerRadius(AppRadius.md)
                        }
                        .cardStyle()
                    }

                    // 알림 설정
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("알림 설정")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)

                        VStack(spacing: AppSpacing.sm) {
                            Toggle(isOn: $shouldNotifyOnMissedDose) {
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(shouldNotifyOnMissedDose ? AppColors.primary : AppColors.textTertiary)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("복약 미이행 시 알림")
                                            .font(AppTypography.body)
                                            .foregroundColor(AppColors.textPrimary)

                                        Text("복약을 놓치면 보호자에게 알림")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                            }
                            .tint(AppColors.primary)
                            .padding(AppSpacing.md)
                            .background(AppColors.background)
                            .cornerRadius(AppRadius.md)

                            if shouldNotifyOnMissedDose {
                                VStack(spacing: AppSpacing.sm) {
                                    // 알림 조건
                                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                        Text("알림 조건")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textSecondary)

                                        HStack(spacing: AppSpacing.xs) {
                                            Button {
                                                notificationPreference = .missedOnly
                                            } label: {
                                                Text("미이행 시만")
                                                    .font(AppTypography.subheadline)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, AppSpacing.sm)
                                                    .background(notificationPreference == .missedOnly ? AppColors.primary.opacity(0.15) : AppColors.background)
                                                    .foregroundColor(notificationPreference == .missedOnly ? AppColors.primary : AppColors.textSecondary)
                                                    .cornerRadius(AppRadius.md)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: AppRadius.md)
                                                            .stroke(notificationPreference == .missedOnly ? AppColors.primary.opacity(0.5) : AppColors.divider, lineWidth: 1)
                                                    )
                                            }
                                            .buttonStyle(.plain)

                                            Button {
                                                notificationPreference = .all
                                            } label: {
                                                Text("모든 상태")
                                                    .font(AppTypography.subheadline)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, AppSpacing.sm)
                                                    .background(notificationPreference == .all ? AppColors.primary.opacity(0.15) : AppColors.background)
                                                    .foregroundColor(notificationPreference == .all ? AppColors.primary : AppColors.textSecondary)
                                                    .cornerRadius(AppRadius.md)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: AppRadius.md)
                                                            .stroke(notificationPreference == .all ? AppColors.primary.opacity(0.5) : AppColors.divider, lineWidth: 1)
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }

                                    // 알림 지연 시간
                                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                        Text("알림 지연 시간")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textSecondary)

                                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: AppSpacing.xs) {
                                            ForEach([0, 15, 30, 60, 120], id: \.self) { minutes in
                                                Button {
                                                    notificationDelayMinutes = minutes
                                                } label: {
                                                    Text(delayText(for: minutes))
                                                        .font(AppTypography.caption)
                                                        .frame(maxWidth: .infinity)
                                                        .padding(.vertical, AppSpacing.sm)
                                                        .background(notificationDelayMinutes == minutes ? AppColors.primary.opacity(0.15) : AppColors.background)
                                                        .foregroundColor(notificationDelayMinutes == minutes ? AppColors.primary : AppColors.textSecondary)
                                                        .cornerRadius(AppRadius.md)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: AppRadius.md)
                                                                .stroke(notificationDelayMinutes == minutes ? AppColors.primary.opacity(0.5) : AppColors.divider, lineWidth: 1)
                                                        )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                                .padding(AppSpacing.md)
                                .background(AppColors.background)
                                .cornerRadius(AppRadius.md)
                            }
                        }
                        .cardStyle()
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("보호자 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") {
                        saveCaregiver()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(name.isEmpty ? AppColors.textTertiary : AppColors.primary)
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func delayText(for minutes: Int) -> String {
        switch minutes {
        case 0: return "즉시"
        case 15: return "15분 후"
        case 30: return "30분 후"
        case 60: return "1시간 후"
        case 120: return "2시간 후"
        default: return "\(minutes)분"
        }
    }
    
    private func saveCaregiver() {
        let caregiver = Caregiver(
            name: name,
            relationship: relationship.displayName,
            phoneNumber: phoneNumber.isEmpty ? "" : phoneNumber,
            email: email.isEmpty ? nil : email
        )
        caregiver.shouldNotifyOnMissedDose = shouldNotifyOnMissedDose
        caregiver.notificationPreferences = notificationPreference.rawValue
        caregiver.notificationDelayMinutes = notificationDelayMinutes
        
        onSave(caregiver)
        dismiss()
    }
}

// MARK: - Edit Caregiver View

struct EditCaregiverView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var caregiver: Caregiver
    let onSave: () -> Void
    
    @State private var relationship: CaregiverRelationship = .other
    @State private var notificationPreference: NotificationPreference = .missedOnly
    
    init(caregiver: Caregiver, onSave: @escaping () -> Void) {
        self.caregiver = caregiver
        self.onSave = onSave
        
        _relationship = State(initialValue: CaregiverRelationship(rawValue: caregiver.relationship) ?? .other)
        _notificationPreference = State(initialValue: NotificationPreference(rawValue: caregiver.notificationPreferences) ?? .missedOnly)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("이름", text: $caregiver.name)
                    
                    Picker("관계", selection: $relationship) {
                        ForEach(CaregiverRelationship.allCases) { rel in
                            Text(rel.displayName).tag(rel)
                        }
                    }
                    .onChange(of: relationship) { _, newValue in
                        caregiver.relationship = newValue.displayName
                    }
                }
                
                Section("연락처") {
                    TextField("전화번호", text: Binding(
                        get: { caregiver.phoneNumber },
                        set: { caregiver.phoneNumber = $0.isEmpty ? "" : $0 }
                    ))
                    .keyboardType(.phonePad)
                    
                    TextField("이메일", text: Binding(
                        get: { caregiver.email ?? "" },
                        set: { caregiver.email = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                }
                
                Section("알림 설정") {
                    Toggle("복약 미이행 시 알림", isOn: $caregiver.shouldNotifyOnMissedDose)
                    
                    if caregiver.shouldNotifyOnMissedDose {
                        Picker("알림 조건", selection: $notificationPreference) {
                            Text("복약 미이행 시만").tag(NotificationPreference.missedOnly)
                            Text("모든 복약 상태").tag(NotificationPreference.all)
                        }
                        .onChange(of: notificationPreference) { _, newValue in
                            caregiver.notificationPreferences = newValue.rawValue
                        }
                        
                        Picker("알림 지연 시간", selection: $caregiver.notificationDelayMinutes) {
                            Text("즉시").tag(0)
                            Text("15분 후").tag(15)
                            Text("30분 후").tag(30)
                            Text("1시간 후").tag(60)
                            Text("2시간 후").tag(120)
                        }
                    }
                }
                
                Section {
                    Toggle("활성화", isOn: $caregiver.isActive)
                }
                
                // 연락 버튼들
                if caregiver.phoneNumber != nil || caregiver.email != nil {
                    Section("연락하기") {
                        if let phoneURL = caregiver.phoneURL {
                            Button {
                                UIApplication.shared.open(phoneURL)
                            } label: {
                                Label("전화하기", systemImage: "phone.fill")
                            }
                        }
                        
                        if let smsURL = caregiver.smsURL {
                            Button {
                                UIApplication.shared.open(smsURL)
                            } label: {
                                Label("문자 보내기", systemImage: "message.fill")
                            }
                        }
                        
                        if let emailURL = caregiver.emailURL {
                            Button {
                                UIApplication.shared.open(emailURL)
                            } label: {
                                Label("이메일 보내기", systemImage: "envelope.fill")
                            }
                        }
                    }
                }
            }
            .navigationTitle("보호자 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Caregiver Relationship Extension

extension CaregiverRelationship: Identifiable {
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spouse: return "배우자"
        case .child: return "자녀"
        case .parent: return "부모"
        case .sibling: return "형제자매"
        case .friend: return "친구"
        case .caregiver: return "간병인"
        case .other: return "기타"
        }
    }

    static var allCases: [CaregiverRelationship] {
        [.spouse, .child, .parent, .sibling, .friend, .caregiver, .other]
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "배우자": self = .spouse
        case "자녀": self = .child
        case "부모": self = .parent
        case "형제자매": self = .sibling
        case "친구": self = .friend
        case "간병인": self = .caregiver
        case "기타": self = .other
        default: return nil
        }
    }
    
    var rawValue: String { displayName }
}

// MARK: - Preview

#Preview {
    CaregiverView()
        .modelContainer(for: Caregiver.self, inMemory: true)
}
