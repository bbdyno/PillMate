//
//  DesignSystem.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI

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
    
    /// 아주 연한 하늘색 (배경용)
    static let primarySoft = Color(hex: "E8F4FD")
    
    // MARK: - Secondary (보조색)
    
    /// 민트색
    static let mint = Color(hex: "5ECFB8")
    
    /// 라벤더
    static let lavender = Color(hex: "9B8FD9")
    
    /// 피치
    static let peach = Color(hex: "F5A88E")
    
    /// 레몬
    static let lemon = Color(hex: "F5D76E")
    
    // MARK: - Semantic Colors
    
    /// 성공 (초록)
    static let success = Color(hex: "4CAF93")
    
    /// 경고 (주황)
    static let warning = Color(hex: "F5A623")
    
    /// 위험 (빨강)
    static let danger = Color(hex: "E57373")
    
    /// 정보 (파랑)
    static let info = Color(hex: "64B5F6")
    
    // MARK: - Neutral Colors
    
    /// 텍스트 색상
    static let textPrimary = Color(hex: "1A2B4A")
    static let textSecondary = Color(hex: "6B7D99")
    static let textTertiary = Color(hex: "9CADC4")
    
    /// 배경 색상
    static let background = Color(hex: "F5F9FC")
    static let cardBackground = Color.white
    static let surfaceElevated = Color(hex: "FFFFFF")
    
    /// 구분선
    static let divider = Color(hex: "E5EBF1")
    
    // MARK: - Gradients
    
    /// 메인 그라데이션
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "4A90D9"), Color(hex: "7EB8F0")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 성공 그라데이션
    static let successGradient = LinearGradient(
        colors: [Color(hex: "4CAF93"), Color(hex: "7DD3BE")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 헤더 그라데이션
    static let headerGradient = LinearGradient(
        colors: [Color(hex: "4A90D9"), Color(hex: "6BA8E5"), Color(hex: "7EB8F0")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 카드 그라데이션 (미묘한)
    static let cardGradient = LinearGradient(
        colors: [Color.white, Color(hex: "F8FBFD")],
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
    var padding: CGFloat = AppSpacing.md
    var cornerRadius: CGFloat = AppRadius.lg
    var shadow: Bool = true
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadow ? Color.black.opacity(0.06) : .clear,
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

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(AppColors.primaryGradient)
            
            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let buttonTitle = buttonTitle, let action = action {
                Button(buttonTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(width: 200)
            }
        }
        .padding(AppSpacing.xxl)
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
