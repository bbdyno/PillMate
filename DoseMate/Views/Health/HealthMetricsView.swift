//
//  HealthMetricsView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import SwiftData
import Charts

/// 건강 지표 화면
struct HealthMetricsView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HealthMetricsViewModel()
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var showPremiumSheet = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if !PremiumFeatures.canUseHealthKit {
                    // 프리미엄이 아닌 사용자: 업그레이드 안내만 표시
                    premiumRequiredContent
                } else {
                    // 프리미엄 사용자: 전체 기능 표시
                    ScrollView {
                        VStack(spacing: AppSpacing.lg) {
                            // HealthKit 동기화 카드
                            syncCard

                            // 지표 그리드
                            metricsGrid

                            // 선택된 지표 상세
                            if let selectedType = viewModel.selectedMetricType {
                                metricDetailCard(for: selectedType)
                            }
                        }
                        .padding(.top, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.xxl)
                    }
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(AppColors.danger.gradient)
                        Text(DoseMateStrings.Health.title)
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }

                // 프리미엄 사용자에게만 + 버튼 표시
                if PremiumFeatures.canUseHealthKit {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.inputMetricType = nil
                            viewModel.showInputSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(AppColors.primaryGradient)
                        }
                    }
                }
            }
            .toolbarBackground(.clear, for: .navigationBar)
            .onAppear {
                viewModel.setup(with: modelContext)
            }
            .sheet(isPresented: $viewModel.showInputSheet) {
                metricInputSheet
            }
            .sheet(isPresented: $showPremiumSheet) {
                PremiumView()
            }
            .alert(DoseMateStrings.Health.error, isPresented: .constant(viewModel.errorMessage != nil)) {
                Button(DoseMateStrings.Health.confirm) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Premium Required Content

    private var premiumRequiredContent: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // 아이콘
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF6B6B").opacity(0.2), Color(hex: "EE5A5A").opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FF6B6B"), Color(hex: "EE5A5A")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, AppSpacing.md)

            // 제목
            VStack(spacing: AppSpacing.sm) {
                Text(DoseMateStrings.Health.premiumFeature)
                    .font(AppTypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)

                Text(DoseMateStrings.Health.premiumDescription)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            // 기능 목록
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                FeatureRow(
                    icon: "heart.text.square.fill",
                    title: DoseMateStrings.Health.syncFromHealth,
                    description: "건강 앱과 자동 동기화"
                )

                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: DoseMateStrings.Health.metricsTitle,
                    description: "건강 지표 추적 및 분석"
                )

                FeatureRow(
                    icon: "calendar",
                    title: "기록 관리",
                    description: "모든 건강 데이터 기록 보관"
                )
            }
            .padding(AppSpacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(AppRadius.lg)
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            .padding(.horizontal, AppSpacing.lg)

            Spacer()

            // 업그레이드 버튼
            Button {
                showPremiumSheet = true
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "crown.fill")
                    Text("프리미엄으로 업그레이드")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FF6B6B"), Color(hex: "EE5A5A")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(AppRadius.md)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sync Card

    private var syncCard: some View {
        Group {
            if !healthKitManager.isAuthorized {
                // 권한 요청 카드
                Button {
                    Task {
                        await viewModel.requestHealthKitPermission()
                    }
                } label: {
                    HStack(spacing: AppSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "FF6B6B"), Color(hex: "EE5A5A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 50, height: 50)

                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(DoseMateStrings.Health.permissionRequired)
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)

                            Text(DoseMateStrings.Health.permissionDescription)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.primary)
                            .frame(width: 36, height: 36)
                            .background(AppColors.primarySoft)
                            .cornerRadius(AppRadius.sm)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppRadius.lg)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
                }
                .buttonStyle(.plain)
            } else {
                // 동기화 카드
                Button {
                    Task {
                        await viewModel.syncAuthorized()
                    }
                } label: {
                    HStack(spacing: AppSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "FF6B6B"), Color(hex: "EE5A5A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 50, height: 50)

                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(DoseMateStrings.Health.syncFromHealth)
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)

                            if let lastSync = healthKitManager.lastSyncDate {
                                Text(DoseMateStrings.Health.lastSync(lastSync.relativeTimeString))
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            } else {
                                Text(DoseMateStrings.Health.syncDescription)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }

                        Spacer()

                        if viewModel.isSyncing {
                            ProgressView()
                                .tint(AppColors.primary)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.primary)
                                .frame(width: 36, height: 36)
                                .background(AppColors.primarySoft)
                                .cornerRadius(AppRadius.sm)
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppRadius.lg)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSyncing)
            }
        }
    }
    
    // MARK: - Metrics Grid
    
    private var metricsGrid: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: DoseMateStrings.Health.metricsTitle)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppSpacing.sm),
                GridItem(.flexible(), spacing: AppSpacing.sm)
            ], spacing: AppSpacing.sm) {
                ForEach(viewModel.supportedMetricTypes) { type in
                    HealthMetricCardView(
                        type: type,
                        metric: viewModel.latestMetrics[type],
                        isSelected: viewModel.selectedMetricType == type
                    ) {
                        withAnimation(.spring(duration: 0.3)) {
                            if viewModel.selectedMetricType == type {
                                viewModel.selectedMetricType = nil
                            } else {
                                viewModel.selectedMetricType = type
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Metric Detail Card
    
    private func metricDetailCard(for type: MetricType) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // 헤더
            HStack {
                IconBadge(icon: type.icon, color: type.color, size: 40, iconSize: 18)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Text(DoseMateStrings.Health.recentRecords)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Button {
                    viewModel.openInputSheet(for: type)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(type.color)
                        .frame(width: 32, height: 32)
                        .background(type.color.opacity(0.15))
                        .cornerRadius(AppRadius.sm)
                }
            }
            
            // 차트
            let history = viewModel.selectedMetricHistory
            if !history.isEmpty {
                Chart(history) { metric in
                    LineMark(
                        x: .value("날짜", metric.recordedAt),
                        y: .value("값", metric.value)
                    )
                    .foregroundStyle(type.color.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    
                    AreaMark(
                        x: .value("날짜", metric.recordedAt),
                        y: .value("값", metric.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [type.color.opacity(0.3), type.color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    PointMark(
                        x: .value("날짜", metric.recordedAt),
                        y: .value("값", metric.value)
                    )
                    .foregroundStyle(type.color)
                    .symbolSize(40)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.day())
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                            .foregroundStyle(AppColors.divider)
                        AxisValueLabel()
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .frame(height: 180)
                
                // 최근 기록 목록
                VStack(spacing: AppSpacing.xs) {
                    ForEach(history.prefix(5)) { metric in
                        HStack {
                            Text(metric.recordedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Spacer()
                            
                            Text(metric.displayValue + " " + metric.unit)
                                .font(AppTypography.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(.vertical, AppSpacing.xs)
                        
                        if metric.id != history.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.top, AppSpacing.sm)
            } else {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.textTertiary)

                    Text(DoseMateStrings.Health.noRecords)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)

                    Button {
                        viewModel.openInputSheet(for: type)
                    } label: {
                        Label(DoseMateStrings.Health.addRecord, systemImage: "plus")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(width: 140)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xl)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Metric Input Sheet
    
    private var metricInputSheet: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                // 지표 타입 선택
                if viewModel.inputMetricType == nil {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text(DoseMateStrings.Health.selectMetric)
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: AppSpacing.sm) {
                            ForEach(viewModel.supportedMetricTypes) { type in
                                Button {
                                    viewModel.inputMetricType = type
                                } label: {
                                    HStack {
                                        Image(systemName: type.icon)
                                            .foregroundColor(type.color)
                                        Text(type.displayName)
                                            .font(AppTypography.subheadline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(AppSpacing.md)
                                    .background(AppColors.cardBackground)
                                    .foregroundColor(AppColors.textPrimary)
                                    .cornerRadius(AppRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.md)
                                            .stroke(AppColors.divider, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(AppSpacing.lg)
                } else if let type = viewModel.inputMetricType {
                    // 값 입력
                    VStack(spacing: AppSpacing.lg) {
                        IconBadge(icon: type.icon, color: type.color, size: 60, iconSize: 28)
                        
                        Text(type.displayName)
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        VStack(spacing: AppSpacing.sm) {
                            if type == .bloodPressure {
                                TextField(DoseMateStrings.Health.systolicBp, text: $viewModel.inputSystolic)
                                    .keyboardType(.decimalPad)
                                    .font(AppTypography.title)
                                    .multilineTextAlignment(.center)
                                    .padding(AppSpacing.md)
                                    .background(AppColors.background)
                                    .cornerRadius(AppRadius.md)
                                
                                Text("mmHg (수축기)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)

                                TextField(DoseMateStrings.Health.diastolicBp, text: $viewModel.inputDiastolic)
                                    .keyboardType(.decimalPad)
                                    .font(AppTypography.headline)
                                    .multilineTextAlignment(.center)
                                    .padding(AppSpacing.md)
                                    .background(AppColors.background)
                                    .cornerRadius(AppRadius.md)
                                
                                Text("mmHg (이완기)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            } else if type == .mood {
                                HStack(spacing: AppSpacing.md) {
                                    ForEach(MoodLevel.allCases) { mood in
                                        Button {
                                            viewModel.inputMoodLevel = mood
                                        } label: {
                                            Text(mood.emoji)
                                                .font(.system(size: 32))
                                                .padding(AppSpacing.sm)
                                                .background(
                                                    viewModel.inputMoodLevel == mood
                                                        ? mood.color.opacity(0.3)
                                                        : Color.clear
                                                )
                                                .cornerRadius(AppRadius.md)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            } else {
                                TextField(DoseMateStrings.Health.inputValue, text: $viewModel.inputValue)
                                    .keyboardType(.decimalPad)
                                    .font(AppTypography.title)
                                    .multilineTextAlignment(.center)
                                    .padding(AppSpacing.md)
                                    .background(AppColors.background)
                                    .cornerRadius(AppRadius.md)
                                
                                Text(type.unit)
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(AppSpacing.lg)
                        .background(AppColors.cardBackground)
                        .cornerRadius(AppRadius.lg)
                        
                        // 메모
                        TextField(DoseMateStrings.Health.notesOptional, text: $viewModel.inputNotes)
                            .padding(AppSpacing.md)
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppRadius.md)
                    }
                    .padding(AppSpacing.lg)
                }
                
                Spacer()
                
                // 저장 버튼
                if viewModel.inputMetricType != nil {
                    Button(DoseMateStrings.Health.save) {
                        Task {
                            await viewModel.saveMetric()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isInputInvalid)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.lg)
                }
            }
            .background(AppColors.background)
            .navigationTitle(viewModel.inputMetricType?.displayName ?? DoseMateStrings.Health.inputTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.inputMetricType != nil {
                        Button {
                            viewModel.inputMetricType = nil
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(DoseMateStrings.Health.cancel) {
                        viewModel.showInputSheet = false
                        resetInputFields()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Helpers
    
    private var isInputInvalid: Bool {
        guard let type = viewModel.inputMetricType else { return true }
        
        switch type {
        case .bloodPressure:
            return viewModel.inputSystolic.isEmpty || viewModel.inputDiastolic.isEmpty
        case .mood:
            return false
        default:
            return viewModel.inputValue.isEmpty
        }
    }
    
    private func resetInputFields() {
        viewModel.inputValue = ""
        viewModel.inputSystolic = ""
        viewModel.inputDiastolic = ""
        viewModel.inputMoodLevel = .neutral
        viewModel.inputNotes = ""
        viewModel.inputMetricType = nil
    }
}

// MARK: - Health Metric Card View

struct HealthMetricCardView: View {
    let type: MetricType
    let metric: HealthMetric?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: type.icon)
                        .font(.system(size: 18))
                        .foregroundColor(type.color)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "chevron.up")
                            .font(.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                Text(type.displayName)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                if let metric = metric {
                    Text(metric.displayValue)
                        .font(AppTypography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(metric.recordedAt.relativeTimeString)
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                } else {
                    Text("--")
                        .font(AppTypography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textTertiary)

                    Text(DoseMateStrings.Health.noRecord)
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? type.color.opacity(0.1) : AppColors.cardBackground)
            .cornerRadius(AppRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(isSelected ? type.color.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    HealthMetricsView()
        .modelContainer(for: [
            HealthMetric.self
        ], inMemory: true)
}

