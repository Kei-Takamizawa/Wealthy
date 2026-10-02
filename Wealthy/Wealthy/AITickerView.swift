// xcode: set sdk=iOS

//
//  AITickerView.swift
//  Wealthy
//
//  Created by Harrison on 12/28/25.
//

import SwiftUI

private struct TickerCentersKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]

    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, newest in newest })
    }
}

private struct TickerWidthMeasurement: Equatable {
    let text: String
    let width: CGFloat
}

private struct TickerWidthKey: PreferenceKey {
    static var defaultValue = TickerWidthMeasurement(text: "", width: 0)

    static func reduce(value: inout TickerWidthMeasurement, nextValue: () -> TickerWidthMeasurement) {
        value = nextValue()
    }
}

struct AITickerView: View {
    let text: String
    let onTapSparkle: () -> Void
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animationStart: Date?
    @State private var didFinish = false
    @State private var contentWidth: CGFloat = 0
    @State private var measuredText = ""
    @State private var containerWidth: CGFloat = 0
    @State private var characterCenters: [Int: CGFloat] = [:]

    private let reduceMotionOverride: Bool?
    private let staticRenderDate: Date?
    private let fontSize: CGFloat = 16
    private let speed: CGFloat = 42
    private let leadingInset: CGFloat = 70

    init(
        text: String,
        onTapSparkle: @escaping () -> Void,
        onFinish: @escaping () -> Void,
        staticRenderDate: Date? = nil,
        staticAnimationStartDate: Date? = nil,
        reduceMotionOverride: Bool? = nil
    ) {
        self.text = text
        self.onTapSparkle = onTapSparkle
        self.onFinish = onFinish
        self.staticRenderDate = staticRenderDate
        self.reduceMotionOverride = reduceMotionOverride
        _animationStart = State(initialValue: staticAnimationStartDate)
    }

    private var usesReducedMotion: Bool {
        reduceMotionOverride ?? reduceMotion
    }

    var body: some View {
        Group {
            if usesReducedMotion {
                reducedMotionTicker
            } else {
                animatedTicker
            }
        }
        .frame(minHeight: 42)
        .task(id: text) {
            didFinish = false
            guard !text.isEmpty, staticRenderDate == nil else { return }
            animationStart = nil

            if usesReducedMotion {
                let readingDuration = max(4, min(18, Double(text.count) / 12))
                do {
                    try await Task.sleep(for: .seconds(readingDuration))
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                didFinish = true
                onFinish()
                return
            }

            let measurementDeadline = Date().addingTimeInterval(1)
            while !Task.isCancelled && Date() < measurementDeadline &&
                (containerWidth <= 0 || contentWidth <= 0 || measuredText != text) {
                try? await Task.sleep(for: .milliseconds(20))
            }
            guard !Task.isCancelled else { return }

            if measuredText != text || contentWidth <= 0 {
                contentWidth = CGFloat(text.count) * (fontSize + 4) + leadingInset
            }

            animationStart = Date()
            let duration = Double((containerWidth + contentWidth) / speed)
            do {
                try await Task.sleep(for: .seconds(duration))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            didFinish = true
            onFinish()
        }
    }

    private var animatedTicker: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: didFinish || staticRenderDate != nil)) { timeline in
                let displayDate = staticRenderDate ?? timeline.date
                let viewportWidth = geometry.size.width
                let measuredOrEstimatedTextWidth = contentWidth > 0 ? contentWidth : CGFloat(text.count) * (fontSize + 4) + leadingInset
                let offsetX = tickerOffset(at: displayDate, viewportWidth: viewportWidth, textWidth: measuredOrEstimatedTextWidth)

                ZStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                            let fallbackCenter = leadingInset + CGFloat(index) * (fontSize + 4) + offsetX + (fontSize + 4) / 2
                            let effect = AITickerProjection.effect(centerX: characterCenters[index] ?? fallbackCenter, in: viewportWidth)

                            Text(String(character))
                                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 2)
                                .scaleEffect(effect.scale, anchor: .center)
                                .blur(radius: effect.blurRadius)
                                .opacity(effect.opacity)
                                .accessibilityHidden(true)
                                .background {
                                    GeometryReader { glyphGeometry in
                                        Color.clear.preference(
                                            key: TickerCentersKey.self,
                                            value: [index: glyphGeometry.frame(in: .named("tickerViewport")).midX]
                                        )
                                    }
                                }
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.leading, leadingInset)
                    .background {
                        GeometryReader { textGeometry in
                            Color.clear.preference(
                                key: TickerWidthKey.self,
                                value: TickerWidthMeasurement(text: text, width: textGeometry.size.width)
                            )
                        }
                    }
                    .offset(x: offsetX)
                    .frame(height: geometry.size.height, alignment: .center)
                    .onPreferenceChange(TickerCentersKey.self) { characterCenters = $0 }
                    .onPreferenceChange(TickerWidthKey.self) { measurement in
                        measuredText = measurement.text
                        if abs(contentWidth - measurement.width) > 0.5 { contentWidth = measurement.width }
                    }

                    HStack {
                        sparkleButton
                        Spacer(minLength: 0)
                    }
                }
                .coordinateSpace(name: "tickerViewport")
                .clipped()
                .onAppear { containerWidth = geometry.size.width }
                .onChange(of: geometry.size.width) { _, width in containerWidth = width }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(text)
            }
        }
        .frame(height: 42)
    }

    private var reducedMotionTicker: some View {
        HStack(alignment: .top, spacing: 8) {
            sparkleButton
            Text(text)
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
    }

    private var sparkleButton: some View {
        Button(action: onTapSparkle) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.yellow)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show AI advice")
    }

    private func tickerOffset(at date: Date, viewportWidth: CGFloat, textWidth: CGFloat) -> CGFloat {
        guard viewportWidth > 0 else { return 0 }
        if usesReducedMotion { return (viewportWidth - textWidth) / 2 }
        guard let animationStart else { return viewportWidth }

        let distance = viewportWidth + textWidth
        let duration = Double(distance / speed)
        let elapsed = min(duration, max(0, date.timeIntervalSince(animationStart)))
        return viewportWidth - CGFloat(elapsed) * speed
    }
}

#Preview {
    AITickerView(
        text: "お財布が一息。今月の黒字を少し貯金に回しましょう。",
        onTapSparkle: {},
        onFinish: {}
    )
    .frame(width: 350)
    .background(.black)
    .environment(\.colorScheme, .dark)
    .padding()
}
