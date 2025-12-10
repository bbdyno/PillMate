//
//  DesignSystem.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI

// MARK: - Color Helpers

extension Color {
    /// 라이트/다크 모드에 따라 자동으로 변경되는 색상 생성
    static func adaptive(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - App Colors

/// 앱 컬러 팔레트 (하늘색 테마)
struct AppColors {
    // MARK: - Primary (하늘색 계열)
    
    /// 메인 하늘색
    static let primary = Color(hex: "4A90D9")
    
    /// 밝은 하늘색
    static let primaryLight = Color(hex: "7EB8F0")
    
    /// 진한 하늘색
    static let primaryDark = Color(hex: "2E6BB0")

    /// 아주 연한 하늘색 (배경용, 다크모드 대응)
    static let primarySoft = Color.adaptive(
        light: Color(hex: "E8F4FD"),
        dark: Color(hex: "1A2F47")
    )
    
    // MARK: - Secondary (보조색)
    
    /// 민트색
    static let mint = Color(hex: "5ECFB8")
    
    /// 라벤더
    static let lavender = Color(hex: "9B8FD9")
    
    /// 피치
    static let peach = Color(hex: "F5A88E")
    
    /// 레몬
    static let lemon = Color(hex: "F5D76E")
    
    // MARK: - Semantic Colors (다크모드 대응)

    /// 성공 (초록)
    static let success = Color.adaptive(
        light: Color(hex: "4CAF93"),
        dark: Color(hex: "66BB9A")
    )

    /// 경고 (주황)
    static let warning = Color.adaptive(
        light: Color(hex: "F5A623"),
        dark: Color(hex: "FFB74D")
    )

    /// 위험 (빨강)
    static let danger = Color.adaptive(
        light: Color(hex: "E57373"),
        dark: Color(hex: "EF9A9A")
    )

    /// 정보 (파랑)
    static let info = Color.adaptive(
        light: Color(hex: "64B5F6"),
        dark: Color(hex: "81C9FA")
    )

    // MARK: - Chart Colors (다크모드 대응)

    /// 차트 초록
    static let chartGreen = Color.adaptive(
        light: Color(hex: "4CAF50"),
        dark: Color(hex: "66BB6A")
    )

    /// 차트 주황
    static let chartOrange = Color.adaptive(
        light: Color(hex: "FF9800"),
        dark: Color(hex: "FFB74D")
    )

    /// 차트 빨강
    static let chartRed = Color.adaptive(
        light: Color(hex: "F44336"),
        dark: Color(hex: "E57373")
    )

    /// 차트 파랑
    static let chartBlue = Color.adaptive(
        light: Color(hex: "2196F3"),
        dark: Color(hex: "64B5F6")
    )

    /// 차트 보라
    static let chartPurple = Color.adaptive(
        light: Color(hex: "9C27B0"),
        dark: Color(hex: "BA68C8")
    )

    /// 차트 회색
    static let chartGray = Color.adaptive(
        light: Color(hex: "9E9E9E"),
        dark: Color(hex: "BDBDBD")
    )

    // MARK: - Premium Colors (다크모드 대응)

    /// 프리미엄 골드
    static let premiumGold = Color.adaptive(
        light: Color(hex: "FFD700"),
        dark: Color(hex: "FFE55C")
    )

    /// 프리미엄 블루
    static let premiumBlue = Color.adaptive(
        light: Color(hex: "4A90D9"),
        dark: Color(hex: "5B9FE3")
    )

    /// 프리미엄 퍼플
    static let premiumPurple = Color.adaptive(
        light: Color(hex: "9B8FD9"),
        dark: Color(hex: "A99FE3")
    )

    /// 프리미엄 핑크
    static let premiumPink = Color.adaptive(
        light: Color(hex: "E91E63"),
        dark: Color(hex: "F48FB1")
    )
    
    // MARK: - Neutral Colors

    /// 텍스트 색상 (다크모드 대응)
    static let textPrimary = Color.adaptive(
        light: Color(hex: "1A2B4A"),
        dark: Color(hex: "F0F0F0")
    )
    static let textSecondary = Color.adaptive(
        light: Color(hex: "6B7D99"),
        dark: Color(hex: "A8B4C8")
    )
    static let textTertiary = Color.adaptive(
        light: Color(hex: "9CADC4"),
        dark: Color(hex: "6B7D99")
    )

    /// 배경 색상 (다크모드 대응)
    static let background = Color.adaptive(
        light: Color(hex: "F5F9FC"),
        dark: Color(hex: "0A0E14")
    )
    static let cardBackground = Color.adaptive(
        light: Color.white,
        dark: Color(hex: "1A1F28")
    )
    static let surfaceElevated = Color.adaptive(
        light: Color(hex: "FFFFFF"),
        dark: Color(hex: "1E2430")
    )

    /// 구분선 (다크모드 대응)
    static let divider = Color.adaptive(
        light: Color(hex: "E5EBF1"),
        dark: Color(hex: "2A3140")
    )
    
    // MARK: - Gradients (다크모드 대응)

    /// 메인 그라데이션
    static let primaryGradient = LinearGradient(
        colors: [
            Color.adaptive(light: Color(hex: "4A90D9"), dark: Color(hex: "5B9FE3")),
            Color.adaptive(light: Color(hex: "7EB8F0"), dark: Color(hex: "90C8F5"))
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 성공 그라데이션
    static let successGradient = LinearGradient(
        colors: [
            Color.adaptive(light: Color(hex: "4CAF93"), dark: Color(hex: "66BB9A")),
            Color.adaptive(light: Color(hex: "7DD3BE"), dark: Color(hex: "8FE0CB"))
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 헤더 그라데이션 (다크모드에서 눈의 피로도를 줄이기 위해 어두운 버전 사용)
    static let headerGradient = LinearGradient(
        colors: [
            Color.adaptive(light: Color(hex: "4A90D9"), dark: Color(hex: "2A5080")),
            Color.adaptive(light: Color(hex: "6BA8E5"), dark: Color(hex: "355F92")),
            Color.adaptive(light: Color(hex: "7EB8F0"), dark: Color(hex: "4070A8"))
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 프리미엄 그라데이션
    static let premiumGradient = LinearGradient(
        colors: [
            Color.adaptive(light: Color(hex: "4A90D9"), dark: Color(hex: "5B9FE3")),
            Color.adaptive(light: Color(hex: "9B8FD9"), dark: Color(hex: "A99FE3"))
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// 카드 그라데이션 (미묘한, 다크모드 대응)
    static let cardGradient = LinearGradient(
        colors: [
            Color.adaptive(light: Color.white, dark: Color(hex: "1A1F28")),
            Color.adaptive(light: Color(hex: "F8FBFD"), dark: Color(hex: "151A22"))
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - App Typography

struct AppTypography {
    // 헤더
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    // 본문
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    
    // 작은 텍스트
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    
    // 숫자
    static let number = Font.system(size: 34, weight: .bold, design: .rounded)
    static let numberSmall = Font.system(size: 24, weight: .bold, design: .rounded)
}

// MARK: - App Spacing

struct AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
}

// MARK: - App Radius

struct AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let full: CGFloat = 100
}

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var padding: CGFloat = AppSpacing.md
    var cornerRadius: CGFloat = AppRadius.lg
    var shadow: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadow ? (colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.06)) : .clear,
                radius: 12,
                x: 0,
                y: 4
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = AppSpacing.md, cornerRadius: CGFloat = AppRadius.lg, shadow: Bool = true) -> some View {
        modifier(CardStyle(padding: padding, cornerRadius: cornerRadius, shadow: shadow))
    }
}

// MARK: - Glass Card Style

struct GlassCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.md)
            .background(.ultraThinMaterial)
            .cornerRadius(AppRadius.lg)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCardStyle())
    }
}

// MARK: - Primary Button Style

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                Group {
                    if isEnabled {
                        AppColors.primaryGradient
                    } else {
                        LinearGradient(colors: [AppColors.textTertiary], startPoint: .leading, endPoint: .trailing)
                    }
                }
            )
            .cornerRadius(AppRadius.md)
            .shadow(color: isEnabled ? AppColors.primary.opacity(0.3) : .clear, radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline)
            .foregroundColor(AppColors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.primarySoft)
            .cornerRadius(AppRadius.md)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Chip Style

struct ChipStyle: ViewModifier {
    let isSelected: Bool
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(isSelected ? color.opacity(0.15) : AppColors.cardBackground)
            .foregroundColor(isSelected ? color : AppColors.textSecondary)
            .cornerRadius(AppRadius.full)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.full)
                    .stroke(isSelected ? color : AppColors.divider, lineWidth: isSelected ? 1.5 : 1)
            )
    }
}

