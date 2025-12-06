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
    @State private var storeManager = StoreKitManager.shared
    
    // 💡 프리미엄/기부 시트 표시 상태
    @State private var showPremiumSheet = false
    @State private var showTipJarSheet = false
    
    // 📦 데이터 내보내기/가져오기
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
                // 💎 프리미엄 섹션 (최상단)
                premiumSection
                
                // 알림 설정
                notificationSection
                
                // HealthKit 설정
                healthKitSection
                
                // 외관 설정
                appearanceSection
                
                // 데이터 관리
                dataSection
                
                // 📦 백업 (프리미엄)
                backupSection
                
                // 💕 개발자 응원 (기부)
                supportSection
                
                // 앱 정보
                aboutSection
                
                // 🔧 개발자 설정 (DEBUG 빌드에서만)
                #if DEBUG
                developerSection
                #endif
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(AppColors.primaryGradient)
                        Text("설정")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .onAppear {
                viewModel.setup(with: modelContext)
            }
            .alert("데이터 삭제", isPresented: $viewModel.showDeleteAllConfirmation) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    Task {
                        await viewModel.deleteAllData()
                    }
                }
            } message: {
                Text("모든 약물, 복약 기록, 건강 지표가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
            }
            .alert("알림 재설정", isPresented: $viewModel.showRescheduleConfirmation) {
                Button("취소", role: .cancel) {}
                Button("재설정") {
                    Task {
                        await viewModel.rescheduleAllNotifications()
                    }
                }
            } message: {
                Text("모든 복약 알림을 재설정하시겠습니까?")
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppColors.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            // 💎 프리미엄 시트
            .sheet(isPresented: $showPremiumSheet) {
                PremiumView()
            }
            // 💕 기부 시트
            .sheet(isPresented: $showTipJarSheet) {
                TipJarView()
            }
        }
        .tint(AppColors.primary)
        // 📦 파일 가져오기 (Document Picker)
        .fileImporter(
            isPresented: $showImportFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportFileSelection(result)
        }
        // 📦 내보내기 공유 시트
        .sheet(isPresented: $showExportShareSheet) {
            if let url = exportFileURL {
                ShareSheet(items: [url])
            }
        }
        // 📦 가져오기 확인 Alert
        .alert("데이터 가져오기", isPresented: $showImportConfirmation) {
            Button("취소", role: .cancel) {
                pendingImportURL = nil
                importValidation = nil
            }
            Button("가져오기", role: .destructive) {
                Task {
                    await performImport()
                }
            }
        } message: {
            if let validation = importValidation {
                Text("""
                다음 데이터를 가져옵니다:
                
                내보낸 날짜: \(validation.exportDate.formatted(date: .abbreviated, time: .shortened))
                앱 버전: \(validation.appVersion)
                기기: \(validation.deviceName)
                
                총 \(validation.totalCount)개 항목
                (환자 \(validation.patientCount), 약물 \(validation.medicationCount), 기록 \(validation.logCount)개 등)
                
                ⚠️ 기존 데이터가 모두 삭제됩니다.
                """)
            }
        }
        // 📦 가져오기 결과 Alert
        .alert("가져오기 완료", isPresented: $showImportResult) {
            Button("확인") {
                importResult = nil
            }
        } message: {
            if let result = importResult {
                Text("""
                데이터를 성공적으로 가져왔습니다.
                
                \(result.summary)
                
                총 \(result.totalCount)개 항목
                """)
            }
        }
        // ☁️ 앱 재시작 필요 Alert
        .alert("앱 재시작 필요", isPresented: $viewModel.showRestartAlert) {
            Button("나중에") { }
            Button("지금 종료") {
                exit(0)
            }
        } message: {
            Text("iCloud 동기화 설정을 변경하려면 앱을 완전히 종료한 후 다시 실행해야 합니다.\n\n앱을 종료하시겠습니까?")
        }
        // ☁️ iCloud 동기화 중 가져오기 경고
        .alert("iCloud 동기화 주의", isPresented: $viewModel.showImportWithICloudWarning) {
            Button("취소", role: .cancel) { }
            Button("계속") {
                showImportFilePicker = true
            }
        } message: {
            Text("iCloud 동기화가 활성화된 상태입니다.\n\n데이터를 가져오면 이 계정에 연결된 모든 기기의 데이터가 교체됩니다.\n\n계속하시겠습니까?")
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
            viewModel.errorMessage = "내보내기 실패: \(error.localizedDescription)"
        }
    }
    
    /// 파일 선택 처리
    private func handleImportFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Security scoped resource access
            guard url.startAccessingSecurityScopedResource() else {
                viewModel.errorMessage = "파일에 접근할 수 없습니다."
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
                viewModel.errorMessage = "파일을 읽을 수 없습니다: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            viewModel.errorMessage = "파일 선택 실패: \(error.localizedDescription)"
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
            viewModel.errorMessage = "가져오기 실패: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Premium Section
    // 💡 프리미엄 정책 변경 시 이 섹션 수정
    
    private var premiumSection: some View {
        Section {
            Button {
                showPremiumSheet = true
            } label: {
                HStack {
                    // 아이콘
                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(storeManager.isPremium ? "프리미엄" : "프리미엄으로 업그레이드")
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            if storeManager.isPremium {
                                Text("사용 중")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.15))
                                    .cornerRadius(4)
                            }
                        }
                        
                        if !storeManager.isPremium {
                            Text("모든 기능 잠금 해제 · \(storeManager.premiumPriceString)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listRowBackground(
                Group {
                    if storeManager.isPremium {
                        Color.green.opacity(0.1)
                    } else {
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
        } header: {
            if !storeManager.isPremium {
                Text("프리미엄")
            }
        }
    }
    
    // MARK: - Support Section
    // 💕 개발자 응원하기 섹션
    
    private var supportSection: some View {
        Section {
            // 기부하기
            Button {
                showTipJarSheet = true
            } label: {
                HStack {
                    Label("개발자 응원하기", systemImage: "heart.fill")
                        .foregroundColor(.pink)
                    
                    Spacer()
                    
                    if storeManager.totalTipCount > 0 {
                        Text("\(storeManager.totalTipCount)회 💕")
                            .font(.caption)
                            .foregroundColor(.pink)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 구매 복원
            Button {
                Task {
                    await storeManager.restorePurchases()
                }
            } label: {
                Label("구매 복원", systemImage: "arrow.clockwise")
            }
            .disabled(storeManager.isLoading)
        } header: {
            Text("지원")
        } footer: {
            Text("이미 구매하셨다면 복원을 눌러주세요.")
        }
    }
    
    // MARK: - Notification Section
    
    private var notificationSection: some View {
        Section {
            // 알림 권한 상태
            HStack {
                Label("알림 권한", systemImage: "bell.badge")
                Spacer()
                Text(viewModel.notificationStatusText)
                    .foregroundColor(.secondary)
                
                if viewModel.notificationAuthorizationStatus == .denied {
                    Button("설정") {
                        viewModel.openSettings()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            // 알림 토글
            Toggle(isOn: $viewModel.notificationEnabled) {
                Label("알림 받기", systemImage: "bell")
            }
            
            if viewModel.notificationEnabled {
                // 사운드
                Toggle(isOn: $viewModel.soundEnabled) {
                    Label("알림 소리", systemImage: "speaker.wave.2")
                }
                
                // 햅틱
                Toggle(isOn: $viewModel.hapticEnabled) {
                    Label("진동", systemImage: "iphone.radiowaves.left.and.right")
                }
                
                // 스누즈 간격
                Picker(selection: $viewModel.defaultSnoozeInterval) {
                    ForEach(viewModel.snoozeOptions, id: \.self) { minutes in
                        Text("\(minutes)분").tag(minutes)
                    }
                } label: {
                    Label("기본 스누즈 시간", systemImage: "clock.arrow.circlepath")
                }
                
                // 미리 알림
                Picker(selection: $viewModel.reminderMinutesBefore) {
                    ForEach(viewModel.reminderBeforeOptions, id: \.self) { minutes in
                        if minutes == 0 {
                            Text("정각에").tag(minutes)
                        } else {
                            Text("\(minutes)분 전").tag(minutes)
                        }
                    }
                } label: {
                    Label("미리 알림", systemImage: "clock")
                }
            }
            
            // 알림 재설정
            Button {
                viewModel.showRescheduleConfirmation = true
            } label: {
                Label("알림 재설정", systemImage: "arrow.triangle.2.circlepath")
            }
        } header: {
            Text("알림")
        }
    }
    
    // MARK: - HealthKit Section
    // 💎 프리미엄 전용 기능
    
    private var healthKitSection: some View {
        Section {
            // 💎 프리미엄 체크
            if !PremiumFeatures.canUseHealthKit {
                // 프리미엄 필요 안내
                HStack {
                    Label("건강 앱 연동", systemImage: "heart.fill")
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    PremiumBadge()
                }
                
                Button {
                    showPremiumSheet = true
                } label: {
                    Text("프리미엄으로 잠금 해제")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            } else {
                // HealthKit 상태 (프리미엄 사용자)
                HStack {
                    Label("건강 앱 연동", systemImage: "heart.fill")
                        .foregroundColor(.red)
                    Spacer()
                    Text(viewModel.healthKitStatusText)
                        .foregroundColor(.secondary)
                }
                
                if !HealthKitManager.shared.isAvailable {
                    Text("이 기기에서는 건강 앱을 사용할 수 없습니다.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if !viewModel.healthKitAuthorized {
                    Button {
                        Task {
                            await viewModel.requestHealthKitPermission()
                        }
                    } label: {
                        Label("건강 앱 권한 요청", systemImage: "hand.raised")
                    }
                } else {
                    Toggle(isOn: $viewModel.healthKitEnabled) {
                        Label("자동 동기화", systemImage: "arrow.triangle.2.circlepath")
                    }
                    
                    // 마지막 동기화
                    HStack {
                        Text("마지막 동기화")
                        Spacer()
                        Text(viewModel.lastSyncText)
                            .foregroundColor(.secondary)
                    }
                    
                    // 수동 동기화
                    Button {
                        Task {
                            await viewModel.syncHealthKit()
                        }
                    } label: {
                        HStack {
                            Label("지금 동기화", systemImage: "arrow.clockwise")
                            Spacer()
                            if viewModel.isSyncing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.isSyncing)
                }
            }
        } header: {
            HStack {
                Text("건강")
                if !PremiumFeatures.canUseHealthKit {
                    PremiumBadge()
                }
            }
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
                Label("외관 모드", systemImage: "paintbrush")
            }
        } header: {
            Text("외관")
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
                    Label("환자 관리", systemImage: "person.2.fill")
                    Spacer()
                    Text("가족 복약 관리")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 보호자 관리 (알림 연락처)
            NavigationLink {
                CaregiverListView()
            } label: {
                HStack {
                    Label("보호자 알림", systemImage: "bell.badge.fill")
                    Spacer()
                    Text("미복약 시 알림")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 진료 예약 관리
            NavigationLink {
                AppointmentListView()
            } label: {
                Label("진료 예약", systemImage: "calendar.badge.clock")
            }
            
            // 샘플 데이터
            #if DEBUG
            Button {
                Task {
                    await viewModel.createSampleData()
                }
            } label: {
                Label("샘플 데이터 생성", systemImage: "wand.and.stars")
            }
            #endif
            
            // 데이터 삭제
            Button(role: .destructive) {
                viewModel.showDeleteAllConfirmation = true
            } label: {
                Label("모든 데이터 삭제", systemImage: "trash")
            }
        } header: {
            Text("데이터")
        }
    }
    
    // MARK: - Cloud & Backup Section (💎 Premium)
    
    private var backupSection: some View {
        Section {
            // 💎 프리미엄 체크
            if !StoreKitManager.shared.isPremium {
                // 프리미엄 필요 안내
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Label("iCloud 동기화", systemImage: "icloud.fill")
                            .foregroundColor(.blue)
                        Spacer()
                        PremiumBadge()
                    }
                    
                    HStack {
                        Label("데이터 백업", systemImage: "externaldrive.fill")
                        Spacer()
                        PremiumBadge()
                    }
                }
                
                Text("프리미엄으로 여러 기기 간 동기화와 데이터 백업/복원이 가능합니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button {
                    showPremiumSheet = true
                } label: {
                    Text("프리미엄으로 잠금 해제")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            } else {
                // ☁️ iCloud 동기화 (프리미엄 사용자)
                Toggle(isOn: $viewModel.iCloudSyncEnabled) {
                    HStack {
                        Label("iCloud 동기화", systemImage: "icloud.fill")
                            .foregroundColor(.blue)
                    }
                }
                .onChange(of: viewModel.iCloudSyncEnabled) { _, newValue in
                    viewModel.showRestartAlert = true
                }
                
                // iCloud 상태 표시
                HStack {
                    Text("동기화 상태")
                        .foregroundColor(.secondary)
                    Spacer()
                    if viewModel.isICloudAvailable {
                        if viewModel.iCloudSyncEnabled && DoseMateApp.isCloudSyncEnabled {
                            Label("활성화됨", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else if viewModel.iCloudSyncEnabled && !DoseMateApp.isCloudSyncEnabled {
                            Label("재시작 필요", systemImage: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            Text("비활성화")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Label("iCloud 사용 불가", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Divider()
                
                // 💎 데이터 내보내기 (프리미엄 사용자)
                Button {
                    Task {
                        await exportData()
                    }
                } label: {
                    HStack {
                        Label("데이터 내보내기", systemImage: "square.and.arrow.up")
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
                
                // 💎 데이터 가져오기 (프리미엄 사용자)
                Button {
                    // iCloud 동기화 중이면 경고
                    if viewModel.iCloudSyncEnabled && DoseMateApp.isCloudSyncEnabled {
                        viewModel.showImportWithICloudWarning = true
                    } else {
                        showImportFilePicker = true
                    }
                } label: {
                    HStack {
                        Label("데이터 가져오기", systemImage: "square.and.arrow.down")
                        Spacer()
                        if viewModel.isImporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isImporting)
            }
        } header: {
            HStack {
                Text("클라우드 및 백업")
                if !StoreKitManager.shared.isPremium {
                    PremiumBadge()
                }
            }
        } footer: {
            if StoreKitManager.shared.isPremium {
                if viewModel.iCloudSyncEnabled {
                    Text("iCloud 동기화가 켜진 상태에서 가져오기를 하면 다른 기기에도 영향을 줄 수 있습니다.")
                } else {
                    Text("내보내기된 파일은 다른 기기나 재설치 후 가져오기로 복원할 수 있습니다.")
                }
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text("버전")
                Spacer()
                Text(viewModel.appVersion)
                    .foregroundColor(.secondary)
            }
            
            Link(destination: URL(string: "https://www.apple.com/legal/privacy")!) {
                Label("개인정보 처리방침", systemImage: "hand.raised")
            }
            
            Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                Label("이용약관", systemImage: "doc.text")
            }
        } header: {
            Text("정보")
        }
    }
    
    // MARK: - Developer Section (DEBUG only)
    
    #if DEBUG
    private var developerSection: some View {
        Section {
            // 프리미엄 상태 토글
            Toggle(isOn: Binding(
                get: { storeManager.isPremium },
                set: { newValue in
                    storeManager.debugSetPremium(newValue)
                }
            )) {
                Label {
                    VStack(alignment: .leading) {
                        Text("프리미엄 상태")
                        Text(storeManager.isPremium ? "활성화됨" : "비활성화됨")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: "crown.fill")
                        .foregroundColor(storeManager.isPremium ? .yellow : .gray)
                }
            }
            
            // 기부 횟수 리셋
            Button {
                storeManager.debugResetTipCount()
            } label: {
                Label("기부 횟수 리셋", systemImage: "arrow.counterclockwise")
            }
            
            // 현재 상태 표시
            HStack {
                Text("총 기부 횟수")
                Spacer()
                Text("\(storeManager.totalTipCount)회")
                    .foregroundColor(.secondary)
            }
            
            // 개발자 설정 화면으로 이동
            NavigationLink {
                DeveloperSettingsView()
            } label: {
                Label("개발자 옵션 더보기", systemImage: "hammer.fill")
            }
        } header: {
            Label("개발자 설정", systemImage: "wrench.and.screwdriver.fill")
        } footer: {
            Text("⚠️ DEBUG 빌드에서만 표시됩니다. 릴리즈 빌드에서는 자동으로 숨겨집니다.")
        }
    }
    #endif
}

// MARK: - Caregiver List View

struct CaregiverListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var caregivers: [Caregiver]
    
    @State private var showAddSheet = false
    @State private var caregiverToDelete: Caregiver?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        List {
            ForEach(caregivers) { caregiver in
                CaregiverRow(caregiver: caregiver)
                    .swipeActions {
                        Button(role: .destructive) {
                            caregiverToDelete = caregiver
                            showDeleteConfirmation = true
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
            }
        }
        .navigationTitle("보호자 관리")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if caregivers.isEmpty {
                ContentUnavailableView(
                    "보호자 없음",
                    systemImage: "person.2.slash",
                    description: Text("보호자를 추가하면 복약 누락 시 알림을 보낼 수 있습니다")
                )
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddCaregiverView { caregiver in
                modelContext.insert(caregiver)
                try? modelContext.save()
            }
        }
        .alert("보호자 삭제", isPresented: $showDeleteConfirmation) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                if let caregiver = caregiverToDelete {
                    modelContext.delete(caregiver)
                    try? modelContext.save()
                }
            }
        }
    }
}

// MARK: - Appointment List View

struct AppointmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Appointment.appointmentDate) private var appointments: [Appointment]
    
    @State private var showAddSheet = false
    
    var body: some View {
        List {
            if !upcomingAppointments.isEmpty {
                Section("예정된 진료") {
                    ForEach(upcomingAppointments) { appointment in
                        AppointmentRow(appointment: appointment)
                            .swipeActions {
                                Button(role: .destructive) {
                                    modelContext.delete(appointment)
                                    try? modelContext.save()
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                                
                                Button {
                                    appointment.markAsCompleted()
                                    try? modelContext.save()
                                } label: {
                                    Label("완료", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                    }
                }
            }
            
            if !pastAppointments.isEmpty {
                Section("지난 진료") {
                    ForEach(pastAppointments) { appointment in
                        AppointmentRow(appointment: appointment)
                            .swipeActions {
                                Button(role: .destructive) {
                                    modelContext.delete(appointment)
                                    try? modelContext.save()
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("진료 예약")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if appointments.isEmpty {
                ContentUnavailableView(
                    "진료 예약 없음",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("진료 예약을 추가하세요")
                )
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddAppointmentView { appointment in
                modelContext.insert(appointment)
                try? modelContext.save()
            }
        }
    }
    
    private var upcomingAppointments: [Appointment] {
        appointments.filter { $0.isUpcoming || $0.isToday }
    }
    
    private var pastAppointments: [Appointment] {
        appointments.filter { $0.isPast }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: [
            Medication.self,
            MedicationSchedule.self,
            MedicationLog.self,
            HealthMetric.self,
            Appointment.self,
            Caregiver.self
        ], inMemory: true)
}
