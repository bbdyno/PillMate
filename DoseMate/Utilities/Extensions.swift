//
//  Extensions.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation
import SwiftUI
import DMateDesignSystem
import DMateResource

// MARK: - Date Extensions

extension Date {
    /// 오늘인지 확인
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// 내일인지 확인
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    /// 어제인지 확인
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// 이번 주인지 확인
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// 이번 달인지 확인
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    /// 하루의 시작
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// 하루의 끝
    var endOfDay: Date {
        Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) ?? self
    }
    
    /// 주의 시작
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// 월의 시작
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// 요일 (0 = 일요일)
    var weekday: Int {
        Calendar.current.component(.weekday, from: self) - 1
    }
    
    /// 요일 이름
    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    /// 짧은 요일 이름
    var shortWeekdayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }
    
    /// 일 추가
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// 시간 추가
    func addingHours(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }
    
    /// 분 추가
    func addingMinutes(_ minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }
    
    /// 두 날짜 사이의 일수
    func daysBetween(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self.startOfDay, to: date.startOfDay)
        return components.day ?? 0
    }
    
    /// 상대적 시간 표시
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// 시간만 추출
    var timeOnly: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// 시:분 문자열
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    /// 날짜 문자열 (M월 d일)
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate(DMateResourceStrings.DateFormat.shortDate)
        return formatter.string(from: self)
    }

    /// 전체 날짜 문자열
    var fullDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate(DMateResourceStrings.DateFormat.fullDate)
        return formatter.string(from: self)
    }
}

// MARK: - DateFormatter Extensions

extension DateFormatter {
    /// 짧은 시간 포맷터 (HH:mm)
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    /// 시간 포맷터 (오전/오후 h:mm)
    static var localizedTime: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeStyle = .short
        return formatter
    }

    /// 날짜 포맷터 (M월 d일)
    static var localizedShortDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate(DMateResourceStrings.DateFormat.shortDate)
        return formatter
    }

    /// 전체 날짜 포맷터
    static var localizedFullDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate(DMateResourceStrings.DateFormat.fullDate)
        return formatter
    }

    /// 날짜 + 시간 포맷터
    static var localizedDateTime: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - String Extensions

extension String {
    /// 빈 문자열이거나 공백만 있는지 확인
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 유효한 이메일인지 확인
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// 유효한 전화번호인지 확인 (한국)
    var isValidPhoneNumber: Bool {
        let phoneRegex = "^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: self.replacingOccurrences(of: "-", with: ""))
    }
    
    /// 전화번호 포맷팅
    var formattedPhoneNumber: String {
        let cleaned = replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if cleaned.count == 11 {
            let index1 = cleaned.index(cleaned.startIndex, offsetBy: 3)
            let index2 = cleaned.index(cleaned.startIndex, offsetBy: 7)
            return "\(cleaned[..<index1])-\(cleaned[index1..<index2])-\(cleaned[index2...])"
        }
        
        return self
    }
}

// MARK: - Double Extensions

extension Double {
    /// 소수점 n자리로 반올림
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    /// 퍼센트 문자열
    var percentString: String {
        String(format: "%.0f%%", self * 100)
    }
    
    /// 소수점 1자리 문자열
    var oneDecimalString: String {
        String(format: "%.1f", self)
    }
    
    /// 정수 문자열
    var integerString: String {
        String(format: "%.0f", self)
    }
}

// MARK: - Int Extensions

extension Int {
    /// 서수형 문자열 (1st, 2nd, 3rd...)
    var ordinal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// MARK: - Array Extensions

extension Array {
    /// 안전한 인덱스 접근
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Array where Element: Hashable {
    /// 중복 제거
    var unique: [Element] {
        Array(Set(self))
    }
}

// MARK: - Color Extensions
// Color extensions는 DMateDesignSystem 모듈로 이동됨

// MARK: - View Extensions

extension View {
    /// 조건부 수정자
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// 조건부 수정자 (else 포함)
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
    
