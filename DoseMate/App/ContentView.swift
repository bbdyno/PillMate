//
//  ContentView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftData
import SwiftUI

/// 메인 탭 뷰
struct ContentView: View {
    // MARK: - Properties
    
    @State private var selectedTab: Tab = .home
    
    // MARK: - Tab Enum
    
    enum Tab: String, CaseIterable {
        case home = "홈"
        case medications = "약물"
        case log = "기록"
        case health = "건강"
        case settings = "설정"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .medications: return "pill.fill"
            case .log: return "list.clipboard.fill"
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
                    Label(Tab.log.rawValue, systemImage: Tab.log.icon)
                }
                .tag(Tab.log)
            
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
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [
            Medication.self,
            MedicationSchedule.self,
            MedicationLog.self,
            HealthMetric.self,
            Appointment.self,
            Caregiver.self
        ], inMemory: true)
}
