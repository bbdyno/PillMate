//
//  PatientView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import SwiftData

/// 환자 관리 화면
struct PatientView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Patient.createdAt) private var patients: [Patient]
    
    @State private var showAddSheet = false
    @State private var patientToEdit: Patient?
    @State private var patientToDelete: Patient?
    @State private var showDeleteConfirmation = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if patients.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: AppSpacing.lg) {
                        // 헤더 카드
                        headerCard
                        
                        // 환자 목록
                        patientList
                    }
                    .padding(.top, AppSpacing.sm)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .background(AppColors.background)
            .navigationTitle("환자 관리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AddButton { showAddSheet = true }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddPatientView()
            }
            .sheet(item: $patientToEdit) { patient in
                EditPatientView(patient: patient)
            }
            .alert("환자 삭제", isPresented: $showDeleteConfirmation) {
                Button(DoseMateStrings.Common.cancel, role: .cancel) {}
                Button(DoseMateStrings.Common.delete, role: .destructive) {
                    if let patient = patientToDelete {
                        deletePatient(patient)
                    }
                }
            } message: {
                if let patient = patientToDelete {
                    Text("\(patient.name)님의 모든 복약 기록이 삭제됩니다.")
                }
            }
        }
    }
    
    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack {
            Spacer()
            EmptyStateView(
                icon: "person.2.fill",
                title: "등록된 환자가 없습니다",
                description: "가족이나 피보호자의 복약을 관리하려면\n환자를 등록하세요.",
                buttonTitle: "환자 등록하기",
                action: { showAddSheet = true }
            )
            Spacer()
        }
    }
    
    // MARK: - Header Card

    private var headerCard: some View {
        StandardHeaderCard(
            icon: "person.2.fill",
            title: "총 \(patients.count)명의 환자",
            subtitle: "복약을 관리하고 있습니다"
        )
    }
    
    // MARK: - Patient List
    
    private var patientList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "환자 목록")
            
            VStack(spacing: AppSpacing.sm) {
                ForEach(patients) { patient in
                    NavigationLink {
                        PatientDetailView(patient: patient)
                    } label: {
                        PatientCard(
                            patient: patient,
                            onEdit: { patientToEdit = patient },
                            onDelete: {
                                patientToDelete = patient
                                showDeleteConfirmation = true
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func deletePatient(_ patient: Patient) {
        withAnimation {
            modelContext.delete(patient)
            try? modelContext.save()
        }
    }
}

// MARK: - Patient Card

struct PatientCard: View {
    let patient: Patient
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // 프로필 아바타
            Circle()
                .fill(patient.color.gradient)
                .frame(width: 56, height: 56)
                .overlay {
                    if let image = patient.profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                    } else {
                        Text(patient.initials)
                            .font(AppTypography.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: patient.color.opacity(0.3), radius: 4, y: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AppSpacing.xs) {
                    Text(patient.name)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(patient.relationshipType.rawValue)
                        .font(AppTypography.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(patient.color.opacity(0.15))
                        .foregroundColor(patient.color)
                        .cornerRadius(AppRadius.sm)
                }
                
                HStack(spacing: AppSpacing.md) {
                    if let ageText = patient.ageText {
                        Label(ageText, systemImage: "calendar")
                    }
                    
                    Label("\(patient.activeMedicationCount)개 약물", systemImage: "pills.fill")
                }
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // 오늘 준수율
            VStack(alignment: .trailing, spacing: 2) {
                ProgressRing(
                    progress: patient.todayAdherenceRate,
                    lineWidth: 4,
                    size: 44,
                    color: adherenceColor,
                    showPercentage: false
                )
                .overlay {
                    Text("\(Int(patient.todayAdherenceRate * 100))")
                        .font(AppTypography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(adherenceColor)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadius.lg)
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label(DoseMateStrings.Common.edit, systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(DoseMateStrings.Common.delete, systemImage: "trash")
            }
        }
    }
    
    private var adherenceColor: Color {
        let rate = patient.todayAdherenceRate
        if rate >= 0.8 { return AppColors.success }
        if rate >= 0.5 { return AppColors.warning }
        return AppColors.danger
    }
}

// MARK: - Patient Detail View

struct PatientDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let patient: Patient
    
    @State private var showAddMedicationSheet = false
    @State private var showAddAppointmentSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // 프로필 헤더
                profileHeader
                
                // 오늘의 복약 현황
                adherenceCard
                
                // 약물 목록
                medicationSection
                
                // 진료 예약
                appointmentSection
                
                // 메모
                if let notes = patient.notes, !notes.isEmpty {
                    notesSection(notes)
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColors.background)
        .navigationTitle(patient.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddMedicationSheet) {
            AddMedicationForPatientView(patient: patient)
        }
        .sheet(isPresented: $showAddAppointmentSheet) {
            AddAppointmentForPatientView(patient: patient)
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: AppSpacing.md) {
            // 아바타
            Circle()
                .fill(patient.color.gradient)
                .frame(width: 80, height: 80)
                .overlay {
                    Text(patient.initials)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .shadow(color: patient.color.opacity(0.4), radius: 8, y: 4)
            
            VStack(spacing: 4) {
                Text(patient.name)
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: patient.relationshipType.icon)
                    Text(patient.relationshipType.rawValue)
                    if let ageText = patient.ageText {
                        Text("•")
                        Text(ageText)
                    }
                }
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
        .background(
            LinearGradient(
                colors: [patient.color.opacity(0.15), AppColors.cardBackground],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(AppRadius.xl)
    }
    
    // MARK: - Adherence Card
    
    private var adherenceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("오늘의 복약")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                
                Text("\(Int(patient.todayAdherenceRate * 100))%")
                    .font(AppTypography.number)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("준수율")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            ProgressRing(
                progress: patient.todayAdherenceRate,
                lineWidth: 8,
                size: 80,
                color: patient.color
            )
        }
        .cardStyle()
    }
    
    // MARK: - Medication Section
    
    private var medicationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(
                title: "약물 목록",
                subtitle: "\(patient.medications.count)개",
                action: { showAddMedicationSheet = true },
                actionTitle: "추가"
            )
            
            if patient.medications.isEmpty {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "pills")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text("등록된 약물이 없습니다")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Button {
                        showAddMedicationSheet = true
                    } label: {
                        Label("약물 추가", systemImage: "plus")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(width: 140)
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.xl)
                .cardStyle()
            } else {
                VStack(spacing: AppSpacing.xs) {
                    ForEach(patient.medications) { medication in
                        HStack(spacing: AppSpacing.sm) {
                            Circle()
                                .fill(medication.medicationColor.color)
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(medication.name)
                                    .font(AppTypography.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text("\(medication.dosage) • \(medication.strength)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            if medication.isLowStock {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("\(medication.stockCount)")
                                }
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.warning)
                            }
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColors.background)
                        .cornerRadius(AppRadius.md)
                    }
                }
                .padding(AppSpacing.sm)
                .background(AppColors.cardBackground)
                .cornerRadius(AppRadius.lg)
            }
        }
    }
    
    // MARK: - Appointment Section
    
    private var appointmentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(
                title: "진료 예약",
                action: { showAddAppointmentSheet = true },
                actionTitle: "추가"
            )
            
            let upcomingAppointments = patient.appointments.filter { $0.isUpcoming }
            
            if upcomingAppointments.isEmpty {
                HStack {
                    Image(systemName: "calendar.badge.checkmark")
                        .foregroundColor(AppColors.textTertiary)
                    Text("예정된 진료가 없습니다")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.lg)
                .cardStyle()
            } else {
                VStack(spacing: AppSpacing.xs) {
                    ForEach(upcomingAppointments.prefix(3)) { appointment in
                        HStack {
                            IconBadge(icon: "stethoscope", color: AppColors.lavender, size: 36, iconSize: 16)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appointment.doctorName)
                                    .font(AppTypography.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                if let specialty = appointment.specialty {
                                    Text(specialty)
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(appointment.appointmentDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Text(appointment.appointmentDate.formatted(date: .omitted, time: .shortened))
                                    .font(AppTypography.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppColors.lavender)
                            }
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColors.background)
                        .cornerRadius(AppRadius.md)
                    }
                }
                .padding(AppSpacing.sm)
                .background(AppColors.cardBackground)
                .cornerRadius(AppRadius.lg)
            }
        }
    }
    
    // MARK: - Notes Section
    
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "메모")
            
            Text(notes)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
        }
    }
}

