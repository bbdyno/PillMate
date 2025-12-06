//
//  LogHistoryView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import SwiftData

/// 복약 기록 화면
struct LogHistoryView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = LogHistoryViewModel()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // 통계 헤더 카드
                    statisticsHeader
                    
                    // 기간 선택
                    periodSelector
                    
                    // 뷰 모드 전환
                    viewModeToggle
                    
                    // 컨텐츠
                    if viewModel.viewMode == .calendar {
                        calendarContent
                    } else {
                        listContent
                    }
                }
                .padding(.top, AppSpacing.sm)
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "list.clipboard.fill")
                            .foregroundStyle(AppColors.primaryGradient)
                        Text(DoseMateStrings.LogHistory.title)
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.prepareExport()
                        } label: {
                            Label(DoseMateStrings.LogHistory.csvExport, systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .toolbarBackground(.clear, for: .navigationBar)
            .onAppear {
                viewModel.setup(with: modelContext)
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                ShareSheet(items: [viewModel.exportData])
            }
        }
    }
    
    // MARK: - Statistics Header
    
    private var statisticsHeader: some View {
        VStack(spacing: 0) {
            // 그라데이션 헤더
            HStack(spacing: AppSpacing.xl) {
                // 준수율 링
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.3), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: viewModel.overallAdherenceRate)
                        .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(duration: 0.8), value: viewModel.overallAdherenceRate)
                    
                    VStack(spacing: 0) {
                        Text("\(Int(viewModel.overallAdherenceRate * 100))")
                            .font(AppTypography.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("%")
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(width: 90, height: 90)
                
                // 통계 항목
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    LogStatRow(
                        icon: "checkmark.circle.fill",
                        value: viewModel.takenCount,
                        label: DoseMateStrings.LogHistory.taken,
                        color: .white
                    )
                    
                    LogStatRow(
                        icon: "clock.fill",
                        value: viewModel.delayedCount,
                        label: DoseMateStrings.LogHistory.delayed,
                        color: .white.opacity(0.8)
                    )
                    
                    LogStatRow(
                        icon: "xmark.circle.fill",
                        value: viewModel.skippedCount,
                        label: DoseMateStrings.LogHistory.skipped,
                        color: .white.opacity(0.6)
                    )
                }
            }
            .padding(AppSpacing.lg)
            .background(AppColors.headerGradient)
            
            // 하단 요약
            HStack {
                LogSummaryItem(
                    value: viewModel.logs.count,
                    label: DoseMateStrings.LogHistory.totalRecords
                )
                
                Divider()
                    .frame(height: 30)
                
                LogSummaryItem(
                    value: viewModel.consecutiveDays,
                    label: DoseMateStrings.LogHistory.consecutiveDays
                )
                
                Divider()
                    .frame(height: 30)
                
                LogSummaryItem(
                    value: viewModel.filteredLogs.count,
                    label: DoseMateStrings.LogHistory.filterResults
                )
            }
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.cardBackground)
        }
        .cornerRadius(AppRadius.xl)
        .shadow(color: AppColors.primary.opacity(0.15), radius: 20, y: 10)
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(StatisticsPeriod.allCases) { period in
                    Button {
                        viewModel.selectedPeriod = period
                    } label: {
                        Text(period.displayName)
                            .font(AppTypography.subheadline)
                            .fontWeight(viewModel.selectedPeriod == period ? .semibold : .regular)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                viewModel.selectedPeriod == period
                                    ? AppColors.primary.opacity(0.15)
                                    : AppColors.cardBackground
                            )
                            .foregroundColor(
                                viewModel.selectedPeriod == period
                                    ? AppColors.primary
                                    : AppColors.textSecondary
                            )
                            .cornerRadius(AppRadius.full)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.full)
                                    .stroke(
                                        viewModel.selectedPeriod == period
                                            ? AppColors.primary.opacity(0.5)
                                            : AppColors.divider,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - View Mode Toggle
    
    private var viewModeToggle: some View {
        HStack {
            SectionHeader(title: DoseMateStrings.LogHistory.viewRecords)
            
            Spacer()
            
            HStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.viewMode = .calendar
                    }
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(viewModel.viewMode == .calendar ? .white : AppColors.textSecondary)
                        .frame(width: 36, height: 32)
                        .background(
                            viewModel.viewMode == .calendar
                                ? AppColors.primary
                                : Color.clear
                        )
                }
                .buttonStyle(.plain)
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.viewMode = .list
                    }
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14))
                        .foregroundColor(viewModel.viewMode == .list ? .white : AppColors.textSecondary)
                        .frame(width: 36, height: 32)
                        .background(
                            viewModel.viewMode == .list
                                ? AppColors.primary
                                : Color.clear
                        )
                }
                .buttonStyle(.plain)
            }
            .background(AppColors.cardBackground)
            .cornerRadius(AppRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .stroke(AppColors.divider, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Calendar Content
    
    private var calendarContent: some View {
        VStack(spacing: AppSpacing.md) {
            // 월 네비게이션
            HStack {
                Button {
                    viewModel.previousMonth()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppColors.primary)
                        .frame(width: 36, height: 36)
                        .background(AppColors.primarySoft)
                        .cornerRadius(AppRadius.sm)
                }
                
                Spacer()
                
                Text(viewModel.displayMonthText)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button {
                    viewModel.nextMonth()
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.primary)
                        .frame(width: 36, height: 36)
                        .background(AppColors.primarySoft)
                        .cornerRadius(AppRadius.sm)
                }
            }
            
            // 요일 헤더
            HStack(spacing: 0) {
                let weekdays = [
                    DoseMateStrings.Calendar.sunday,
                    DoseMateStrings.Calendar.monday,
                    DoseMateStrings.Calendar.tuesday,
                    DoseMateStrings.Calendar.wednesday,
                    DoseMateStrings.Calendar.thursday,
                    DoseMateStrings.Calendar.friday,
                    DoseMateStrings.Calendar.saturday
                ]
                
                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(AppTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(index == 0 ? AppColors.danger : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, AppSpacing.xs)
            
            // 달력 그리드
            let calendar = Calendar.current
            let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: viewModel.displayMonth))!
            let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
            let daysInMonth = viewModel.datesInMonth
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppSpacing.xs) {
                // 빈 칸 (이전 달)
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Color.clear
                        .frame(height: 44)
                }
                
                // 날짜들
                ForEach(daysInMonth, id: \.self) { date in
                    LogCalendarDayCell(
                        date: date,
                        color: viewModel.colorForDate(date),
                        isSelected: calendar.isDate(viewModel.selectedDate, inSameDayAs: date),
                        isToday: calendar.isDateInToday(date)
                    ) {
                        viewModel.selectedDate = date
                    }
                }
            }
            
            // 선택된 날짜 상세
            selectedDateDetail
        }
        .cardStyle()
    }
    
    // MARK: - Selected Date Detail
    
    private var selectedDateDetail: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Divider()
            
            HStack {
                Text(viewModel.selectedDate.fullDateString)
                    .font(AppTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                let dayLogs = viewModel.selectedDateLogs
                let rate = dayLogs.isEmpty ? 0.0 : Double(dayLogs.filter { $0.logStatus == .taken || $0.logStatus == .delayed }.count) / Double(dayLogs.count)
                StatusBadge(
                    text: "\(Int(rate * 100))%",
                    status: rate >= 0.8 ? .success : rate >= 0.5 ? .warning : .danger
                )
            }
            
            let logs = viewModel.selectedDateLogs
            if logs.isEmpty {
                Text(DoseMateStrings.LogHistory.noRecords)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
            } else {
                ForEach(logs) { log in
                    LogHistoryRow(log: log)
                }
            }
        }
    }
    
    // MARK: - List Content
    
    private var listContent: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(viewModel.logsByDate, id: \.date) { group in
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    // 날짜 헤더
                    HStack {
                        Text(group.date.shortDateString)
                            .font(AppTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        let rate = Double(group.logs.filter { $0.logStatus == .taken || $0.logStatus == .delayed }.count) / Double(max(group.logs.count, 1))
                        StatusBadge(
                            text: "\(Int(rate * 100))%",
                            status: rate >= 0.8 ? .success : rate >= 0.5 ? .warning : .danger
                        )
                    }
                    .padding(.horizontal, AppSpacing.xs)
                    
                    // 로그 목록
                    VStack(spacing: AppSpacing.xs) {
                        ForEach(group.logs) { log in
                            LogHistoryRow(log: log)
                        }
                    }
                }
            }
            
            if viewModel.logsByDate.isEmpty {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text(DoseMateStrings.LogHistory.noRecords)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xxxl)
            }
        }
    }
}