    /// 카드 스타일 - DesignSystem의 cardStyle 사용
    /// 이 함수는 호환성을 위해 유지됨 (새 코드는 .cardStyle() 사용 권장)
    func legacyCardStyle() -> some View {
        self
            .background(AppColors.cardBackground)
            .cornerRadius(AppRadius.md)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 숨기기
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }
    
    /// 키보드 숨기기
    /// ⚠️ App Extension에서는 동작하지 않음
    func hideKeyboard() {
        #if !WIDGET_EXTENSION
        // UIApplication.shared는 Extension에서 사용 불가
        // NSClassFromString을 통한 런타임 접근으로 컴파일 에러 회피
        guard let windowScene = (UIApplication.value(forKeyPath: "sharedApplication.connectedScenes") as? Set<UIScene>)?
            .first(where: { $0 is UIWindowScene }) as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.endEditing(true)
        #endif
    }
    
    /// 햅틱 피드백
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        #if !WIDGET_EXTENSION
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        #endif
    }
    
    /// 성공 햅틱
    func successHaptic() {
        #if !WIDGET_EXTENSION
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
    
    /// 에러 햅틱
    func errorHaptic() {
        #if !WIDGET_EXTENSION
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        #endif
    }
}

// MARK: - Binding Extensions

extension Binding {
    /// 옵셔널 바인딩을 non-optional로 변환
    func unwrap<T>(defaultValue: T) -> Binding<T> where Value == T? {
        Binding<T>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

extension Binding where Value == String {
    /// 숫자만 입력 가능하도록
    func numbersOnly() -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue.filter { $0.isNumber }
            }
        )
    }
}

// MARK: - UIApplication Extensions
// ⚠️ App Extension에서는 사용 불가 - 메인 앱 타겟에서만 사용
// 
// 위젯 타겟에서 이 파일을 사용할 경우:
// 1. 위젯 타겟의 Build Settings > Active Compilation Conditions에 WIDGET_EXTENSION 추가
// 또는
// 2. 위젯 타겟에서 Extensions.swift 파일 제외

#if !WIDGET_EXTENSION
@available(iOSApplicationExtension, unavailable)
extension UIApplication {
    /// 현재 키 윈도우
    var currentKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    /// 상단 SafeArea 높이
    var safeAreaTop: CGFloat {
        currentKeyWindow?.safeAreaInsets.top ?? 0
    }
    
    /// 하단 SafeArea 높이
    var safeAreaBottom: CGFloat {
        currentKeyWindow?.safeAreaInsets.bottom ?? 0
    }
}
#endif

// MARK: - Calendar Extensions

extension Calendar {
    /// 해당 월의 날짜들
    func datesInMonth(for date: Date) -> [Date] {
        guard let range = self.range(of: .day, in: .month, for: date),
              let startOfMonth = self.date(from: self.dateComponents([.year, .month], from: date)) else {
            return []
        }
        
        return range.compactMap { day -> Date? in
            self.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
    
    /// 해당 주의 날짜들
    func datesInWeek(for date: Date) -> [Date] {
        guard let startOfWeek = self.date(from: self.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else {
            return []
        }
        
        return (0..<7).compactMap { day in
            self.date(byAdding: .day, value: day, to: startOfWeek)
        }
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {
    /// 분으로 변환
    var minutes: Double {
        self / 60
    }
    
    /// 시간으로 변환
    var hours: Double {
        self / 3600
    }
    
    /// 일로 변환
    var days: Double {
        self / 86400
    }
    
    /// 시:분:초 문자열
    var timeString: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Optional Extensions

extension Optional where Wrapped == String {
    /// nil이거나 빈 문자열인지 확인
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
    
    /// nil이면 빈 문자열 반환
    var orEmpty: String {
        self ?? ""
    }
}

// MARK: - Data Extensions

extension Data {
    /// MB 단위 크기
    var megabytes: Double {
        Double(count) / 1_048_576
    }
    
    /// KB 단위 크기
    var kilobytes: Double {
        Double(count) / 1_024
    }
}
