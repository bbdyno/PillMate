//
//  SupportConfig.swift
//  DoseMate
//
//  Created by bbdyno on 12/10/25.
//

import Foundation

// MARK: - Support Configuration

/// 개발자 후원 설정
/// MetaMask 지갑 주소 및 외부 후원 링크 관리
struct SupportConfig {

    // MARK: - 암호화폐 지갑 주소
    // ⚠️ MetaMask 지갑의 Public Address만 입력 (Private Key 절대 금지!)

    /// Ethereum (ETH) 및 ERC-20 토큰 (USDT 등) 주소
    /// MetaMask 지갑 주소 (0x로 시작)
    static let ethereumAddress = "0x5f35523757d0e672fa3ffbc0f1d50d35fd6b2571"

    /// Bitcoin (BTC) 주소
    /// Bitcoin 네트워크 주소 (bc1 또는 1, 3으로 시작)
    static let bitcoinAddress = "bc1qz5neag5j4cg6j8sj53889udws70v7223zlvgd3"

    // MARK: - 전통적 후원 방법

    /// Buy Me a Coffee URL
    static let buyMeACoffeeURL = "https://buymeacoffee.com/bbdyno"

    /// Ko-fi URL
    static let kofiURL = "https://ko-fi.com/bbdyno"

    /// GitHub Sponsors
    static let githubSponsorsURL = "https://github.com/sponsors/bbdyno"

    // MARK: - 지원 토큰 정보

    /// 지원하는 암호화폐 목록
    static let supportedCryptos: [CryptoType] = [
        .ethereum,
        .bitcoin
    ]

    /// 지원하는 전통적 방법
    static let supportedTraditionalMethods: [TraditionalSupportMethod] = [
        .buyMeACoffee,
        .githubSponsors,
        .kofi
    ]
}

// MARK: - Crypto Type

/// 암호화폐 종류
enum CryptoType: String, CaseIterable {
    case ethereum = "ETH"
    case bitcoin = "BTC"
    case usdtERC20 = "USDT"

    /// 표시 이름
    var displayName: String {
        switch self {
        case .ethereum: return "Ethereum"
        case .bitcoin: return "Bitcoin"
        case .usdtERC20: return "USDT (ERC-20)"
        }
    }

    /// 한국어 이름
    var displayNameKorean: String {
        switch self {
        case .ethereum: return "이더리움"
        case .bitcoin: return "비트코인"
        case .usdtERC20: return "테더 (USDT)"
        }
    }

    /// 아이콘
    var icon: String {
        switch self {
        case .ethereum: return "diamond.fill"
        case .bitcoin: return "bitcoinsign.circle.fill"
        case .usdtERC20: return "dollarsign.circle.fill"
        }
    }

    /// 아이콘 색상 (gradient용)
    var iconColor: (String, String) {
        switch self {
        case .ethereum: return ("purple", "blue")
        case .bitcoin: return ("orange", "yellow")
        case .usdtERC20: return ("green", "teal")
        }
    }

    /// 지갑 주소
    var address: String {
        switch self {
        case .ethereum, .usdtERC20:
            return SupportConfig.ethereumAddress
        case .bitcoin:
            return SupportConfig.bitcoinAddress
        }
    }

    /// QR 코드용 URI
    var qrCodeURI: String {
        switch self {
        case .ethereum:
            return "ethereum:\(address)"
        case .bitcoin:
            return "bitcoin:\(address)"
        case .usdtERC20:
            // USDT는 Ethereum 네트워크 사용 (ERC-20)
            return "ethereum:\(address)"
        }
    }

    /// 설명 (한국어)
    var descriptionKorean: String {
        switch self {
        case .ethereum:
            return "MetaMask, Trust Wallet 등에서 ETH 송금"
        case .bitcoin:
            return "Bitcoin 지갑에서 BTC 송금"
        case .usdtERC20:
            return "Ethereum 네트워크의 USDT 송금 (가격 변동 없음)"
        }
    }

