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
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(AppColors.danger.gradient)
                        Text("건강 지표")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                
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
            .onAppear {
                viewModel.setup(with: modelContext)
            }
            .sheet(isPresented: $viewModel.showInputSheet) {
                metricInputSheet
            }
            .sheet(isPresented: $showPremiumSheet) {
                PremiumView()
            }
            .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("확인") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Sync Card
    
    private var syncCard: some View {
        Group {
            if !PremiumFeatures.canUseHealthKit {
                // 프리미엄 업셀 카드 (비프리미엄 사용자)
                Button {
                    showPremiumSheet = true
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

                            Image(systemName: "crown.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("프리미엄 전용 • 건강 앱 연동")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)

                            Text("업그레이드하고 건강 데이터를 동기화하세요")
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
            } else if !healthKitManager.isAuthorized {
                // 권한 요청 카드 (프리미엄 사용자 + 미승인)
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
                            Text("건강 앱 권한 요청")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)

                            Text("건강 데이터를 연동하려면 권한이 필요합니다")
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
                // 동기화 카드 (프리미엄 사용자 + 권한 승인됨)
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
                            Text("건강 앱에서 동기화")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)

                            if let lastSync = healthKitManager.lastSyncDate {
                                Text("마지막: \(lastSync.relativeTimeString)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            } else {
                                Text("동기화하여 건강 데이터를 가져오세요")
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
            SectionHeader(title: "건강 지표")
            
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
                    
                    Text("최근 기록")
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
                    
                    Text("기록이 없습니다")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Button {
                        viewModel.openInputSheet(for: type)
                    } label: {
                        Label("기록 추가", systemImage: "plus")
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
                        Text("측정 항목 선택")
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
                                TextField("수축기 혈압", text: $viewModel.inputSystolic)
                                    .keyboardType(.decimalPad)
                                    .font(AppTypography.title)
                                    .multilineTextAlignment(.center)
                                    .padding(AppSpacing.md)
                                    .background(AppColors.background)
                                    .cornerRadius(AppRadius.md)
                                
                                Text("mmHg (수축기)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                TextField("이완기 혈압", text: $viewModel.inputDiastolic)
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
                                TextField("값 입력", text: $viewModel.inputValue)
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
                        TextField("메모 (선택)", text: $viewModel.inputNotes)
                            .padding(AppSpacing.md)
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppRadius.md)
                    }
                    .padding(AppSpacing.lg)
                }
                
                Spacer()
                
                // 저장 버튼
                if viewModel.inputMetricType != nil {
                    Button("저장") {
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
            .navigationTitle(viewModel.inputMetricType?.displayName ?? "건강 지표 입력")
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
                    Button("취소") {
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
                    
                    Text("기록 없음")
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

