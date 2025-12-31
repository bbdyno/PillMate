//
//  MedicationListView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import DMateDesignSystem
import DMateResource
import SwiftData

/// 약물 목록 화면
struct MedicationListView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MedicationListViewModel()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // 통계 헤더
                    statisticsHeader

                    // 약물 목록
                    if viewModel.isEmpty {
                        emptyStateView
                    } else if viewModel.hasNoSearchResults {
                        noResultsView
                    } else {
                        medicationList
                    }
                }
                .padding(.top, AppSpacing.sm)
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $viewModel.searchText,
                prompt: DMateResourceStrings.MedicationList.searchPrompt
            )
            .navigationTitle(DMateResourceStrings.MedicationList.titleShort)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: AppSpacing.sm) {
                        // 필터/정렬 메뉴
                        Menu {
                            Section(DMateResourceStrings.MedicationList.sortSection) {
                                Picker(DMateResourceStrings.MedicationList.sortLabel, selection: $viewModel.sortOption) {
                                    ForEach(MedicationSortOption.allCases) { option in
                                        Label(option.displayName, systemImage: option.icon)
                                            .tag(option)
                                    }
                                }
                            }

                            Section(DMateResourceStrings.MedicationList.filterSection) {
                                Picker(DMateResourceStrings.MedicationList.filterLabel, selection: $viewModel.filterOption) {
                                    ForEach(MedicationFilterOption.allCases) { option in
                                        Text(option.displayName).tag(option)
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(AppColors.primary)
                        }
                        
                        // 추가 버튼
                        Button {
                            viewModel.showAddMedicationSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(AppColors.primaryGradient)
                        }
                    }
                }
            }
            .toolbarBackground(.clear, for: .navigationBar)
            .refreshable {
                await viewModel.loadMedications()
            }
            .onAppear {
                viewModel.setup(with: modelContext)
            }
            .sheet(isPresented: $viewModel.showAddMedicationSheet) {
                AddMedicationView { medication in
                    Task {
                        await viewModel.addMedication(medication)
                    }
                }
            }
            .alert(DMateResourceStrings.MedicationList.deleteAlertTitle, isPresented: $viewModel.showDeleteConfirmation) {
                Button(DMateResourceStrings.Common.cancel, role: .cancel) {}
                Button(DMateResourceStrings.Common.delete, role: .destructive) {
                    Task {
                        await viewModel.executeDelete()
                    }
                }
            } message: {
                if let medication = viewModel.medicationToDelete {
                    Text(DMateResourceStrings.MedicationList.deleteMessage(medication.name))
                }
            }
        }
    }
    
    // MARK: - Statistics Header
    
    private var statisticsHeader: some View {
        HStack(spacing: AppSpacing.sm) {
            StatCard(
                icon: "pills.fill",
                value: "\(viewModel.activeMedicationsCount)",
                label: DMateResourceStrings.MedicationList.activeLabel,
                color: AppColors.success
            )

            StatCard(
                icon: "exclamationmark.triangle.fill",
                value: "\(viewModel.lowStockMedicationsCount)",
                label: DMateResourceStrings.MedicationList.lowStock,
                color: AppColors.warning
            )

            StatCard(
                icon: "square.stack.3d.up.fill",
                value: "\(viewModel.totalMedicationsCount)",
                label: DMateResourceStrings.MedicationList.total,
                color: AppColors.primary
            )
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
                .frame(height: 40)
            
            ZStack {
                Circle()
                    .fill(AppColors.primarySoft)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "pill.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.primaryGradient)
            }
            
            VStack(spacing: AppSpacing.xs) {
                Text(DMateResourceStrings.MedicationList.noMedications)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)

                Text(DMateResourceStrings.MedicationList.addToStart)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Button {
                viewModel.showAddMedicationSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(DMateResourceStrings.Medications.add)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: 160)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - No Results
    
    private var noResultsView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(AppColors.textTertiary)
            
            Text(DMateResourceStrings.MedicationList.noResults)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Text(DMateResourceStrings.MedicationList.noResultsFor(viewModel.searchText))
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxxl)
    }
    
    // MARK: - Medication List
    
    private var medicationList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(
                title: DMateResourceStrings.MedicationList.medicationListTitle,
                subtitle: "\(viewModel.filteredMedications.count)\(DMateResourceStrings.MedicationList.items)"
            )
            
            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.filteredMedications) { medication in
                    NavigationLink {
                        MedicationDetailView(medication: medication)
                    } label: {
                        MedicationCard(
                            medication: medication,
                            onDelete: {
                                viewModel.confirmDelete(medication)
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Text(value)
                    .font(AppTypography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadius.md)
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
    }
}

// MARK: - Medication Card

struct MedicationCard: View {
    let medication: Medication
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // 약물 색상 인디케이터
            Circle()
                .fill(medication.medicationColor.swiftUIColor.gradient)
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: medication.medicationForm.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .shadow(color: medication.medicationColor.swiftUIColor.opacity(0.3), radius: 4, y: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(medication.name)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if !medication.isActive {
                        Text(DMateResourceStrings.MedicationList.discontinued)
                            .font(AppTypography.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.textTertiary.opacity(0.2))
                            .foregroundColor(AppColors.textTertiary)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: AppSpacing.sm) {
                    Text(medication.dosage)
                    Text("•")
                    Text(medication.strength)
                }
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if medication.isLowStock {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("\(medication.stockCount)")
                    }
                    .font(AppTypography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(medication.isOutOfStock ? AppColors.danger : AppColors.warning)
                } else if medication.stockCount > 0 {
                    Text("\(medication.stockCount)\(DMateResourceStrings.MedicationList.items)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Text(medication.medicationForm.displayName)
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadius.lg)
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        .contextMenu {
            Button {
                onDelete()
            } label: {
                Label(DMateResourceStrings.Common.delete, systemImage: "trash")
            }
        }
    }
}

// MARK: - Sort Option Extension

extension MedicationSortOption {
    var icon: String {
        switch self {
        case .name: return "textformat"
        case .createdAt: return "calendar"
        case .nextDose: return "clock"
        case .stockCount: return "number.square"
        }
    }
}

// MARK: - Preview

#Preview {
    MedicationListView()
        .modelContainer(for: [
            Medication.self,
            MedicationSchedule.self,
            MedicationLog.self
        ], inMemory: true)
}
