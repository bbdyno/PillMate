//
//  MedicationDetailView.swift
//  PillMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import SwiftData

/// 약물 상세 화면
struct MedicationDetailView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let medication: Medication
    @State private var viewModel: MedicationDetailViewModel
    
    @State private var showEditSheet = false
    @State private var showStockSheet = false
    @State private var stockAmount = ""
    
    // MARK: - Initialization
    
    init(medication: Medication) {
        self.medication = medication
        self._viewModel = State(initialValue: MedicationDetailViewModel(medication: medication))
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 헤더
                headerSection
                
                // 통계
                statisticsSection
                
                // 스케줄
                schedulesSection
                
                // 복약 기록
                logsSection
                
                // 상세 정보
                detailsSection
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle(medication.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("편집", systemImage: "pencil")
                    }
                    
                    Button {
                        Task {
                            await viewModel.toggleActive()
                        }
                    } label: {
                        Label(
                            medication.isActive ? "복용 중단" : "복용 재개",
                            systemImage: medication.isActive ? "pause.circle" : "play.circle"
                        )
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        viewModel.showDeleteConfirmation = true
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            viewModel.setup(with: modelContext)
        }
        .sheet(isPresented: $showEditSheet) {
            AddMedicationView(medicationToEdit: medication) { _ in
                Task {
                    await viewModel.refresh()
                }
            }
        }
        .sheet(isPresented: $showStockSheet) {
            stockInputSheet
        }
        .sheet(isPresented: $viewModel.showAddScheduleSheet) {
            AddScheduleView(medication: medication) { schedule in
                Task {
                    await viewModel.addSchedule(schedule)
                }
            }
        }
        .alert("약물 삭제", isPresented: $viewModel.showDeleteConfirmation) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                Task {
                    await viewModel.deleteMedication()
                    dismiss()
                }
            }
        } message: {
            Text("이 약물과 관련된 모든 기록이 삭제됩니다.")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // 약물 이미지
            if let image = medication.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: medication.medicationForm.icon)
                            .font(.system(size: 40))
                            .foregroundColor(medication.medicationColor.swiftUIColor == .white ? .gray : medication.medicationColor.swiftUIColor)
                    }
            }
            
            // 약물 정보
            VStack(spacing: 4) {
                Text(medication.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(medication.dosage) • \(medication.strength)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !medication.purpose.isEmpty {
                    Text(medication.purpose)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !medication.isActive {
                    Text("복용 중단됨")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            // 재고 정보
            HStack(spacing: 16) {
                VStack {
                    Text("\(medication.stockCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(stockColor)
                    Text("남은 재고")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button {
                    showStockSheet = true
                } label: {
                    Label("재고 추가", systemImage: "plus.circle")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
    
    private var stockColor: Color {
        if medication.isOutOfStock { return .red }
        if medication.isLowStock { return .orange }
        return .primary
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("복약 통계")
                .font(.headline)
            
            // 기간 선택
            Picker("기간", selection: $viewModel.selectedPeriod) {
                ForEach(StatisticsPeriod.allCases) { period in
                    Text(period.displayName).tag(period)
                }
            }
            .pickerStyle(.segmented)
            
            // 통계
            HStack(spacing: 16) {
                statisticCard(
                    title: "오늘",
                    value: formatPercent(viewModel.dailyAdherenceRate),
                    color: rateColor(viewModel.dailyAdherenceRate)
                )
                
                statisticCard(
                    title: "주간",
                    value: formatPercent(viewModel.weeklyAdherenceRate),
                    color: rateColor(viewModel.weeklyAdherenceRate)
                )
                
                statisticCard(
                    title: "월간",
                    value: formatPercent(viewModel.monthlyAdherenceRate),
                    color: rateColor(viewModel.monthlyAdherenceRate)
                )
                
                statisticCard(
                    title: "연속",
                    value: "\(viewModel.consecutiveDays)일",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
    
    private func statisticCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func rateColor(_ rate: Double) -> Color {
        if rate >= 0.8 { return .green }
        if rate >= 0.5 { return .orange }
        return .red
    }
    
    // MARK: - Schedules Section
    
    private var schedulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("복용 스케줄")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    viewModel.showAddScheduleSheet = true
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
            
            if viewModel.activeSchedules.isEmpty {
                Text("등록된 스케줄이 없습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.activeSchedules) { schedule in
                    ScheduleRow(schedule: schedule)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteSchedule(schedule)
                                }
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Logs Section
    
    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("최근 복약 기록")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink {
                    LogHistoryView()
                } label: {
                    Text("전체 보기")
                        .font(.subheadline)
                }
            }
            
            if viewModel.logs.isEmpty {
                Text("복약 기록이 없습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.logs.prefix(5)) { log in
                    LogRow(log: log)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("상세 정보")
                .font(.headline)
            
            if !medication.prescribingDoctor.isEmpty {
                detailRow(title: "처방 의사", value: medication.prescribingDoctor)
            }
            
            if !medication.sideEffects.isEmpty {
                detailRow(title: "부작용", value: medication.sideEffects)
            }
            
            if !medication.precautions.isEmpty {
                detailRow(title: "주의사항", value: medication.precautions)
            }
            
            if let notes = medication.notes, !notes.isEmpty {
                detailRow(title: "메모", value: notes)
            }
            
            detailRow(title: "등록일", value: Formatters.fullDate.string(from: medication.createdAt))
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
    
    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Stock Input Sheet
    
    private var stockInputSheet: some View {
        NavigationStack {
            Form {
                Section("재고 추가") {
                    TextField("수량", text: $stockAmount)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("추가") {
                        if let amount = Int(stockAmount), amount > 0 {
                            medication.increaseStock(by: amount)
                            try? modelContext.save()
                            stockAmount = ""
                            showStockSheet = false
                        }
                    }
                    .disabled(Int(stockAmount) == nil || Int(stockAmount)! <= 0)
                }
            }
            .navigationTitle("재고 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        stockAmount = ""
                        showStockSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Schedule Row

struct ScheduleRow: View {
    let schedule: MedicationSchedule
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.descriptionText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                let times = schedule.times
                Text(times.map { formatTime($0) }
                    .joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if schedule.mealRelationEnum != .anytime {
                Text(schedule.mealRelationEnum.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Log Row

struct LogRow: View {
    let log: MedicationLog
    
    var body: some View {
        HStack {
            Image(systemName: log.statusIcon)
                .foregroundColor(log.statusColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(Formatters.dateWithWeekday.string(from: log.scheduledTime))
                    .font(.subheadline)
                
                Text(formatTime(log.scheduledTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(log.logStatus.displayName)
                .font(.caption)
                .foregroundColor(log.statusColor)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Schedule View

struct AddScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    
    let medication: Medication
    let onSave: (MedicationSchedule) -> Void
    
    @State private var scheduleType: ScheduleType = .daily
    @State private var frequency: Frequency = .onceDaily
    @State private var times: [Date] = [Date()]
    @State private var selectedDays: Set<Int> = []
    @State private var mealRelation: MealRelation = .anytime
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date().addingDays(30)
    @State private var notificationEnabled = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("복용 주기") {
                    Picker("주기 타입", selection: $scheduleType) {
                        ForEach(ScheduleType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    if scheduleType == .specificDays {
                        weekdaySelector
                    }
                }
                
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
                
                Section("복용 시간") {
                    ForEach(times.indices, id: \.self) { index in
                        DatePicker(
                            "시간 \(index + 1)",
                            selection: $times[index],
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
                
                Section("식사와의 관계") {
                    Picker("", selection: $mealRelation) {
                        ForEach(MealRelation.allCases) { relation in
                            Text(relation.displayName).tag(relation)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("알림") {
                    Toggle("알림 받기", isOn: $notificationEnabled)
                }
            }
            .navigationTitle("스케줄 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") {
                        saveSchedule()
                    }
                }
            }
        }
    }
    
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
                        .font(.caption)
                        .frame(width: 32, height: 32)
                        .background(selectedDays.contains(weekday.rawValue) ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedDays.contains(weekday.rawValue) ? .white : .primary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func updateTimesForFrequency(_ frequency: Frequency) {
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())
        
        switch frequency {
        case .onceDaily:
            times = [calendar.date(bySettingHour: 8, minute: 0, second: 0, of: baseDate)!]
        case .twiceDaily:
            times = [
                calendar.date(bySettingHour: 8, minute: 0, second: 0, of: baseDate)!,
                calendar.date(bySettingHour: 20, minute: 0, second: 0, of: baseDate)!
            ]
        case .threeTimesDaily:
            times = [
                calendar.date(bySettingHour: 8, minute: 0, second: 0, of: baseDate)!,
                calendar.date(bySettingHour: 13, minute: 0, second: 0, of: baseDate)!,
                calendar.date(bySettingHour: 20, minute: 0, second: 0, of: baseDate)!
            ]
        case .fourTimesDaily:
            times = [
                calendar.date(bySettingHour: 8, minute: 0, second: 0, of: baseDate)!,
                calendar.date(bySettingHour: 12, minute: 0, second: 0, of: baseDate)!,
                calendar.date(bySettingHour: 18, minute: 0, second: 0, of: baseDate)!,
                calendar.date(bySettingHour: 22, minute: 0, second: 0, of: baseDate)!
            ]
        case .custom:
            break
        }
    }
    
    private func saveSchedule() {
        let schedule = MedicationSchedule(
            scheduleType: scheduleType,
            frequency: frequency,
            times: times,
            specificDays: scheduleType == .specificDays ? Array(selectedDays) : nil,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            mealRelation: mealRelation,
            notificationEnabled: notificationEnabled
        )
        
        onSave(schedule)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MedicationDetailView(medication: Medication.preview)
    }
    .modelContainer(for: [Medication.self, MedicationSchedule.self, MedicationLog.self], inMemory: true)
}
