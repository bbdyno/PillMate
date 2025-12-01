//
//  PillMateApp.swift
//  PillMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import SwiftData
import UserNotifications

/// 메인 앱
@main
struct PillMateApp: App {
    // MARK: - Properties
    
    /// 앱 델리게이트
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    /// 외관 모드
    @AppStorage(AppConstants.UserDefaultsKeys.appearanceMode) private var appearanceMode = "system"
    
    /// SwiftData 모델 컨테이너
    let modelContainer: ModelContainer
    
    // MARK: - Initialization
    
    init() {
        // 모델 컨테이너 설정
        let schema = Schema([
            Medication.self,
            MedicationSchedule.self,
            MedicationLog.self,
            HealthMetric.self,
            Appointment.self,
            Caregiver.self,
            Patient.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        // 외관 설정
        configureAppearance()
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
                .onAppear {
                    setupNotifications()
                }
        }
        .modelContainer(modelContainer)
    }
    
    // MARK: - Computed Properties
    
    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    // MARK: - Methods
    
    /// 외관 설정
    private func configureAppearance() {
        // 네비게이션 바 외관
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // 탭 바 외관
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    /// 알림 설정
    private func setupNotifications() {
        Task {
            do {
                try await NotificationManager.shared.requestAuthorization()
            } catch {
                print("알림 권한 요청 실패: \(error)")
            }
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 알림 델리게이트 설정
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // 원격 알림 등록 처리
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(token)")
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("원격 알림 등록 실패: \(error)")
    }
}
