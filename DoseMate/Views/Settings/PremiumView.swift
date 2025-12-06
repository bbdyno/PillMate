//
//  PremiumView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import StoreKit

struct PremiumView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @State private var storeManager = StoreKitManager.shared
    @State private var showRestoreAlert = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    purchaseSection
                    footerSection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle(DoseMateStrings.Premium.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(DoseMateStrings.Premium.close) {
                        dismiss()
                    }
                }
            }
            .overlay {
                if storeManager.isPurchasing || storeManager.isLoading {
                    loadingOverlay
                }
            }
            .alert(DoseMateStrings.Premium.restoreAlertTitle, isPresented: $showRestoreAlert) {
                Button(DoseMateStrings.Premium.confirm, role: .cancel) {}
            } message: {
                Text(storeManager.successMessage ?? storeManager.errorMessage ?? "")
            }
            .onChange(of: storeManager.successMessage) { _, newValue in
                if newValue != nil && !storeManager.isPurchasing {
                    showRestoreAlert = true
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // 아이콘
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .orange.opacity(0.5), radius: 10)
            
            // 제목
            Text(DoseMateStrings.Premium.upgradeTitle)
                .font(.title)
                .fontWeight(.bold)
            
            // 부제목
            Text(DoseMateStrings.Premium.upgradeSubtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 이미 프리미엄인 경우
            if storeManager.isPremium {
                Label(DoseMateStrings.Premium.currentStatus, systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(20)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(DoseMateStrings.Premium.featuresTitle)
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ForEach(PremiumFeatures.features, id: \.title) { feature in
                    FeatureRow(
                        icon: feature.icon,
                        title: feature.title,
                        description: feature.description
                    )
                }
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Purchase Section
    
    private var purchaseSection: some View {
        VStack(spacing: 16) {
            // 💡 가격 정책 변경 시 이 섹션 수정
            // 현재: 평생 이용권 (일회성 구매)
            
            if !storeManager.isPremium {
                // 가격 표시
                VStack(spacing: 4) {
                    if let product = storeManager.premiumProduct {
                        Text(product.displayPrice)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        
                        Text(DoseMateStrings.Premium.lifetimeAccess)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        // 제품 로딩 중
                        ProgressView()
                    }
                }
                
                // 구매 버튼
                Button {
                    Task {
                        await storeManager.purchasePremium()
                        if storeManager.isPremium {
                            // 구매 성공 시 약간의 지연 후 닫기
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text(DoseMateStrings.Premium.purchaseButton)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(storeManager.premiumProduct == nil)
                
                // 가족 공유 안내
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.blue)
                    Text(DoseMateStrings.Premium.familySharing)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            // 복원 버튼
            Button {
                Task {
                    await storeManager.restorePurchases()
                    showRestoreAlert = true
                }
            } label: {
                Text(DoseMateStrings.Premium.restorePurchases)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            // 약관 링크
            HStack(spacing: 16) {
                // 💡 실제 앱 출시 시 링크 업데이트 필요
                Link(DoseMateStrings.Premium.termsOfService, destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                
                Text("·")
                    .foregroundColor(.secondary)
                
                Link(DoseMateStrings.Premium.privacyPolicy, destination: URL(string: "https://www.apple.com/kr/privacy/")!)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            // 안내 문구
            Text(DoseMateStrings.Premium.paymentInfo)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text(storeManager.isPurchasing ? DoseMateStrings.Premium.processing : DoseMateStrings.Premium.loading)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }
}

// MARK: - Tip Jar View (기부 화면)

/// 개발자 응원하기 (기부) 화면
struct TipJarView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storeManager = StoreKitManager.shared
    @State private var showThankYou = false
    @State private var showError = false
    @State private var selectedProductID: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 헤더
                    VStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text(DoseMateStrings.TipJar.supportDeveloper)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(DoseMateStrings.TipJar.supportDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if storeManager.totalTipCount > 0 {
                            Text(DoseMateStrings.TipJar.totalTips(storeManager.totalTipCount))
                                .font(.caption)
                                .foregroundColor(.pink)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.pink.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top)
                    
                    // 기부 옵션들
                    if storeManager.tipProducts.isEmpty {
                        // 제품 로딩 중
                        VStack(spacing: 12) {
                            ProgressView()
                            Text(DoseMateStrings.TipJar.loadingProducts)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(Color.appCardBackground)
                        .cornerRadius(16)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(storeManager.tipProducts, id: \.id) { product in
                                TipButton(
                                    product: product,
                                    isProcessing: storeManager.isPurchasing && selectedProductID == product.id
                                ) {
                                    performTipPurchase(product: product)
                                }
                                .disabled(storeManager.isPurchasing)
                            }
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(16)
                    }
                    
                    // 안내 문구
                    VStack(spacing: 12) {
                        Text(DoseMateStrings.TipJar.infoTitle)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Label {
                                Text(DoseMateStrings.TipJar.infoNoFeatures)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } icon: {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            
                            Label {
                                Text(DoseMateStrings.TipJar.infoSupportOnly)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } icon: {
                                Image(systemName: "heart.circle.fill")
                                    .foregroundColor(.pink)
                            }
                            
                            Label {
                                Text(DoseMateStrings.TipJar.infoSecurePayment)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } icon: {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding()
                    .background(Color.appCardBackground.opacity(0.5))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle(DoseMateStrings.TipJar.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(DoseMateStrings.TipJar.close) {
                        dismiss()
                    }
                }
            }
            .overlay {
                if storeManager.isPurchasing {
                    loadingOverlay
                }
            }
            .alert(DoseMateStrings.TipJar.thankYouTitle, isPresented: $showThankYou) {
                Button(DoseMateStrings.Premium.confirm, role: .cancel) {
                    selectedProductID = nil
                }
            } message: {
                Text(DoseMateStrings.TipJar.thankYouMessage)
            }
            .alert(DoseMateStrings.TipJar.errorTitle, isPresented: $showError) {
                Button(DoseMateStrings.Premium.confirm, role: .cancel) {
                    selectedProductID = nil
                }
            } message: {
                Text(storeManager.errorMessage ?? DoseMateStrings.TipJar.errorUnknown)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// 기부 구매 처리
    private func performTipPurchase(product: Product) {
        selectedProductID = product.id
        
        Task {
            guard let productID = ProductID(rawValue: product.id) else {
                showError = true
                return
            }
            
            let success = await storeManager.tip(productID)
            
            if success {
                // 구매 성공
                showThankYou = true
            } else if storeManager.errorMessage != nil {
                // 에러가 있는 경우만 에러 표시 (사용자 취소는 표시 안 함)
                showError = true
            } else {
                // 사용자가 취소한 경우
                selectedProductID = nil
            }
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text(DoseMateStrings.TipJar.processing)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
}

// MARK: - Tip Button

struct TipButton: View {
    let product: Product
    let isProcessing: Bool
    let action: () -> Void
    
    private var productID: ProductID? {
        ProductID(rawValue: product.id)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // 상단: 아이콘과 가격
                HStack(spacing: 12) {
                    // 아이콘 (그라데이션 배경)
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.pink.opacity(0.2), .pink.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: productID?.icon ?? "heart.fill")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    // 제품명
                    Text(productID?.displayName ?? product.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 가격 또는 로딩
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.9)
                    } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(product.displayPrice)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.pink, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                }
                .padding(.bottom, product.description.isEmpty ? 0 : 12)
                
                // 하단: 설명 (여러 줄)
                if !product.description.isEmpty {
                    Text(product.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isProcessing 
                                    ? LinearGradient(
                                        colors: [.pink, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [.clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                lineWidth: isProcessing ? 2 : 0
                            )
                    )
            )
            .scaleEffect(isProcessing ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isProcessing)
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }
}

// MARK: - Premium Required View

/// 프리미엄 필요 안내 뷰 (기능 제한 시 표시)
struct PremiumRequiredView: View {
    let feature: String
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text(DoseMateStrings.PremiumRequired.title)
                .font(.headline)
            
            Text(DoseMateStrings.PremiumRequired.message(feature))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                onUpgrade()
            } label: {
                Label(DoseMateStrings.PremiumRequired.viewPremium, systemImage: "crown")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Premium Badge

/// 프리미엄 배지 (프리미엄 전용 기능 표시)
struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.caption2)
            Text(DoseMateStrings.PremiumBadge.pro)
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(4)
    }
}

// MARK: - Preview

#Preview("Premium View") {
    PremiumView()
}

#Preview("Tip Jar View") {
    TipJarView()
}

#Preview("Premium Required") {
    PremiumRequiredView(feature: "HealthKit 연동") {
        print("Upgrade tapped")
    }
    .padding()
}
