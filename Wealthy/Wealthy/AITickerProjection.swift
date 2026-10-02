import Foundation

nonisolated struct AITickerProjection: Equatable {
    let scale: CGFloat
    let blurRadius: CGFloat
    let opacity: CGFloat

    static func effect(centerX: CGFloat, in width: CGFloat) -> Self {
        guard width > 0 else { return Self(scale: 1, blurRadius: 0, opacity: 0) }
        let midpoint = width / 2
        let normalizedDistance = min(1, abs(centerX - midpoint) / midpoint)
        let roundedDepth = normalizedDistance * normalizedDistance
        let edgeVisibility = min(1, max(0, min(centerX, width - centerX) / 28))

        return Self(
            scale: 1.22 - 0.40 * roundedDepth,
            blurRadius: 2.4 * roundedDepth,
            opacity: edgeVisibility * (1 - 0.2 * roundedDepth)
        )
    }
}
