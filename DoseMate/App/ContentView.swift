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
    
    enum Tab: CaseIterable {
        case home
        case medications
        case log
        case health
        case settings
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .medications: return "pill.fill"
            case .log: return "list.clipboard.fill"
            case .health: return "heart.fill"
            case .settings: return "gearshape.fill"
            }
        }
        
        var title: String {
            switch self {
            case .home: return DoseMateStrings.Tab.home
            case .medications: return DoseMateStrings.Tab.medications
            case .log: return DoseMateStrings.Tab.history
            case .health: return DoseMateStrings.Tab.health
            case .settings: return DoseMateStrings.Tab.settings
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.title, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)
            
            MedicationListView()
                .tabItem {
                    Label(Tab.medications.title, systemImage: Tab.medications.icon)
                }
                .tag(Tab.medications)
            
            LogHistoryView()
                .tabItem {
                    Label(Tab.log.title, systemImage: Tab.log.icon)
                }
                .tag(Tab.log)
            
            HealthMetricsView()
                .tabItem {
                    Label(Tab.health.title, systemImage: Tab.health.icon)
                }
                .tag(Tab.health)
            
            SettingsView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.icon)
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
