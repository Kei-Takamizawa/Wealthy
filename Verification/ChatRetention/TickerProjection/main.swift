import Foundation

// Run from the repository root:
// swiftc Wealthy/Wealthy/AITickerProjection.swift Verification/ChatRetention/TickerProjection/main.swift -o /tmp/wealthy-ticker-projection-checks
// /tmp/wealthy-ticker-projection-checks
let width: CGFloat = 300
let center = AITickerProjection.effect(centerX: width / 2, in: width)
let left = AITickerProjection.effect(centerX: 25, in: width)
let right = AITickerProjection.effect(centerX: width - 25, in: width)
let outside = AITickerProjection.effect(centerX: -10, in: width)

var failures: [String] = []
if center.scale <= left.scale || center.blurRadius >= left.blurRadius { failures.append("Center glyphs should appear larger and sharper than edge glyphs.") }
if left != right { failures.append("Projection should be symmetric on both sides.") }
if left.opacity <= 0 || outside.opacity != 0 { failures.append("Edge fade should taper to zero outside the viewport.") }
if AITickerProjection.effect(centerX: 100, in: 0) != AITickerProjection(scale: 1, blurRadius: 0, opacity: 0) {
    failures.append("Zero-width viewport should return a safe neutral effect.")
}

if failures.isEmpty {
    print("Passed 4 ticker projection geometry checks.")
} else {
    failures.forEach { print("FAIL: \($0)") }
    exit(1)
}
