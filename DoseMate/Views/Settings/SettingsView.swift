//
//  SettingsView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
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
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                supportSection
                notificationSection
                healthKitSection
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
            .navigationTitle(DoseMateStrings.Settings.title)
            .toolbarBackground(.clear, for: .navigationBar)
            .onAppear {
                viewModel.setup(with: modelContext)
            }
            .alert(DoseMateStrings.Settings.deleteAllDataAlertTitle, isPresented: $viewModel.showDeleteAllConfirmation) {
                Button(DoseMateStrings.Common.cancel, role: .cancel) {}
                Button(DoseMateStrings.Common.delete, role: .destructive) {
                    Task {
                        await viewModel.deleteAllData()
                    }
                }
            } message: {
                Text(DoseMateStrings.Settings.deleteAllMessage)
            }
            .alert(DoseMateStrings.Settings.rescheduleNotificationsAlertTitle, isPresented: $viewModel.showRescheduleConfirmation) {
                Button(DoseMateStrings.Common.cancel, role: .cancel) {}
                Button(DoseMateStrings.Settings.rescheduleButton) {
                    Task {
                        await viewModel.rescheduleAllNotifications()
                    }
                }
            } message: {
                Text(DoseMateStrings.Settings.rescheduleMessage)
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
        .alert(DoseMateStrings.Settings.importDataAlertTitle, isPresented: $showImportConfirmation) {
            Button(DoseMateStrings.Common.cancel, role: .cancel) {
                pendingImportURL = nil
                importValidation = nil
            }
            Button(DoseMateStrings.Settings.importButton, role: .destructive) {
                Task {
                    await performImport()
                }
            }
        } message: {
            if let validation = importValidation {
                Text(DoseMateStrings.Alert.importDataMessage(
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
        .alert(DoseMateStrings.Settings.importCompleteAlertTitle, isPresented: $showImportResult) {
            Button(DoseMateStrings.Common.confirm) {
                importResult = nil
            }
        } message: {
            if let result = importResult {
                Text(DoseMateStrings.Alert.importCompleteMessage(result.summary, result.totalCount))
            }
        }
        .alert(DoseMateStrings.Settings.restartRequiredAlertTitle, isPresented: $viewModel.showRestartAlert) {
            Button(DoseMateStrings.Settings.laterButton) { }
            Button(DoseMateStrings.Settings.quitNowButton) {
                exit(0)
            }
        } message: {
            Text(DoseMateStrings.Alert.restartRequiredMessage)
        }
        .alert(DoseMateStrings.Alert.icloudWarningTitle, isPresented: $viewModel.showImportWithICloudWarning) {
            Button(DoseMateStrings.Common.cancel, role: .cancel) { }
            Button(DoseMateStrings.Settings.continueButton) {
                showImportFilePicker = true
            }
        } message: {
            Text(DoseMateStrings.Alert.icloudWarningMessage)
        }
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
            viewModel.errorMessage = DoseMateStrings.Settings.errorExportFailed(error.localizedDescription)
        }
    }
    
    /// 파일 선택 처리
    private func handleImportFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            guard url.startAccessingSecurityScopedResource() else {
                viewModel.errorMessage = DoseMateStrings.Settings.errorFileAccessDenied
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
                viewModel.errorMessage = DoseMateStrings.Settings.errorFileReadFailed(error.localizedDescription)
            }
            
        case .failure(let error):
            viewModel.errorMessage = DoseMateStrings.Settings.errorFileSelectionFailed(error.localizedDescription)
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
            viewModel.errorMessage = DoseMateStrings.Settings.errorImportFailed(error.localizedDescription)
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
                        Text(DoseMateStrings.Settings.developerSupport)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("암호화폐 및 일반 후원")
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
            Text(DoseMateStrings.Settings.supportSection)
        } footer: {
            Text("DoseMate는 완전 무료 앱입니다. 자발적 후원은 앱 개발에 큰 도움이 됩니다.")
        }
    }
    
    // MARK: - Notification Section
    
    private var notificationSection: some View {
        Section {
            // 알림 권한 상태
            HStack {
                Label(DoseMateStrings.Settings.notificationPermission, systemImage: "bell.badge")
                Spacer()
                Text(viewModel.notificationStatusText)
                    .foregroundColor(.secondary)

                if viewModel.notificationAuthorizationStatus == .denied {
                    Button(DoseMateStrings.Settings.openSettings) {
                        viewModel.openSettings()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Toggle(isOn: $viewModel.notificationEnabled) {
                Label(DoseMateStrings.Settings.enableNotifications, systemImage: "bell")
            }

            if viewModel.notificationEnabled {
                Toggle(isOn: $viewModel.soundEnabled) {
                    Label(DoseMateStrings.Settings.sound, systemImage: "speaker.wave.2")
                }

                Toggle(isOn: $viewModel.hapticEnabled) {
                    Label(DoseMateStrings.Settings.haptic, systemImage: "iphone.radiowaves.left.and.right")
                }

                Picker(selection: $viewModel.defaultSnoozeInterval) {
                    ForEach(viewModel.snoozeOptions, id: \.self) { minutes in
                        Text("\(minutes)분").tag(minutes)
                    }
                } label: {
                    Label(DoseMateStrings.Settings.defaultSnooze, systemImage: "clock.arrow.circlepath")
                }

                Picker(selection: $viewModel.reminderMinutesBefore) {
                    ForEach(viewModel.reminderBeforeOptions, id: \.self) { minutes in
                        if minutes == 0 {
                            Text(DoseMateStrings.Settings.onTheHour).tag(minutes)
                        } else {
                            Text("\(minutes)분 전").tag(minutes)
                        }
                    }
                } label: {
                    Label(DoseMateStrings.Settings.reminderBefore, systemImage: "clock")
                }
            }

            Button {
                viewModel.showRescheduleConfirmation = true
            } label: {
                Label(DoseMateStrings.Settings.rescheduleNotifications, systemImage: "arrow.triangle.2.circlepath")
            }
        } header: {
            Text(DoseMateStrings.Settings.notifications)
        }
    }
    
    // MARK: - HealthKit Section
    
    private var healthKitSection: some View {
        Section {
            HStack {
                Label(DoseMateStrings.Settings.healthkitIntegration, systemImage: "heart.fill")
                    .foregroundColor(AppColors.danger)
                Spacer()
                Text(viewModel.healthKitStatusText)
                    .foregroundColor(.secondary)
            }

            if !HealthKitManager.shared.isAvailable {
                Text(DoseMateStrings.Settings.healthkitUnavailable)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if !viewModel.healthKitAuthorized {
                Button {
                    Task {
                        await viewModel.requestHealthKitPermission()
                    }
                } label: {
                    Label(DoseMateStrings.Settings.requestPermission, systemImage: "hand.raised")
                }
            } else {
                Toggle(isOn: $viewModel.healthKitEnabled) {
                    Label(DoseMateStrings.Settings.autoSync, systemImage: "arrow.triangle.2.circlepath")
                }

                // 마지막 동기화
                HStack {
                    Text(DoseMateStrings.Settings.lastSyncLabel)
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
                        Label(DoseMateStrings.Settings.syncNow, systemImage: "arrow.clockwise")
                        Spacer()
                        if viewModel.isSyncing {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isSyncing)
            }
        } header: {
            Text(DoseMateStrings.Settings.healthkit)
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
                Label(DoseMateStrings.Settings.appearanceMode, systemImage: "paintbrush")
            }
        } header: {
            Text(DoseMateStrings.Settings.appearance)
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
                    Label(DoseMateStrings.Settings.patientManagement, systemImage: "person.2.fill")
                    Spacer()
                    Text(DoseMateStrings.Settings.familyMedication)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 진료 예약 관리
            NavigationLink {
                AppointmentListView()
            } label: {
                Label(DoseMateStrings.Settings.appointments, systemImage: "calendar.badge.clock")
            }

            // 샘플 데이터
            #if DEBUG
            Button {
                Task {
                    await viewModel.createSampleData()
                }
            } label: {
                Label(DoseMateStrings.Settings.createSampleData, systemImage: "wand.and.stars")
            }
            #endif

            // 데이터 삭제
            Button(role: .destructive) {
                viewModel.showDeleteAllConfirmation = true
            } label: {
                Label(DoseMateStrings.Settings.deleteAll, systemImage: "trash")
            }
        } header: {
            Text(DoseMateStrings.Settings.data)
        }
    }
    
    // MARK: - Cloud & Backup Section
    
    private var backupSection: some View {
        Section {
            Toggle(isOn: $viewModel.iCloudSyncEnabled) {
                HStack {
                    Label(DoseMateStrings.Settings.icloudSync, systemImage: "icloud.fill")
                        .foregroundColor(AppColors.primary)
                }
            }
            .onChange(of: viewModel.iCloudSyncEnabled) { _, newValue in
                viewModel.showRestartAlert = true
            }

            HStack {
                Text(DoseMateStrings.Settings.syncStatusLabel)
                    .foregroundColor(.secondary)
                Spacer()
                if viewModel.isICloudAvailable {
                    if viewModel.iCloudSyncEnabled && DoseMateApp.isCloudSyncEnabled {
                        Label(DoseMateStrings.Settings.syncActive, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(AppColors.success)
                    } else if viewModel.iCloudSyncEnabled && !DoseMateApp.isCloudSyncEnabled {
                        Label(DoseMateStrings.Settings.syncRestartRequired, systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(AppColors.warning)
                    } else {
                        Text(DoseMateStrings.Settings.syncDisabled)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Label(DoseMateStrings.Settings.icloudUnavailable, systemImage: "xmark.circle.fill")
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
                    Label(DoseMateStrings.Settings.exportData, systemImage: "square.and.arrow.up")
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
                    Label(DoseMateStrings.Settings.importData, systemImage: "square.and.arrow.down")
                    Spacer()
                    if viewModel.isImporting {
                        ProgressView()
                    }
                }
            }
            .disabled(viewModel.isImporting)
        } header: {
            Text(DoseMateStrings.Settings.cloudBackup)
        } footer: {
            if viewModel.iCloudSyncEnabled {
                Text(DoseMateStrings.Settings.icloudSyncImportWarning)
            } else {
                Text(DoseMateStrings.Settings.exportDescription)
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text(DoseMateStrings.Settings.versionLabel)
                Spacer()
                Text(viewModel.appVersion)
                    .foregroundColor(.secondary)
            }

            Link(destination: URL(string: "https://www.apple.com/legal/privacy")!) {
                Label(DoseMateStrings.Settings.privacyPolicy, systemImage: "hand.raised")
            }

            Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                Label(DoseMateStrings.Settings.termsOfService, systemImage: "doc.text")
            }
        } header: {
            Text(DoseMateStrings.Settings.infoSection)
        }
    }
    
    // MARK: - Developer Section (DEBUG only)
    
    #if DEBUG
    private var developerSection: some View {
        Section {
            NavigationLink {
                DeveloperSettingsView()
            } label: {
                Label(DoseMateStrings.Settings.moreDeveloperOptions, systemImage: "hammer.fill")
            }
        } header: {
            Label(DoseMateStrings.Settings.developerSettings, systemImage: "wrench.and.screwdriver.fill")
        } footer: {
            Text(DoseMateStrings.Settings.debugFooter)
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
            HealthMetric.self,
            Appointment.self
        ], inMemory: true)
}
