//
//  String+Localization.swift
//  DoseMate
//
//  Created by bbdyno on 12/6/25.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func localized(_ arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}

// MARK: - App Strings

struct AppStrings {
    // MARK: - Log History
    struct LogHistory {
        static let title = "log_history_title".localized
        static let csvExport = "log_history_csv_export".localized
        static let totalRecords = "log_history_total_records".localized
        static let consecutiveDays = "log_history_consecutive_days".localized
        static let filterResults = "log_history_filter_results".localized
        static let viewRecords = "log_history_view_records".localized
        static let noRecords = "log_history_no_records".localized
        static let adherenceRate = "log_history_adherence_rate".localized
        static let taken = "log_history_taken".localized
        static let delayed = "log_history_delayed".localized
        static let skipped = "log_history_skipped".localized
        static let snoozed = "log_history_snoozed".localized
        static let pending = "log_history_pending".localized
        static let unknown = "log_history_unknown".localized
        
        // Calendar
        static let sunday = "calendar_sunday".localized
        static let monday = "calendar_monday".localized
        static let tuesday = "calendar_tuesday".localized
        static let wednesday = "calendar_wednesday".localized
        static let thursday = "calendar_thursday".localized
        static let friday = "calendar_friday".localized
        static let saturday = "calendar_saturday".localized
        
        // Period names
        static let today = "period_today".localized
        static let yesterday = "period_yesterday".localized
        static let thisWeek = "period_this_week".localized
        static let lastWeek = "period_last_week".localized
        static let thisMonth = "period_this_month".localized
        static let lastMonth = "period_last_month".localized
        static let last3Months = "period_last_3_months".localized
        static let last6Months = "period_last_6_months".localized
        static let thisYear = "period_this_year".localized
        static let allTime = "period_all_time".localized
    }
    
    // MARK: - Log Status
    struct LogStatus {
        static let taken = "status_taken".localized
        static let skipped = "status_skipped".localized
        static let delayed = "status_delayed".localized
        static let snoozed = "status_snoozed".localized
        static let pending = "status_pending".localized
    }
}
