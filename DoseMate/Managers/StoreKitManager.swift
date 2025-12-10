//
//  StoreKitManager.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

//  ⚠️ 서버 없이 클라이언트만으로 구현
//  - 비소모품(Non-Consumable): 프리미엄 평생 이용권
//  - 소모품(Consumable): 기부/팁 (기능 해제 없음)
//

import Foundation
import StoreKit

// MARK: - Product IDs

/// 인앱 결제 제품 ID
/// App Store Connect에서 동일한 ID로 제품 생성 필요
enum ProductID: String, CaseIterable {
    // MARK: 프리미엄 (Non-Consumable)
    // 정책 변경 시 이 ID들을 수정
    
    /// 프리미엄 평생 이용권
    /// 가격: ₩12,900 (권장)
    case premium = "com.dosemate.premium"
    
    // MARK: 기부/팁 (Consumable)
    // 기부 금액은 App Store Connect에서 설정
    
    /// 작은 기부 (₩1,000)
    case tipSmall = "com.dosemate.tip.small"
    
    /// 중간 기부 (₩3,900)
    case tipMedium = "com.dosemate.tip.medium"
    
    /// 큰 기부 (₩9,900)
    case tipLarge = "com.dosemate.tip.large"
    
    // MARK: - 제품 분류
    
    /// 비소모품 ID 목록
    static var nonConsumables: [ProductID] {
        [.premium]
    }
    
    /// 소모품(기부) ID 목록
    static var consumables: [ProductID] {
        [.tipSmall, .tipMedium, .tipLarge]
    }
    
    /// 모든 제품 ID 문자열
    static var allProductIDs: Set<String> {
        Set(allCases.map { $0.rawValue })
    }
    
    /// 표시 이름
    var displayName: String {
        switch self {
        case .premium: return "프리미엄 평생 이용권"
        case .tipSmall: return "커피 한 잔"
        case .tipMedium: return "맛있는 식사"
        case .tipLarge: return "든든한 후원"
        }
    }
    
    /// 아이콘
    var icon: String {
        switch self {
        case .premium: return "crown.fill"
        case .tipSmall: return "cup.and.saucer.fill"
        case .tipMedium: return "fork.knife"
        case .tipLarge: return "heart.fill"
        }
    }
}

// MARK: - StoreKit Manager

/// StoreKit 2 기반 인앱 결제 매니저
/// - 서버 없이 클라이언트에서 모든 처리
/// - Apple의 서명된 거래 정보로 검증
@MainActor
@Observable
final class StoreKitManager {
    
    // MARK: - Singleton
    
    static let shared = StoreKitManager()
    
    // MARK: - Published Properties
    
    /// 사용 가능한 제품 목록
    var products: [Product] = []
    
    /// 프리미엄 제품
    var premiumProduct: Product? {
        products.first { $0.id == ProductID.premium.rawValue }
    }
    
    /// 기부 제품들
    var tipProducts: [Product] {
        products.filter { product in
            ProductID.consumables.map { $0.rawValue }.contains(product.id)
        }.sorted { $0.price < $1.price }
    }
    
    /// 프리미엄 구매 여부
    var isPremium: Bool = false {
        didSet {
            // 앱 시작 시 iCloud 설정을 위해 캐시
            UserDefaults.standard.set(isPremium, forKey: "isPremiumCached")
        }
    }
    
    /// 로딩 상태
    var isLoading: Bool = false
    
    /// 구매 진행 중
    var isPurchasing: Bool = false
    
    /// 에러 메시지
    var errorMessage: String?
    
    /// 성공 메시지
    var successMessage: String?
    
    /// 총 기부 횟수 (UserDefaults 저장)
    var totalTipCount: Int {
        get { UserDefaults.standard.integer(forKey: "totalTipCount") }
        set { UserDefaults.standard.set(newValue, forKey: "totalTipCount") }
    }
    
    // MARK: - Private Properties
    
    /// 거래 리스너 태스크
    nonisolated(unsafe) private var transactionListener: Task<Void, Error>?
    
    /// 프리미엄 상태 저장 키
    private let premiumKey = "isPremiumUser"
    
    // MARK: - Initialization
    
