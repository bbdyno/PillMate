//
//  MainTabView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftData
import SwiftUI
import DMateDesignSystem
import DMateResource
import Darwin

/// 메인 탭 뷰
struct MainTabView: View {
    // MARK: - Properties

    @State private var selectedTab: Tab = .home

    /// AI 브리핑 탭 사용 가능 여부 (iPhone 15 Pro+ & iOS 18.2+)
    private var isAIBriefingAvailable: Bool {
        // iOS 버전 체크 (18.2 이상)
        guard #available(iOS 18.2, *) else {
            return false
        }

        // 디바이스 모델 체크 (iPhone 15 Pro 이상)
        return isDeviceSupportedForAI()
    }

    /// AI 브리핑을 지원하는 디바이스인지 확인
    private func isDeviceSupportedForAI() -> Bool {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        }

        guard let model = modelCode else { return false }

        // iPhone 15 Pro: iPhone16,1 (Pro), iPhone16,2 (Pro Max)
        // iPhone 16 Pro: iPhone17,1 (Pro), iPhone17,2 (Pro Max)
        // 시뮬레이터: 개발 목적으로 허용
        let supportedModels = [
            "iPhone16,1", "iPhone16,2",  // iPhone 15 Pro/Pro Max
            "iPhone17,1", "iPhone17,2",  // iPhone 16 Pro/Pro Max
            "arm64", "x86_64"            // Simulator
        ]

        // 정확한 모델 매칭 또는 시뮬레이터
        if supportedModels.contains(model) {
            return true
        }

        // iPhone16,1 이상의 모델 번호 체크 (미래 기기 대응)
        if model.hasPrefix("iPhone") {
            let components = model.components(separatedBy: ",")
            if let firstComponent = components.first,
               let modelNumber = Int(firstComponent.replacingOccurrences(of: "iPhone", with: "")),
               modelNumber >= 16 {
                return true
            }
        }

        return false
    }
    
    enum Tab: CaseIterable {
        case home
        case medications
        case history
        case ai
        case settings

        var title: String {
            switch self {
            case .home: return DMateResourceStrings.Tab.home
            case .medications: return DMateResourceStrings.Tab.medications
            case .settings: return DMateResourceStrings.Tab.settings
            case .history: return
                DMateResourceStrings.Tab.history
            case .ai: return
                DMateResourceStrings.Tab.ai
            }
        }
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .medications: return "pill.fill"
            case .history: return "list.clipboard"
            case .ai: return "brain.head.profile"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label(Tab.home.title, systemImage: Tab.home.icon)
            }
            .tag(Tab.home)

            NavigationStack {
                MedicationListView()
            }
            .tabItem {
                Label(Tab.medications.title, systemImage: Tab.medications.icon)
            }
            .tag(Tab.medications)

            NavigationStack {
                LogHistoryView()
            }
            .tabItem {
                Label(Tab.history.title, systemImage: Tab.history.icon)
            }
            .tag(Tab.history)

            // AI 브리핑 탭 (iPhone 15 Pro+ & iOS 18.2+ 에서만 표시)
//            if isAIBriefingAvailable {
//                NavigationStack {
//                    AIHealthBriefingView()
//                }
//                .tabItem {
//                    Label(Tab.ai.title, systemImage: Tab.ai.icon)
//                }
//                .tag(Tab.ai)
//            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(Tab.settings.title, systemImage: Tab.settings.icon)
            }
            .tag(Tab.settings)
        }
        .tint(AppColors.primary)
        .onAppear {
            // NavigationBar 외관 설정 (투명 배경)
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithTransparentBackground()
            navBarAppearance.backgroundColor = UIColor.clear
            navBarAppearance.shadowColor = UIColor.clear
            
            UINavigationBar.appearance().standardAppearance = navBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
            UINavigationBar.appearance().compactAppearance = navBarAppearance
            UINavigationBar.appearance().compactScrollEdgeAppearance = navBarAppearance
            
            // 탭바 외관 설정
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor.systemBackground
            
            // 선택 안 된 아이템
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppColors.textTertiary)
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(AppColors.textTertiary)]
            
            // 선택된 아이템
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.primary)
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(AppColors.primary)]
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: [
            Medication.self,
            MedicationSchedule.self,
            MedicationLog.self,
//            HealthMetric.self,
            Appointment.self,
            Patient.self
        ], inMemory: true)
}
