//
//  AIHealthBriefingView.swift
//  DoseMate
//
//  Created by bbdyno on 12/16/25.
//

import SwiftUI
import DMateDesignSystem
import DMateResource
import SwiftData

struct AIHealthBriefingView: View {
    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AIHealthBriefingViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.isAuthorized {
                    // 권한 요청 뷰
                    permissionRequestView
                } else if viewModel.hasHealthData {
                    // 브리핑 뷰
                    briefingContentView
                } else {
                    // 제로케이스 뷰
                    emptyStateView
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(NSLocalizedString("tab.ai", comment: ""))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.loadHealthData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppColors.primary)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .toolbarBackground(.clear, for: .navigationBar)
        .onAppear {
            viewModel.setup(with: modelContext)
            viewModel.isAuthorized = HealthKitManager.shared.isAuthorized

            if viewModel.isAuthorized {
                Task {
                    await viewModel.loadHealthData()
                }
            }
        }
        .alert(DMateResourceStrings.Common.error, isPresented: .constant(viewModel.errorMessage != nil)) {
            Button(DMateResourceStrings.Common.ok) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    // MARK: - Permission Request View

    private var permissionRequestView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
                .frame(height: 40)

            ZStack {
                Circle()
                    .fill(AppColors.primarySoft)
                    .frame(width: 100, height: 100)

                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.primaryGradient)
            }

            VStack(spacing: AppSpacing.xs) {
                Text(NSLocalizedString("ai.permission_required", comment: ""))
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)

                Text(NSLocalizedString("ai.permission_description", comment: ""))
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            Button {
                Task {
                    await viewModel.requestHealthKitPermission()
                }
            } label: {
                HStack {
                    Image(systemName: "heart.fill")
                    Text(NSLocalizedString("ai.request_permission", comment: ""))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: 200)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
                .frame(height: 40)

            ZStack {
                Circle()
                    .fill(AppColors.primarySoft)
                    .frame(width: 100, height: 100)

                Image(systemName: "figure.walk")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.primaryGradient)
            }

            VStack(spacing: AppSpacing.xs) {
                Text(NSLocalizedString("ai.no_health_data", comment: ""))
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)

                Text(NSLocalizedString("ai.no_health_data_description", comment: ""))
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            Button {
                Task {
                    await viewModel.loadHealthData()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text(NSLocalizedString("ai.refresh", comment: ""))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: 160)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Briefing Content View

    private var briefingContentView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // 활동 통계 카드
                activityStatsCard

                // AI 브리핑 카드
                aiBriefingCard

                // 활동 추천 카드들
                recommendationsSection
            }
            .padding(.top, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxl)
        }
    }

    // MARK: - Activity Stats Card

    private var activityStatsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: NSLocalizedString("ai.today_activity", comment: ""))

            HStack(spacing: AppSpacing.sm) {
                // 걸음 수
                StatCard(
                    icon: "figure.walk",
                    value: "\(viewModel.todaySteps)",
                    label: NSLocalizedString("ai.steps", comment: ""),
                    color: AppColors.success
                )

                // 이동 거리
                StatCard(
                    icon: "location.fill",
                    value: String(format: "%.1f", viewModel.todayDistance),
                    label: NSLocalizedString("ai.distance_km", comment: ""),
                    color: AppColors.primary
                )

                // 활동 에너지
                StatCard(
                    icon: "flame.fill",
                    value: "\(Int(viewModel.todayActiveEnergy))",
                    label: NSLocalizedString("ai.calories", comment: ""),
                    color: AppColors.warning
                )
            }

            // 주간 평균 비교
            if viewModel.averageStepsLastWeek > 0 {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text(NSLocalizedString("ai.weekly_average", comment: "") + ": \(viewModel.averageStepsLastWeek) " + NSLocalizedString("ai.steps", comment: ""))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Spacer()

                    if viewModel.todaySteps > viewModel.averageStepsLastWeek {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                            let percentage = Int((Double(viewModel.todaySteps - viewModel.averageStepsLastWeek) / Double(viewModel.averageStepsLastWeek)) * 100)
                            Text("+\(percentage)%")
                        }
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.success)
                    } else if viewModel.todaySteps < viewModel.averageStepsLastWeek {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.right")
                                .font(.caption2)
                            let percentage = Int((Double(viewModel.averageStepsLastWeek - viewModel.todaySteps) / Double(viewModel.averageStepsLastWeek)) * 100)
                            Text("-\(percentage)%")
                        }
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.danger)
                    }
                }
                .padding(.top, AppSpacing.xs)
            }
        }
    }

    // MARK: - AI Briefing Card

    private var aiBriefingCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.primaryGradient)

                Text(NSLocalizedString("ai.briefing_title", comment: ""))
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                if viewModel.isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if !viewModel.briefingText.isEmpty {
                Text(viewModel.briefingText)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .lineSpacing(4)
            } else {
                Text(NSLocalizedString("ai.generating_briefing", comment: ""))
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .italic()
            }
        }
        .cardStyle()
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: NSLocalizedString("ai.recommendations", comment: ""))

            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.recommendations) { recommendation in
                    RecommendationCard(recommendation: recommendation)
                }
            }
        }
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: ActivityRecommendation

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(recommendation.color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: recommendation.icon)
                    .font(.system(size: 24))
                    .foregroundColor(recommendation.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Text(recommendation.description)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
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
}

// MARK: - Preview

#Preview {
    AIHealthBriefingView()
        .modelContainer(for: [
            Medication.self,
            MedicationLog.self
        ], inMemory: true)
}