    private init() {
        // 저장된 프리미엄 상태 로드
        isPremium = UserDefaults.standard.bool(forKey: premiumKey)
        // 앱 시작 시 iCloud 설정을 위해 캐시 동기화
        UserDefaults.standard.set(isPremium, forKey: "isPremiumCached")
        
        // 거래 리스너 시작
        transactionListener = listenForTransactions()
        
        // 제품 로드 및 구매 상태 확인
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Product Loading
    
    /// App Store에서 제품 정보 로드
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // StoreKit 2: Product.products(for:)로 제품 로드
            let loadedProducts = try await Product.products(for: ProductID.allProductIDs)
            
            // 정렬: 프리미엄 먼저, 그 다음 가격순
            products = loadedProducts.sorted { product1, product2 in
                if product1.id == ProductID.premium.rawValue { return true }
                if product2.id == ProductID.premium.rawValue { return false }
                return product1.price < product2.price
            }
            
            print("제품 로드 완료: \(products.count)개")
            
        } catch {
            print("제품 로드 실패: \(error)")
            errorMessage = "제품 정보를 불러올 수 없습니다."
        }
    }
    
    // MARK: - Purchase
    
    /// 제품 구매
    /// - Parameter product: 구매할 제품
    /// - Returns: 구매 성공 여부
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        errorMessage = nil
        successMessage = nil
        
        defer { isPurchasing = false }
        
        do {
            // StoreKit 2: 구매 요청
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // 거래 검증
                let transaction = try checkVerified(verification)
                
                // 구매 처리
                await handlePurchase(transaction)
                
                // 거래 완료 표시 (중요!)
                await transaction.finish()
                
                print("구매 성공: \(product.displayName)")
                return true
                
            case .userCancelled:
                print("사용자가 구매를 취소했습니다.")
                return false
                
            case .pending:
                // 부모 승인 대기 등
                print("구매 대기 중 (승인 필요)")
                errorMessage = "구매 승인 대기 중입니다."
                return false
                
            @unknown default:
                return false
            }
            
        } catch StoreKit.StoreKitError.userCancelled {
            print("사용자가 구매를 취소했습니다.")
            return false
            
        } catch {
            print("구매 실패: \(error)")
            errorMessage = "구매에 실패했습니다. 다시 시도해주세요."
            return false
        }
    }
    
    /// 프리미엄 구매 (편의 메서드)
    @discardableResult
    func purchasePremium() async -> Bool {
        guard let product = premiumProduct else {
            errorMessage = "프리미엄 제품을 찾을 수 없습니다."
            return false
        }
        
        let success = await purchase(product)
        if success {
            successMessage = "프리미엄으로 업그레이드되었습니다! 🎉"
        }
        return success
    }
    
    /// 기부하기
    @discardableResult
    func tip(_ productID: ProductID) async -> Bool {
        guard ProductID.consumables.contains(productID),
              let product = products.first(where: { $0.id == productID.rawValue }) else {
            errorMessage = "제품을 찾을 수 없습니다."
            return false
        }
        
        let success = await purchase(product)
        if success {
            totalTipCount += 1
            successMessage = "감사합니다! 개발에 큰 힘이 됩니다 💕"
        }
        return success
    }
    
    // MARK: - Restore Purchases
    
    /// 구매 복원
    /// - 다른 기기에서 구매한 내역 복원
    /// - 앱 재설치 후 복원
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        defer { isLoading = false }
        
        do {
            // StoreKit 2: 동기화 요청
            try await AppStore.sync()
            
            // 구매 상태 업데이트
            await updatePurchasedProducts()
            
            if isPremium {
                successMessage = "프리미엄이 복원되었습니다!"
            } else {
                successMessage = "복원할 구매 내역이 없습니다."
            }
            
            print("구매 복원 완료")
            
        } catch {
            print("구매 복원 실패: \(error)")
            errorMessage = "구매 복원에 실패했습니다."
        }
    }
    
    // MARK: - Transaction Handling
    
    /// 거래 리스너
    /// - 앱 실행 중 발생하는 거래 감지
    /// - 백그라운드에서 완료된 거래 처리
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            // StoreKit 2: Transaction.updates로 거래 스트림 수신
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.handlePurchase(transaction)
                    await transaction.finish()
                } catch {
                    print("거래 처리 실패: \(error)")
                }
            }
        }
    }
    
    /// 구매 처리
    private func handlePurchase(_ transaction: Transaction) async {
        // 제품 타입에 따라 처리
        if transaction.productID == ProductID.premium.rawValue {
            // 프리미엄 활성화
            await MainActor.run {
                self.isPremium = true
                UserDefaults.standard.set(true, forKey: self.premiumKey)
            }
            print("프리미엄 활성화됨")
        }
        
        // 기부는 별도 처리 없음 (소모품)
    }
    
    /// 구매 상태 업데이트
    /// - 앱 시작 시 현재 구매 상태 확인
    func updatePurchasedProducts() async {
        // StoreKit 2: Transaction.currentEntitlements로 현재 구매 내역 확인
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.productID == ProductID.premium.rawValue {
                    // 유효한 프리미엄 구매 확인
                    await MainActor.run {
                        self.isPremium = true
                        UserDefaults.standard.set(true, forKey: self.premiumKey)
                    }
                }
            } catch {
                print("거래 검증 실패: \(error)")
            }
        }
        
        print("프리미엄 상태: \(isPremium)")
    }
    
    // MARK: - Verification
    
    /// 거래 검증
    /// - Apple의 서명 검증 (서버 없이 클라이언트에서 처리)
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            // Apple이 서명 검증 완료
            return safe
            
        case .unverified(_, let error):
            // 검증 실패 (변조 가능성)
            throw StoreKitError.failedVerification(error)
        }
    }
    
    // MARK: - Helper Methods
    
    /// 제품 가격 문자열
    func priceString(for productID: ProductID) -> String {
        guard let product = products.first(where: { $0.id == productID.rawValue }) else {
            return "-"
        }
        return product.displayPrice
    }
    
    /// 프리미엄 가격 문자열
    var premiumPriceString: String {
        premiumProduct?.displayPrice ?? "₩12,900"
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    /// 디버그용 프리미엄 상태 토글
    /// ⚠️ DEBUG 빌드에서만 사용 가능
    func debugTogglePremium() {
        isPremium.toggle()
        UserDefaults.standard.set(isPremium, forKey: premiumKey)
        print("🔧 [DEBUG] 프리미엄 상태 변경: \(isPremium)")
    }
    
    /// 디버그용 프리미엄 상태 강제 설정
    func debugSetPremium(_ value: Bool) {
        isPremium = value
        UserDefaults.standard.set(value, forKey: premiumKey)
        print("🔧 [DEBUG] 프리미엄 상태 설정: \(value)")
    }
    
    /// 디버그용 기부 횟수 리셋
    func debugResetTipCount() {
        UserDefaults.standard.set(0, forKey: "totalTipCount")
        print("🔧 [DEBUG] 기부 횟수 리셋")
    }
    #endif
}

