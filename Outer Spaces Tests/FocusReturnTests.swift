import Foundation
import Testing
@testable import Outer_Spaces

@MainActor
private final class ReturnFixture {
    var time = Date(timeIntervalSince1970: 1_000)
    let a = Space(displayID: "A", spaceID: "1", spaceIndex: 0)
    let b = Space(displayID: "B", spaceID: "2", spaceIndex: 0)
    var focus: Focus
    var session: FocusFilterState
    var snapshot: ManagedDisplaySpacesSnapshot
    var calls = 0
    var errors = 0
    var failure = false
    var feedBack: (() -> Void)?
    lazy var controller = FocusReturnController(
        now: { self.time },
        readSnapshot: { self.snapshot },
        readSession: { self.session },
        apply: { _, current in
            guard current() else { throw CancellationError() }
            self.calls += 1
            self.feedBack?()
            if self.failure { throw SpaceSwitchError.automationNotGranted(-1743) }
            self.snapshot.activeSpaceIDsByDisplay = ["A": "1", "B": "2"]
        },
        report: { _ in self.errors += 1 }
    )
    init() {
        focus = Focus(name: "Work", spaces: [a, b], stageManager: false,
                      autoReturn: .init(enabled: true, delayMinutes: 5))
        session = .preset(focus.id)
        snapshot = ManagedDisplaySpacesSnapshot(desktopSpaces: [], allSpaces: [a,b], activeSpaceID: "1",
                                                 activeSpaceIDsByDisplay: ["A":"1", "B":"2"])
    }
    func update() { controller.update(session: session, presets: [focus], snapshot: snapshot) }
    func depart() { snapshot.activeSpaceIDsByDisplay["A"] = "fullscreen"; update() }
}

@Suite("Automatic return")
@MainActor
struct FocusReturnTests {
    @Test func legacyDecodingAndRoundTrip() throws {
        let id = UUID()
        let json = "{\"id\":\"\(id)\",\"name\":\"Old\",\"spaces\":[],\"stageManager\":false}"
        var focus = try JSONDecoder().decode(Focus.self, from: Data(json.utf8))
        #expect(focus.autoReturn == AutoReturnSettings(enabled: false, delayMinutes: 5))
        focus.autoReturn = .init(enabled: true, delayMinutes: 27)
        #expect(try JSONDecoder().decode(Focus.self, from: JSONEncoder().encode(focus)) == focus)
    }

    @Test(arguments: [-20, 0, 1, 5, 60, 61, Int.max])
    func delayBoundaries(value: Int) throws {
        let expected = min(60, max(1, value))
        var settings = AutoReturnSettings(delayMinutes: value)
        #expect(settings.delayMinutes == expected)
        settings.delayMinutes = value
        #expect(settings.delayMinutes == expected)
        let data = Data("{\"enabled\":true,\"delayMinutes\":\(value)}".utf8)
        #expect(try JSONDecoder().decode(AutoReturnSettings.self, from: data).delayMinutes == expected)
    }

    @Test func fixedDeadlineMultipleDisplaysAndReturnCancellation() async {
        let f = ReturnFixture()
        f.update()
        #expect(f.controller.phase == .idle)
        f.depart()
        let deadline = f.controller.deadline
        f.time += 60
        f.snapshot.activeSpaceIDsByDisplay["B"] = "other"
        f.update()
        await f.controller.tick()
        #expect(f.controller.deadline == deadline)
        #expect(f.controller.remainingSeconds == 240)
        f.snapshot.activeSpaceIDsByDisplay["A"] = "1"
        f.update()
        #expect(f.controller.phase == .counting)
        f.snapshot.activeSpaceIDsByDisplay["B"] = "2"
        f.update()
        #expect(f.controller.deadline == nil)
        #expect(f.controller.phase == .idle)
    }

    @Test func pauseSurvivesDuplicatesAndEditsResumeGetsFullDelay() {
        let f = ReturnFixture()
        f.depart()
        f.controller.pause()
        f.time += 30
        f.update()
        f.focus.autoReturn.delayMinutes = 2
        f.update()
        #expect(f.controller.isPaused)
        #expect(f.controller.deadline == nil)
        f.controller.resume()
        #expect(f.controller.deadline == f.time.addingTimeInterval(120))
        f.controller.pause()
        f.session = .unconfigured
        f.update()
        #expect(!f.controller.isPaused)
        #expect(f.controller.phase == .idle)
    }

    @Test func newMappedPresetClearsPauseAndStartsNewDeadline() {
        let f = ReturnFixture()
        f.depart(); f.controller.pause()
        f.focus = Focus(name: "Other", spaces: [f.a], stageManager: false, autoReturn: .init(enabled: true, delayMinutes: 1))
        f.session = .preset(f.focus.id)
        f.update()
        #expect(!f.controller.isPaused)
        #expect(f.controller.deadline == f.time.addingTimeInterval(60))
    }

    @Test func editsDisableDeletionAndMissingTargetsCancel() {
        let f = ReturnFixture()
        f.depart()
        f.time += 20
        f.focus.autoReturn.delayMinutes = 1
        f.update()
        #expect(f.controller.deadline == f.time.addingTimeInterval(60))
        f.focus.autoReturn.enabled = false; f.update()
        #expect(f.controller.phase == .idle)
        #expect(f.controller.deadline == nil)
        f.focus.autoReturn.enabled = true; f.update()
        f.snapshot.activeSpaceIDsByDisplay.removeValue(forKey: "B"); f.update()
        #expect(f.controller.phase == .suspended)
        #expect(f.controller.deadline == nil)
        f.snapshot.activeSpaceIDsByDisplay["B"] = "2"; f.update()
        #expect(f.controller.phase == .counting)
        f.focus.spaces = [Space(displayID: "A", spaceID: "deleted", spaceIndex: 0)]; f.update()
        #expect(f.controller.phase == .suspended)
        f.controller.update(session: f.session, presets: [], snapshot: f.snapshot)
        #expect(f.controller.preset == nil)
        #expect(f.controller.deadline == nil)
    }

