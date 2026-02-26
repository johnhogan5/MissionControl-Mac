import SwiftUI

// MARK: - Spacing
enum MCSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radii
enum MCCorner {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let pill: CGFloat = 999
}

// MARK: - Colors (Dark theme matching Figma)
enum MCColor {
    static let bg = Color(red: 0.09, green: 0.09, blue: 0.09)           // #171717
    static let sidebarBg = Color(red: 0.11, green: 0.11, blue: 0.11)    // #1C1C1C
    static let cardBg = Color(red: 0.14, green: 0.14, blue: 0.14)       // #242424
    static let cardBorder = Color.white.opacity(0.06)
    static let cardBgHover = Color(red: 0.18, green: 0.18, blue: 0.18)
    static let accent = Color(red: 0.35, green: 0.55, blue: 1.0)        // blue accent
    static let green = Color(red: 0.30, green: 0.85, blue: 0.45)
    static let orange = Color(red: 1.0, green: 0.65, blue: 0.25)
    static let red = Color(red: 0.95, green: 0.30, blue: 0.30)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.78)
    static let textTertiary = Color.white.opacity(0.58)
    static let sidebarSelected = Color.white.opacity(0.08)
    static let divider = Color.white.opacity(0.06)
}

// Back-compat with older view files
enum MCPalette {
    static let assistant = MCColor.cardBgHover
    static let user = MCColor.accent.opacity(0.28)
}

// MARK: - Typography
enum MCFont {
    static let pageTitle = Font.system(size: 28, weight: .bold)
    static let pageSubtitle = Font.system(size: 14, weight: .regular)
    static let sectionTitle = Font.system(size: 18, weight: .semibold)
    static let cardTitle = Font.system(size: 13, weight: .semibold)
    static let cardValue = Font.system(size: 22, weight: .bold)
    static let cardHint = Font.system(size: 12, weight: .regular)
    static let sidebarItem = Font.system(size: 13, weight: .medium)
    static let sidebarSection = Font.system(size: 11, weight: .medium)
    static let body = Font.system(size: 14, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
    static let tiny = Font.system(size: 11, weight: .regular)
}

// MARK: - Card Component
struct MCCard<Content: View>: View {
    var padding: CGFloat = MCSpacing.lg
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(MCColor.cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: MCCorner.lg, style: .continuous)
                    .stroke(MCColor.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: MCCorner.lg, style: .continuous))
    }
}

// MARK: - Status Dot
struct StatusDot: View {
    let color: Color
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }
}

// Backward-compatible wrappers used by existing views
struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { MCCard { content } }
}

struct AppBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [MCColor.bg, MCColor.bg.opacity(0.98)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
