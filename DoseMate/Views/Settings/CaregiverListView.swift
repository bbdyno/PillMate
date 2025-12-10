//
//  CaregiverListView.swift
//  DoseMate
//
//  Created by bbdyno on 12/6/25.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Caregiver List View

struct CaregiverListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var caregivers: [Caregiver]
    
    @State private var showAddSheet = false
    @State private var caregiverToDelete: Caregiver?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            if caregivers.isEmpty {
                emptyStateView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else {
                VStack(spacing: AppSpacing.lg) {
                    // 헤더 카드
                    headerCard

                    // 보호자 목록
                    caregiverList
                }
                .padding(.top, AppSpacing.sm)
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
        }
        .background(AppColors.background)
        .navigationTitle("보호자 관리")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                AddButton { showAddSheet = true }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddCaregiverView { caregiver in
                modelContext.insert(caregiver)
                try? modelContext.save()
            }
        }
        .alert("보호자 삭제", isPresented: $showDeleteConfirmation) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                if let caregiver = caregiverToDelete {
                    modelContext.delete(caregiver)
                    try? modelContext.save()
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "person.2.fill",
            title: "등록된 보호자가 없습니다",
            description: "보호자를 추가하면\n복약 누락 시 알림을 보낼 수 있습니다",
            buttonTitle: "보호자 추가하기",
            action: { showAddSheet = true }
        )
    }

    // MARK: - Header Card

    private var headerCard: some View {
        StandardHeaderCard(
            icon: "person.2.fill",
            title: "총 \(caregivers.count)명의 보호자",
            subtitle: "알림 연락처로 등록되어 있습니다"
        )
    }

    // MARK: - Caregiver List

    private var caregiverList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "보호자 목록")

            VStack(spacing: AppSpacing.sm) {
                ForEach(caregivers) { caregiver in
                    CaregiverCard(
                        caregiver: caregiver,
                        onDelete: {
                            caregiverToDelete = caregiver
                            showDeleteConfirmation = true
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Caregiver Card

struct CaregiverCard: View {
    let caregiver: Caregiver
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // 프로필 아바타
            Circle()
                .fill(caregiver.isActive ? AppColors.primaryGradient : LinearGradient(colors: [AppColors.textTertiary], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 56, height: 56)
                .overlay {
                    Text(caregiver.initials)
                        .font(AppTypography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .shadow(color: caregiver.isActive ? AppColors.primary.opacity(0.3) : Color.clear, radius: 4, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AppSpacing.xs) {
                    Text(caregiver.name)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    if !caregiver.isActive {
                        Text("비활성")
                            .font(AppTypography.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppColors.textTertiary.opacity(0.15))
                            .foregroundColor(AppColors.textTertiary)
                            .cornerRadius(AppRadius.sm)
                    }
                }

                HStack(spacing: AppSpacing.md) {
                    Label(caregiver.relationship, systemImage: "person.fill")

                    if !caregiver.phoneNumber.isEmpty {
                        Label(caregiver.formattedPhoneNumber, systemImage: "phone.fill")
                    }
                }
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            // 알림 상태
            VStack(alignment: .trailing, spacing: 2) {
                Image(systemName: caregiver.isActive ? "bell.fill" : "bell.slash.fill")
                    .font(.system(size: 20))
                    .foregroundColor(caregiver.isActive ? AppColors.primary : AppColors.textTertiary)

                if caregiver.isActive {
                    Text("\(caregiver.notificationDelayMinutes)분 후")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadius.lg)
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        .opacity(caregiver.isActive ? 1 : 0.7)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }
}