    @Test func expiryVerifiesResultAndIgnoresOwnNotifications() async {
        let f = ReturnFixture()
        f.depart()
        f.feedBack = { f.update(); #expect(f.controller.deadline == nil) }
        f.time += 299
        await f.controller.tick()
        #expect(f.calls == 0)
        f.time += 1
        await f.controller.tick()
        #expect(f.calls == 1)
        #expect(f.controller.phase == .idle)
        #expect(f.errors == 0)
        await f.controller.tick()
        #expect(f.calls == 1)
    }

    @Test func failedReturnPausesUntilResume() async {
        let f = ReturnFixture()
        f.depart(); f.failure = true
        await f.controller.returnNow()
        #expect(f.controller.phase == .paused)
        #expect(f.errors == 1)
        f.update(); f.time += 600
        await f.controller.tick()
        #expect(f.calls == 1)
        f.failure = false; f.controller.resume()
        #expect(f.controller.deadline == f.time.addingTimeInterval(300))
        await f.controller.returnNow()
        #expect(f.controller.phase == .idle)
    }

    @Test func sleepWakeAndUnknownSession() async {
        let f = ReturnFixture()
        f.depart(); f.time += 50
        f.controller.prepareForSleep()
        #expect(f.controller.deadline == nil)
        f.time += 1000
        await f.controller.tick()
        #expect(f.calls == 0)
        await f.controller.reloadAfterWake()
        #expect(f.controller.deadline == f.time.addingTimeInterval(300))
        f.session = .unknown; f.update()
        #expect(f.controller.phase == .suspended)
        #expect(f.controller.deadline == nil)
    }

    @Test func expiryRevalidatesFilterBeforeSwitching() async {
        let f = ReturnFixture()
        f.depart()
        f.session = .unconfigured // Fresh provider differs from the last published callback.
        await f.controller.returnNow()
        #expect(f.calls == 0)
        #expect(f.controller.phase == .idle)
    }

    @Test func staleReturnCannotSwitchAfterDeactivation() async {
        let f = ReturnFixture()
        var read: CheckedContinuation<FocusFilterState, Never>?
        let controller = FocusReturnController(now: { f.time }, readSnapshot: { f.snapshot },
            readSession: { await withCheckedContinuation { read = $0 } },
            apply: { _, _ in f.calls += 1 }, report: { _ in f.errors += 1 })
        f.depart()
        controller.update(session: f.session, presets: [f.focus], snapshot: f.snapshot)
        let task = Task { await controller.returnNow() }
        while read == nil { await Task.yield() }
        controller.update(session: .unconfigured, presets: [f.focus], snapshot: f.snapshot)
        read?.resume(returning: f.session)
        await task.value
        #expect(f.calls == 0)
        #expect(controller.phase == .idle)
    }
    @Test func unsuccessfulSwitchIsVerifiedAndPaused() async {
        let f = ReturnFixture()
        f.depart()
        let controller = FocusReturnController(now: { f.time }, readSnapshot: { f.snapshot },
            readSession: { f.session }, apply: { _, _ in f.calls += 1 }, report: { _ in f.errors += 1 })
        controller.update(session: f.session, presets: [f.focus], snapshot: f.snapshot)
        await controller.returnNow()
        #expect(f.calls == 1)
        #expect(f.errors == 1)
        #expect(controller.isPaused)
    }

    @Test func wakeDoesNotOverwriteNewFilterWhileReadingSpaces() async {
        let f = ReturnFixture()
        f.depart()
        var read: CheckedContinuation<ManagedDisplaySpacesSnapshot, Never>?
        let controller = FocusReturnController(now: { f.time },
            readSnapshot: { await withCheckedContinuation { read = $0 } },
            readSession: { f.session }, apply: { _, _ in f.calls += 1 }, report: { _ in f.errors += 1 })
        controller.update(session: f.session, presets: [f.focus], snapshot: f.snapshot)
        let task = Task { await controller.reloadAfterWake() }
        while read == nil { await Task.yield() }
        controller.update(session: .unconfigured, presets: [f.focus], snapshot: f.snapshot)
        read?.resume(returning: f.snapshot)
        await task.value
        #expect(controller.phase == .idle)
        #expect(controller.preset == nil)
        #expect(controller.deadline == nil)
    }

    @Test func targetEditsInvalidateAnInFlightOperation() async {
        let f = ReturnFixture()
        f.depart()
        var read: CheckedContinuation<ManagedDisplaySpacesSnapshot, Never>?
        let controller = FocusReturnController(now: { f.time },
            readSnapshot: { await withCheckedContinuation { read = $0 } },
            readSession: { f.session }, apply: { _, _ in f.calls += 1 }, report: { _ in f.errors += 1 })
        controller.update(session: f.session, presets: [f.focus], snapshot: f.snapshot)
        let task = Task { await controller.returnNow() }
        while read == nil { await Task.yield() }
        f.focus.spaces = [f.b]
        controller.update(session: f.session, presets: [f.focus], snapshot: f.snapshot)
        read?.resume(returning: f.snapshot)
        await task.value
        #expect(f.calls == 0)
        #expect(controller.phase == .idle)
    }

}
