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
    @State private var agreedToTerms = false
    @State private var agreedToPrivacy = false
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false
    
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

            // 약관 동의
            VStack(spacing: AppSpacing.sm) {
                // 이용약관 동의
                AgreementRow(
                    isAgreed: $agreedToTerms,
                    title: DMateResourceStrings.Onboarding.agreeTerms,
                    onViewTapped: { showTermsSheet = true }
                )

                // 개인정보 처리방침 동의
                AgreementRow(
                    isAgreed: $agreedToPrivacy,
                    title: DMateResourceStrings.Onboarding.agreePrivacyPolicy,
                    onViewTapped: { showPrivacySheet = true }
                )
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)

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
                    .background(isFormValid ? AppColors.primary : AppColors.chartGray)
                    .foregroundColor(.white)
                    .cornerRadius(AppRadius.lg)
                    .shadow(color: isFormValid ? AppColors.primary.opacity(0.4) : .clear, radius: 8, y: 4)
            }
            .disabled(!isFormValid)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background.ignoresSafeArea())
        .sheet(isPresented: $showTermsSheet) {
            DocumentViewer(
                title: DMateResourceStrings.Onboarding.termsOfService,
                fileName: termsFileName
            )
        }
        .sheet(isPresented: $showPrivacySheet) {
            DocumentViewer(
                title: DMateResourceStrings.Onboarding.privacyPolicy,
                fileName: privacyFileName
            )
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty && agreedToTerms && agreedToPrivacy
    }

    private var termsFileName: String {
        Locale.current.language.languageCode?.identifier == "ko" ? "TERMS_OF_SERVICE_ko" : "TERMS_OF_SERVICE_en"
    }

    private var privacyFileName: String {
        Locale.current.language.languageCode?.identifier == "ko" ? "PRIVACY_POLICY_ko" : "PRIVACY_POLICY_en"
    }
    
    private func savePatient() {
        let myself = Patient(name: name, relationship: .myself, profileColor: .blue)
        modelContext.insert(myself)
        try? modelContext.save()
    }
}

// MARK: - Supporting Views

struct AgreementRow: View {
    @Binding var isAgreed: Bool
    let title: String
    let onViewTapped: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Button(action: {
                isAgreed.toggle()
            }) {
                Image(systemName: isAgreed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isAgreed ? AppColors.primary : AppColors.textSecondary)
            }

            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onViewTapped) {
                Text(DMateResourceStrings.Onboarding.view)
                    .font(AppTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)
                    .underline()
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [Patient.self], inMemory: true)
}
