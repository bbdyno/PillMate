//
//  ContentView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    @Environment(\.modelContext) private var modelContext
    @Query private var patients: [Patient]
    @Query private var medications: [Medication]

    var body: some View {
        Group {
            if shouldShowOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            checkAndSkipOnboarding()
        }
    }

    /// 온보딩을 표시해야 하는지 확인
    private var shouldShowOnboarding: Bool {
        // 이미 온보딩을 완료했으면 표시하지 않음
        if onboardingCompleted {
            return false
        }

        // iCloud에서 데이터가 동기화되었으면 온보딩 스킵
        // Patient나 Medication 데이터가 있으면 이미 사용 중인 것으로 간주
        if !patients.isEmpty || !medications.isEmpty {
            return false
        }

        return true
    }

    /// iCloud 데이터 확인 및 온보딩 자동 스킵
    private func checkAndSkipOnboarding() {
        // iCloud 동기화가 활성화되어 있고 데이터가 있으면 온보딩 자동 완료
        if DoseMateApp.isCloudSyncEnabled && (!patients.isEmpty || !medications.isEmpty) {
            onboardingCompleted = true
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
            Patient.self
        ], inMemory: true)
}
