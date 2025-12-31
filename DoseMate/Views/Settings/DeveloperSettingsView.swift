//
//  DeveloperSettingsView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import DMateDesignSystem
import DMateResource
import SwiftData

#if DEBUG

/// 개발자 설정 화면
/// ⚠️ DEBUG 빌드에서만 사용 가능
struct DeveloperSettingsView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext

    @Query private var medications: [Medication]
    @Query private var logs: [MedicationLog]
    @Query private var appointments: [Appointment]
    @Query private var healthMetrics: [HealthMetric]
    @Query private var patients: [Patient]
    
    @State private var showResetAlert = false
    @State private var showSampleDataAlert = false
    
    // MARK: - Body
    
    var body: some View {
        List {
            // 데이터 현황
            dataStatusSection
            
            // 테스트 도구
            testToolsSection
            
            // 앱 정보
            appInfoSection
        }
        .navigationTitle(DMateResourceStrings.Developer.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert(DMateResourceStrings.Developer.deleteAllTitle, isPresented: $showResetAlert) {
            Button(DMateResourceStrings.Common.cancel, role: .cancel) {}
            Button(DMateResourceStrings.Common.delete, role: .destructive) {
                resetAllData()
            }
        } message: {
            Text(DMateResourceStrings.Developer.deleteAllMessage)
        }
        .alert(DMateResourceStrings.Developer.addSampleData, isPresented: $showSampleDataAlert) {
            Button(DMateResourceStrings.Common.cancel, role: .cancel) {}
            Button(DMateResourceStrings.Common.add) {
                addSampleData()
            }
        } message: {
            Text(DMateResourceStrings.Developer.addSampleDataMessage)
        }
    }

    // MARK: - Data Status Section
    
    private var dataStatusSection: some View {
        Section {
            dataRow(DMateResourceStrings.Developer.dataPatients, count: patients.count, icon: "person.crop.circle.fill", color: .teal)
            dataRow(DMateResourceStrings.Developer.dataMedications, count: medications.count, icon: "pills.fill", color: .blue)
            dataRow(DMateResourceStrings.Developer.dataLogs, count: logs.count, icon: "list.clipboard.fill", color: .green)
            dataRow(DMateResourceStrings.Developer.dataAppointments, count: appointments.count, icon: "calendar", color: .orange)
            dataRow(DMateResourceStrings.Developer.dataHealthMetrics, count: healthMetrics.count, icon: "heart.fill", color: .red)

            // 총 데이터
            HStack {
                Text(DMateResourceStrings.Developer.totalData)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(totalDataCount)개")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        } header: {
            Label(DMateResourceStrings.Developer.dataStatus, systemImage: "chart.bar.fill")
        }
    }
    
    private func dataRow(_ title: String, count: Int, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
            Spacer()
            Text("\(count)")
                .foregroundColor(.secondary)
        }
    }
    
    private var totalDataCount: Int {
        patients.count + medications.count + logs.count + appointments.count + healthMetrics.count
    }
    
    // MARK: - Test Tools Section
    
    private var testToolsSection: some View {
        Section {
            // 샘플 데이터 추가
            Button {
                showSampleDataAlert = true
            } label: {
                Label(DMateResourceStrings.Developer.addSampleData, systemImage: "plus.rectangle.on.rectangle")
            }

            // 모든 데이터 삭제
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Label(DMateResourceStrings.Developer.deleteAllTitle, systemImage: "trash.fill")
            }

            // UserDefaults 초기화
            Button(role: .destructive) {
                resetUserDefaults()
            } label: {
                Label(DMateResourceStrings.Developer.resetUserDefaults, systemImage: "arrow.counterclockwise")
            }
        } header: {
            Label(DMateResourceStrings.Developer.testTools, systemImage: "hammer.fill")
        } footer: {
            Text(DMateResourceStrings.Developer.testToolsFooter)
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        Section {
            infoRow(DMateResourceStrings.Developer.buildType, value: "DEBUG")
            infoRow("Bundle ID", value: Bundle.main.bundleIdentifier ?? "-")
            infoRow(DMateResourceStrings.Developer.version, value: appVersion)
            infoRow(DMateResourceStrings.Developer.build, value: buildNumber)
            infoRow("iOS", value: UIDevice.current.systemVersion)
            infoRow(DMateResourceStrings.Developer.device, value: UIDevice.current.model)
        } header: {
            Label(DMateResourceStrings.Developer.appInfo, systemImage: "info.circle")
        }
    }
    
    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .font(.system(.body, design: .monospaced))
        }
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Actions
    
    private func resetAllData() {
        // SwiftData 모델 삭제
        patients.forEach { modelContext.delete($0) }
        medications.forEach { modelContext.delete($0) }
        logs.forEach { modelContext.delete($0) }
        appointments.forEach { modelContext.delete($0) }
        healthMetrics.forEach { modelContext.delete($0) }
        
        try? modelContext.save()
        print("🔧 [DEBUG] 모든 데이터 삭제됨")
    }
    
    private func resetUserDefaults() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        print("🔧 [DEBUG] UserDefaults 초기화됨")
    }
    
    private func addSampleData() {
        // 샘플 환자 추가
        let samplePatient = Patient(
            name: "김영수",
            relationship: .parent,
            birthDate: Calendar.current.date(byAdding: .year, value: -75, to: Date()),
            profileColor: .blue,
            notes: "고혈압, 당뇨 관리 중"
        )
        modelContext.insert(samplePatient)
        
        // 샘플 약물 추가 (본인용)
        let sampleMedications = [
            Medication(name: "아스피린", dosage: "1정", strength: "100mg"),
            Medication(name: "메트포르민", dosage: "1정", strength: "500mg"),
            Medication(name: "비타민D", dosage: "1정", strength: "1000IU")
        ]
        
        sampleMedications.forEach { modelContext.insert($0) }
        
        // 샘플 환자용 약물 추가
        let patientMedication = Medication(name: "아토르바스타틴", dosage: "1정", strength: "20mg")
        patientMedication.patient = samplePatient
        modelContext.insert(patientMedication)
        
        // 샘플 진료 예약 추가
        let sampleAppointment = Appointment(
            doctorName: "김의사",
            specialty: "내과",
            appointmentDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        )
        modelContext.insert(sampleAppointment)
        
        try? modelContext.save()
        print("🔧 [DEBUG] 샘플 데이터 추가됨")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DeveloperSettingsView()
    }
    .modelContainer(for: [
        Medication.self,
        MedicationSchedule.self,
        MedicationLog.self,
        Appointment.self,
//        HealthMetric.self,
        Patient.self
    ], inMemory: true)
}

#endif
