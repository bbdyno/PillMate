//
//  AddMedicationView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import DMateDesignSystem
import DMateResource
import PhotosUI

/// 약물 추가 화면
struct AddMedicationView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    
    /// 저장 콜백
    let onSave: (Medication) -> Void
    
    /// 편집할 약물 (nil이면 새로 추가)
    var medicationToEdit: Medication?
    
    // MARK: - State
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var strength = ""
    @State private var selectedForm: MedicationForm = .tablet
    @State private var selectedColor: MedicationColor = .white
    @State private var selectedCategory: MedicationCategory = .other
    @State private var purpose = ""
    @State private var prescribingDoctor = ""
    @State private var sideEffects = ""
    @State private var precautions = ""
    @State private var stockCount = 0
    @State private var lowStockThreshold = 5
    @State private var notes = ""
    
    // 이미지 관련
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showCamera = false
    
    // 스케줄 관련
    @State private var scheduleType: ScheduleType = .daily
    @State private var frequency: Frequency = .onceDaily
    @State private var scheduleTimes: [Date] = [Date()]
    @State private var selectedDays: Set<Int> = []
    @State private var intervalDays = 1 // 간격 설정 (N일마다)
    @State private var mealRelation: MealRelation = .anytime
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date().addingDays(30)
    
    // 알림
    @State private var notificationEnabled = true
    @State private var reminderMinutesBefore = 0
    
    // 페이지 관리
    @State private var currentPage = 0
    
    // 유효성
    @State private var showValidationError = false
    @State private var validationErrorMessage = ""
    
    // MARK: - Initialization
    
    init(medicationToEdit: Medication? = nil, onSave: @escaping (Medication) -> Void) {
        self.medicationToEdit = medicationToEdit
        self.onSave = onSave
        
        if let medication = medicationToEdit {
            _name = State(initialValue: medication.name)
            _dosage = State(initialValue: medication.dosage)
            _strength = State(initialValue: medication.strength)
            _selectedForm = State(initialValue: medication.medicationForm)
            _selectedColor = State(initialValue: medication.medicationColor)
            _selectedCategory = State(initialValue: medication.medicationCategory)
            _purpose = State(initialValue: medication.purpose)
            _prescribingDoctor = State(initialValue: medication.prescribingDoctor)
            _sideEffects = State(initialValue: medication.sideEffects)
            _precautions = State(initialValue: medication.precautions)
            _stockCount = State(initialValue: medication.stockCount)
            _lowStockThreshold = State(initialValue: medication.lowStockThreshold)
            _notes = State(initialValue: medication.notes ?? "")
            _selectedImageData = State(initialValue: medication.imageData)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                TabView(selection: $currentPage) {
                    basicInfoPage.tag(0)
                    scheduleSettingsPage.tag(1)
                    additionalInfoPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // 하단 네비게이션
                bottomNavigationBar
            }
            .background(AppColors.background)
            .navigationTitle(medicationToEdit == nil ? DMateResourceStrings.Medications.add : DMateResourceStrings.Medication.editTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(DMateResourceStrings.Common.cancel) {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
            .toolbarBackground(.clear, for: .navigationBar)
            .alert(DMateResourceStrings.Medication.inputError, isPresented: $showValidationError) {
                Button(DMateResourceStrings.Common.ok, role: .cancel) {}
            } message: {
                Text(validationErrorMessage)
            }
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    selectedImageData = image.jpegData(compressionQuality: 0.7)
                }
            }
        }
    }
    
    // MARK: - Page 1: Basic Info
    
    private var basicInfoPage: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // 헤더
                pageHeaderCard(
                    icon: "pill.fill",
                    title: DMateResourceStrings.Medication.basicInfoTitle,
                    subtitle: DMateResourceStrings.Medication.basicInfoSubtitle,
                    color: AppColors.primary
                )
                
                // 이미지 섹션
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader(title: DMateResourceStrings.Medication.photoSection, subtitle: "")
                    
                    imageSelector
                }
                .cardStyle()
                
                // 기본 정보
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader(title: DMateResourceStrings.Medication.requiredInfo, subtitle: "")
                    
                    VStack(spacing: AppSpacing.sm) {
                        CustomTextField(
                            icon: "pill",
                            placeholder: DMateResourceStrings.Medication.nameRequiredPlaceholder,
                            text: $name
                        )

                        CustomTextField(
                            icon: "number",
                            placeholder: DMateResourceStrings.Medication.dosageExamplePlaceholder,
                            text: $dosage
                        )

                        CustomTextField(
                            icon: "chart.bar",
                            placeholder: DMateResourceStrings.Medication.strengthExamplePlaceholder,
                            text: $strength
                        )
                    }
                }
                .cardStyle()
                
                // 형태 및 색상
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader(title: DMateResourceStrings.Medication.formSection, subtitle: "")
                    
                    VStack(spacing: AppSpacing.md) {
                        // 형태 선택
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(DMateResourceStrings.Medication.formLabel)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppSpacing.sm) {
                                    ForEach(MedicationForm.allCases) { form in
                                        FormSelectionChip(
                                            form: form,
                                            isSelected: selectedForm == form,
                                            onTap: { selectedForm = form }
                                        )
                                    }
                                }
                            }
                        }
                        
                        Divider()

                        // 카테고리 선택
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(DMateResourceStrings.Medication.categoryLabel)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)

                            Menu {
                                ForEach(MedicationCategory.allCases) { category in
                                    Button {
                                        selectedCategory = category
                                    } label: {
                                        HStack {
                                            Image(systemName: category.icon)
                                            Text(category.displayName)
                                            if selectedCategory == category {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: selectedCategory.icon)
                                        .foregroundColor(AppColors.primary)
                                        .frame(width: 24)

                                    Text(selectedCategory.displayName)
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.textPrimary)

                                    Spacer()

                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textTertiary)
                                }
                                .padding(AppSpacing.md)
                                .background(AppColors.background)
                                .cornerRadius(AppRadius.md)
                            }
                        }

                        Divider()

                        // 색상 선택
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(DMateResourceStrings.Medication.colorLabel)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)

                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 60))
                            ], spacing: AppSpacing.sm) {
                                ForEach(MedicationColor.allCases) { color in
                                    ColorSelectionChip(
                                        color: color,
                                        isSelected: selectedColor == color,
                                        onTap: { selectedColor = color }
                                    )
                                }
                            }
                        }
                    }
                }
                .cardStyle()
                
                // 목적
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader(title: DMateResourceStrings.Medication.purposeSection, subtitle: "")

                    CustomTextField(
                        icon: "target",
                        placeholder: DMateResourceStrings.Medication.purposePlaceholder,
                        text: $purpose
                    )
                }
                .cardStyle()
            }
            .padding(AppSpacing.md)
            .padding(.bottom, 80)
        }
    }
    
    // MARK: - Page 2: Schedule
    
    private var scheduleSettingsPage: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // 헤더
                pageHeaderCard(
                    icon: "clock.fill",
                    title: DMateResourceStrings.Medication.scheduleSectionTitle,
                    subtitle: DMateResourceStrings.Medication.scheduleSectionSubtitle,
                    color: AppColors.lavender
                )
                
                // 스케줄 타입
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader(title: DMateResourceStrings.Medication.cycleSection, subtitle: "")
                    
                    VStack(spacing: AppSpacing.sm) {
                        Picker(DMateResourceStrings.Medication.cycleTypeLabel, selection: $scheduleType) {
                            ForEach(ScheduleType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        // 설명 텍스트
                        Text(scheduleType.description)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, AppSpacing.xs)
                        
                        // 특정 요일 선택
                        if scheduleType == .specificDays {
                            weekdaySelector
                        }
                        
                        // 간격 설정
                        if scheduleType == .interval {
                            intervalSelector
                        }
                    }
                }
                .cardStyle()
                
                // 복용 횟수
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader(title: DMateResourceStrings.Medication.frequencySection, subtitle: "")

                    Picker(DMateResourceStrings.Medication.frequencyPickerLabel, selection: $frequency) {
                        ForEach(Frequency.allCases) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .cardStyle()
                .onChange(of: frequency) { _, newValue in
                    updateTimesForFrequency(newValue)
                }
                
                // 복용 시간
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        SectionHeader(title: DMateResourceStrings.Medication.timeSection, subtitle: "")
                        Spacer()
                        if frequency == .custom {
                            Button {
                                scheduleTimes.append(Date())
                            } label: {
                                Label(DMateResourceStrings.Medication.addTime, systemImage: "plus.circle.fill")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                    
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(scheduleTimes.indices, id: \.self) { index in
                            HStack {
                                IconBadge(icon: "clock", color: AppColors.lavender, size: 36, iconSize: 16)
                                
                                Text(DMateResourceStrings.Medication.timeN(index + 1))
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Spacer()
                                
                                DatePicker(
                                    "",
                                    selection: $scheduleTimes[index],
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                            }
                            .padding(AppSpacing.sm)
                            .background(AppColors.background)
                            .cornerRadius(AppRadius.md)
                        }
                    }
                }
                .cardStyle()
                
                // 식사 관계
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader(title: DMateResourceStrings.Medication.mealRelationSection, subtitle: "")
                    
                    VStack(spacing: AppSpacing.xs) {
                        ForEach(MealRelation.allCases) { relation in
                            Button {
                                mealRelation = relation
                            } label: {
                                HStack {
                                    IconBadge(
                                        icon: relation.icon,
                                        color: mealRelation == relation ? AppColors.primary : AppColors.textTertiary,
                                        size: 40,
                                        iconSize: 18
                                    )
                                    
                                    Text(relation.displayName)
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Spacer()
                                    
                                    if mealRelation == relation {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppColors.primary)
                                    }
                                }
                                .padding(AppSpacing.sm)
                                .background(mealRelation == relation ? AppColors.primarySoft : AppColors.background)
                                .cornerRadius(AppRadius.md)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .cardStyle()
                
                // 기간
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader(title: DMateResourceStrings.Medication.periodSection, subtitle: "")

                    VStack(spacing: AppSpacing.sm) {
                        DatePicker(DMateResourceStrings.Medication.startDateLabel, selection: $startDate, displayedComponents: .date)
                            .padding(AppSpacing.sm)
                            .background(AppColors.background)
                            .cornerRadius(AppRadius.md)

                        Toggle(DMateResourceStrings.Medication.hasEndDateLabel, isOn: $hasEndDate)
                            .padding(AppSpacing.sm)
                            .background(AppColors.background)
                            .cornerRadius(AppRadius.md)

                        if hasEndDate {
                            DatePicker(DMateResourceStrings.Medication.endDateLabel, selection: $endDate, displayedComponents: .date)
                                .padding(AppSpacing.sm)
                                .background(AppColors.background)
                                .cornerRadius(AppRadius.md)
                        }
                    }
                }
                .cardStyle()
                
                // 알림
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader(title: DMateResourceStrings.Medication.notificationSection, subtitle: "")

                    VStack(spacing: AppSpacing.sm) {
                        Toggle(DMateResourceStrings.Medication.enableNotificationLabel, isOn: $notificationEnabled)
                            .padding(AppSpacing.sm)
                            .background(AppColors.background)
                            .cornerRadius(AppRadius.md)

                        if notificationEnabled {
                            Picker(DMateResourceStrings.Medication.reminderBeforeLabel, selection: $reminderMinutesBefore) {
                                Text(DMateResourceStrings.Medication.onTime).tag(0)
                                Text(DMateResourceStrings.Medication.before5min).tag(5)
                                Text(DMateResourceStrings.Medication.before10min).tag(10)
                                Text(DMateResourceStrings.Medication.before15min).tag(15)
                                Text(DMateResourceStrings.Medication.before30min).tag(30)
                            }
                            .pickerStyle(.menu)
                            .padding(AppSpacing.sm)
                            .background(AppColors.background)
                            .cornerRadius(AppRadius.md)
                        }
                    }
                }
                .cardStyle()
            }
            .padding(AppSpacing.md)
            .padding(.bottom, 80)
        }
    }
    
    // MARK: - Page 3: Additional Info
    
    private var additionalInfoPage: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // 헤더
                pageHeaderCard(
                    icon: "doc.text.fill",
                    title: DMateResourceStrings.Medication.additionalInfoTitle,
                    subtitle: DMateResourceStrings.Medication.additionalInfoSubtitle,
                    color: AppColors.mint
                )

                // 의사 정보
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader(title: DMateResourceStrings.Medication.prescriptionSection, subtitle: "")

                    CustomTextField(
                        icon: "stethoscope",
                        placeholder: DMateResourceStrings.Medication.prescribingDoctorPlaceholder,
                        text: $prescribingDoctor
                    )
                }
                .cardStyle()
                
                // 재고
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader(title: DMateResourceStrings.Medication.stockSection, subtitle: "")

                    VStack(spacing: AppSpacing.sm) {
                        HStack {
                            IconBadge(icon: "shippingbox", color: AppColors.mint, size: 40, iconSize: 18)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(DMateResourceStrings.Medication.currentStockLabel)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Text("\(stockCount)\(DMateResourceStrings.Medication.stockUnit)")
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.textPrimary)
                            }

                            Spacer()

                            Stepper("", value: $stockCount, in: 0...999)
                                .labelsHidden()
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColors.background)
                        .cornerRadius(AppRadius.md)

                        HStack {
                            IconBadge(icon: "exclamationmark.triangle", color: AppColors.warning, size: 40, iconSize: 18)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(DMateResourceStrings.Medication.lowStockThresholdLabel)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Text(DMateResourceStrings.Medication.stockBelow(lowStockThreshold))
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.textPrimary)
                            }

                            Spacer()

                            Stepper("", value: $lowStockThreshold, in: 1...50)
                                .labelsHidden()
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColors.background)
                        .cornerRadius(AppRadius.md)
                    }
                }
                .cardStyle()
                
                // 부작용
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader(title: DMateResourceStrings.Medication.sideEffectsSection, subtitle: "")

                    TextField(DMateResourceStrings.Medication.sideEffectsPlaceholder, text: $sideEffects, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...5)
                        .padding(AppSpacing.md)
                        .background(AppColors.background)
                        .cornerRadius(AppRadius.md)
                }
                .cardStyle()
                
                // 주의사항
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader(title: DMateResourceStrings.Medication.precautionsSection, subtitle: "")

                    TextField(DMateResourceStrings.Medication.precautionsPlaceholder, text: $precautions, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...5)
                        .padding(AppSpacing.md)
                        .background(AppColors.background)
                        .cornerRadius(AppRadius.md)
                }
                .cardStyle()
                
                // 메모
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader(title: DMateResourceStrings.Medication.notesSection, subtitle: "")

                    TextField(DMateResourceStrings.Medication.notesPlaceholder, text: $notes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...5)
                        .padding(AppSpacing.md)
                        .background(AppColors.background)
                        .cornerRadius(AppRadius.md)
                }
                .cardStyle()
            }
            .padding(AppSpacing.md)
            .padding(.bottom, 80)
        }
    }
    
    // MARK: - Image Selector
    
    private var imageSelector: some View {
        VStack(spacing: AppSpacing.md) {
            if let imageData = selectedImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(AppColors.divider, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                
                Button {
                    selectedImageData = nil
                } label: {
                    Text(DMateResourceStrings.Medication.changePhoto)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.primary)
                }
            } else {
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(AppColors.primarySoft)
                    .frame(width: 140, height: 140)
                    .overlay {
                        Image(systemName: selectedForm.icon)
                            .font(.system(size: 50))
                            .foregroundStyle(AppColors.primaryGradient)
                    }
                
                HStack(spacing: AppSpacing.lg) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        VStack(spacing: 4) {
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                            Text(DMateResourceStrings.Medication.gallery)
                                .font(AppTypography.caption)
                        }
                        .foregroundColor(AppColors.primary)
                    }
                    
                    Button {
                        showCamera = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "camera")
                                .font(.system(size: 24))
                            Text(DMateResourceStrings.Medication.camera)
                                .font(AppTypography.caption)
                        }
                        .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
    }
    
    // MARK: - Weekday Selector
    
    private var weekdaySelector: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(Weekday.allCases) { weekday in
                Button {
                    if selectedDays.contains(weekday.rawValue) {
                        selectedDays.remove(weekday.rawValue)
                    } else {
                        selectedDays.insert(weekday.rawValue)
                    }
                } label: {
                    Text(weekday.shortName)
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                        .frame(width: 40, height: 40)
                        .background(
                            selectedDays.contains(weekday.rawValue)
                            ? AppColors.primaryGradient
                            : LinearGradient(colors: [AppColors.divider], startPoint: .top, endPoint: .bottom)
                        )
                        .foregroundColor(
                            selectedDays.contains(weekday.rawValue)
                            ? .white
                            : AppColors.textSecondary
                        )
                        .clipShape(Circle())
                        .shadow(
                            color: selectedDays.contains(weekday.rawValue) ? AppColors.primary.opacity(0.3) : .clear,
                            radius: 4,
                            y: 2
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
    
    // MARK: - Interval Selector
    
    private var intervalSelector: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                IconBadge(icon: "calendar.badge.clock", color: AppColors.lavender, size: 40, iconSize: 18)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(DMateResourceStrings.Medication.intervalLabel)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(DMateResourceStrings.Medication.intervalDescription(intervalDays))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            .padding(AppSpacing.sm)
            .background(AppColors.background)
            .cornerRadius(AppRadius.md)
            
            // 간격 선택 옵션들
            VStack(spacing: AppSpacing.xs) {
                ForEach([1, 2, 3, 5, 7, 14, 30], id: \.self) { days in
                    Button {
                        intervalDays = days
                    } label: {
                        HStack {
                            Image(systemName: intervalDays == days ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(intervalDays == days ? AppColors.primary : AppColors.textTertiary)
                            
                            Text(intervalDisplayText(for: days))
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                            
                            if days == 1 {
                                Text("(매일)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            } else if days == 7 {
                                Text("(매주)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            } else if days == 14 {
                                Text("(격주)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            } else if days == 30 {
                                Text("(매월)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(AppSpacing.sm)
                        .background(intervalDays == days ? AppColors.primarySoft : AppColors.background)
                        .cornerRadius(AppRadius.md)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func intervalDisplayText(for days: Int) -> String {
        if days == 1 {
            return DMateResourceStrings.Medication.everyDay
        } else {
            return DMateResourceStrings.Medication.everyNDays(days)
        }
    }
    
    // MARK: - Bottom Navigation Bar
    
    private var bottomNavigationBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: AppSpacing.md) {
                // 페이지 인디케이터
                HStack(spacing: AppSpacing.xs) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(currentPage >= index ? AppColors.primaryGradient : LinearGradient(colors: [AppColors.divider], startPoint: .top, endPoint: .bottom))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Spacer()
                
                // 이전 버튼
                if currentPage > 0 {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            currentPage -= 1
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text(DMateResourceStrings.Medication.previous)
                        }
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                    }
                }
                
                // 다음/저장 버튼
                if currentPage < 2 {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            currentPage += 1
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(DMateResourceStrings.Medication.next)
                            Image(systemName: "chevron.right")
                        }
                        .font(AppTypography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background((currentPage == 0 && name.isEmpty) ? LinearGradient(colors: [AppColors.divider], startPoint: .top, endPoint: .bottom) : AppColors.primaryGradient)
                        .cornerRadius(AppRadius.full)
                        .shadow(color: (currentPage == 0 && name.isEmpty) ? .clear : AppColors.primary.opacity(0.3), radius: 8, y: 4)
                        .opacity((currentPage == 0 && name.isEmpty) ? 0.5 : 1.0)
                    }
                    .disabled(currentPage == 0 && name.isEmpty)
                } else {
                    Button {
                        saveMedication()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                            Text(DMateResourceStrings.Common.save)
                        }
                        .font(AppTypography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background(name.isEmpty ? LinearGradient(colors: [AppColors.divider], startPoint: .top, endPoint: .bottom) : AppColors.successGradient)
                        .cornerRadius(AppRadius.full)
                        .shadow(color: name.isEmpty ? .clear : AppColors.success.opacity(0.3), radius: 8, y: 4)
                        .opacity(name.isEmpty ? 0.5 : 1.0)
                    }
                    .disabled(name.isEmpty)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.cardBackground)
        }
    }
    
    // MARK: - Page Header Card
    
    private func pageHeaderCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: AppSpacing.md) {
            IconBadge(icon: icon, color: color, size: 50, iconSize: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(color.opacity(0.1))
        .cornerRadius(AppRadius.lg)
    }
    
    // MARK: - Methods
    
    private func updateTimesForFrequency(_ frequency: Frequency) {
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())
        
        switch frequency {
        case .onceDaily:
            scheduleTimes = [
                calendar.date(bySettingHour: 8, minute: 0, second: 0, of: baseDate)!
            ]
        case .twiceDaily:
            scheduleTimes = [
                calendar.date(bySettingHour: 8, minute: 0, second: 0, of: baseDate)!,
                calendar.date(bySettingHour: 20, minute: 0, second: 0, of: baseDate)!
            ]
        case .threeTimesDaily:
            scheduleTimes = [
                calendar.date(bySettingHour: 8, minute: 0, second: 0, of: baseDate)!,
                calendar.date(bySettingHour: 13, minute: 0, second: 0, of: baseDate)!,
                calendar.date(bySettingHour: 20, minute: 0, second: 0, of: baseDate)!
            ]
        case .fourTimesDaily:
            scheduleTimes = [
                calendar.date(bySettingHour: 8, minute: 0, second: 0, of: baseDate)!,
                calendar.date(bySettingHour: 12, minute: 0, second: 0, of: baseDate)!,
                calendar.date(bySettingHour: 18, minute: 0, second: 0, of: baseDate)!,
                calendar.date(bySettingHour: 22, minute: 0, second: 0, of: baseDate)!
            ]
        case .custom:
            if scheduleTimes.isEmpty {
                scheduleTimes = [baseDate]
            }
        }
    }
    
    private func saveMedication() {
        // 유효성 검사
        guard !name.isEmpty else {
            validationErrorMessage = DMateResourceStrings.Medication.validationNameRequired
            showValidationError = true
            return
        }
        
        // 약물 생성 또는 업데이트
        let medication: Medication
        
        if let existing = medicationToEdit {
            medication = existing
            medication.name = name
            medication.dosage = dosage
            medication.strength = strength
            medication.form = selectedForm.rawValue
            medication.color = selectedColor.rawValue
            medication.category = selectedCategory.rawValue
            medication.purpose = purpose
            medication.prescribingDoctor = prescribingDoctor
            medication.sideEffects = sideEffects
            medication.precautions = precautions
            medication.stockCount = stockCount
            medication.lowStockThreshold = lowStockThreshold
            medication.notes = notes.isEmpty ? nil : notes
            medication.imageData = selectedImageData
        } else {
            medication = Medication(
                name: name,
                dosage: dosage,
                strength: strength,
                form: selectedForm,
                color: selectedColor,
                category: selectedCategory,
                purpose: purpose,
                prescribingDoctor: prescribingDoctor,
                sideEffects: sideEffects,
                precautions: precautions,
                stockCount: stockCount,
                lowStockThreshold: lowStockThreshold,
                imageData: selectedImageData,
                notes: notes.isEmpty ? nil : notes
            )
            
            // 스케줄 생성 (새 약물인 경우만)
            let schedule = MedicationSchedule(
                scheduleType: scheduleType,
                frequency: frequency,
                times: scheduleTimes,
                specificDays: scheduleType == .specificDays ? Array(selectedDays) : nil,
                intervalDays: scheduleType == .interval ? intervalDays : 1,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                mealRelation: mealRelation,
                notificationEnabled: notificationEnabled,
                reminderMinutesBefore: reminderMinutesBefore
            )
            
            // 약물과 스케줄 연결
            schedule.medication = medication
            medication.schedules.append(schedule)
        }
        
        onSave(medication)
        dismiss()
    }
}

// MARK: - Custom TextField

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textTertiary)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .font(AppTypography.body)
        }
        .padding(AppSpacing.md)
        .background(AppColors.background)
        .cornerRadius(AppRadius.md)
    }
}

// MARK: - Form Selection Chip

struct FormSelectionChip: View {
    let form: MedicationForm
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.xs) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.primaryGradient : LinearGradient(colors: [AppColors.divider.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: form.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                }
                .shadow(color: isSelected ? AppColors.primary.opacity(0.3) : .clear, radius: 8, y: 4)
                
                Text(form.displayName)
                    .font(AppTypography.caption2)
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
            }
            .padding(.horizontal, AppSpacing.xs)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Selection Chip

struct ColorSelectionChip: View {
    let color: MedicationColor
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.xs) {
                ZStack {
                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(color == .white ? AppColors.divider : .clear, lineWidth: 1)
                        )
                        .overlay(
                            Circle()
                                .stroke(isSelected ? AppColors.primary : .clear, lineWidth: 3)
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(color == .white || color == .yellow ? AppColors.primary : .white)
                    }
                }
                .shadow(color: isSelected ? AppColors.primary.opacity(0.3) : .clear, radius: 8, y: 4)
                
                Text(color.displayName)
                    .font(AppTypography.caption2)
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onCapture: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    AddMedicationView { _ in }
}