extension View {
    func chipStyle(isSelected: Bool, color: Color = AppColors.primary) -> some View {
        modifier(ChipStyle(isSelected: isSelected, color: color))
    }
}

// MARK: - Icon Badge

struct IconBadge: View {
    let icon: String
    let color: Color
    var size: CGFloat = 44
    var iconSize: CGFloat = 20
    
    var body: some View {
        Circle()
            .fill(color.opacity(0.15))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(color)
            )
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var size: CGFloat = 80
    var color: Color = AppColors.primary
    var showPercentage: Bool = true
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.8), value: progress)
            
            // Percentage text
            if showPercentage {
                VStack(spacing: 0) {
                    Text("\(Int(progress * 100))")
                        .font(AppTypography.numberSmall)
                        .foregroundColor(AppColors.textPrimary)
                    Text("%")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Animated Checkmark

struct AnimatedCheckmark: View {
    let isChecked: Bool
    var size: CGFloat = 28
    var color: Color = AppColors.success
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isChecked ? color : AppColors.divider)
                .frame(width: size, height: size)
            
            if isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundColor(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: isChecked)
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.5),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Empty State View (표준 Empty State)

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            ZStack {
                Circle()
                    .fill(AppColors.primarySoft)
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(AppColors.primaryGradient)
            }

            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)

                Text(description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let buttonTitle = buttonTitle, let action = action {
                Button {
                    action()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(buttonTitle)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 200)
            }
        }
        .padding(AppSpacing.xl)
    }
}

