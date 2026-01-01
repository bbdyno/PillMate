//
//  MedicationDetailView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import DMateDesignSystem
import DMateResource
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

                // 관련 건강 지표
                if !medication.relatedMetricTypes.isEmpty {
                    relatedHealthMetricsSection
                }

                // 복약 기록
                logsSection
                
                // 상세 정보
                detailsSection
            }
            .padding()
        }
        .background(AppColors.background)
        .navigationTitle(medication.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label(DMateResourceStrings.Common.edit, systemImage: "pencil")
                    }

                    Button {
                        Task {
                            await viewModel.toggleActive()
                        }
                    } label: {
                        Label(
                            medication.isActive ? DMateResourceStrings.Medication.pauseAction : DMateResourceStrings.Medication.resumeAction,
                            systemImage: medication.isActive ? "pause.circle" : "play.circle"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        viewModel.showDeleteConfirmation = true
                    } label: {
                        Label(DMateResourceStrings.Common.delete, systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .toolbarBackground(.clear, for: .navigationBar)
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
        .alert(DMateResourceStrings.Medication.deleteTitle, isPresented: $viewModel.showDeleteConfirmation) {
            Button(DMateResourceStrings.Common.cancel, role: .cancel) {}
            Button(DMateResourceStrings.Common.delete, role: .destructive) {
                Task {
                    await viewModel.deleteMedication()
                    dismiss()
                }
            }
        } message: {
            Text(DMateResourceStrings.Medication.deleteMessage)
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
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(AppColors.divider.opacity(0.5))
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
                    Text(DMateResourceStrings.Medication.discontinuedStatus)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.divider.opacity(0.3))
                        .cornerRadius(AppRadius.sm)
                }
            }
            
            // 재고 정보
            HStack(spacing: 16) {
                VStack {
                    Text("\(medication.stockCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(stockColor)
                    Text(DMateResourceStrings.Medication.stockRemaining)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button {
                    showStockSheet = true
                } label: {
                    Label(DMateResourceStrings.Medication.addStock, systemImage: "plus.circle")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadius.lg)
    }
    
    private var stockColor: Color {
        if medication.isOutOfStock { return AppColors.danger }
        if medication.isLowStock { return AppColors.warning }
        return AppColors.primary
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(DMateResourceStrings.Medication.adherenceStats)
                .font(.headline)

            // 기간 선택
            Picker(DMateResourceStrings.Medication.periodLabel, selection: $viewModel.selectedPeriod) {
                ForEach(StatisticsPeriod.allCases) { period in
                    Text(period.displayName).tag(period)
                }
            }
            .pickerStyle(.segmented)

            // 통계
            HStack(spacing: 16) {
                statisticCard(
                    title: DMateResourceStrings.Medication.periodToday,
                    value: formatPercent(viewModel.dailyAdherenceRate),
                    color: rateColor(viewModel.dailyAdherenceRate)
                )

                statisticCard(
                    title: DMateResourceStrings.Medication.periodWeekly,
                    value: formatPercent(viewModel.weeklyAdherenceRate),
                    color: rateColor(viewModel.weeklyAdherenceRate)
                )

                statisticCard(
                    title: DMateResourceStrings.Medication.periodMonthly,
                    value: formatPercent(viewModel.monthlyAdherenceRate),
                    color: rateColor(viewModel.monthlyAdherenceRate)
                )

                statisticCard(
                    title: DMateResourceStrings.Medication.periodStreak,
                    value: DMateResourceStrings.Common.daysFormat(viewModel.consecutiveDays),
                    color: AppColors.warning
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadius.lg)
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
        if rate >= 0.8 { return AppColors.chartGreen }
        if rate >= 0.5 { return AppColors.chartOrange }
        return AppColors.chartRed
    }
    
    // MARK: - Schedules Section
    
    private var schedulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(DMateResourceStrings.Medication.scheduleTitle)
                    .font(.headline)

                Spacer()

                Button {
                    viewModel.showAddScheduleSheet = true
                } label: {
                    Image(systemName: "plus.circle")
                }
            }

            if viewModel.activeSchedules.isEmpty {
                Text(DMateResourceStrings.Medication.noSchedules)
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
                                Label(DMateResourceStrings.Common.delete, systemImage: "trash")
                            }
                        }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadius.lg)
    }
    
    // MARK: - Logs Section
    
    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(DMateResourceStrings.Medication.recentLogs)
                    .font(.headline)

                Spacer()

                NavigationLink {
                    LogHistoryView()
                } label: {
                    Text(DMateResourceStrings.Medication.viewAll)
                        .font(.subheadline)
                }
            }

            if viewModel.logs.isEmpty {
                Text(DMateResourceStrings.Medication.noLogs)
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
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadius.lg)
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(DMateResourceStrings.Medication.detailInfo)
                .font(.headline)

            if !medication.prescribingDoctor.isEmpty {
                detailRow(title: DMateResourceStrings.Medication.prescribingDoctor, value: medication.prescribingDoctor)
            }

            if !medication.sideEffects.isEmpty {
                detailRow(title: DMateResourceStrings.Medication.sideEffectsSection, value: medication.sideEffects)
            }

            if !medication.precautions.isEmpty {
                detailRow(title: DMateResourceStrings.Medication.precautionsSection, value: medication.precautions)
            }

            if let notes = medication.notes, !notes.isEmpty {
                detailRow(title: DMateResourceStrings.Common.memo, value: notes)
            }

            detailRow(title: DMateResourceStrings.Medication.registrationDate, value: Formatters.fullDate.string(from: medication.createdAt))
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadius.lg)
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

    // MARK: - Related Health Metrics Section

    private var relatedHealthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(DMateResourceStrings.Medication.healthMetricsTitle)
                .font(.headline)

            Text("\(medication.medicationCategory.displayName) 약물과 관련된 건강 지표를 추적하세요")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                ForEach(medication.relatedMetricTypes) { metricType in
                    HStack {
                        Image(systemName: metricType.icon)
                            .font(.system(size: 18))
                            .foregroundColor(metricType.color)
                            .frame(width: 32, height: 32)
                            .background(metricType.color.opacity(0.1))
                            .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(metricType.displayName)
                                .font(.subheadline)
                                .foregroundColor(.primary)

                            if let latestMetric = viewModel.latestMetrics[metricType] {
                                Text("\(latestMetric.displayValue) \(latestMetric.unit) · \(latestMetric.recordedAt.relativeTimeString)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(DMateResourceStrings.Medication.noHealthData)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, AppSpacing.sm)
                    .padding(.horizontal, AppSpacing.md)
                    .background(AppColors.cardBackground.opacity(0.5))
                    .cornerRadius(AppRadius.md)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadius.lg)
    }

    // MARK: - Stock Input Sheet

    private var stockInputSheet: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                    .frame(height: AppSpacing.md)
                
                // 아이콘
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.primary)
                    }

                VStack(spacing: AppSpacing.xs) {
                    Text(DMateResourceStrings.Medication.addStock)
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)

                    Text(medication.name)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }

                // 수량 입력
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(DMateResourceStrings.MedicationDetail.quantityToAdd)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(AppColors.textTertiary)
                            .frame(width: 24)

                        TextField("0", text: $stockAmount)
                            .keyboardType(.numberPad)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.background)
                    .cornerRadius(AppRadius.md)
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()

                // 버튼들
                VStack(spacing: AppSpacing.sm) {
                    Button {
                        if let amount = Int(stockAmount), amount > 0 {
                            medication.increaseStock(by: amount)
                            try? modelContext.save()
                            stockAmount = ""
                            showStockSheet = false
                        }
                    } label: {
                        Text(DMateResourceStrings.Common.add)
                            .font(AppTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(AppSpacing.md)
                            .background(
                                (Int(stockAmount) ?? 0) > 0
                                    ? AppColors.primaryGradient
                                    : LinearGradient(colors: [AppColors.divider], startPoint: .top, endPoint: .bottom)
                            )
                            .cornerRadius(AppRadius.md)
                    }
                    .disabled(Int(stockAmount) == nil || Int(stockAmount)! <= 0)

                    Button {
                        stockAmount = ""
                        showStockSheet = false
                    } label: {
                        Text(DMateResourceStrings.Common.cancel)
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(AppSpacing.md)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            .padding(AppSpacing.lg)
            .background(AppColors.cardBackground)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
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
                    .background(AppColors.primarySoft)
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
                Section(DMateResourceStrings.Medication.cycleSection) {
                    Picker(DMateResourceStrings.Medication.cycleTypeLabel, selection: $scheduleType) {
                        ForEach(ScheduleType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    if scheduleType == .specificDays {
                        weekdaySelector
                    }
                }

                Section(DMateResourceStrings.Medication.frequencySection) {
                    Picker(DMateResourceStrings.Medication.frequencyPickerLabel, selection: $frequency) {
                        ForEach(Frequency.allCases) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                    .onChange(of: frequency) { _, newValue in
                        updateTimesForFrequency(newValue)
                    }
                }

                Section(DMateResourceStrings.Medication.timeSection) {
                    ForEach(times.indices, id: \.self) { index in
                        DatePicker(
                            DMateResourceStrings.Medication.timeN(index + 1),
                            selection: $times[index],
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                Section(DMateResourceStrings.Medication.mealRelationSection) {
                    Picker("", selection: $mealRelation) {
                        ForEach(MealRelation.allCases) { relation in
                            Text(relation.displayName).tag(relation)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(DMateResourceStrings.Medication.notificationSection) {
                    Toggle(DMateResourceStrings.Medication.receiveNotification, isOn: $notificationEnabled)
                }
            }
            .navigationTitle(DMateResourceStrings.Schedule.addTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(DMateResourceStrings.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(DMateResourceStrings.Common.save) {
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
                        .background(selectedDays.contains(weekday.rawValue) ? AppColors.primary : AppColors.divider)
                        .foregroundColor(selectedDays.contains(weekday.rawValue) ? .white : AppColors.textPrimary)
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
