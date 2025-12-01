//
//  PremiumView.swift
//  PillMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import StoreKit

/// 프리미엄 업그레이드 화면
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
                    // 헤더
                    headerSection
                    
                    // 기능 목록
                    featuresSection
                    
                    // 구매 버튼
                    purchaseSection
                    
                    // 복원 및 약관
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
            .navigationTitle("프리미엄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if storeManager.isPurchasing || storeManager.isLoading {
                    loadingOverlay
                }
            }
            .alert("구매 복원", isPresented: $showRestoreAlert) {
                Button("확인", role: .cancel) {}
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
            Text("프리미엄으로 업그레이드")
                .font(.title)
                .fontWeight(.bold)
            
            // 부제목
            Text("모든 기능을 제한 없이 사용하세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 이미 프리미엄인 경우
            if storeManager.isPremium {
                Label("프리미엄 사용 중", systemImage: "checkmark.seal.fill")
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
            Text("프리미엄 기능")
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
                        
                        Text("평생 이용 · 한 번만 결제")
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
                        Text("프리미엄 구매하기")
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
                    Text("가족 공유 지원")
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
                Text("구매 복원")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            // 약관 링크
            HStack(spacing: 16) {
                // 💡 실제 앱 출시 시 링크 업데이트 필요
                Link("이용약관", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                
                Text("·")
                    .foregroundColor(.secondary)
                
                Link("개인정보처리방침", destination: URL(string: "https://www.apple.com/kr/privacy/")!)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            // 안내 문구
            Text("결제는 Apple ID를 통해 처리되며,\n구독이 아닌 일회성 결제입니다.")
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
                
                Text(storeManager.isPurchasing ? "구매 처리 중..." : "불러오는 중...")
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
    
    var body: some View {
        NavigationStack {
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
                    
                    Text("개발자 응원하기")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("여러분의 작은 후원이\n더 나은 앱을 만드는 데 큰 힘이 됩니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if storeManager.totalTipCount > 0 {
                        Text("총 \(storeManager.totalTipCount)번 응원해주셨어요! 💕")
                            .font(.caption)
                            .foregroundColor(.pink)
                    }
                }
                .padding(.top)
                
                // 기부 옵션들
                VStack(spacing: 12) {
                    ForEach(storeManager.tipProducts, id: \.id) { product in
                        TipButton(product: product) {
                            Task {
                                if let productID = ProductID(rawValue: product.id) {
                                    let success = await storeManager.tip(productID)
                                    if success {
                                        showThankYou = true
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.appCardBackground)
                .cornerRadius(16)
                
                Spacer()
                
                // 안내 문구
                Text("기부는 추가 기능을 해제하지 않습니다.\n순수하게 개발자를 응원하는 목적입니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("응원하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if storeManager.isPurchasing {
                    loadingOverlay
                }
            }
            .alert("감사합니다! 💕", isPresented: $showThankYou) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("따뜻한 응원에 감사드립니다.\n더 좋은 앱으로 보답하겠습니다!")
            }
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                Text("처리 중...")
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }
}

// MARK: - Tip Button

struct TipButton: View {
    let product: Product
    let action: () -> Void
    
    private var productID: ProductID? {
        ProductID(rawValue: product.id)
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: productID?.icon ?? "heart.fill")
                    .font(.title2)
                    .foregroundColor(.pink)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(productID?.displayName ?? product.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(product.displayPrice)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.pink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.pink.opacity(0.15))
                    .cornerRadius(8)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
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
            
            Text("프리미엄 기능")
                .font(.headline)
            
            Text("\(feature) 기능은\n프리미엄 사용자만 이용할 수 있습니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                onUpgrade()
            } label: {
                Label("프리미엄 보기", systemImage: "crown")
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
            Text("PRO")
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
