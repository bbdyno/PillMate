//
//  DeveloperSettingsView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import SwiftData

#if DEBUG

/// 개발자 설정 화면
/// ⚠️ DEBUG 빌드에서만 사용 가능
struct DeveloperSettingsView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @State private var storeManager = StoreKitManager.shared
    
    @Query private var medications: [Medication]
    @Query private var logs: [MedicationLog]
    @Query private var appointments: [Appointment]
    @Query private var caregivers: [Caregiver]
    @Query private var healthMetrics: [HealthMetric]
    @Query private var patients: [Patient]
    
    @State private var showResetAlert = false
    @State private var showSampleDataAlert = false
    
    // MARK: - Body
    
    var body: some View {
        List {
            // 프리미엄 설정
            premiumSection
            
            // 데이터 현황
            dataStatusSection
            
            // 테스트 도구
            testToolsSection
            
            // 앱 정보
            appInfoSection
        }
        .navigationTitle("개발자 설정")
        .navigationBarTitleDisplayMode(.inline)
        .alert("모든 데이터 삭제", isPresented: $showResetAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("모든 데이터가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
        }
        .alert("샘플 데이터 추가", isPresented: $showSampleDataAlert) {
            Button("취소", role: .cancel) {}
            Button("추가") {
                addSampleData()
            }
        } message: {
            Text("테스트용 샘플 데이터를 추가하시겠습니까?")
        }
    }
    
    // MARK: - Premium Section
    
    private var premiumSection: some View {
        Section {
            // 프리미엄 토글
            Toggle(isOn: Binding(
                get: { storeManager.isPremium },
                set: { storeManager.debugSetPremium($0) }
            )) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(storeManager.isPremium ? .yellow : .gray)
                    Text("프리미엄 활성화")
                }
            }
            
            // 빠른 토글 버튼들
            HStack {
                Button {
                    storeManager.debugSetPremium(true)
                } label: {
                    Text("ON")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(storeManager.isPremium ? Color.green : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button {
                    storeManager.debugSetPremium(false)
                } label: {
                    Text("OFF")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(!storeManager.isPremium ? Color.red : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            // 기부 횟수
            HStack {
                Text("기부 횟수")
                Spacer()
                Text("\(storeManager.totalTipCount)")
                    .foregroundColor(.secondary)
                Button("리셋") {
                    storeManager.debugResetTipCount()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        } header: {
            Label("프리미엄 설정", systemImage: "crown")
        } footer: {
            Text("실제 결제 없이 프리미엄 상태를 테스트할 수 있습니다.")
        }
    }
    
    // MARK: - Data Status Section
    
    private var dataStatusSection: some View {
        Section {
            dataRow("환자", count: patients.count, icon: "person.crop.circle.fill", color: .teal)
            dataRow("약물", count: medications.count, icon: "pills.fill", color: .blue)
            dataRow("복약 기록", count: logs.count, icon: "list.clipboard.fill", color: .green)
            dataRow("진료 예약", count: appointments.count, icon: "calendar", color: .orange)
            dataRow("보호자", count: caregivers.count, icon: "person.2.fill", color: .purple)
            dataRow("건강 지표", count: healthMetrics.count, icon: "heart.fill", color: .red)
            
            // 총 데이터
            HStack {
                Text("총 데이터")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(totalDataCount)개")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        } header: {
            Label("데이터 현황", systemImage: "chart.bar.fill")
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
        patients.count + medications.count + logs.count + appointments.count + caregivers.count + healthMetrics.count
    }
    
    // MARK: - Test Tools Section
    
    private var testToolsSection: some View {
        Section {
            // 샘플 데이터 추가
            Button {
                showSampleDataAlert = true
            } label: {
                Label("샘플 데이터 추가", systemImage: "plus.rectangle.on.rectangle")
            }
            
            // 모든 데이터 삭제
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Label("모든 데이터 삭제", systemImage: "trash.fill")
            }
            
            // UserDefaults 초기화
            Button(role: .destructive) {
                resetUserDefaults()
            } label: {
                Label("UserDefaults 초기화", systemImage: "arrow.counterclockwise")
            }
        } header: {
            Label("테스트 도구", systemImage: "hammer.fill")
        } footer: {
            Text("테스트 및 디버깅을 위한 도구입니다.")
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        Section {
            infoRow("빌드 타입", value: "DEBUG")
            infoRow("Bundle ID", value: Bundle.main.bundleIdentifier ?? "-")
            infoRow("버전", value: appVersion)
            infoRow("빌드", value: buildNumber)
            infoRow("iOS", value: UIDevice.current.systemVersion)
            infoRow("기기", value: UIDevice.current.model)
        } header: {
            Label("앱 정보", systemImage: "info.circle")
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
        caregivers.forEach { modelContext.delete($0) }
        healthMetrics.forEach { modelContext.delete($0) }
        
        try? modelContext.save()
        print("🔧 [DEBUG] 모든 데이터 삭제됨")
    }
    
    private func resetUserDefaults() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        // 프리미엄 상태도 리셋
        storeManager.debugSetPremium(false)
        
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
        Caregiver.self,
        HealthMetric.self,
        Patient.self
    ], inMemory: true)
}

#endif
