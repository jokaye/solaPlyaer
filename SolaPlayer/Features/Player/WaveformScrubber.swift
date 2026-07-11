import SwiftUI

struct WaveformScrubber: View {
    let samples: [Float]
    let progress: Double
    let duration: TimeInterval
    let markers: [Marker]
    let isScrubbing: Bool
    let onChanged: (Double) -> Void
    let onEnded: (Double) -> Void
    let onAdjustTime: (TimeInterval) -> Void

    private var headIndex: Int {
        guard samples.isEmpty == false else {
            return 0
        }
        return Int((progress * Double(samples.count - 1)).rounded())
    }

    private var activeMarkerID: UUID? {
        guard isScrubbing, duration > 0, samples.isEmpty == false else {
            return nil
        }
        let threshold = duration / Double(samples.count) / 2
        let currentTime = progress * duration
        return markers.first(where: { abs($0.time - currentTime) <= threshold })?.id
    }

    private var hapticHeadIndex: Int? {
        guard isScrubbing,
              activeMarkerID == nil,
              headIndex != 0,
              headIndex != samples.count - 1 else {
            return nil
        }
        return headIndex
    }

    private var boundaryHeadIndex: Int? {
        guard isScrubbing, activeMarkerID == nil, samples.isEmpty == false,
              headIndex == 0 || headIndex == samples.count - 1 else {
            return nil
        }
        return headIndex
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    drawWaveform(in: context, size: size)
                }

                ScrubberPillView(text: (progress * duration).durationText)
                    .offset(x: pillOffset(for: proxy.size.width))

                ForEach(markers) { marker in
                    Text(marker.time.durationText)
                        .appFont(AppTypography.flag)
                        .foregroundStyle(AppColor.ink)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(AppColor.marker, in: .capsule)
                        .offset(x: markerOffset(time: marker.time, width: proxy.size.width), y: 24)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(.rect)
            .gesture(dragGesture(width: proxy.size.width))
        }
        .sensoryFeedback(AppHaptic.selection, trigger: hapticHeadIndex)
        .sensoryFeedback(AppHaptic.boundary, trigger: boundaryHeadIndex)
        .sensoryFeedback(AppHaptic.marker, trigger: activeMarkerID)
        .accessibilityElement()
        .accessibilityLabel("播放进度")
        .accessibilityValue(
            "\((progress * duration).durationText)，总时长 \(duration.durationText)，\(markers.count) 个标记"
        )
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                onAdjustTime(5)
            case .decrement:
                onAdjustTime(-5)
            @unknown default:
                break
            }
        }
    }

    private func drawWaveform(in context: GraphicsContext, size: CGSize) {
        guard samples.isEmpty == false else {
            return
        }

        let topInset: CGFloat = 30
        let availableHeight = max(size.height - topInset, 1)
        let spacing: CGFloat = 2
        let totalSpacing = spacing * CGFloat(samples.count - 1)
        let barWidth = max((size.width - totalSpacing) / CGFloat(samples.count), 1)

        for (index, sample) in samples.enumerated() {
            let amplitude = min(max(CGFloat(sample), 0.14), 1)
            let baseHeight = availableHeight * (0.14 + amplitude * 0.8)
            let height = isScrubbing && index == headIndex
                ? min(baseHeight * 1.12, availableHeight)
                : baseHeight
            let x = CGFloat(index) * (barWidth + spacing)
            let rect = CGRect(
                x: x,
                y: topInset + (availableHeight - height) / 2,
                width: barWidth,
                height: height
            )
            let normalizedIndex = Double(index) / Double(max(samples.count - 1, 1))
            let color = normalizedIndex <= progress ? Color.white : Color.white.opacity(0.32)
            context.fill(
                Path(roundedRect: rect, cornerRadius: min(AppRadius.waveformBar, barWidth / 2)),
                with: .color(color)
            )
        }


        guard duration > 0 else {
            return
        }
        for marker in markers {
            let normalizedTime = min(max(marker.time / duration, 0), 1)
            let x = CGFloat(normalizedTime) * size.width
            let line = CGRect(x: x - 1, y: 30, width: 2, height: max(size.height - 30, 1))
            context.fill(Path(line), with: .color(AppColor.marker))
        }
    }

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                onChanged(normalizedProgress(x: value.location.x, width: width))
            }
            .onEnded { value in
                onEnded(normalizedProgress(x: value.location.x, width: width))
            }
    }

    private func normalizedProgress(x: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else {
            return 0
        }
        return min(max(Double(x / width), 0), 1)
    }

    private func pillOffset(for width: CGFloat) -> CGFloat {
        min(max(CGFloat(progress) * width - 28, 0), max(width - 56, 0))
    }

    private func markerOffset(time: TimeInterval, width: CGFloat) -> CGFloat {
        guard duration > 0 else {
            return 0
        }
        let normalizedTime = min(max(time / duration, 0), 1)
        return min(max(CGFloat(normalizedTime) * width - 20, 0), max(width - 40, 0))
    }
}
