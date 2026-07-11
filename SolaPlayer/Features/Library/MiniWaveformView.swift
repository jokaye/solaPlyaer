import SwiftUI

struct MiniWaveformView: View {
    let seed: UUID

    var body: some View {
        Canvas { context, size in
            let bars = 12
            let spacing: CGFloat = 2
            let barWidth = max((size.width - spacing * CGFloat(bars - 1)) / CGFloat(bars), 1)
            let bytes = withUnsafeBytes(of: seed.uuid) { Array($0) }

            for index in 0..<bars {
                let value = CGFloat(bytes[index % bytes.count]) / 255
                let height = size.height * (0.28 + value * 0.68)
                let rect = CGRect(
                    x: CGFloat(index) * (barWidth + spacing),
                    y: (size.height - height) / 2,
                    width: barWidth,
                    height: height
                )
                context.fill(
                    Path(roundedRect: rect, cornerRadius: barWidth / 2),
                    with: .color(.white.opacity(0.94))
                )
            }
        }
        .accessibilityHidden(true)
    }
}
