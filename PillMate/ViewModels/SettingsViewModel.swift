//
//  SettingsViewModel.swift
//  PillMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation
import SwiftUI
import SwiftData
import UserNotifications

/// 설정 ViewModel
@MainActor
@Observable
final class SettingsViewModel {
    // MARK: - Notification Settings
    
    /// 알림 활성화
    var notificationEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(notificationEnabled, forKey: AppConstants.UserDefaultsKeys.notificationEnabled)
        }
    }
    
    /// 알림 사운드
    var soundEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: AppConstants.UserDefaultsKeys.soundEnabled)
            NotificationManager.shared.soundEnabled = soundEnabled
        }
    }
    
    /// 햅틱 피드백
    var hapticEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(hapticEnabled, forKey: AppConstants.UserDefaultsKeys.hapticEnabled)
        }
    }
    
    /// Critical Alerts
    var criticalAlertsEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(criticalAlertsEnabled, forKey: AppConstants.UserDefaultsKeys.criticalAlertsEnabled)
        }
    }
    
    /// 기본 스누즈 간격 (분)
    var defaultSnoozeInterval: Int = 10 {
        didSet {
            UserDefaults.standard.set(defaultSnoozeInterval, forKey: AppConstants.UserDefaultsKeys.defaultSnoozeInterval)
            NotificationManager.shared.defaultSnoozeInterval = defaultSnoozeInterval
        }
    }
    
    /// 알림 미리 알림 시간 (분)
    var reminderMinutesBefore: Int = 0 {
        didSet {
            UserDefaults.standard.set(reminderMinutesBefore, forKey: AppConstants.UserDefaultsKeys.reminderMinutesBefore)
        }
    }
    
    // MARK: - HealthKit Settings
    
    /// HealthKit 연동 활성화
    var healthKitEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(healthKitEnabled, forKey: AppConstants.UserDefaultsKeys.healthKitEnabled)
        }
    }
    
    /// HealthKit 권한 상태
    var healthKitAuthorized: Bool = false
    
    /// 마지막 동기화 시간
    var lastSyncDate: Date? {
        get {
            UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.lastSyncDate) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppConstants.UserDefaultsKeys.lastSyncDate)
        }
    }
    
    // MARK: - Appearance Settings
    
    /// 외관 모드
    var appearanceMode: ColorTheme = .system {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: AppConstants.UserDefaultsKeys.appearanceMode)
        }
    }
    
    // MARK: - iCloud Settings
    
    /// iCloud 동기화 활성화
    var iCloudSyncEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(iCloudSyncEnabled, forKey: AppConstants.UserDefaultsKeys.iCloudSyncEnabled)
        }
    }
    
    // MARK: - Status Properties
    
    /// 알림 권한 상태
    var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    
    /// 로딩 상태
    var isLoading: Bool = false
    
    /// 내보내기 중
    var isExporting: Bool = false
    
    /// 가져오기 중
    var isImporting: Bool = false
    
    /// 에러 메시지
    var errorMessage: String?
    
    /// 성공 메시지
    var successMessage: String?
    
    /// 동기화 중
    var isSyncing: Bool = false
    
    /// 앱 버전
    var appVersion: String {
        "\(AppConstants.appVersion) (\(AppConstants.appBuild))"
    }
    
    // MARK: - Confirmation Alerts
    
    /// 데이터 삭제 확인
    var showDeleteAllConfirmation: Bool = false
    
    /// 알림 재설정 확인
    var showRescheduleConfirmation: Bool = false
    
    /// 앱 재시작 필요 알림 (iCloud 설정 변경 시)
    var showRestartAlert: Bool = false
    
    /// iCloud 동기화 중 가져오기 경고
    var showImportWithICloudWarning: Bool = false
    
    // MARK: - iCloud Status
    
    /// iCloud 계정 가용성
    var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
    
    /// iCloud 상태 텍스트
    var iCloudStatusText: String {
        if !isICloudAvailable {
            return "iCloud 사용 불가"
        } else if iCloudSyncEnabled && PillMateApp.isCloudSyncEnabled {
            return "동기화 중"
        } else if iCloudSyncEnabled && !PillMateApp.isCloudSyncEnabled {
            return "재시작 필요"
        } else {
            return "비활성화"
        }
    }
    
    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    private let notificationManager = NotificationManager.shared
    private let healthKitManager = HealthKitManager.shared
    
    // MARK: - Initialization
    
    init() {
        loadSettings()
    }
    
    // MARK: - Setup
    
    func setup(with context: ModelContext) {
        self.modelContext = context
        Task {
            await checkPermissions()
        }
    }
    
    // MARK: - Load Settings
    
    /// 저장된 설정 로드
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        notificationEnabled = defaults.bool(forKey: AppConstants.UserDefaultsKeys.notificationEnabled)
        soundEnabled = defaults.bool(forKey: AppConstants.UserDefaultsKeys.soundEnabled)
        hapticEnabled = defaults.bool(forKey: AppConstants.UserDefaultsKeys.hapticEnabled)
        criticalAlertsEnabled = defaults.bool(forKey: AppConstants.UserDefaultsKeys.criticalAlertsEnabled)
        
        let snooze = defaults.integer(forKey: AppConstants.UserDefaultsKeys.defaultSnoozeInterval)
        defaultSnoozeInterval = snooze > 0 ? snooze : 10
        
        reminderMinutesBefore = defaults.integer(forKey: AppConstants.UserDefaultsKeys.reminderMinutesBefore)
        
        healthKitEnabled = defaults.bool(forKey: AppConstants.UserDefaultsKeys.healthKitEnabled)
        iCloudSyncEnabled = defaults.bool(forKey: AppConstants.UserDefaultsKeys.iCloudSyncEnabled)
        
        if let themeString = defaults.string(forKey: AppConstants.UserDefaultsKeys.appearanceMode),
           let theme = ColorTheme(rawValue: themeString) {
            appearanceMode = theme
        }
    }
    
    // MARK: - Permissions
    
    /// 권한 상태 확인
    func checkPermissions() async {
        await notificationManager.checkAuthorizationStatus()
        notificationAuthorizationStatus = notificationManager.authorizationStatus
        
        healthKitAuthorized = healthKitManager.isAuthorized
    }
    
    /// 알림 권한 요청
    func requestNotificationPermission() async {
        do {
            try await notificationManager.requestAuthorization(includingCriticalAlerts: criticalAlertsEnabled)
            await checkPermissions()
            successMessage = "알림 권한이 허용되었습니다."
        } catch {
            errorMessage = "알림 권한 요청에 실패했습니다."
        }
    }
    
    /// HealthKit 권한 요청
    func requestHealthKitPermission() async {
        do {
            try await healthKitManager.requestAuthorization()
            healthKitAuthorized = true
            healthKitEnabled = true
            successMessage = "건강 앱 연동이 활성화되었습니다."
        } catch {
            errorMessage = "건강 앱 권한 요청에 실패했습니다."
        }
    }
    
    /// 설정 앱 열기
    func openSettings() {
        notificationManager.openSettings()
    }
    
    // MARK: - HealthKit Actions
    
    /// HealthKit 동기화
    func syncHealthKit() async {
        guard healthKitEnabled && healthKitAuthorized else {
            errorMessage = "건강 앱 연동이 활성화되지 않았습니다."
            return
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        await healthKitManager.syncHealthData()
        lastSyncDate = Date()
        successMessage = "건강 데이터가 동기화되었습니다."
    }
    
    // MARK: - Notification Actions
    
    /// 모든 알림 재설정
    func rescheduleAllNotifications() async {
        guard let context = modelContext else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        let descriptor = FetchDescriptor<MedicationSchedule>(
            predicate: #Predicate { $0.isActive }
        )
        
        guard let schedules = try? context.fetch(descriptor) else {
            errorMessage = "스케줄을 불러오는데 실패했습니다."
            return
        }
        
        do {
            try await notificationManager.rescheduleAllNotifications(schedules: schedules)
            successMessage = "알림이 재설정되었습니다."
        } catch {
            errorMessage = "알림 재설정에 실패했습니다."
        }
    }
    
    /// 모든 알림 제거
    func removeAllNotifications() {
        notificationManager.removeAllNotifications()
        successMessage = "모든 알림이 제거되었습니다."
    }
    
    // MARK: - Data Actions
    
    /// 모든 데이터 삭제
    func deleteAllData() async {
        guard let context = modelContext else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try context.delete(model: MedicationLog.self)
            try context.delete(model: MedicationSchedule.self)
            try context.delete(model: Medication.self)
            try context.delete(model: HealthMetric.self)
            try context.delete(model: Appointment.self)
            try context.delete(model: Caregiver.self)
            
            try context.save()
            
            // 알림도 모두 제거
            notificationManager.removeAllNotifications()
            
            successMessage = "모든 데이터가 삭제되었습니다."
        } catch {
            errorMessage = "데이터 삭제에 실패했습니다."
        }
    }
    
    /// 샘플 데이터 생성
    func createSampleData() async {
        guard let context = modelContext else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // 약물 추가
        for medication in Medication.sampleData {
            context.insert(medication)
            
            // 스케줄 추가
            let schedule = MedicationSchedule(
                scheduleType: .daily,
                frequency: .twiceDaily
            )
            schedule.setDefaultTimes(for: .twiceDaily)
            schedule.medication = medication
            context.insert(schedule)
        }
        
        // 보호자 추가
        for caregiver in Caregiver.sampleData {
            context.insert(caregiver)
        }
        
        // 진료 예약 추가
        for appointment in Appointment.sampleData {
            context.insert(appointment)
        }
        
        try? context.save()
        successMessage = "샘플 데이터가 생성되었습니다."
    }
    
    // MARK: - Computed Properties
    
    /// 알림 권한 텍스트
    var notificationStatusText: String {
        switch notificationAuthorizationStatus {
        case .notDetermined:
            return "권한 필요"
        case .denied:
            return "거부됨"
        case .authorized:
            return "허용됨"
        case .provisional:
            return "임시 허용"
        case .ephemeral:
            return "일시적 허용"
        @unknown default:
            return "알 수 없음"
        }
    }
    
    /// HealthKit 상태 텍스트
    var healthKitStatusText: String {
        if !HealthKitManager.shared.isAvailable {
            return "사용 불가"
        } else if healthKitAuthorized {
            return "연동됨"
        } else {
            return "연동 안됨"
        }
    }
    
    /// 마지막 동기화 텍스트
    var lastSyncText: String {
        if let date = lastSyncDate {
            return formatRelativeTime(date)
        }
        return "동기화 안됨"
    }
    
    /// 스누즈 옵션들
    var snoozeOptions: [Int] {
        AppConstants.Time.snoozeOptions
    }
    
    /// 미리 알림 옵션들
    var reminderBeforeOptions: [Int] {
        AppConstants.Time.reminderBeforeOptions
    }
}

// MARK: - ColorTheme Extension

extension ColorTheme: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "light": self = .light
        case "dark": self = .dark
        case "system": self = .system
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .light: return "light"
        case .dark: return "dark"
        case .system: return "system"
        }
    }
}