    /// 설명 (영어)
    var descriptionEnglish: String {
        switch self {
        case .ethereum:
            return "Send ETH from MetaMask, Trust Wallet, etc."
        case .bitcoin:
            return "Send BTC from Bitcoin wallet"
        case .usdtERC20:
            return "Send USDT on Ethereum network (stable price)"
        }
    }

    /// 주의사항 (한국어)
    var warningKorean: String {
        switch self {
        case .ethereum:
            return "⚠️ 반드시 Ethereum 메인넷으로 송금하세요"
        case .bitcoin:
            return "⚠️ Bitcoin 네트워크 수수료를 확인하세요"
        case .usdtERC20:
            return "⚠️ 반드시 ERC-20 (Ethereum) 네트워크를 선택하세요"
        }
    }

    /// 주의사항 (영어)
    var warningEnglish: String {
        switch self {
        case .ethereum:
            return "⚠️ Make sure to use Ethereum Mainnet"
        case .bitcoin:
            return "⚠️ Check Bitcoin network fees"
        case .usdtERC20:
            return "⚠️ Select ERC-20 (Ethereum) network only"
        }
    }

    /// 네트워크 정보
    var networkInfo: String {
        switch self {
        case .ethereum:
            return "Ethereum Mainnet"
        case .bitcoin:
            return "Bitcoin Network"
        case .usdtERC20:
            return "Ethereum (ERC-20)"
        }
    }
}

// MARK: - Traditional Support Method

/// 전통적인 후원 방법
enum TraditionalSupportMethod: String, CaseIterable {
    case buyMeACoffee = "Buy Me a Coffee"
    case kofi = "Ko-fi"
    case githubSponsors = "GitHub Sponsors"

    /// 표시 이름
    var displayName: String {
        rawValue
    }

    /// 아이콘
    var icon: String {
        switch self {
        case .buyMeACoffee:
            return "cup.and.saucer.fill"
        case .kofi:
            return "cup.and.saucer.fill"
        case .githubSponsors:
            return "heart.fill"
        }
    }

    /// URL
    var url: String {
        switch self {
        case .buyMeACoffee:
            return SupportConfig.buyMeACoffeeURL
        case .kofi:
            return SupportConfig.kofiURL
        case .githubSponsors:
            return SupportConfig.githubSponsorsURL
        }
    }

    /// 설명 (한국어)
    var descriptionKorean: String {
        switch self {
        case .buyMeACoffee:
            return "커피 한 잔 값으로 후원 (국제 사용자)"
        case .kofi:
            return "Ko-fi로 후원 (국제 사용자)"
        case .githubSponsors:
            return "GitHub Sponsors로 월간 후원"
        }
    }

    /// 설명 (영어)
    var descriptionEnglish: String {
        switch self {
        case .buyMeACoffee:
            return "Buy me a coffee (International)"
        case .kofi:
            return "Support via Ko-fi (International)"
        case .githubSponsors:
            return "Monthly sponsorship via GitHub"
        }
    }

    /// 한국 전용 여부
    var isKoreaOnly: Bool {
        return false
    }

    /// 월간 후원 지원 여부
    var supportsRecurring: Bool {
        switch self {
        case .githubSponsors:
            return true
        default:
            return false
        }
    }
}

// MARK: - Support Analytics (Optional)

/// 후원 통계 (UserDefaults 기반)
struct SupportAnalytics {

    private static let viewCountKey = "supportViewCount"
    private static let lastViewedKey = "supportLastViewed"

    /// 후원 페이지 조회 횟수
    static var viewCount: Int {
        get { UserDefaults.standard.integer(forKey: viewCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: viewCountKey) }
    }

    /// 마지막 조회 날짜
    static var lastViewed: Date? {
        get { UserDefaults.standard.object(forKey: lastViewedKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastViewedKey) }
    }

    /// 조회 기록
    static func recordView() {
        viewCount += 1
        lastViewed = Date()
    }
}
