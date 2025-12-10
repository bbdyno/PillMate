//
//  MainTabView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftData
import SwiftUI

/// 메인 탭 뷰
struct MainTabView: View {
    // MARK: - Properties
    
    @State private var selectedTab: Tab = .home
    
    enum Tab: CaseIterable {
        case home
        case medications
        case history
        case health
        case settings

        var title: String {
            switch self {
            case .home: return DoseMateStrings.Tab.home
            case .medications: return DoseMateStrings.Tab.medications
            case .settings: return DoseMateStrings.Tab.settings
            case .history: return NSLocalizedString("tab.history", comment: "")
            case .health: return NSLocalizedString("tab.health", comment: "")
            }
        }
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .medications: return "pill.fill"
            case .history: return "list.clipboard"
            case .health: return "heart.fill"
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
            
            NavigationStack {
                HealthMetricsView()
            }
            .tabItem {
                Label(Tab.health.title, systemImage: Tab.health.icon)
            }
            .tag(Tab.health)
            
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
            HealthMetric.self,
            Appointment.self,
            Patient.self
        ], inMemory: true)
}
