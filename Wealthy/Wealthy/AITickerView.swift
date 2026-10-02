// xcode: set sdk=iOS

//
//  AITickerView.swift
//  Wealthy
//
//  Created by Harrison on 12/28/25.
//

import SwiftUI

/// Draw system-shaped glyphs so Arabic joining and Indic ligatures survive the curve effect.
nonisolated private struct CurvedTickerRenderer: TextRenderer {
    let viewportWidth: CGFloat
    let textOriginX: CGFloat

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            for run in line {
                for glyph in run {
                    let bounds = glyph.typographicBounds.rect
                    let effect = AITickerProjection.effect(centerX: textOriginX + bounds.midX, in: viewportWidth)
                    var glyphContext = context
                    glyphContext.opacity *= effect.opacity
                    glyphContext.addFilter(.blur(radius: effect.blurRadius))
                    glyphContext.translateBy(x: bounds.midX, y: bounds.midY)
                    glyphContext.scaleBy(x: effect.scale, y: effect.scale)
                    glyphContext.translateBy(x: -bounds.midX, y: -bounds.midY)
                    glyphContext.draw(glyph)
                }
            }
        }
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
    @Environment(\.locale) private var locale
    let text: String
    let onTapSparkle: () -> Void
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animationStart: Date?
    @State private var didFinish = false
    @State private var contentWidth: CGFloat = 0
    @State private var measuredText = ""
    @State private var containerWidth: CGFloat = 0

    private let reduceMotionOverride: Bool?
    private let staticRenderDate: Date?
    private let fontSize: CGFloat = 16
    private let speed: CGFloat = 42

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
                contentWidth = CGFloat(text.count) * (fontSize + 4)
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
                let measuredOrEstimatedTextWidth = contentWidth > 0 ? contentWidth : CGFloat(text.count) * (fontSize + 4)
                let offsetX = tickerOffset(at: displayDate, viewportWidth: viewportWidth, textWidth: measuredOrEstimatedTextWidth)

                ZStack {
                    Text(text)
                        .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .textRenderer(CurvedTickerRenderer(viewportWidth: viewportWidth, textOriginX: offsetX))
                        .environment(\.layoutDirection, AppLanguage.from(identifier: locale.identifier).isRTL ? .rightToLeft : .leftToRight)
                        .fixedSize(horizontal: true, vertical: false)
                        .background {
                            GeometryReader { textGeometry in
                                Color.clear.preference(
                                    key: TickerWidthKey.self,
                                    value: TickerWidthMeasurement(text: text, width: textGeometry.size.width)
                                )
                            }
                        }
                        .position(x: offsetX + measuredOrEstimatedTextWidth / 2, y: geometry.size.height / 2)
                        .accessibilityHidden(true)
                        .onPreferenceChange(TickerWidthKey.self) { measurement in
                            measuredText = measurement.text
                            if abs(contentWidth - measurement.width) > 0.5 { contentWidth = measurement.width }
                        }

                    HStack {
                        sparkleButton
                        Spacer(minLength: 0)
                    }
                    .environment(\.layoutDirection, AppLanguage.from(identifier: locale.identifier).isRTL ? .rightToLeft : .leftToRight)
                }
                .clipped()
                .onAppear { containerWidth = geometry.size.width }
                .onChange(of: geometry.size.width) { _, width in containerWidth = width }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(text)
            }
        }
        .frame(height: 42)
        // Position and projection use physical x coordinates; text keeps its own reading direction.
        .environment(\.layoutDirection, .leftToRight)
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
        .accessibilityLabel(AppLocalization.text("showAIAdvice", language: AppLanguage.from(identifier: locale.identifier)))
    }

    private func tickerOffset(at date: Date, viewportWidth: CGFloat, textWidth: CGFloat) -> CGFloat {
        guard viewportWidth > 0 else { return 0 }
        if usesReducedMotion { return (viewportWidth - textWidth) / 2 }
        let isRTL = AppLanguage.from(identifier: locale.identifier).isRTL
        guard let animationStart else { return isRTL ? -textWidth : viewportWidth }

        let distance = viewportWidth + textWidth
        let duration = Double(distance / speed)
        let elapsed = min(duration, max(0, date.timeIntervalSince(animationStart)))
        return isRTL ? -textWidth + CGFloat(elapsed) * speed : viewportWidth - CGFloat(elapsed) * speed
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
