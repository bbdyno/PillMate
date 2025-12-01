//
//  MainTabView.swift
//  PillMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftData
import SwiftUI

/// 메인 탭 뷰
struct MainTabView: View {
    // MARK: - Properties
    
    @State private var selectedTab: Tab = .home
    
    enum Tab: String, CaseIterable {
        case home = "홈"
        case medications = "약물"
        case history = "기록"
        case health = "건강"
        case settings = "설정"
        
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
            HomeView()
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)
            
            MedicationListView()
                .tabItem {
                    Label(Tab.medications.rawValue, systemImage: Tab.medications.icon)
                }
                .tag(Tab.medications)
            
            LogHistoryView()
                .tabItem {
                    Label(Tab.history.rawValue, systemImage: Tab.history.icon)
                }
                .tag(Tab.history)
            
            HealthMetricsView()
                .tabItem {
                    Label(Tab.health.rawValue, systemImage: Tab.health.icon)
                }
                .tag(Tab.health)
            
            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(AppColors.primary)
        .onAppear {
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
            Caregiver.self,
            Patient.self
        ], inMemory: true)
}
