import Cocoa
import Combine

@MainActor
final class SpaceObserver: ObservableObject {
    @Published private(set) var snapshot: ManagedDisplaySpacesSnapshot?
    @Published private(set) var lastError: Error?
    private var cancellables = Set<AnyCancellable>()
    private let fetch: () throws -> [NSDictionary]

    init(notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
         debounce: RunLoop.SchedulerTimeType.Stride = .milliseconds(300),
         fetch: @escaping () throws -> [NSDictionary] = {
             guard let displays = CGSCopyManagedDisplaySpaces(_CGSDefaultConnection()) as? [NSDictionary] else {
                 throw SpaceSwitchError.snapshotUnavailable
             }
             return displays
         }) {
        self.fetch = fetch
        notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .debounce(for: debounce, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    do { _ = try self?.refresh() }
                    catch { Logger.shared.logError("Space refresh failed: \(error.localizedDescription)") }
                }
            }
            .store(in: &cancellables)
    }

    @discardableResult
    func refresh() throws -> ManagedDisplaySpacesSnapshot {
        do {
            let value = ManagedDisplaySpacesParser.parse(try fetch())
            guard !value.activeSpaceIDsByDisplay.isEmpty else { throw SpaceSwitchError.snapshotUnavailable }
            lastError = nil
            snapshot = value
            return value
        } catch {
            lastError = error
            snapshot = nil
            throw error
        }
    }
}
