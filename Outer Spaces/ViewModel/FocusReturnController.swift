import Foundation

/// One cancellable departure deadline for the active filter, independent of the editor selection.
@MainActor
final class FocusReturnController: ObservableObject {
    enum Phase: Equatable { case idle, counting, returning, paused, suspended }
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var remainingSeconds: Int?
    @Published private(set) var isPaused = false
    private(set) var deadline: Date?
    @Published private(set) var preset: Focus?
    private var session: FocusFilterState = .unknown
    private var knownPresetID: UUID?
    private var presets: [Focus] = []
    private var snapshot: ManagedDisplaySpacesSnapshot?
    private var configuration: Configuration?
    private var revision = 0
    private var lifecycleRevision = 0
    private var sleeping = false
    private var operation: UUID?
    private let now: @MainActor () -> Date
    private let readSnapshot: @MainActor () async throws -> ManagedDisplaySpacesSnapshot
    private let readSession: @MainActor () async -> FocusFilterState
    private let apply: @MainActor (Focus, @escaping @MainActor () -> Bool) async throws -> Void
    private let report: @MainActor (Error) -> Void

    private struct Configuration: Equatable {
        let id: UUID
        let settings: AutoReturnSettings
        // Changes to active flags, generated model UUIDs, or display order are not preset edits.
        let targets: [String]
        init(_ preset: Focus) {
            id = preset.id
            settings = preset.autoReturn
            targets = preset.spaces.map { "\($0.displayID):\($0.spaceID)" }.sorted()
        }
    }

    init(now: @escaping @MainActor () -> Date = Date.init,
         readSnapshot: @escaping @MainActor () async throws -> ManagedDisplaySpacesSnapshot,
         readSession: @escaping @MainActor () async -> FocusFilterState,
         apply: @escaping @MainActor (Focus, @escaping @MainActor () -> Bool) async throws -> Void,
         report: @escaping @MainActor (Error) -> Void) {
        self.now = now
        self.readSnapshot = readSnapshot
        self.readSession = readSession
        self.apply = apply
        self.report = report
    }

    var countdownText: String? {
        guard let seconds = remainingSeconds else { return nil }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    func update(session: FocusFilterState, presets: [Focus], snapshot: ManagedDisplaySpacesSnapshot?) {
        self.presets = presets
        self.snapshot = snapshot
        if self.session != session {
            invalidate()
            self.session = session
        }
        switch session {
        case .preset(let id):
            if knownPresetID != id { isPaused = false; knownPresetID = id }
        case .unconfigured:
            isPaused = false
            knownPresetID = nil
        case .unknown:
            break // An unavailable status is not a new Focus session.
        }
        let next = knownPresetID.flatMap { id in presets.first { $0.id == id } }
        let nextConfiguration = next.map(Configuration.init)
        if configuration != nextConfiguration {
            invalidate()
            configuration = nextConfiguration
        }
        preset = next
        reconcile()
    }

    private func invalidate() {
        revision += 1
        operation = nil
        deadline = nil
        remainingSeconds = nil
    }

    private func setPhase(_ phase: Phase) {
        if self.phase != phase { self.phase = phase }
    }

    private func reconcile() {
        guard !sleeping else { setPhase(.idle); return }
        guard case .preset = session else {
            deadline = nil
            remainingSeconds = nil
            setPhase(session == .unknown && preset?.autoReturn.enabled == true ? .suspended : .idle)
            return
        }
        guard let preset else { invalidate(); setPhase(.suspended); return }
        guard preset.autoReturn.enabled else { invalidate(); setPhase(.idle); return }
        if isPaused { setPhase(.paused); return }
        guard let snapshot,
              let targets = try? SpaceSwitcher.targets(for: preset.spaces, in: snapshot),
              targets.allSatisfy({ snapshot.activeSpaceIDsByDisplay[$0.0.displayID] != nil }) else {
            invalidate()
            setPhase(.suspended)
            return
        }
        // Notifications produced by our own switching service cannot schedule another return.
        guard operation == nil else { return }
        if targets.allSatisfy({ snapshot.activeSpaceIDsByDisplay[$0.0.displayID] == $0.0.spaceID }) {
            deadline = nil
            remainingSeconds = nil
            setPhase(.idle)
            return
        }
        if deadline == nil { deadline = now().addingTimeInterval(TimeInterval(preset.autoReturn.delayMinutes * 60)) }
        updateRemainingTime()
        setPhase(.counting)
    }

    private func updateRemainingTime() {
        remainingSeconds = deadline.map { max(0, Int(ceil($0.timeIntervalSince(now())))) }
    }

    func tick() async {
        guard phase == .counting, let deadline else { return }
        updateRemainingTime()
        if now() >= deadline { await returnNow() }
    }

    func pause() {
        guard preset?.autoReturn.enabled == true else { return }
        invalidate()
        isPaused = true
        setPhase(.paused)
    }

    func resume() {
        invalidate()
        isPaused = false
        reconcile()
    }

    func returnNow() async {
        guard !sleeping, !isPaused, operation == nil, case .preset = session,
              let target = preset, target.autoReturn.enabled else { return }
        let token = UUID()
        let expectedRevision = revision
        operation = token
        deadline = nil
        remainingSeconds = nil
        setPhase(.returning)
        let isCurrent: @MainActor () -> Bool = { [weak self] in
            guard let self else { return false }
            return self.operation == token && self.revision == expectedRevision && !self.sleeping && !self.isPaused
        }
        do {
            let freshSession = await readSession()
            guard isCurrent() else { return }
            update(session: freshSession, presets: presets, snapshot: snapshot)
            guard isCurrent() else { return }
            let freshSnapshot = try await readSnapshot()
            guard isCurrent() else { return }
            update(session: freshSession, presets: presets, snapshot: freshSnapshot)
            guard isCurrent() else { return }
            try await apply(target, isCurrent)
            guard isCurrent() else { return }
            let verified = try await readSnapshot()
            guard isCurrent() else { return }
            let targets = try SpaceSwitcher.targets(for: target.spaces, in: verified)
            guard targets.allSatisfy({ verified.activeSpaceIDsByDisplay[$0.0.displayID] == $0.0.spaceID }) else {
                throw SpaceSwitchError.transitionFailed(target.name)
            }
            operation = nil
            snapshot = verified
            reconcile()
        } catch is CancellationError {
            guard isCurrent() else { return }
            operation = nil
            reconcile()
        } catch {
            guard isCurrent() else { return }
            operation = nil
            isPaused = true
            setPhase(.paused)
            report(error)
        }
    }

    func prepareForSleep() {
        lifecycleRevision += 1
        sleeping = true
        invalidate()
        setPhase(.idle)
    }

    func reloadAfterWake() async {
        lifecycleRevision += 1
        let lifecycle = lifecycleRevision
        sleeping = true
        invalidate()
        setPhase(.idle)
        let freshSession = await readSession()
        let sessionRevision = revision
        do {
            let freshSnapshot = try await readSnapshot()
            guard lifecycleRevision == lifecycle else { return }
            sleeping = false
            update(session: revision == sessionRevision ? freshSession : session, presets: presets, snapshot: freshSnapshot)
        } catch {
            guard lifecycleRevision == lifecycle else { return }
            sleeping = false
            update(session: revision == sessionRevision ? freshSession : session, presets: presets, snapshot: nil)
            Logger.shared.logError("Automatic return is waiting for the desktop layout: \(error)")
        }
    }
}
