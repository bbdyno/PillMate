//
//  HomeView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import DMateDesignSystem
import DMateResource
import SwiftData

/// 메인 홈 화면
struct HomeView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var showSkipReasonSheet = false
    @State private var selectedLogForSkip: MedicationLog?
    @State private var skipReason = ""
    @State private var showPatientSelector = false
    @State private var showAddMedicationSheet = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // 헤더 카드
                    headerCard

                    // 환자 선택 바 (환자가 2명 이상일 때만 표시)
                    if viewModel.patients.count > 1 {
                        patientSelectorBar
                    }
                    
                    // 다음 복약 카드
                    if let nextLog = viewModel.nextLog {
                        nextDoseCard(nextLog)
                    }
                    
                    // 오늘의 복약 일정
                    todayScheduleSection
                    
                    // 재고 부족 경고
                    if !viewModel.lowStockMedications.isEmpty {
                        lowStockSection
                    }
                    
                    // 오늘의 진료 예약
                    if !viewModel.todayAppointments.isEmpty {
                        appointmentSection
                    }
                }
                .padding(.top, AppSpacing.sm)
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(DMateResourceStrings.App.name)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.refresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .toolbarBackground(.clear, for: .navigationBar)
            .refreshable {
                await viewModel.refresh()
            }
            .onAppear {
                viewModel.setup(with: modelContext)
            }
            .sheet(isPresented: $showSkipReasonSheet) {
                skipReasonSheet
            }
            .sheet(isPresented: $showPatientSelector) {
                PatientSelectorSheet(
                    patients: viewModel.patients,
                    selectedPatient: viewModel.selectedPatient,
                    onSelect: { patient in
                        viewModel.selectPatient(patient)
                        showPatientSelector = false
                    }
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showAddMedicationSheet) {
                AddMedicationView { medication in
                    Task {
                        // ModelContext에 약물 추가
                        modelContext.insert(medication)

                        do {
                            try modelContext.save()
                            print("[HomeView] 약물 저장 완료: \(medication.name)")

                            // 오늘의 복약 로그 생성
                            DataManager.shared.generateTodayLogs()
                            print("[HomeView] 복약 로그 생성 완료")

                            // 위젯 데이터 업데이트
                            WidgetDataUpdater.shared.updateWidgetData(context: modelContext)
                            print("[HomeView] 위젯 데이터 업데이트 완료")

                            // 데이터 리로드
                            await viewModel.loadData()
                        } catch {
                            print("[HomeView] 약물 저장 실패: \(error)")
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showHealthMetricPrompt) {
                quickHealthMetricInputSheet
            }
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(spacing: 0) {
            // 그라데이션 헤더
            VStack(spacing: AppSpacing.md) {
                // 인사말
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greetingText)
                            .font(AppTypography.subheadline)
                            .foregroundColor(Color.white.opacity(0.95))
                        Text(viewModel.medicationTitle)
                            .font(AppTypography.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()

                    // 환자 선택 버튼 (환자가 2명 이상일 때만 표시)
                    if viewModel.patients.count > 1 {
                        Button {
                            showPatientSelector = true
                        } label: {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if let patient = viewModel.selectedPatient {
                                        Text(patient.initials)
                                            .font(AppTypography.headline)
                                            .foregroundColor(.white)
                                    }
                                }
                        }
                    }
                }
                
                // 준수율 링
                HStack(spacing: AppSpacing.xl) {
                    adherenceRing(
                        title: DMateResourceStrings.Period.today,
                        rate: viewModel.todayAdherenceRate,
                        size: 85
                    )

                    adherenceRing(
                        title: DMateResourceStrings.Period.thisWeek,
                        rate: viewModel.weekAdherenceRate,
                        size: 70
                    )

                    adherenceRing(
                        title: DMateResourceStrings.Period.thisMonth,
                        rate: viewModel.monthAdherenceRate,
                        size: 70
                    )
                }
                .padding(.vertical, AppSpacing.sm)
            }
            .padding(AppSpacing.lg)
            .background(AppColors.headerGradient)
            
            // 통계 바
            HStack {
                statisticItem(
                    icon: "checkmark.circle.fill",
                    value: "\(viewModel.completedLogsCount)",
                    label: DMateResourceStrings.Home.completed,
                    color: AppColors.success
                )
                
                Divider()
                    .frame(height: 40)
                
                statisticItem(
                    icon: "clock.fill",
                    value: "\(viewModel.pendingLogsCount)",
                    label: DMateResourceStrings.Home.pending,
                    color: AppColors.warning
                )
                
                Divider()
                    .frame(height: 40)
                
                statisticItem(
                    icon: "flame.fill",
                    value: "\(viewModel.consecutiveDays)일",
                    label: DMateResourceStrings.Home.streak,
                    color: AppColors.peach
                )
            }
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.cardBackground)
        }
        .cornerRadius(AppRadius.xl)
        .shadow(color: AppColors.primary.opacity(0.15), radius: 20, y: 10)
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return DMateResourceStrings.Home.greetingMorning
        case 12..<17: return DMateResourceStrings.Home.greetingAfternoon
        case 17..<21: return DMateResourceStrings.Home.greetingEvening
        default: return DMateResourceStrings.Home.greetingDefault
        }
    }
    
    private func adherenceRing(title: String, rate: Double, size: CGFloat) -> some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: size == 85 ? 8 : 6)

                Circle()
                    .trim(from: 0, to: rate)
                    .stroke(
                        Color.white,
                        style: StrokeStyle(lineWidth: size == 85 ? 8 : 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.8), value: rate)

                Text("\(Int(rate * 100))%")
                    .font(size == 85 ? AppTypography.headline : AppTypography.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: size, height: size)

            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(Color.white.opacity(0.95))
        }
    }
    
    private func statisticItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
                Text(value)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Patient Selector Bar

    private var patientSelectorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                // 환자 목록 (본인 포함)
                ForEach(viewModel.patients) { patient in
                    PatientChipView(
                        name: patient.displayName,
                        color: patient.color,
                        isSelected: viewModel.selectedPatient?.id == patient.id,
                        onTap: {
                            viewModel.selectPatient(patient)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Next Dose Card
    
    private func nextDoseCard(_ log: MedicationLog) -> some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                IconBadge(icon: "bell.fill", color: AppColors.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(DMateResourceStrings.Reminders.title)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    if let timeText = viewModel.timeUntilNextDoseText {
                        Text(timeText)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.primary)
                    }
                }
                
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(AppColors.primarySoft)
            
            // 약물 정보
            if let medication = log.medication {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(medication.name)
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        HStack(spacing: AppSpacing.xs) {
                            Text(medication.dosage)
                            Text("•")
                            Text(formatTime(log.scheduledTime))
                        }
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // 복용 버튼
                    Button {
                        Task {
                            await viewModel.markAsTaken(log)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(AppColors.successGradient)
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(viewModel.processingLogId == log.id)
                    .shadow(color: AppColors.success.opacity(0.4), radius: 8, y: 4)
                }
                .padding(AppSpacing.md)
            }
        }
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadius.xl)
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
    }
    
    // MARK: - Today Schedule Section
    
    private var todayScheduleSection: some View {
        VStack(alignment: .center, spacing: AppSpacing.md) {
            SectionHeader(
                title: DMateResourceStrings.Reminders.title,
                subtitle: "\(viewModel.completedLogsCount)/\(viewModel.totalLogsCount) \(DMateResourceStrings.Status.taken)"
            )
            
            if viewModel.todayLogs.isEmpty {
                emptyScheduleView
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.groupedLogs, id: \.title) { group in
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            // 시간대 헤더
                            Text(group.title)
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.leading, AppSpacing.xs)
                            
                            VStack(spacing: AppSpacing.xs) {
                                ForEach(group.logs) { log in
                                    MedicationLogCard(
                                        log: log,
                                        onTaken: {
                                            Task {
                                                await viewModel.markAsTaken(log)
                                            }
                                        },
                                        onSkip: {
                                            selectedLogForSkip = log
                                            showSkipReasonSheet = true
                                        },
                                        onSnooze: { minutes in
                                            Task {
                                                await viewModel.snooze(log, minutes: minutes)
                                            }
                                        },
                                        isProcessing: viewModel.processingLogId == log.id
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var emptyScheduleView: some View {
        EmptyStateView(
            icon: "checkmark.seal.fill",
            title: DMateResourceStrings.LogHistory.noRecords,
            description: DMateResourceStrings.MedicationList.addToStart,
            buttonTitle: DMateResourceStrings.Medications.add,
            action: { showAddMedicationSheet = true }
        )
//        .cardStyle(padding: AppSpacing.xl)
    }
    
    // MARK: - Low Stock Section
    
    private var lowStockSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: DMateResourceStrings.Home.lowStock, subtitle: "\(viewModel.lowStockMedications.count)개 \(DMateResourceStrings.Tab.medications)")
            
            VStack(spacing: AppSpacing.xs) {
                ForEach(viewModel.lowStockMedications) { medication in
                    HStack {
                        IconBadge(icon: "exclamationmark.triangle.fill", color: AppColors.warning, size: 36, iconSize: 16)
                        
                        Text(medication.name)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Text("\(medication.stockCount)개 남음")
                            .font(AppTypography.subheadline)
                            .foregroundColor(medication.isOutOfStock ? AppColors.danger : AppColors.warning)
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.warning.opacity(0.08))
                    .cornerRadius(AppRadius.md)
                }
            }
        }
    }
    
    // MARK: - Appointment Section
    
    private var appointmentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: DMateResourceStrings.Home.todayAppointments, subtitle: "\(viewModel.todayAppointments.count)개 \(DMateResourceStrings.Reminders.title)")
            
            VStack(spacing: AppSpacing.xs) {
                ForEach(viewModel.todayAppointments) { appointment in
                    HStack {
                        IconBadge(icon: "stethoscope", color: AppColors.lavender, size: 40, iconSize: 18)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appointment.doctorName)
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)
                            if let specialty = appointment.specialty {
                                Text(specialty)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text(formatTime(appointment.appointmentDate))
                            .font(AppTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.lavender)
                    }
                    .cardStyle(padding: AppSpacing.sm)
                }
            }
        }
    }
    
    // MARK: - Skip Reason Sheet
    
    private var skipReasonSheet: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                // 아이콘
                IconBadge(icon: "forward.fill", color: AppColors.warning, size: 60, iconSize: 28)
                
                Text(DMateResourceStrings.Status.skipped)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)

                // 이유 입력
                TextField(DMateResourceStrings.Common.edit, text: $skipReason, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(AppSpacing.md)
                    .background(AppColors.background)
                    .cornerRadius(AppRadius.md)
                    .lineLimit(3...5)
                
                Spacer()
                
                // 버튼들
                VStack(spacing: AppSpacing.sm) {
                    Button(DMateResourceStrings.Status.skipped) {
                        if let log = selectedLogForSkip {
                            Task {
                                await viewModel.markAsSkipped(
                                    log,
                                    reason: skipReason.isEmpty ? nil : skipReason
                                )
                                skipReason = ""
                                selectedLogForSkip = nil
                                showSkipReasonSheet = false
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button(DMateResourceStrings.Common.cancel) {
                        skipReason = ""
                        selectedLogForSkip = nil
                        showSkipReasonSheet = false
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(AppSpacing.lg)
            .background(AppColors.cardBackground)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Quick Health Metric Input Sheet

    private var quickHealthMetricInputSheet: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                if let log = viewModel.logForHealthMetric,
                   let medication = log.medication {

                    // 약물 정보
                    HStack(spacing: AppSpacing.md) {
                        Circle()
                            .fill(medication.medicationColor.swiftUIColor.gradient)
                            .frame(width: 48, height: 48)
                            .overlay {
                                Image(systemName: medication.medicationForm.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(medication.name)
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)

                            Text(DMateResourceStrings.Health.recordAfterMedication)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppRadius.lg)

                    // 관련 건강 지표 버튼들
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text(DMateResourceStrings.Health.selectMetrics)
                            .font(AppTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)

                        ForEach(medication.relatedMetricTypes.prefix(3)) { metricType in
                            Button {
                                viewModel.showHealthMetricPrompt = false
                                // TODO: 건강 탭으로 이동하거나 바로 입력
                            } label: {
                                HStack {
                                    Image(systemName: metricType.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(metricType.color)
                                        .frame(width: 40, height: 40)
                                        .background(metricType.color.opacity(0.1))
                                        .cornerRadius(AppRadius.sm)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(metricType.displayName)
                                            .font(AppTypography.subheadline)
                                            .foregroundColor(AppColors.textPrimary)

                                        Text(DMateResourceStrings.Health.recordNow(metricType.displayName))
                                            .font(AppTypography.caption2)
                                            .foregroundColor(AppColors.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppColors.textTertiary)
                                }
                                .padding(AppSpacing.md)
                                .background(AppColors.cardBackground)
                                .cornerRadius(AppRadius.lg)
                                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()

                    // 나중에 하기 버튼
                    Button {
                        viewModel.showHealthMetricPrompt = false
                        viewModel.logForHealthMetric = nil
                    } label: {
                        Text(DMateResourceStrings.Health.recordLater)
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(AppSpacing.md)
                    }
                }
            }
            .padding(AppSpacing.lg)
            .background(AppColors.background)
            .navigationTitle(DMateResourceStrings.Health.recordTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Medication Log Card

struct MedicationLogCard: View {
    let log: MedicationLog
    let onTaken: () -> Void
    let onSkip: () -> Void
    let onSnooze: (Int) -> Void
    let isProcessing: Bool
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // 상태 체크박스
            statusCheckbox
            
            // 약물 정보
            VStack(alignment: .leading, spacing: 2) {
                if let medication = log.medication {
                    Text(medication.name)
                        .font(AppTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(isCompleted ? AppColors.textTertiary : AppColors.textPrimary)
                        .strikethrough(isCompleted)
                    
                    HStack(spacing: AppSpacing.xs) {
                        Text(medication.dosage)
                        Text("•")
                        Text(formatTime(log.scheduledTime))
                        
                        if let timeText = log.timeRemainingText, log.logStatus == .pending {
                            Text("•")
                            Text(timeText)
                                .foregroundColor(log.isPastDue ? AppColors.danger : AppColors.textTertiary)
                        }
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            // 액션 버튼
            if log.logStatus == .pending {
                actionButtons
            } else {
                StatusBadge(
                    text: log.logStatus.displayName,
                    status: statusForLogStatus
                )
            }
        }
        .padding(AppSpacing.sm)
        .background(isCompleted ? AppColors.background : AppColors.cardBackground)
        .cornerRadius(AppRadius.md)
        .shadow(color: isCompleted ? .clear : Color.black.opacity(0.04), radius: 8, y: 2)
    }
    
    private var isCompleted: Bool {
        log.logStatus == .taken || log.logStatus == .skipped
    }
    
    private var statusCheckbox: some View {
        ZStack {
            Circle()
                .fill(checkboxColor)
                .frame(width: 32, height: 32)
            
            Image(systemName: checkboxIcon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private var checkboxColor: Color {
        switch log.logStatus {
        case .taken, .delayed:
            return AppColors.success
        case .skipped:
            return AppColors.textTertiary
        case .snoozed:
            return AppColors.warning
        case .pending:
            return log.isPastDue ? AppColors.warning : AppColors.divider
        }
    }
    
    private var checkboxIcon: String {
        switch log.logStatus {
        case .taken, .delayed:
            return "checkmark"
        case .skipped:
            return "forward.fill"
        case .snoozed:
            return "bell.slash.fill"
        case .pending:
            return log.isPastDue ? "exclamationmark" : "circle"
        }
    }
    
    private var statusForLogStatus: StatusBadge.Status {
        switch log.logStatus {
        case .taken, .delayed:
            return .success
        case .skipped:
            return .pending
        case .snoozed:
            return .warning
        case .pending:
            return .info
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: AppSpacing.xs) {
            // 스누즈 버튼
            Menu {
                ForEach(SnoozeOption.allCases) { option in
                    Button(option.displayName) {
                        onSnooze(option.rawValue)
                    }
                }
            } label: {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.warning)
                    .frame(width: 36, height: 36)
                    .background(AppColors.warning.opacity(0.12))
                    .cornerRadius(AppRadius.sm)
            }
            
            // 건너뛰기 버튼
            Button(action: onSkip) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.divider)
                    .cornerRadius(AppRadius.sm)
            }
            
            // 복용 완료 버튼
            Button(action: onTaken) {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 36)
                    .background(AppColors.successGradient)
                    .cornerRadius(AppRadius.sm)
            }
            .disabled(isProcessing)
        }
    }
}

// MARK: - Patient Chip View

struct PatientChipView: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.xs) {
                Circle()
                    .fill(isSelected ? color : color.opacity(0.5))
                    .frame(width: 24, height: 24)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                
                Text(name)
                    .font(AppTypography.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(isSelected ? color.opacity(0.15) : AppColors.cardBackground)
            .foregroundColor(isSelected ? color : AppColors.textSecondary)
            .cornerRadius(AppRadius.full)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.full)
                    .stroke(isSelected ? color.opacity(0.5) : AppColors.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Patient Selector Sheet

struct PatientSelectorSheet: View {
    let patients: [Patient]
    let selectedPatient: Patient?
    let onSelect: (Patient?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    ForEach(patients) { patient in
                        PatientSelectionRow(
                            name: patient.displayName,
                            subtitle: DMateResourceStrings.Patient.medicationCount(patient.activeMedicationCount),
                            color: patient.color,
                            initials: patient.initials,
                            isSelected: selectedPatient?.id == patient.id,
                            onTap: { onSelect(patient) }
                        )
                    }
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle(DMateResourceStrings.Patient.selectTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(DMateResourceStrings.Common.done) {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

struct PatientSelectionRow: View {
    let name: String
    let subtitle: String
    let color: Color
    var initials: String? = nil
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                Circle()
                    .fill(color)
                    .frame(width: 50, height: 50)
                    .overlay {
                        if let initials = initials {
                            Text(initials)
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
            }
            .padding(AppSpacing.md)
            .background(isSelected ? color.opacity(0.08) : AppColors.cardBackground)
            .cornerRadius(AppRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(isSelected ? color.opacity(0.3) : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helper Functions
// Note: formatTime(_:) is provided globally in Formatters.swift; use that.

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [
            Medication.self,
            MedicationSchedule.self,
            MedicationLog.self,
//            HealthMetric.self,
            Appointment.self,
            Patient.self
        ], inMemory: true)
}
