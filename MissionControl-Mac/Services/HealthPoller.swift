import Foundation

final class HealthPoller {
    private var task: Task<Void, Never>?

    func start(intervalSeconds: Int, action: @escaping @Sendable () async -> Void) {
        stop()
        task = Task {
            while !Task.isCancelled {
                await action()
                try? await Task.sleep(nanoseconds: UInt64(max(intervalSeconds, 5)) * 1_000_000_000)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    deinit {
        stop()
    }
}