// MARK: - Supporting Views

struct LogStatRow: View {
    let icon: String
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text("\(value)")
                .font(AppTypography.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(color.opacity(0.8))
        }
    }
}

struct LogSummaryItem: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(AppTypography.caption2)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LogCalendarDayCell: View {
    let date: Date
    let color: Color
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 배경
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 40, height: 40)
                
                // 날짜
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(AppTypography.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(textColor)
            }
        }
        .buttonStyle(.plain)
        .frame(height: 44)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return AppColors.primary
        } else if color != .clear {
            return color.opacity(0.3)
        }
        return Color.clear
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return AppColors.primary
        }
        return AppColors.textPrimary
    }
}

struct LogHistoryRow: View {
    let log: MedicationLog
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // 상태 아이콘
            Circle()
                .fill(statusColor)
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: statusIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            
            // 약물 정보
            VStack(alignment: .leading, spacing: 2) {
                Text(log.medication?.name ?? DoseMateStrings.LogHistory.unknown)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(log.scheduledTime.formatted(date: .omitted, time: .shortened))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // 상태 뱃지
            StatusBadge(
                text: log.logStatus.displayName,
                status: statusBadgeStatus,
                showIcon: false
            )
        }
        .padding(AppSpacing.sm)
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadius.md)
    }
    
    private var statusColor: Color {
        switch log.logStatus {
        case .taken: return AppColors.success
        case .delayed: return AppColors.warning
        case .skipped: return AppColors.textTertiary
        case .snoozed: return AppColors.info
        case .pending: return AppColors.warning
        }
    }
    
    private var statusIcon: String {
        switch log.logStatus {
        case .taken: return "checkmark"
        case .delayed: return "clock"
        case .skipped: return "forward.fill"
        case .snoozed: return "bell.slash"
        case .pending: return "circle"
        }
    }
    
    private var statusBadgeStatus: StatusBadge.Status {
        switch log.logStatus {
        case .taken: return .success
        case .delayed: return .warning
        case .skipped: return .pending
        case .snoozed: return .info
        case .pending: return .warning
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    LogHistoryView()
        .modelContainer(for: [
            Medication.self,
            MedicationSchedule.self,
            MedicationLog.self
        ], inMemory: true)
}
