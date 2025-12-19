//
//  OnboardingView.swift
//  DoseMate
//
//  Created by bbdyno on 12/10/25.
//

import SwiftUI
import DMateDesignSystem
import DMateResource
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    @State private var name = ""
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // 로고 또는 아이콘
            DoseMateAsset.dosemateIco.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .padding(.bottom, AppSpacing.lg)
            
            VStack(spacing: AppSpacing.sm) {
                Text(DMateResourceStrings.App.welcome)
                    .font(AppTypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)

                Text(DMateResourceStrings.Onboarding.askName)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer()

            // 이름 입력
            TextField(DMateResourceStrings.Onboarding.namePlaceholder, text: $name)
                .font(AppTypography.title3)
                .padding(AppSpacing.md)
                .background(AppColors.cardBackground)
                .cornerRadius(AppRadius.lg)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                .padding(.horizontal, AppSpacing.lg)
            
            Spacer()
            
            // 시작 버튼
            Button(action: {
                savePatient()
                onboardingCompleted = true
            }) {
                Text(DMateResourceStrings.Onboarding.getStarted)
                    .font(AppTypography.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(name.isEmpty ? AppColors.chartGray : AppColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(AppRadius.lg)
                    .shadow(color: name.isEmpty ? .clear : AppColors.primary.opacity(0.4), radius: 8, y: 4)
            }
            .disabled(name.isEmpty)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background.ignoresSafeArea())
    }
    
    private func savePatient() {
        let myself = Patient(name: name, relationship: .myself, profileColor: .blue)
        modelContext.insert(myself)
        try? modelContext.save()
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [Patient.self], inMemory: true)
}
