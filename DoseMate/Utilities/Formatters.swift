//
//  Formatters.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation

/// 앱 전체에서 사용되는 포맷터들
enum Formatters {
    // MARK: - Date Formatters
    
    /// 시간 포맷터 (HH:mm)
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    /// 오전/오후 시간 포맷터
    static let timeWithAMPM: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    /// 짧은 날짜 포맷터 (M월 d일)
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    /// 전체 날짜 포맷터 (yyyy년 M월 d일)
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    /// 날짜 + 요일 포맷터
    static let dateWithWeekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    /// 날짜 + 시간 포맷터
    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    /// 전체 날짜 + 시간 포맷터
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    /// 요일 포맷터
    static let weekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    /// 짧은 요일 포맷터
    static let shortWeekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    /// 월/년 포맷터
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    /// ISO 8601 포맷터
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    /// 상대적 시간 포맷터
    static let relativeTime: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .full
        return formatter
    }()
    
    // MARK: - Number Formatters
    
    /// 정수 포맷터
    static let integer: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    /// 소수점 1자리 포맷터
    static let oneDecimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    /// 소수점 2자리 포맷터
    static let twoDecimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    /// 퍼센트 포맷터
    static let percent: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    /// 퍼센트 포맷터 (소수점 1자리)
    static let percentWithDecimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    /// 서수형 포맷터 (1st, 2nd...)
    static let ordinal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    // MARK: - Measurement Formatters
    
    /// 체중 포맷터 (kg)
    static let weight: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()
    
    /// 체온 포맷터 (°C)
    static let temperature: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()
    
    /// 길이 포맷터 (cm)
    static let length: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()
    
    // MARK: - Byte Count Formatter
    
    /// 바이트 포맷터
    static let byteCount: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter
    }()
    
    // MARK: - List Formatter
    
    /// 리스트 포맷터
    static let list: ListFormatter = {
        let formatter = ListFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
}

// MARK: - Formatting Helper Functions

/// 날짜 포맷팅 헬퍼
func formatDate(_ date: Date, format: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    formatter.locale = Locale(identifier: "ko_KR")
    return formatter.string(from: date)
}

/// 시간 포맷팅
func formatTime(_ date: Date) -> String {
    Formatters.time.string(from: date)
}

/// 날짜 + 시간 포맷팅
func formatDateTime(_ date: Date) -> String {
    Formatters.dateTime.string(from: date)
}

/// 상대적 시간 포맷팅
func formatRelativeTime(_ date: Date) -> String {
    Formatters.relativeTime.localizedString(for: date, relativeTo: Date())
}

/// 숫자 포맷팅
func formatNumber(_ number: Double, decimals: Int = 1) -> String {
    String(format: "%.\(decimals)f", number)
}

/// 퍼센트 포맷팅
func formatPercent(_ value: Double) -> String {
    Formatters.percent.string(from: NSNumber(value: value)) ?? "\(Int(value * 100))%"
}

/// 체중 포맷팅
func formatWeight(_ kg: Double) -> String {
    "\(formatNumber(kg, decimals: 1)) kg"
}

/// 혈압 포맷팅
func formatBloodPressure(systolic: Double, diastolic: Double) -> String {
    "\(Int(systolic))/\(Int(diastolic)) mmHg"
}

/// 혈당 포맷팅
func formatBloodGlucose(_ value: Double) -> String {
    "\(Int(value)) mg/dL"
}

/// 심박수 포맷팅
func formatHeartRate(_ bpm: Double) -> String {
    "\(Int(bpm)) BPM"
}

/// 체온 포맷팅
func formatTemperature(_ celsius: Double) -> String {
    "\(formatNumber(celsius, decimals: 1))°C"
}

/// 산소포화도 포맷팅
func formatOxygenSaturation(_ percent: Double) -> String {
    "\(Int(percent))%"
}

/// 수분 섭취량 포맷팅
func formatWaterIntake(_ ml: Double) -> String {
    if ml >= 1000 {
        return "\(formatNumber(ml / 1000, decimals: 1)) L"
    } else {
        return "\(Int(ml)) mL"
    }
}

/// 걸음수 포맷팅
func formatSteps(_ steps: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale(identifier: "ko_KR")
    return (formatter.string(from: NSNumber(value: Int(steps))) ?? "\(Int(steps))") + " 걸음"
}

/// 수면 시간 포맷팅
func formatSleepDuration(_ hours: Double) -> String {
    let totalMinutes = Int(hours * 60)
    let h = totalMinutes / 60
    let m = totalMinutes % 60
    
    if m == 0 {
        return "\(h)시간"
    } else {
        return "\(h)시간 \(m)분"
    }
}

/// 시간 간격 포맷팅 (초)
func formatDuration(_ seconds: TimeInterval) -> String {
    let hours = Int(seconds) / 3600
    let minutes = (Int(seconds) % 3600) / 60
    
    if hours > 0 {
        return "\(hours)시간 \(minutes)분"
    } else if minutes > 0 {
        return "\(minutes)분"
    } else {
        return "1분 미만"
    }
}

/// 남은 시간 포맷팅
func formatTimeRemaining(_ seconds: TimeInterval) -> String {
    if seconds < 0 {
        let overdue = abs(seconds)
        if overdue < 60 {
            return "지금"
        } else if overdue < 3600 {
            return "\(Int(overdue / 60))분 경과"
        } else {
            return "\(Int(overdue / 3600))시간 경과"
        }
    } else {
        if seconds < 60 {
            return "곧"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))분 후"
        } else if seconds < 86400 {
            return "\(Int(seconds / 3600))시간 후"
        } else {
            return "\(Int(seconds / 86400))일 후"
        }
    }
}

/// 날짜 범위 포맷팅
func formatDateRange(from startDate: Date, to endDate: Date) -> String {
    let calendar = Calendar.current
    
    if calendar.isDate(startDate, inSameDayAs: endDate) {
        return Formatters.dateWithWeekday.string(from: startDate)
    } else if calendar.isDate(startDate, equalTo: endDate, toGranularity: .month) {
        let startDay = calendar.component(.day, from: startDate)
        let endFormatted = Formatters.dateWithWeekday.string(from: endDate)
        return "\(startDay)일 ~ \(endFormatted)"
    } else {
        let startFormatted = Formatters.shortDate.string(from: startDate)
        let endFormatted = Formatters.shortDate.string(from: endDate)
        return "\(startFormatted) ~ \(endFormatted)"
    }
}

// MARK: - Validation Helpers

/// 이메일 유효성 검사
func isValidEmail(_ email: String) -> Bool {
    let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
    return emailPredicate.evaluate(with: email)
}

/// 전화번호 유효성 검사
func isValidPhoneNumber(_ phone: String) -> Bool {
    let cleaned = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
    return cleaned.count >= 10 && cleaned.count <= 11
}

/// 전화번호 포맷팅
func formatPhoneNumber(_ phone: String) -> String {
    let cleaned = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
    
    if cleaned.count == 11 {
        let index1 = cleaned.index(cleaned.startIndex, offsetBy: 3)
        let index2 = cleaned.index(cleaned.startIndex, offsetBy: 7)
        return "\(cleaned[..<index1])-\(cleaned[index1..<index2])-\(cleaned[index2...])"
    } else if cleaned.count == 10 {
        let index1 = cleaned.index(cleaned.startIndex, offsetBy: 3)
        let index2 = cleaned.index(cleaned.startIndex, offsetBy: 6)
        return "\(cleaned[..<index1])-\(cleaned[index1..<index2])-\(cleaned[index2...])"
    }
    
    return phone
}
