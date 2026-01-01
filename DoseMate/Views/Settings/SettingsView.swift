//
//  SettingsView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import DMateDesignSystem
import DMateResource
import SwiftData
import UniformTypeIdentifiers

/// 설정 화면
struct SettingsView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()

    // 후원 시트 표시 상태
    @State private var showSupportSheet = false
    
    // 데이터 내보내기/가져오기
    @State private var showImportFilePicker = false
    @State private var showExportShareSheet = false
    @State private var exportFileURL: URL?
    @State private var showImportConfirmation = false
    @State private var importValidation: ImportValidationResult?
    @State private var pendingImportURL: URL?
    @State private var showImportResult = false
    @State private var importResult: ImportResult?

    // 약관 및 개인정보 처리방침
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                supportSection
                notificationSection
//                healthKitSection
                appearanceSection
                dataSection
                backupSection
                aboutSection

                #if DEBUG
                developerSection
                #endif
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(DMateResourceStrings.Settings.title)
            .toolbarBackground(.clear, for: .navigationBar)
            .onAppear {
                viewModel.setup(with: modelContext)
            }
            .alert(DMateResourceStrings.Settings.deleteAllDataAlertTitle, isPresented: $viewModel.showDeleteAllConfirmation) {
                Button(DMateResourceStrings.Common.cancel, role: .cancel) {}
                Button(DMateResourceStrings.Common.delete, role: .destructive) {
                    Task {
                        await viewModel.deleteAllData()
                    }
                }
            } message: {
                Text(DMateResourceStrings.Settings.deleteAllMessage)
            }
            .alert(DMateResourceStrings.Settings.rescheduleNotificationsAlertTitle, isPresented: $viewModel.showRescheduleConfirmation) {
                Button(DMateResourceStrings.Common.cancel, role: .cancel) {}
                Button(DMateResourceStrings.Settings.rescheduleButton) {
                    Task {
                        await viewModel.rescheduleAllNotifications()
                    }
                }
            } message: {
                Text(DMateResourceStrings.Settings.rescheduleMessage)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppColors.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .sheet(isPresented: $showSupportSheet) {
                SupportDeveloperView()
            }
            .sheet(isPresented: $showTermsSheet) {
                DocumentViewer(
                    title: DMateResourceStrings.Onboarding.termsOfService,
                    fileName: termsFileName
                )
            }
            .sheet(isPresented: $showPrivacySheet) {
                DocumentViewer(
                    title: DMateResourceStrings.Onboarding.privacyPolicy,
                    fileName: privacyFileName
                )
            }
        }
        .tint(AppColors.primary)
        .fileImporter(
            isPresented: $showImportFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportFileSelection(result)
        }
        .sheet(isPresented: $showExportShareSheet) {
            if let url = exportFileURL {
                ShareSheet(items: [url])
            }
        }
        .alert(DMateResourceStrings.Settings.importDataAlertTitle, isPresented: $showImportConfirmation) {
            Button(DMateResourceStrings.Common.cancel, role: .cancel) {
                pendingImportURL = nil
                importValidation = nil
            }
            Button(DMateResourceStrings.Settings.importButton, role: .destructive) {
                Task {
                    await performImport()
                }
            }
        } message: {
            if let validation = importValidation {
                Text(DMateResourceStrings.Alert.importDataMessage(
                    validation.exportDate.formatted(date: .abbreviated, time: .shortened),
                    validation.appVersion,
                    validation.deviceName,
                    validation.totalCount,
                    validation.patientCount,
                    validation.medicationCount,
                    validation.logCount
                ))
            }
        }
        .alert(DMateResourceStrings.Settings.importCompleteAlertTitle, isPresented: $showImportResult) {
            Button(DMateResourceStrings.Common.confirm) {
                importResult = nil
            }
        } message: {
            if let result = importResult {
                Text(DMateResourceStrings.Alert.importCompleteMessage(result.summary, result.totalCount))
            }
        }
        .alert(DMateResourceStrings.Settings.restartRequiredAlertTitle, isPresented: $viewModel.showRestartAlert) {
            Button(DMateResourceStrings.Settings.laterButton) { }
            Button(DMateResourceStrings.Settings.quitNowButton) {
                exit(0)
            }
        } message: {
            Text(DMateResourceStrings.Alert.restartRequiredMessage)
        }
        .alert(DMateResourceStrings.Alert.icloudWarningTitle, isPresented: $viewModel.showImportWithICloudWarning) {
            Button(DMateResourceStrings.Common.cancel, role: .cancel) { }
            Button(DMateResourceStrings.Settings.continueButton) {
                showImportFilePicker = true
            }
        } message: {
            Text(DMateResourceStrings.Alert.icloudWarningMessage)
        }
    }
    
    // MARK: - Computed Properties

    private var termsFileName: String {
        Locale.current.language.languageCode?.identifier == "ko" ? "TERMS_OF_SERVICE_ko" : "TERMS_OF_SERVICE_en"
    }

    private var privacyFileName: String {
        Locale.current.language.languageCode?.identifier == "ko" ? "PRIVACY_POLICY_ko" : "PRIVACY_POLICY_en"
    }

    // MARK: - Export/Import Methods

    /// 데이터 내보내기
    private func exportData() async {
        viewModel.isExporting = true
        defer { viewModel.isExporting = false }
        
        do {
            let data = try await DataExportManager.shared.exportAllData(context: modelContext)
            let fileURL = try DataExportManager.shared.createExportFile(data: data)
            exportFileURL = fileURL
            showExportShareSheet = true
        } catch {
            viewModel.errorMessage = DMateResourceStrings.Settings.errorExportFailed(error.localizedDescription)
        }
    }
    
    /// 파일 선택 처리
    private func handleImportFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            guard url.startAccessingSecurityScopedResource() else {
                viewModel.errorMessage = DMateResourceStrings.Settings.errorFileAccessDenied
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                // 파일을 임시 디렉토리로 복사
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                try FileManager.default.copyItem(at: url, to: tempURL)
                
                // 유효성 검사
                let validation = try DataExportManager.shared.validateImportFile(at: tempURL)
                importValidation = validation
                pendingImportURL = tempURL
                showImportConfirmation = true
            } catch {
                viewModel.errorMessage = DMateResourceStrings.Settings.errorFileReadFailed(error.localizedDescription)
            }
            
        case .failure(let error):
            viewModel.errorMessage = DMateResourceStrings.Settings.errorFileSelectionFailed(error.localizedDescription)
        }
    }
    
    /// 가져오기 실행
    private func performImport() async {
        guard let url = pendingImportURL else { return }
        
        viewModel.isImporting = true
        defer {
            viewModel.isImporting = false
            pendingImportURL = nil
            importValidation = nil
        }
        
        do {
            let result = try await DataExportManager.shared.importData(
                from: url,
                context: modelContext,
                mergeStrategy: .replace
            )
            importResult = result
            showImportResult = true
            
            // 임시 파일 삭제
            try? FileManager.default.removeItem(at: url)
        } catch {
            viewModel.errorMessage = DMateResourceStrings.Settings.errorImportFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Support Section

    private var supportSection: some View {
        Section {
            Button {
                showSupportSheet = true
            } label: {
                HStack {
                    // 아이콘
                    Image(systemName: "heart.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.premiumPink, AppColors.danger],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(DMateResourceStrings.Settings.developerSupport)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text(DMateResourceStrings.Settings.cryptoSupportSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listRowBackground(
                LinearGradient(
                    colors: [AppColors.premiumPink.opacity(0.1), AppColors.danger.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        } header: {
            Text(DMateResourceStrings.Settings.supportSection)
        } footer: {
            Text(DMateResourceStrings.Settings.freeAppFooter)
        }
    }
    
    // MARK: - Notification Section
    
    private var notificationSection: some View {
        Section {
            // 알림 권한 상태
            HStack {
                Label(DMateResourceStrings.Settings.notificationPermission, systemImage: "bell.badge")
                Spacer()
                Text(viewModel.notificationStatusText)
                    .foregroundColor(.secondary)

                if viewModel.notificationAuthorizationStatus == .denied {
                    Button(DMateResourceStrings.Settings.openSettings) {
                        viewModel.openSettings()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Toggle(isOn: $viewModel.notificationEnabled) {
                Label(DMateResourceStrings.Settings.enableNotifications, systemImage: "bell")
            }

            if viewModel.notificationEnabled {
                Toggle(isOn: $viewModel.soundEnabled) {
                    Label(DMateResourceStrings.Settings.sound, systemImage: "speaker.wave.2")
                }

                Toggle(isOn: $viewModel.hapticEnabled) {
                    Label(DMateResourceStrings.Settings.haptic, systemImage: "iphone.radiowaves.left.and.right")
                }

                Picker(selection: $viewModel.defaultSnoozeInterval) {
                    ForEach(viewModel.snoozeOptions, id: \.self) { minutes in
                        Text("\(minutes)분").tag(minutes)
                    }
                } label: {
                    Label(DMateResourceStrings.Settings.defaultSnooze, systemImage: "clock.arrow.circlepath")
                }

                Picker(selection: $viewModel.reminderMinutesBefore) {
                    ForEach([0, 5, 10, 15, 30, 60], id: \.self) { (minutes: Int) in
                        if minutes == 0 {
                            Text(DMateResourceStrings.Settings.onTheHour).tag(minutes)
                        } else {
                            Text(DMateResourceStrings.Schedule.beforeMinutes(minutes)).tag(minutes)
                        }
                    }
                } label: {
                    Label(DMateResourceStrings.Settings.reminderBefore, systemImage: "clock")
                }
            }

            Button {
                viewModel.showRescheduleConfirmation = true
            } label: {
                Label(DMateResourceStrings.Settings.rescheduleNotifications, systemImage: "arrow.triangle.2.circlepath")
            }
        } header: {
            Text(DMateResourceStrings.Settings.notifications)
        }
    }
    
    // MARK: - HealthKit Section
    
    private var healthKitSection: some View {
        Section {
            HStack {
                Label(DMateResourceStrings.Settings.healthkitIntegration, systemImage: "heart.fill")
                    .foregroundColor(AppColors.danger)
                Spacer()
                Text(viewModel.healthKitStatusText)
                    .foregroundColor(.secondary)
            }

            if !HealthKitManager.shared.isAvailable {
                Text(DMateResourceStrings.Settings.healthkitUnavailable)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if !viewModel.healthKitAuthorized {
                Button {
                    Task {
                        await viewModel.requestHealthKitPermission()
                    }
                } label: {
                    Label(DMateResourceStrings.Settings.requestPermission, systemImage: "hand.raised")
                }
            } else {
                Toggle(isOn: $viewModel.healthKitEnabled) {
                    Label(DMateResourceStrings.Settings.autoSync, systemImage: "arrow.triangle.2.circlepath")
                }

                // 마지막 동기화
                HStack {
                    Text(DMateResourceStrings.Settings.lastSyncLabel)
                    Spacer()
                    Text(viewModel.lastSyncText)
                        .foregroundColor(.secondary)
                }

                Button {
                    Task {
                        await viewModel.syncHealthKit()
                    }
                } label: {
                    HStack {
                        Label(DMateResourceStrings.Settings.syncNow, systemImage: "arrow.clockwise")
                        Spacer()
                        if viewModel.isSyncing {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isSyncing)
            }
        } header: {
            Text(DMateResourceStrings.Settings.healthkit)
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        Section {
            Picker(selection: $viewModel.appearanceMode) {
                ForEach([ColorTheme.system, .light, .dark], id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            } label: {
                Label(DMateResourceStrings.Settings.appearanceMode, systemImage: "paintbrush")
            }
        } header: {
            Text(DMateResourceStrings.Settings.appearance)
        }
    }
    
    // MARK: - Data Section
    
    private var dataSection: some View {
        Section {
            // 환자 관리 (피보호자)
            NavigationLink {
                PatientView()
            } label: {
                HStack {
                    Label(DMateResourceStrings.Settings.patientManagement, systemImage: "person.2.fill")
                    Spacer()
                    Text(DMateResourceStrings.Settings.familyMedication)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 진료 예약 관리
            NavigationLink {
                AppointmentListView()
            } label: {
                Label(DMateResourceStrings.Settings.appointments, systemImage: "calendar.badge.clock")
            }

            // 샘플 데이터
            #if DEBUG
            Button {
                Task {
                    await viewModel.createSampleData()
                }
            } label: {
                Label(DMateResourceStrings.Settings.createSampleData, systemImage: "wand.and.stars")
            }
            #endif

            // 데이터 삭제
            Button(role: .destructive) {
                viewModel.showDeleteAllConfirmation = true
            } label: {
                Label(DMateResourceStrings.Settings.deleteAll, systemImage: "trash")
            }
        } header: {
            Text(DMateResourceStrings.Settings.data)
        }
    }
    
    // MARK: - Cloud & Backup Section
    
    private var backupSection: some View {
        Section {
            Toggle(isOn: $viewModel.iCloudSyncEnabled) {
                HStack {
                    Label(DMateResourceStrings.Settings.icloudSync, systemImage: "icloud.fill")
                        .foregroundColor(AppColors.primary)
                }
            }
            .onChange(of: viewModel.iCloudSyncEnabled) { _, newValue in
                viewModel.showRestartAlert = true
            }

            HStack {
                Text(DMateResourceStrings.Settings.syncStatusLabel)
                    .foregroundColor(.secondary)
                Spacer()
                if viewModel.isICloudAvailable {
                    if viewModel.iCloudSyncEnabled && DoseMateApp.isCloudSyncEnabled {
                        Label(DMateResourceStrings.Settings.syncActive, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(AppColors.success)
                    } else if viewModel.iCloudSyncEnabled && !DoseMateApp.isCloudSyncEnabled {
                        Label(DMateResourceStrings.Settings.syncRestartRequired, systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(AppColors.warning)
                    } else {
                        Text(DMateResourceStrings.Settings.syncDisabled)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Label(DMateResourceStrings.Settings.icloudUnavailable, systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(AppColors.danger)
                }
            }

            Divider()

            Button {
                Task {
                    await exportData()
                }
            } label: {
                HStack {
                    Label(DMateResourceStrings.Settings.exportData, systemImage: "square.and.arrow.up")
                    Spacer()
                    if viewModel.isExporting {
                        ProgressView()
                    } else {
                        Text("JSON")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .disabled(viewModel.isExporting)

            Button {
                // iCloud 동기화 중이면 경고
                if viewModel.iCloudSyncEnabled && DoseMateApp.isCloudSyncEnabled {
                    viewModel.showImportWithICloudWarning = true
                } else {
                    showImportFilePicker = true
                }
            } label: {
                HStack {
                    Label(DMateResourceStrings.Settings.importData, systemImage: "square.and.arrow.down")
                    Spacer()
                    if viewModel.isImporting {
                        ProgressView()
                    }
                }
            }
            .disabled(viewModel.isImporting)
        } header: {
            Text(DMateResourceStrings.Settings.cloudBackup)
        } footer: {
            if viewModel.iCloudSyncEnabled {
                Text(DMateResourceStrings.Settings.icloudSyncImportWarning)
            } else {
                Text(DMateResourceStrings.Settings.exportDescription)
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text(DMateResourceStrings.Settings.versionLabel)
                Spacer()
                Text(viewModel.appVersion)
                    .foregroundColor(.secondary)
            }

            Button {
                showPrivacySheet = true
            } label: {
                Label(DMateResourceStrings.Settings.privacyPolicy, systemImage: "hand.raised")
            }

            Button {
                showTermsSheet = true
            } label: {
                Label(DMateResourceStrings.Settings.termsOfService, systemImage: "doc.text")
            }
        } header: {
            Text(DMateResourceStrings.Settings.infoSection)
        }
    }
    
    // MARK: - Developer Section (DEBUG only)
    
    #if DEBUG
    private var developerSection: some View {
        Section {
            NavigationLink {
                DeveloperSettingsView()
            } label: {
                Label(DMateResourceStrings.Settings.moreDeveloperOptions, systemImage: "hammer.fill")
            }
        } header: {
            Label(DMateResourceStrings.Settings.developerSettings, systemImage: "wrench.and.screwdriver.fill")
        } footer: {
            Text(DMateResourceStrings.Settings.debugFooter)
        }
    }
    #endif
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: [
            Medication.self,
            MedicationSchedule.self,
            MedicationLog.self,
//            HealthMetric.self,
            Appointment.self
        ], inMemory: true)
}
