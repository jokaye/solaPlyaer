import SwiftUI

enum AppPalette: String, CaseIterable, Identifiable {
    case clearSky
    case lake
    case mint
    case ocean
    case azure
    case aqua

    var id: String { rawValue }

    var label: String {
        switch self {
        case .clearSky: "晴空"
        case .lake: "湖水"
        case .mint: "薄荷"
        case .ocean: "海洋"
        case .azure: "天青"
        case .aqua: "水绿"
        }
    }

    var colors: AppGradientColors {
        switch self {
        case .clearSky:
            AppGradientColors(
                top: Color(red: 74 / 255, green: 168 / 255, blue: 255 / 255),
                middle: Color(red: 143 / 255, green: 201 / 255, blue: 255 / 255),
                bottom: Color(red: 219 / 255, green: 238 / 255, blue: 255 / 255)
            )
        case .lake:
            AppGradientColors(
                top: Color(red: 23 / 255, green: 179 / 255, blue: 198 / 255),
                middle: Color(red: 127 / 255, green: 224 / 255, blue: 230 / 255),
                bottom: Color(red: 224 / 255, green: 247 / 255, blue: 247 / 255)
            )
        case .mint:
            AppGradientColors(
                top: Color(red: 46 / 255, green: 201 / 255, blue: 138 / 255),
                middle: Color(red: 143 / 255, green: 230 / 255, blue: 189 / 255),
                bottom: Color(red: 226 / 255, green: 248 / 255, blue: 236 / 255)
            )
        case .ocean:
            AppGradientColors(
                top: Color(red: 15 / 255, green: 143 / 255, blue: 214 / 255),
                middle: Color(red: 63 / 255, green: 208 / 255, blue: 192 / 255),
                bottom: Color(red: 196 / 255, green: 242 / 255, blue: 232 / 255)
            )
        case .azure:
            AppGradientColors(
                top: Color(red: 90 / 255, green: 176 / 255, blue: 255 / 255),
                middle: Color(red: 99 / 255, green: 214 / 255, blue: 194 / 255),
                bottom: Color(red: 205 / 255, green: 246 / 255, blue: 228 / 255)
            )
        case .aqua:
            AppGradientColors(
                top: Color(red: 0 / 255, green: 188 / 255, blue: 212 / 255),
                middle: Color(red: 95 / 255, green: 224 / 255, blue: 184 / 255),
                bottom: Color(red: 218 / 255, green: 247 / 255, blue: 239 / 255)
            )
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: colors.top, location: 0),
                .init(color: colors.middle, location: 0.52),
                .init(color: colors.bottom, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
