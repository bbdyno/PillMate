//
//  AddMedicationView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
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
            TabView(selection: $currentPage) {
                basicInfoPage.tag(0)
                scheduleSettingsPage.tag(1)
                additionalInfoPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .navigationTitle(medicationToEdit == nil ? "약물 추가" : "약물 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if currentPage == 2 {
                        Button("저장") {
                            saveMedication()
                        }
                        .fontWeight(.semibold)
                        .disabled(name.isEmpty)
                    } else {
                        Button("다음") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                pageIndicator
            }
            .alert("입력 오류", isPresented: $showValidationError) {
                Button("확인", role: .cancel) {}
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
        Form {
            // 이미지 섹션
            Section {
                HStack {
                    Spacer()
                    
                    imageSelector
                    
                    Spacer()
                }
            }
            
            // 기본 정보
            Section("기본 정보") {
                TextField("약물 이름 *", text: $name)
                
                TextField("용량 (예: 1정, 5mL)", text: $dosage)
                
                TextField("강도 (예: 500mg)", text: $strength)
            }
            
            // 형태 및 색상
            Section("약물 형태") {
                Picker("형태", selection: $selectedForm) {
                    ForEach(MedicationForm.allCases) { form in
                        Label(form.displayName, systemImage: form.icon)
                            .tag(form)
                    }
                }
                
                Picker("색상", selection: $selectedColor) {
                    ForEach(MedicationColor.allCases) { color in
                        HStack {
                            Circle()
                                .fill(color.swiftUIColor)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray, lineWidth: color == .white ? 1 : 0)
                                )
                            Text(color.displayName)
                        }
                        .tag(color)
                    }
                }
            }
            
            // 목적
            Section("복용 목적") {
                TextField("질환 또는 복용 목적", text: $purpose)
            }
        }
    }
    
    // MARK: - Page 2: Schedule
    
    private var scheduleSettingsPage: some View {
        Form {
            // 스케줄 타입
            Section("복용 주기") {
                Picker("주기 타입", selection: $scheduleType) {
                    ForEach(ScheduleType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                
                if scheduleType == .specificDays {
                    weekdaySelector
                }
            }
            
            // 복용 횟수
            Section("복용 횟수") {
                Picker("하루 복용 횟수", selection: $frequency) {
                    ForEach(Frequency.allCases) { freq in
                        Text(freq.displayName).tag(freq)
                    }
                }
                .onChange(of: frequency) { _, newValue in
                    updateTimesForFrequency(newValue)
                }
            }
            
            // 복용 시간
            Section("복용 시간") {
                ForEach(scheduleTimes.indices, id: \.self) { index in
                    DatePicker(
                        "시간 \(index + 1)",
                        selection: $scheduleTimes[index],
                        displayedComponents: .hourAndMinute
                    )
                }
                
                if frequency == .custom {
                    Button {
                        scheduleTimes.append(Date())
                    } label: {
                        Label("시간 추가", systemImage: "plus")
                    }
                }
            }
            
            // 식사 관계
            Section("식사와의 관계") {
                Picker("", selection: $mealRelation) {
                    ForEach(MealRelation.allCases) { relation in
                        Label(relation.displayName, systemImage: relation.icon)
                            .tag(relation)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
            
            // 기간
            Section("복용 기간") {
                DatePicker("시작일", selection: $startDate, displayedComponents: .date)
                
                Toggle("종료일 설정", isOn: $hasEndDate)
                
                if hasEndDate {
                    DatePicker("종료일", selection: $endDate, displayedComponents: .date)
                }
            }
            
            // 알림
            Section("알림") {
                Toggle("알림 받기", isOn: $notificationEnabled)
                
                if notificationEnabled {
                    Picker("미리 알림", selection: $reminderMinutesBefore) {
                        Text("정각에").tag(0)
                        Text("5분 전").tag(5)
                        Text("10분 전").tag(10)
                        Text("15분 전").tag(15)
                        Text("30분 전").tag(30)
                    }
                }
            }
        }
    }
    
    // MARK: - Page 3: Additional Info
    
    private var additionalInfoPage: some View {
        Form {
            // 의사 정보
            Section("처방 정보") {
                TextField("처방 의사", text: $prescribingDoctor)
            }
            
            // 재고
            Section("재고 관리") {
                Stepper("현재 재고: \(stockCount)개", value: $stockCount, in: 0...999)
                
                Stepper("부족 알림 기준: \(lowStockThreshold)개", value: $lowStockThreshold, in: 1...50)
            }
            
            // 부작용
            Section("부작용") {
                TextField("알려진 부작용", text: $sideEffects, axis: .vertical)
                    .lineLimit(3...5)
            }
            
            // 주의사항
            Section("주의사항") {
                TextField("복용 주의사항", text: $precautions, axis: .vertical)
                    .lineLimit(3...5)
            }
            
            // 메모
            Section("메모") {
                TextField("추가 메모", text: $notes, axis: .vertical)
                    .lineLimit(3...5)
            }
        }
    }
    
    // MARK: - Image Selector
    
    private var imageSelector: some View {
        VStack(spacing: 12) {
            if let imageData = selectedImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button("사진 변경") {
                    selectedImageData = nil
                }
                .font(.caption)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "pill.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
                
                HStack(spacing: 20) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("갤러리", systemImage: "photo")
                    }
                    
                    Button {
                        showCamera = true
                    } label: {
                        Label("카메라", systemImage: "camera")
                    }
                }
                .font(.subheadline)
            }
        }
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
        HStack(spacing: 8) {
            ForEach(Weekday.allCases) { weekday in
                Button {
                    if selectedDays.contains(weekday.rawValue) {
                        selectedDays.remove(weekday.rawValue)
                    } else {
                        selectedDays.insert(weekday.rawValue)
                    }
                } label: {
                    Text(weekday.shortName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(width: 36, height: 36)
                        .background(
                            selectedDays.contains(weekday.rawValue)
                            ? Color.blue
                            : Color.gray.opacity(0.2)
                        )
                        .foregroundColor(
                            selectedDays.contains(weekday.rawValue)
                            ? .white
                            : .primary
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Page Indicator
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(Color.appBackground)
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
            validationErrorMessage = "약물 이름을 입력해주세요."
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
                purpose: purpose,
                prescribingDoctor: prescribingDoctor,
                sideEffects: sideEffects,
                precautions: precautions,
                stockCount: stockCount,
                lowStockThreshold: lowStockThreshold,
                imageData: selectedImageData,
                notes: notes.isEmpty ? nil : notes
            )
        }
        
        onSave(medication)
        dismiss()
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
