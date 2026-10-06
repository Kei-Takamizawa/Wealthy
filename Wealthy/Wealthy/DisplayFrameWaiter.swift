import UIKit

/// A one-shot display boundary; invalidates after two display callbacks and has no ambient redraw loop.
@MainActor final class DisplayFrameWaiter: NSObject {
    private var continuation: CheckedContinuation<Void, Never>?
    private var link: CADisplayLink?
    private var callbacks = 0
    static func wait() async {
        let waiter = DisplayFrameWaiter()
        await withCheckedContinuation { waiter.start($0) }
    }
    private func start(_ continuation: CheckedContinuation<Void, Never>) {
        self.continuation = continuation
        let link = CADisplayLink(target: self, selector: #selector(frame))
        self.link = link
        link.add(to: .main, forMode: .common)
    }
    @objc private func frame() {
        callbacks += 1
        guard callbacks >= 2 else { return }
        link?.invalidate(); link = nil
        let completion = continuation; continuation = nil
        completion?.resume()
    }
}
