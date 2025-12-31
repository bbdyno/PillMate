//
//  SupportDeveloperView.swift
//  DoseMate
//
//  Created by bbdyno on 12/10/25.
//

import SwiftUI
import DMateDesignSystem
import DMateResource

// MARK: - Support Developer View

/// 개발자 후원 메인 화면
struct SupportDeveloperView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    // 언어 감지
    private var isKorean: Bool {
        locale.language.languageCode?.identifier == "ko"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    cryptoSection
                    traditionalSection
                    infoSection
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle(DMateResourceStrings.Support.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(DMateResourceStrings.Support.close) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                SupportAnalytics.recordView()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // 아이콘
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            AppColors.premiumPink,
                            AppColors.danger
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // 제목
            Text(isKorean ? "DoseMate 개발 지원" : "Support DoseMate Development")
                .font(.title2)
                .fontWeight(.bold)

            // 설명
            Text(isKorean
                ? "DoseMate는 무료 앱입니다.\n자발적 후원은 더 나은 앱 개발에 큰 힘이 됩니다."
                : "DoseMate is a free app.\nYour support helps improve the app.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    // MARK: - Crypto Section

    private var cryptoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            HStack {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundColor(AppColors.warning)
                Text(DMateResourceStrings.Support.cryptoSection)
                    .font(.headline)
            }
            .padding(.horizontal, 4)

            // 암호화폐 목록
            VStack(spacing: 12) {
                ForEach(SupportConfig.supportedCryptos, id: \.self) { crypto in
                    NavigationLink {
                        CryptoDetailView(cryptoType: crypto)
                    } label: {
                        CryptoRow(cryptoType: crypto)
                    }
                }
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(16)
        }
    }

    // MARK: - Traditional Section

    private var traditionalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(AppColors.primary)
                Text(DMateResourceStrings.Support.traditionalSection)
                    .font(.headline)
            }
            .padding(.horizontal, 4)

            // 전통적 방법 목록
            VStack(spacing: 12) {
                ForEach(SupportConfig.supportedTraditionalMethods, id: \.self) { method in
                    TraditionalSupportRow(method: method)
                }
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(16)
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(spacing: 12) {
            Text(DMateResourceStrings.Support.infoSection)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(
                    icon: "checkmark.circle.fill",
                    color: AppColors.success,
                    text: DMateResourceStrings.Support.infoVoluntary
                )

                InfoRow(
                    icon: "lock.shield.fill",
                    color: AppColors.info,
                    text: DMateResourceStrings.Support.infoBlockchain
                )

                InfoRow(
                    icon: "heart.fill",
                    color: AppColors.premiumPink,
                    text: DMateResourceStrings.Support.infoDevelopment
                )
            }
        }
        .padding()
        .background(Color.appCardBackground.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Crypto Row

struct CryptoRow: View {
    let cryptoType: CryptoType
    @Environment(\.locale) private var locale

    private var isKorean: Bool {
        locale.language.languageCode?.identifier == "ko"
    }

    var body: some View {
        HStack(spacing: 16) {
            // 아이콘
            Image(systemName: cryptoType.icon)
                .font(.title2)
                .foregroundColor(getCryptoColor())
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                // 이름
                Text(isKorean ? cryptoType.displayNameKorean : cryptoType.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                // 네트워크 정보
                Text(cryptoType.networkInfo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func getCryptoColor() -> Color {
        switch cryptoType {
        case .ethereum:
            return Color.purple
        case .bitcoin:
            return Color.orange
        case .usdtERC20:
            return Color.green
        }
    }
}

// MARK: - Crypto Detail View

struct CryptoDetailView: View {
    let cryptoType: CryptoType
    @Environment(\.locale) private var locale
    @State private var showCopiedAlert = false
    @State private var showShareSheet = false

    private var isKorean: Bool {
        locale.language.languageCode?.identifier == "ko"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // QR 코드
                qrCodeSection

                // 주소
                addressSection

                // 설명 및 주의사항
                infoSection

                // 액션 버튼들
                actionButtons
            }
            .padding()
        }
        .background(AppColors.background)
        .navigationTitle(isKorean ? cryptoType.displayNameKorean : cryptoType.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .alert(DMateResourceStrings.Support.addressCopied, isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(DMateResourceStrings.Support.pasteWallet)
        }
    }

    // QR 코드 섹션
    private var qrCodeSection: some View {
        VStack(spacing: 16) {
            CryptoQRCodeView(for: cryptoType, size: CGSize(width: 250, height: 250))
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 10)

            Text(DMateResourceStrings.Support.qrScan)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // 주소 섹션
    private var addressSection: some View {
        VStack(spacing: 12) {
            Text(DMateResourceStrings.Support.addressLabel)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text(cryptoType.address)
                    .font(.system(.footnote, design: .monospaced))
                    .lineLimit(2)
                    .foregroundColor(.primary)

                Button {
                    UIPasteboard.general.string = cryptoType.address
                    showCopiedAlert = true
                } label: {
                    Image(systemName: "doc.on.doc.fill")
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
    }

    // 정보 섹션
    private var infoSection: some View {
        VStack(spacing: 16) {
            // 설명
            VStack(alignment: .leading, spacing: 8) {
                Label(DMateResourceStrings.Support.howToSend, systemImage: "info.circle.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.info)

                Text(isKorean ? cryptoType.descriptionKorean : cryptoType.descriptionEnglish)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(AppColors.info.opacity(0.1))
            .cornerRadius(12)

            // 주의사항
            VStack(alignment: .leading, spacing: 8) {
                Label(DMateResourceStrings.Support.warningLabel, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.warning)

                Text(isKorean ? cryptoType.warningKorean : cryptoType.warningEnglish)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(AppColors.warning.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // 액션 버튼들
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 주소 복사 버튼
            Button {
                UIPasteboard.general.string = cryptoType.address
                showCopiedAlert = true
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text(DMateResourceStrings.Support.addressCopy)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // QR 코드 공유 버튼 (선택사항)
            Button {
                shareQRCode()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text(isKorean ? "QR 코드 공유" : "Share QR Code")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.appCardBackground)
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }

    private func shareQRCode() {
        let qrImage = QRCodeGenerator.generateCrypto(
            for: cryptoType,
            size: CGSize(width: 512, height: 512)
        )

        let activityVC = UIActivityViewController(
            activityItems: [qrImage],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Traditional Support Row

struct TraditionalSupportRow: View {
    let method: TraditionalSupportMethod
    @Environment(\.locale) private var locale

    private var isKorean: Bool {
        locale.language.languageCode?.identifier == "ko"
    }

    var body: some View {
        Button {
            if let url = URL(string: method.url) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 16) {
                // 아이콘
                Image(systemName: method.icon)
                    .font(.title2)
                    .foregroundColor(getMethodColor())
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    // 이름
                    Text(method.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    // 설명
                    Text(isKorean ? method.descriptionKorean : method.descriptionEnglish)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }

    private func getMethodColor() -> Color {
        switch method {
        case .buyMeACoffee:
            return Color.brown
        case .kofi:
            return Color.red
        case .githubSponsors:
            return Color.pink
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview("Support Developer View") {
    SupportDeveloperView()
}

#Preview("Crypto Detail - Ethereum") {
    NavigationStack {
        CryptoDetailView(cryptoType: .ethereum)
    }
}

#Preview("Crypto Detail - Bitcoin") {
    NavigationStack {
        CryptoDetailView(cryptoType: .bitcoin)
    }
}
