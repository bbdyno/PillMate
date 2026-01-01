//
//  Constants.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation
import SwiftUI
import DMateResource

/// 앱 전체 상수
enum AppConstants {
    // MARK: - App Info

    static let appName = DMateResourceStrings.App.medicationManagement
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.pillreminder"
    
    // MARK: - Bundle Identifiers
    
    /// 메인 앱 번들 식별자
    static let mainAppBundleId = "com.pillreminder.pillmate"
    
    /// 위젯 확장 번들 식별자 (메인 앱 번들 ID + .widget)
    static let widgetBundleId = "\(mainAppBundleId).widget"
    
    /// App Group 식별자 (데이터 공유용)
    static let appGroupId = "group.\(mainAppBundleId)"
    
    // MARK: - UserDefaults Keys
    
    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let notificationEnabled = "notificationEnabled"
        static let soundEnabled = "soundEnabled"
        static let hapticEnabled = "hapticEnabled"
        static let defaultSnoozeInterval = "defaultSnoozeInterval"
        static let healthKitEnabled = "healthKitEnabled"
        static let lastSyncDate = "lastSyncDate"
        static let appearanceMode = "appearanceMode"
        static let selectedLanguage = "selectedLanguage"
        static let iCloudSyncEnabled = "iCloudSyncEnabled"
        static let criticalAlertsEnabled = "criticalAlertsEnabled"
        static let reminderMinutesBefore = "reminderMinutesBefore"
    }
    
    // MARK: - Notification Identifiers
    
    enum NotificationIds {
        static let medicationReminder = "medication_reminder"
        static let lowStock = "low_stock"
        static let caregiver = "caregiver_alert"
        static let appointment = "appointment_reminder"
    }
    
    // MARK: - UI Constants
    
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 16
        
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        
        static let iconSize: CGFloat = 24
        static let smallIconSize: CGFloat = 16
        static let largeIconSize: CGFloat = 32
        
        static let buttonHeight: CGFloat = 50
        static let textFieldHeight: CGFloat = 44
        
        static let cardShadowRadius: CGFloat = 4
        static let cardShadowOpacity: Double = 0.1
        
        static let animationDuration: Double = 0.3
        static let shortAnimationDuration: Double = 0.15
        
        static let maxImageSize: CGFloat = 1024
        static let thumbnailSize: CGFloat = 80
    }
    
    // MARK: - Time Constants
    
    enum Time {
        static let defaultSnoozeMinutes = 10
        static let snoozeOptions = [5, 10, 15, 30, 60]
        
        static let reminderBeforeOptions = [0, 5, 10, 15, 30, 60]
        
        static let defaultMorningTime = DateComponents(hour: 8, minute: 0)
        static let defaultNoonTime = DateComponents(hour: 12, minute: 0)
        static let defaultEveningTime = DateComponents(hour: 18, minute: 0)
        static let defaultNightTime = DateComponents(hour: 22, minute: 0)
        
        static let missedDoseThresholdMinutes = 60
        static let delayedDoseThresholdMinutes = 30
    }
    
    // MARK: - Stock Constants
    
    enum Stock {
        static let defaultLowStockThreshold = 5
        static let criticalStockThreshold = 2
    }
    
    // MARK: - Health Constants
    
    enum Health {
        // 정상 범위
        static let normalWeightRange = 18.5...24.9 // BMI
        static let normalBloodPressureSystolic = 90.0...120.0
        static let normalBloodPressureDiastolic = 60.0...80.0
        static let normalBloodGlucose = 70.0...100.0 // 공복
        static let normalHbA1C = 4.0...5.6
        static let normalHeartRate = 60.0...100.0
        static let normalOxygenSaturation = 95.0...100.0
        static let normalBodyTemperature = 36.1...37.2
        
        // 목표
        static let dailyWaterIntakeGoal = 2000.0 // mL
        static let dailyStepsGoal = 10000.0
        static let dailySleepGoal = 7.0...9.0 // hours
    }
    
    // MARK: - Limits
    
    enum Limits {
        static let maxMedications = 100
        static let maxSchedulesPerMedication = 10
        static let maxTimesPerSchedule = 12
        static let maxCaregivers = 10
        static let maxNotifications = 64 // iOS 제한
        
        static let maxImageSizeBytes = 5 * 1024 * 1024 // 5MB
        static let imageCompressionQuality: CGFloat = 0.7
        
        static let maxNotesLength = 500
        static let maxNameLength = 100
    }
    
    // MARK: - Date Formats

    // NOTE: Date formats are now managed through DMateResourceStrings.DateFormat
    // for proper localization support. See Extensions.swift for usage.
    enum DateFormats {
        static let time = "HH:mm"
        static let timeWithAMPM = "a h:mm"
        static let weekday = "EEEE"
        static let iso8601 = "yyyy-MM-dd'T'HH:mm:ssZ"

        // Deprecated: Use DMateResourceStrings.DateFormat instead
        // static let shortDate = "M월 d일"
        // static let fullDate = "yyyy년 M월 d일"
        // static let fullDateTime = "yyyy년 M월 d일 a h:mm"
        // static let monthYear = "yyyy년 M월"
    }
    
    // MARK: - Widget Constants
    
    enum Widget {
        static let smallWidgetSize = CGSize(width: 155, height: 155)
        static let mediumWidgetSize = CGSize(width: 329, height: 155)
        static let largeWidgetSize = CGSize(width: 329, height: 345)
        
        static let refreshInterval: TimeInterval = 15 * 60 // 15분
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
    }
    
    // MARK: - Accessibility
    
    enum Accessibility {
        static let minimumTapTarget: CGFloat = 44
        static let minimumTextSize: CGFloat = 11
    }
}

// MARK: - Color Theme

enum ColorTheme {
    case light
    case dark
    case system
    
    var displayName: String {
        switch self {
        case .light: return DMateResourceStrings.Appearance.light
        case .dark: return DMateResourceStrings.Appearance.dark
        case .system: return DMateResourceStrings.Appearance.system
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// MARK: - Feature Flags

enum FeatureFlags {
    /// 위젯 지원
    static let widgetsEnabled = true
    
    /// HealthKit 연동
    static let healthKitEnabled = true
    
    /// iCloud 동기화
    static let iCloudSyncEnabled = true
    
    /// Apple Watch 지원
    static let watchAppEnabled = false
    
    /// Siri Shortcuts
    static let siriShortcutsEnabled = false
    
    /// Live Activities
    static let liveActivitiesEnabled = false
    
    /// 바코드 스캔
    static let barcodeScanEnabled = false
    
    /// 약물 상호작용 체크
    static let drugInteractionCheckEnabled = false
}

// MARK: - Sample Data Flag

#if DEBUG
let useSampleData = false
#endif