// MARK: - Add Patient View

struct AddPatientView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var relationship: PatientRelationship = .parent
    @State private var birthDate = Date()
    @State private var hasBirthDate = false
    @State private var profileColor: PatientColor = .blue
    @State private var notes = ""
    
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
                            TextField("이름", text: $name)
                                .textFieldStyle(.plain)
                                .padding(AppSpacing.md)
                                .background(AppColors.background)
                                .cornerRadius(AppRadius.md)
                            
                            // 관계 선택
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                HStack {
                                    Text("관계")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textSecondary)

                                    Spacer()

                                    // 스크롤 힌트
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.left")
                                        Image(systemName: "arrow.right")
                                    }
                                    .font(.caption2)
                                    .foregroundColor(AppColors.textTertiary)
                                }

                                ZStack(alignment: .leading) {
                                    ScrollView(.horizontal, showsIndicators: true) {
                                        HStack(spacing: AppSpacing.xs) {
                                            ForEach(PatientRelationship.allCases) { rel in
                                                Button {
                                                    relationship = rel
                                                } label: {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: rel.icon)
                                                            .font(.caption)
                                                        Text(rel.rawValue)
                                                            .font(AppTypography.caption)
                                                    }
                                                    .padding(.horizontal, AppSpacing.sm)
                                                    .padding(.vertical, AppSpacing.xs)
                                                    .background(relationship == rel ? AppColors.primary.opacity(0.15) : AppColors.background)
                                                    .foregroundColor(relationship == rel ? AppColors.primary : AppColors.textSecondary)
                                                    .cornerRadius(AppRadius.full)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: AppRadius.full)
                                                            .stroke(relationship == rel ? AppColors.primary.opacity(0.5) : AppColors.divider, lineWidth: 1)
                                                    )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 1)
                                    }

                                    // 오른쪽 페이드 효과
                                    HStack {
                                        Spacer()
                                        LinearGradient(
                                            colors: [AppColors.cardBackground.opacity(0), AppColors.cardBackground],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .frame(width: 30)
                                        .allowsHitTesting(false)
                                    }
                                }
                            }
                            
                            // 생년월일
                            Toggle(isOn: $hasBirthDate) {
                                Text("생년월일 입력")
                                    .font(AppTypography.body)
                            }
                            .tint(AppColors.primary)
                            .padding(AppSpacing.md)
                            .background(AppColors.background)
                            .cornerRadius(AppRadius.md)
                            
                            if hasBirthDate {
                                DatePicker("생년월일", selection: $birthDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .padding(AppSpacing.md)
                                    .background(AppColors.background)
                                    .cornerRadius(AppRadius.md)
                            }
                        }
                        .cardStyle()
                    }
                    
                    // 프로필 색상
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("프로필 색상")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: AppSpacing.md) {
                            ForEach(PatientColor.allCases) { color in
                                Circle()
                                    .fill(color.color.gradient)
                                    .frame(width: 50, height: 50)
                                    .overlay {
                                        if profileColor == color {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .shadow(color: profileColor == color ? color.color.opacity(0.4) : .clear, radius: 6, y: 3)
                                    .scaleEffect(profileColor == color ? 1.1 : 1)
                                    .animation(.spring(duration: 0.2), value: profileColor)
                                    .onTapGesture {
                                        profileColor = color
                                    }
                            }
                        }
                        .cardStyle()
                    }
                    
                    // 메모
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("메모 (선택)")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .padding(AppSpacing.sm)
                            .background(AppColors.background)
                            .cornerRadius(AppRadius.md)
                            .cardStyle(padding: 0)
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("환자 등록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(DoseMateStrings.Common.cancel) {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(DoseMateStrings.Common.save) {
                        savePatient()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(name.isEmpty ? AppColors.textTertiary : AppColors.primary)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func savePatient() {
        let patient = Patient(
            name: name,
            relationship: relationship,
            birthDate: hasBirthDate ? birthDate : nil,
            profileColor: profileColor,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(patient)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Edit Patient View

struct EditPatientView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let patient: Patient
    
    @State private var name: String
    @State private var relationship: PatientRelationship
    @State private var birthDate: Date
    @State private var hasBirthDate: Bool
    @State private var profileColor: PatientColor
    @State private var notes: String
    
    init(patient: Patient) {
        self.patient = patient
        _name = State(initialValue: patient.name)
        _relationship = State(initialValue: patient.relationshipType)
        _birthDate = State(initialValue: patient.birthDate ?? Date())
        _hasBirthDate = State(initialValue: patient.birthDate != nil)
        _profileColor = State(initialValue: PatientColor(rawValue: patient.profileColor) ?? .blue)
        _notes = State(initialValue: patient.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // 프리뷰
                    Circle()
                        .fill(profileColor.color.gradient)
                        .frame(width: 80, height: 80)
                        .overlay {
                            Text(String(name.prefix(2)).uppercased())
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .shadow(color: profileColor.color.opacity(0.4), radius: 8, y: 4)
                    
                    // 이름
                    TextField("이름", text: $name)
                        .font(AppTypography.title3)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        .padding(AppSpacing.md)
                        .background(AppColors.cardBackground)
                        .cornerRadius(AppRadius.md)
                    
                    // 관계
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("관계")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: AppSpacing.xs) {
                            ForEach(PatientRelationship.allCases) { rel in
                                Button {
                                    relationship = rel
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: rel.icon)
                                        Text(rel.rawValue)
                                            .font(AppTypography.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(relationship == rel ? AppColors.primary.opacity(0.15) : AppColors.background)
                                    .foregroundColor(relationship == rel ? AppColors.primary : AppColors.textSecondary)
                                    .cornerRadius(AppRadius.md)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .cardStyle()
                    
                    // 생년월일
                    VStack(spacing: AppSpacing.sm) {
                        Toggle("생년월일", isOn: $hasBirthDate)
                            .tint(AppColors.primary)
                        
                        if hasBirthDate {
                            DatePicker("", selection: $birthDate, displayedComponents: .date)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                        }
                    }
                    .cardStyle()
                    
                    // 색상
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("프로필 색상")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: AppSpacing.md) {
                            ForEach(PatientColor.allCases) { color in
                                Circle()
                                    .fill(color.color.gradient)
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        if profileColor == color {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    .onTapGesture {
                                        profileColor = color
                                    }
                            }
                        }
                    }
                    .cardStyle()
                    
                    // 메모
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("메모")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                            .background(AppColors.background)
                            .cornerRadius(AppRadius.sm)
                    }
                    .cardStyle()
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("환자 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(DoseMateStrings.Common.cancel) { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(DoseMateStrings.Common.save) { updatePatient() }
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primary)
                        .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func updatePatient() {
        patient.name = name
        patient.relationship = relationship.rawValue
        patient.birthDate = hasBirthDate ? birthDate : nil
        patient.profileColor = profileColor.rawValue
        patient.notes = notes.isEmpty ? nil : notes
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Add Medication For Patient View

struct AddMedicationForPatientView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let patient: Patient
    
    @State private var name = ""
    @State private var dosage = "1정"
    @State private var strength = ""
    @State private var form: MedicationForm = .tablet
    @State private var color: MedicationColor = .white
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // 환자 표시
                    HStack {
                        Circle()
                            .fill(patient.color)
                            .frame(width: 32, height: 32)
                            .overlay {
                                Text(patient.initials)
                                    .font(AppTypography.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        
                        Text("\(patient.name)님의 약물")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                    }
                    .padding(AppSpacing.md)
                    .background(patient.color.opacity(0.1))
                    .cornerRadius(AppRadius.md)
                    
                    // 약물 정보
                    VStack(spacing: AppSpacing.sm) {
                        TextField("약 이름", text: $name)
                            .textFieldStyle(.plain)
                            .padding(AppSpacing.md)
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppRadius.md)
                        
                        HStack(spacing: AppSpacing.sm) {
                            TextField("용량 (예: 1정)", text: $dosage)
                                .textFieldStyle(.plain)
                                .padding(AppSpacing.md)
                                .background(AppColors.cardBackground)
                                .cornerRadius(AppRadius.md)
                            
                            TextField("함량 (예: 500mg)", text: $strength)
                                .textFieldStyle(.plain)
                                .padding(AppSpacing.md)
                                .background(AppColors.cardBackground)
                                .cornerRadius(AppRadius.md)
                        }
                        
                        // 형태 선택
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("형태")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppSpacing.xs) {
                                    ForEach(MedicationForm.allCases, id: \.self) { f in
                                        Button {
                                            form = f
                                        } label: {
                                            Text(f.displayName)
                                                .font(AppTypography.caption)
                                                .padding(.horizontal, AppSpacing.sm)
                                                .padding(.vertical, AppSpacing.xs)
                                                .background(form == f ? AppColors.primary.opacity(0.15) : AppColors.cardBackground)
                                                .foregroundColor(form == f ? AppColors.primary : AppColors.textSecondary)
                                                .cornerRadius(AppRadius.full)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(AppSpacing.md)
                        .background(AppColors.cardBackground)
                        .cornerRadius(AppRadius.md)
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("약물 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(DoseMateStrings.Common.cancel) { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(DoseMateStrings.Common.save) { saveMedication() }
                        .fontWeight(.semibold)
                        .foregroundColor(name.isEmpty ? AppColors.textTertiary : AppColors.primary)
                        .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveMedication() {
        let medication = Medication(
            name: name,
            dosage: dosage,
            strength: strength,
            form: form,
            color: color
        )
        medication.patient = patient
        
        modelContext.insert(medication)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Add Appointment For Patient View

struct AddAppointmentForPatientView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let patient: Patient
    
    @State private var doctorName = ""
    @State private var specialty = ""
    @State private var appointmentDate = Date()
    @State private var location = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // 환자 표시
                    HStack {
                        Circle()
                            .fill(patient.color)
                            .frame(width: 32, height: 32)
                            .overlay {
                                Text(patient.initials)
                                    .font(AppTypography.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        
                        Text("\(patient.name)님의 진료 예약")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                    }
                    .padding(AppSpacing.md)
                    .background(patient.color.opacity(0.1))
                    .cornerRadius(AppRadius.md)
                    
                    // 진료 정보
                    VStack(spacing: AppSpacing.sm) {
                        TextField("의사 이름", text: $doctorName)
                            .textFieldStyle(.plain)
                            .padding(AppSpacing.md)
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppRadius.md)
                        
                        TextField("진료과", text: $specialty)
                            .textFieldStyle(.plain)
                            .padding(AppSpacing.md)
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppRadius.md)
                        
                        DatePicker("예약 일시", selection: $appointmentDate)
                            .padding(AppSpacing.md)
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppRadius.md)
                        
                        TextField("장소", text: $location)
                            .textFieldStyle(.plain)
                            .padding(AppSpacing.md)
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppRadius.md)
                    }
                    
                    // 메모
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("메모 (선택)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 60)
                            .scrollContentBackground(.hidden)
                            .padding(AppSpacing.sm)
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppRadius.md)
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("진료 예약 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(DoseMateStrings.Common.cancel) { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(DoseMateStrings.Common.save) { saveAppointment() }
                        .fontWeight(.semibold)
                        .foregroundColor(doctorName.isEmpty ? AppColors.textTertiary : AppColors.primary)
                        .disabled(doctorName.isEmpty)
                }
            }
        }
    }
    
    private func saveAppointment() {
        let appointment = Appointment(
            doctorName: doctorName,
            specialty: specialty.isEmpty ? nil : specialty,
            appointmentDate: appointmentDate,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes
        )
        appointment.patient = patient
        
        modelContext.insert(appointment)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    PatientView()
        .modelContainer(for: [
            Patient.self,
            Medication.self,
            MedicationSchedule.self,
            MedicationLog.self,
            Appointment.self
        ], inMemory: true)
}
