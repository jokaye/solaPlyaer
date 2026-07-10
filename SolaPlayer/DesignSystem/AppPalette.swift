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

    var colors: [Color] {
        switch self {
        case .clearSky:
            [Color(red: 0.29, green: 0.66, blue: 1.0), Color(red: 0.56, green: 0.79, blue: 1.0), Color(red: 0.86, green: 0.93, blue: 1.0)]
        case .lake:
            [Color(red: 0.09, green: 0.70, blue: 0.78), Color(red: 0.50, green: 0.88, blue: 0.90), Color(red: 0.88, green: 0.97, blue: 0.97)]
        case .mint:
            [Color(red: 0.18, green: 0.79, blue: 0.54), Color(red: 0.56, green: 0.90, blue: 0.74), Color(red: 0.89, green: 0.97, blue: 0.93)]
        case .ocean:
            [Color(red: 0.06, green: 0.56, blue: 0.84), Color(red: 0.25, green: 0.82, blue: 0.75), Color(red: 0.77, green: 0.95, blue: 0.91)]
        case .azure:
            [Color(red: 0.35, green: 0.69, blue: 1.0), Color(red: 0.39, green: 0.84, blue: 0.76), Color(red: 0.80, green: 0.96, blue: 0.89)]
        case .aqua:
            [Color(red: 0.0, green: 0.74, blue: 0.83), Color(red: 0.37, green: 0.88, blue: 0.72), Color(red: 0.85, green: 0.97, blue: 0.94)]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: colors[0], location: 0),
                .init(color: colors[1], location: 0.52),
                .init(color: colors[2], location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