// MARK: - Standard Header Card (표준 헤더 카드)

struct StandardHeaderCard: View {
    let icon: String
    let title: String
    let subtitle: String
    var iconSize: CGFloat = 24
    var circleSize: CGFloat = 60

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(AppColors.primaryGradient)
                    .frame(width: circleSize, height: circleSize)

                Image(systemName: icon)
                    .font(.system(size: iconSize))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)

                Text(subtitle)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadius.xl)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }
}

// MARK: - Add Button (표준 추가 버튼)

struct AddButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundColor(AppColors.primary)
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var actionTitle: String = "더보기"
    
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.primary)
                }
            }
        }
        .padding(.horizontal, AppSpacing.xs)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    enum Status {
        case success, warning, danger, info, pending
        
        var color: Color {
            switch self {
            case .success: return AppColors.success
            case .warning: return AppColors.warning
            case .danger: return AppColors.danger
            case .info: return AppColors.info
            case .pending: return AppColors.textTertiary
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .danger: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            case .pending: return "clock.fill"
            }
        }
    }
    
    let text: String
    let status: Status
    var showIcon: Bool = true
    
    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: status.icon)
                    .font(.caption2)
            }
            Text(text)
                .font(AppTypography.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(status.color)
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.12))
        .cornerRadius(AppRadius.sm)
    }
}

// MARK: - Preview

#Preview("Design System") {
    ScrollView {
        VStack(spacing: AppSpacing.xl) {
            // Colors
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Colors")
                    .font(AppTypography.headline)
                
                HStack(spacing: AppSpacing.sm) {
                    ColorSwatch(color: AppColors.primary, name: "Primary")
                    ColorSwatch(color: AppColors.primaryLight, name: "Light")
                    ColorSwatch(color: AppColors.primaryDark, name: "Dark")
                    ColorSwatch(color: AppColors.primarySoft, name: "Soft")
                }
            }
            .cardStyle()
            
            // Progress Rings
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Progress")
                    .font(AppTypography.headline)
                
                HStack(spacing: AppSpacing.lg) {
                    ProgressRing(progress: 0.85, color: AppColors.success)
                    ProgressRing(progress: 0.60, color: AppColors.warning)
                    ProgressRing(progress: 0.30, color: AppColors.danger)
                }
            }
            .cardStyle()
            
            // Buttons
            VStack(spacing: AppSpacing.sm) {
                Button("Primary Button") {}
                    .buttonStyle(PrimaryButtonStyle())
                
                Button("Secondary Button") {}
                    .buttonStyle(SecondaryButtonStyle())
            }
            .cardStyle()
            
            // Status Badges
            HStack(spacing: AppSpacing.sm) {
                StatusBadge(text: "완료", status: .success)
                StatusBadge(text: "대기", status: .pending)
                StatusBadge(text: "경고", status: .warning)
                StatusBadge(text: "실패", status: .danger)
            }
            .cardStyle()
        }
        .padding()
    }
    .background(AppColors.background)
}

struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 50, height: 50)
            Text(name)
                .font(.caption2)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}
