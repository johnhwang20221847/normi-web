// ============================================================
//  DesignSystem.swift
//  노르미 디자인 시스템 — 컬러, 타이포, 공통 스타일
// ============================================================

import SwiftUI

// MARK: - Brand Colors

extension Color {
    // Primary
    static let normiNavy    = Color(hex: "#1A2B5E")  // 메인 네이비
    static let normiBlue    = Color(hex: "#3B7FE8")  // 강조 블루
    static let normiSky     = Color(hex: "#E8F1FF")  // 연한 배경 블루
    static let normiOrange  = Color(hex: "#F4A928")  // 따뜻한 오렌지 (날씨 아이콘)
    static let normiGreen   = Color(hex: "#4CAF82")  // 초록 (좋음/운행중)
    static let normiRed     = Color(hex: "#E85353")  // 경고/오류
    static let normiGray    = Color(hex: "#F5F6FA")  // 배경 그레이
    static let normiText    = Color(hex: "#1E2330")  // 기본 텍스트
    static let normiSubText = Color(hex: "#8E95A5")  // 보조 텍스트

    // Category Colors
    static let categoryMarket  = Color(hex: "#FF8C42")
    static let categoryNature  = Color(hex: "#4CAF82")
    static let categorySpa     = Color(hex: "#7B68EE")
    static let categoryFree    = Color(hex: "#3B7FE8")

    // Line Colors (지하철)
    static func subwayLine(_ code: Int) -> Color {
        switch code {
        case 1:  return Color(hex: "#0052A4")
        case 2:  return Color(hex: "#00A84D")
        case 3:  return Color(hex: "#EF7C1C")
        case 4:  return Color(hex: "#00A5DE")
        case 5:  return Color(hex: "#996CAC")
        case 6:  return Color(hex: "#CD7C2F")
        case 7:  return Color(hex: "#747F00")
        case 8:  return Color(hex: "#E6186C")
        case 9:  return Color(hex: "#BDB092")
        default: return Color(hex: "#888888")
        }
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a,r,g,b) = (255,(int>>8)*17,(int>>4&0xF)*17,(int&0xF)*17)
        case 6: (a,r,g,b) = (255,int>>16,int>>8&0xFF,int&0xFF)
        case 8: (a,r,g,b) = (int>>24,int>>16&0xFF,int>>8&0xFF,int&0xFF)
        default:(a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB,
                  red:   Double(r)/255,
                  green: Double(g)/255,
                  blue:  Double(b)/255,
                  opacity: Double(a)/255)
    }
}

// MARK: - Typography

extension Font {
    static let normiLargeTitle  = Font.system(size: 32, weight: .bold,   design: .rounded)
    static let normiTitle       = Font.system(size: 24, weight: .bold,   design: .rounded)
    static let normiTitle2      = Font.system(size: 20, weight: .bold,   design: .rounded)
    static let normiHeadline    = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let normiBody        = Font.system(size: 15, weight: .regular, design: .rounded)
    static let normiCaption     = Font.system(size: 13, weight: .regular, design: .rounded)
    static let normiCaption2    = Font.system(size: 11, weight: .regular, design: .rounded)
}

// MARK: - Card Style

struct NormiCard: ViewModifier {
    var padding: CGFloat = 16
    var radius: CGFloat  = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.white)
            .cornerRadius(radius)
            .shadow(color: Color.normiNavy.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func normiCard(padding: CGFloat = 16, radius: CGFloat = 16) -> some View {
        modifier(NormiCard(padding: padding, radius: radius))
    }
}

// MARK: - Primary Button Style

struct NormiPrimaryButton: ButtonStyle {
    var color: Color = .normiBlue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.normiHeadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1))
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Badge

struct NormiBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.normiCaption2.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(20)
    }
}