// MARK: - StoreKit Error

/// StoreKit 에러 정의
enum StoreKitError: LocalizedError {
    case failedVerification(Error)
    case productNotFound
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "거래 검증에 실패했습니다."
        case .productNotFound:
            return "제품을 찾을 수 없습니다."
        case .purchaseFailed:
            return "구매에 실패했습니다."
        }
    }
}

// MARK: - Premium Features

/// 프리미엄 기능 정의
/// 💡 프리미엄 정책 변경 시 이 구조체 수정
struct PremiumFeatures {
    
    // MARK: - 무료 사용자 제한
    // 💡 제한 값을 변경하여 정책 조정 가능
    
    /// 무료 사용자 최대 약물 등록 수
    static let freeMedicationLimit = 3
    
    /// 무료 사용자 복약 기록 보관 일수
    static let freeLogRetentionDays = 7
    
    /// 무료 사용자 보호자 등록 수
    static let freeCaregiverLimit = 1
    
    // MARK: - 프리미엄 전용 기능 목록
    
    /// 프리미엄 기능 설명
    static let features: [(icon: String, title: String, description: String)] = [
        ("infinity", "무제한 약물 등록", "3개 제한 없이 모든 약물 관리"),
        ("chart.line.uptrend.xyaxis", "상세 통계 & 차트", "주간/월간/연간 복약 분석"),
        ("heart.text.square", "HealthKit 연동", "건강 앱과 데이터 동기화"),
        ("person.2.fill", "보호자 알림", "복약 미이행 시 보호자에게 알림"),
        ("square.and.arrow.up", "데이터 내보내기", "CSV로 기록 내보내기"),
        ("icloud.fill", "iCloud 백업", "기기 간 데이터 동기화"),
        ("bell.badge", "고급 알림", "맞춤 알림음 및 Critical Alerts"),
        ("rectangle.3.group", "모든 위젯", "중형/대형 위젯 사용"),
    ]
    
    // MARK: - 기능 체크 메서드
    
    /// 약물 추가 가능 여부
    @MainActor static func canAddMedication(currentCount: Int) -> Bool {
        StoreKitManager.shared.isPremium || currentCount < freeMedicationLimit
    }
    
    /// HealthKit 사용 가능 여부
    @MainActor static var canUseHealthKit: Bool {
        StoreKitManager.shared.isPremium
    }
    
    /// 상세 통계 사용 가능 여부
    @MainActor static var canUseDetailedStatistics: Bool {
        StoreKitManager.shared.isPremium
    }
    
    /// 보호자 알림 사용 가능 여부
    @MainActor static func canAddCaregiver(currentCount: Int) -> Bool {
        StoreKitManager.shared.isPremium || currentCount < freeCaregiverLimit
    }
    
    /// 데이터 내보내기 가능 여부
    @MainActor static var canExportData: Bool {
        StoreKitManager.shared.isPremium
    }
    
    /// iCloud 백업 가능 여부
    @MainActor static var canUseiCloud: Bool {
        StoreKitManager.shared.isPremium
    }
    
    /// 고급 알림 사용 가능 여부
    @MainActor static var canUseAdvancedNotifications: Bool {
        StoreKitManager.shared.isPremium
    }
    
    /// 위젯 사용 가능 여부 (중형/대형)
    @MainActor static var canUseLargeWidgets: Bool {
        StoreKitManager.shared.isPremium
    }
}
