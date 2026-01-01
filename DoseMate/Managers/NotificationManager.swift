//
//  NotificationManager.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import Combine
import Foundation
import UserNotifications
import UIKit
import DMateResource

/// 알림 카테고리 식별자
enum NotificationCategory: String {
    case medicationReminder = "MEDICATION_REMINDER"
    case criticalMedication = "CRITICAL_MEDICATION"
    case lowStock = "LOW_STOCK"
    case appointmentReminder = "APPOINTMENT_REMINDER"
}

/// 알림 액션 식별자
enum NotificationAction: String {
    case taken = "TAKEN_ACTION"
    case snooze5 = "SNOOZE_5_ACTION"
    case snooze10 = "SNOOZE_10_ACTION"
    case snooze15 = "SNOOZE_15_ACTION"
    case snooze30 = "SNOOZE_30_ACTION"
    case skip = "SKIP_ACTION"
    case viewDetails = "VIEW_DETAILS_ACTION"
}

/// 로컬 알림을 관리하는 싱글톤 매니저
@MainActor
final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    // MARK: - Singleton
    
    static let shared = NotificationManager()
    
    // MARK: - Properties
    
    /// 알림 센터
    private let notificationCenter = UNUserNotificationCenter.current()
    
    /// 권한 부여 여부
    @Published private(set) var isAuthorized: Bool = false
    
    /// Critical Alerts 권한 여부
    @Published private(set) var isCriticalAlertsAuthorized: Bool = false
    
    /// 현재 권한 상태
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    /// 예약된 알림 수
    @Published private(set) var scheduledNotificationsCount: Int = 0
    
    /// 스누즈 간격 설정 (분)
    @Published var defaultSnoozeInterval: Int = 10
    
    /// 알림 사운드 활성화
    @Published var soundEnabled: Bool = true
    
    /// 알림 배지 활성화
    @Published var badgeEnabled: Bool = true
    
    // MARK: - Constants
    
    /// 최대 예약 가능한 알림 수 (iOS 제한)
    private let maxScheduledNotifications = 64
    
    /// 알림 식별자 접두사
    private let notificationPrefix = "com.pillreminder."
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        Task {
            await checkAuthorizationStatus()
            await setupNotificationCategories()
        }
    }
    
    // MARK: - Setup
    
    /// 알림 카테고리 설정
    private func setupNotificationCategories() async {
        // 복약 알림 액션
        let takenAction = UNNotificationAction(
            identifier: NotificationAction.taken.rawValue,
            title: DMateResourceStrings.Notification.actionTaken,
            options: [.foreground]
        )
        
        let snooze5Action = UNNotificationAction(
            identifier: NotificationAction.snooze5.rawValue,
            title: DMateResourceStrings.Notification.snooze5min,
            options: []
        )
        
        let snooze10Action = UNNotificationAction(
            identifier: NotificationAction.snooze10.rawValue,
            title: DMateResourceStrings.Notification.snooze10min,
            options: []
        )
        
        let snooze15Action = UNNotificationAction(
            identifier: NotificationAction.snooze15.rawValue,
            title: DMateResourceStrings.Notification.snooze15min,
            options: []
        )
        
        let snooze30Action = UNNotificationAction(
            identifier: NotificationAction.snooze30.rawValue,
            title: DMateResourceStrings.Notification.snooze30min,
            options: []
        )
        
        let skipAction = UNNotificationAction(
            identifier: NotificationAction.skip.rawValue,
            title: DMateResourceStrings.Notification.actionSkip,
            options: [.destructive]
        )
        
        let viewDetailsAction = UNNotificationAction(
            identifier: NotificationAction.viewDetails.rawValue,
            title: DMateResourceStrings.Notification.actionViewDetails,
            options: [.foreground]
        )
        
        // 일반 복약 알림 카테고리
        let medicationCategory = UNNotificationCategory(
            identifier: NotificationCategory.medicationReminder.rawValue,
            actions: [takenAction, snooze10Action, snooze30Action, skipAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: DMateResourceStrings.Notification.medicationReminder,
            options: [.customDismissAction]
        )
        
        // 중요 복약 알림 카테고리
        let criticalCategory = UNNotificationCategory(
            identifier: NotificationCategory.criticalMedication.rawValue,
            actions: [takenAction, snooze5Action, snooze15Action],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: DMateResourceStrings.Notification.criticalReminder,
            options: [.customDismissAction]
        )
        
        // 재고 부족 알림 카테고리
        let lowStockCategory = UNNotificationCategory(
            identifier: NotificationCategory.lowStock.rawValue,
            actions: [viewDetailsAction],
            intentIdentifiers: [],
            options: []
        )
        
        // 보호자 알림 카테고리
        let appointmentCategory = UNNotificationCategory(
            identifier: NotificationCategory.appointmentReminder.rawValue,
            actions: [viewDetailsAction],
            intentIdentifiers: [],
            options: []
        )
        
        let categories: Set<UNNotificationCategory> = [
            medicationCategory,
            criticalCategory,
            lowStockCategory,
            appointmentCategory
        ]
        
        notificationCenter.setNotificationCategories(categories)
    }
    
    // MARK: - Authorization
    
    /// 권한 상태 확인
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
        isCriticalAlertsAuthorized = settings.criticalAlertSetting == .enabled
        
        await updateScheduledNotificationsCount()
    }
    
    /// 권한 요청
    func requestAuthorization(includingCriticalAlerts: Bool = false) async throws {
        var options: UNAuthorizationOptions = [.alert, .sound, .badge, .providesAppNotificationSettings]
        
        if includingCriticalAlerts {
            options.insert(.criticalAlert)
        }
        
        do {
            let granted = try await notificationCenter.requestAuthorization(options: options)
            isAuthorized = granted
            
            if granted {
                await checkAuthorizationStatus()
            }
        } catch {
            throw NotificationError.authorizationFailed(error)
        }
    }
    
    /// 설정 앱으로 이동
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Schedule Notifications
    
    /// 스케줄 기반 알림 등록
    func scheduleNotification(for schedule: MedicationSchedule) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        guard let medication = schedule.medication else {
            throw NotificationError.invalidSchedule
        }
        
        guard schedule.notificationEnabled else { return }
        
        // 기존 알림 취소
        await cancelNotification(for: schedule)
        
        // 알림 시간들 가져오기
        let times = schedule.times
        guard !times.isEmpty else { return }
        
        // 각 시간에 대해 알림 생성
        for (index, time) in times.enumerated() {
            let identifier = makeNotificationIdentifier(
                scheduleId: schedule.id,
                timeIndex: index
            )
            
            let content = makeNotificationContent(
                medication: medication,
                schedule: schedule,
                scheduledTime: time
            )
            
            let trigger = makeNotificationTrigger(
                for: time,
                schedule: schedule
            )
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            do {
                try await notificationCenter.add(request)
            } catch {
                throw NotificationError.scheduleFailed(error)
            }
        }
        
        await updateScheduledNotificationsCount()
    }
    
    /// 알림 취소
    func cancelNotification(for schedule: MedicationSchedule) async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        
        let identifiersToRemove = pendingRequests
            .map { $0.identifier }
            .filter { $0.contains(schedule.id.uuidString) }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        
        await updateScheduledNotificationsCount()
    }
    
    /// 모든 알림 재등록
    func rescheduleAllNotifications(schedules: [MedicationSchedule]) async throws {
        // 모든 기존 알림 취소
        notificationCenter.removeAllPendingNotificationRequests()
        
        // 활성 스케줄만 필터링
        let activeSchedules = schedules.filter { $0.isActive && $0.notificationEnabled }
        
        // 알림 수 제한 확인
        let totalNotifications = activeSchedules.reduce(0) { $0 + $1.times.count }
        
        if totalNotifications > maxScheduledNotifications {
            // 우선순위에 따라 알림 선별 (최근 시간 우선)
            let sortedSchedules = activeSchedules.sorted { schedule1, schedule2 in
                let next1 = schedule1.nextScheduledTime ?? .distantFuture
                let next2 = schedule2.nextScheduledTime ?? .distantFuture
                return next1 < next2
            }
            
            var scheduledCount = 0
            for schedule in sortedSchedules {
                if scheduledCount + schedule.times.count <= maxScheduledNotifications {
                    try await scheduleNotification(for: schedule)
                    scheduledCount += schedule.times.count
                } else {
                    break
                }
            }
        } else {
            for schedule in activeSchedules {
                try await scheduleNotification(for: schedule)
            }
        }
        
        await updateScheduledNotificationsCount()
    }
    
    /// 스누즈 알림
    func snoozeNotification(for log: MedicationLog, minutes: Int) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        guard let medication = log.medication else {
            throw NotificationError.invalidData
        }
        
        let identifier = makeSnoozeNotificationIdentifier(logId: log.id)
        
        let content = UNMutableNotificationContent()
        content.title = "💊 복약 알림 (스누즈)"
        content.body = "\(medication.name) \(medication.dosage) 복용 시간입니다."
        content.sound = soundEnabled ? .default : nil
        content.categoryIdentifier = NotificationCategory.medicationReminder.rawValue
        content.userInfo = [
            "medicationId": medication.id.uuidString,
            "logId": log.id.uuidString,
            "isSnooze": true
        ]
        
        let triggerDate = Calendar.current.date(
            byAdding: .minute,
            value: minutes,
            to: Date()
        )!
        
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        log.snooze(minutes: minutes)
        
        await updateScheduledNotificationsCount()
    }
    
    /// 재고 부족 알림
    func sendLowStockNotification(for medication: Medication) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        let identifier = makeLowStockNotificationIdentifier(medicationId: medication.id)
        
        let content = UNMutableNotificationContent()
        content.title = "📦 재고 부족 알림"
        content.body = DMateResourceStrings.Notification.stockRemaining(medication.name, medication.stockCount)
        content.sound = soundEnabled ? .default : nil
        content.categoryIdentifier = NotificationCategory.lowStock.rawValue
        content.userInfo = [
            "medicationId": medication.id.uuidString,
            "type": "lowStock"
        ]
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        
        try await notificationCenter.add(request)
    }
    
    /// 진료 예약 알림
    func scheduleAppointmentNotification(for appointment: Appointment) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        guard appointment.notificationEnabled else { return }
        
        let identifier = makeAppointmentNotificationIdentifier(appointmentId: appointment.id)
        
        let content = UNMutableNotificationContent()
        content.title = "🏥 진료 예약 알림"
        content.body = "\(appointment.doctorName) 선생님 진료가 \(appointment.notificationMinutesBefore)분 후입니다."
        if let location = appointment.location {
            content.body += " 장소: \(location)"
        }
        content.sound = soundEnabled ? .default : nil
        content.categoryIdentifier = NotificationCategory.appointmentReminder.rawValue
        content.userInfo = [
            "appointmentId": appointment.id.uuidString,
            "type": "appointment"
        ]
        
        let triggerDate = Calendar.current.date(
            byAdding: .minute,
            value: -appointment.notificationMinutesBefore,
            to: appointment.appointmentDate
        )!
        
        guard triggerDate > Date() else { return }
        
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
    }
    
    // MARK: - Handle Response
    
    /// 알림 응답 처리
    func handleNotificationResponse(_ response: UNNotificationResponse) async -> NotificationResponseResult {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        guard let medicationIdString = userInfo["medicationId"] as? String,
              let medicationId = UUID(uuidString: medicationIdString) else {
            return .error(DMateResourceStrings.Notification.errorInvalidNotificationData)
        }
        
        let logIdString = userInfo["logId"] as? String
        let logId = logIdString.flatMap { UUID(uuidString: $0) }
        
        switch actionIdentifier {
        case NotificationAction.taken.rawValue:
            return .taken(medicationId: medicationId, logId: logId)
            
        case NotificationAction.snooze5.rawValue:
            return .snoozed(medicationId: medicationId, logId: logId, minutes: 5)
            
        case NotificationAction.snooze10.rawValue:
            return .snoozed(medicationId: medicationId, logId: logId, minutes: 10)
            
        case NotificationAction.snooze15.rawValue:
            return .snoozed(medicationId: medicationId, logId: logId, minutes: 15)
            
        case NotificationAction.snooze30.rawValue:
            return .snoozed(medicationId: medicationId, logId: logId, minutes: 30)
            
        case NotificationAction.skip.rawValue:
            return .skipped(medicationId: medicationId, logId: logId)
            
        case NotificationAction.viewDetails.rawValue:
            return .viewDetails(medicationId: medicationId)
            
        case UNNotificationDefaultActionIdentifier:
            return .opened(medicationId: medicationId)
            
        case UNNotificationDismissActionIdentifier:
            return .dismissed(medicationId: medicationId)
            
        default:
            return .unknown
        }
    }
    
    // MARK: - Utility Methods
    
    /// 예약된 알림 수 업데이트
    private func updateScheduledNotificationsCount() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        scheduledNotificationsCount = pendingRequests.count
    }
    
    /// 알림 식별자 생성
    private func makeNotificationIdentifier(scheduleId: UUID, timeIndex: Int) -> String {
        "\(notificationPrefix)schedule.\(scheduleId.uuidString).\(timeIndex)"
    }
    
    private func makeSnoozeNotificationIdentifier(logId: UUID) -> String {
        "\(notificationPrefix)snooze.\(logId.uuidString)"
    }
    
    private func makeLowStockNotificationIdentifier(medicationId: UUID) -> String {
        "\(notificationPrefix)lowstock.\(medicationId.uuidString)"
    }
    
    private func makeAppointmentNotificationIdentifier(appointmentId: UUID) -> String {
        "\(notificationPrefix)appointment.\(appointmentId.uuidString)"
    }
    
    /// 알림 내용 생성
    private func makeNotificationContent(
        medication: Medication,
        schedule: MedicationSchedule,
        scheduledTime: Date
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        content.title = "💊 복약 시간입니다"
        content.body = "\(medication.name) \(medication.dosage) 복용하세요."
        
        if schedule.mealRelationEnum != .anytime {
            content.body += " (\(schedule.mealRelationEnum.displayName))"
        }
        
        if soundEnabled {
            content.sound = .default
        }
        
        if badgeEnabled {
            content.badge = 1
        }
        
        content.categoryIdentifier = NotificationCategory.medicationReminder.rawValue
        
        content.userInfo = [
            "medicationId": medication.id.uuidString,
            "scheduleId": schedule.id.uuidString,
            "scheduledTime": scheduledTime.timeIntervalSince1970
        ]
        
        // Time Sensitive 설정
        content.interruptionLevel = .timeSensitive
        
        return content
    }
    
    /// 알림 트리거 생성
    private func makeNotificationTrigger(
        for time: Date,
        schedule: MedicationSchedule
    ) -> UNNotificationTrigger {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: time)
        
        // 알림 미리 알림 시간 적용
        if schedule.reminderMinutesBefore > 0,
           let adjustedTime = calendar.date(byAdding: .minute, value: -schedule.reminderMinutesBefore, to: time) {
            components = calendar.dateComponents([.hour, .minute], from: adjustedTime)
        }
        
        switch schedule.scheduleTypeEnum {
        case .daily:
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
        case .specificDays:
            // 특정 요일의 경우 각 요일에 대해 별도 트리거 필요
            // 여기서는 매일 반복으로 설정하고, 실제 알림 시 요일 체크
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
        case .asNeeded:
            // 필요시 복용은 예약 알림 없음
            return UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
        case .interval:
            // 간격 설정은 매일 반복으로 설정하고, 실제 알림 시 간격 체크
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }
    }
    
    /// 배지 초기화
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    /// 모든 알림 제거
    func removeAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        clearBadge()
    }
    
    /// 전달된 알림 제거
    func removeDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge, .list]
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await handleNotificationResponse(response)
    }
}

// MARK: - Notification Response Result

enum NotificationResponseResult {
    case taken(medicationId: UUID, logId: UUID?)
    case snoozed(medicationId: UUID, logId: UUID?, minutes: Int)
    case skipped(medicationId: UUID, logId: UUID?)
    case viewDetails(medicationId: UUID)
    case opened(medicationId: UUID)
    case dismissed(medicationId: UUID)
    case error(String)
    case unknown
}

// MARK: - Notification Errors

enum NotificationError: LocalizedError {
    case notAuthorized
    case authorizationFailed(Error)
    case scheduleFailed(Error)
    case invalidSchedule
    case invalidData
    case limitExceeded
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return DMateResourceStrings.Notification.errorNotAuthorized
        case .authorizationFailed(let error):
            return DMateResourceStrings.Notification.errorAuthorizationFailed(error.localizedDescription)
        case .scheduleFailed(let error):
            return DMateResourceStrings.Notification.errorScheduleFailed(error.localizedDescription)
        case .invalidSchedule:
            return DMateResourceStrings.Notification.errorInvalidSchedule
        case .invalidData:
            return DMateResourceStrings.Notification.errorInvalidData
        case .limitExceeded:
            return DMateResourceStrings.Notification.errorLimitExceeded
        }
    }
}
