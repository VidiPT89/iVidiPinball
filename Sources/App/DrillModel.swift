import Observation
import SwiftUI

/// What the coach screen shows during a Flipper Academy drill. The scene
/// pushes each verdict into it; the screen only reads it, apart from the
/// slow-motion switch.
@Observable
final class DrillModel {

    let drill: DrillID
    private(set) var run: DrillRun
    private(set) var lastResult: DrillAttemptResult?
    /// Bumped on every verdict, so the screen can animate a repeat of the
    /// same one.
    private(set) var resultCount = 0
    /// Which flipper the current attempt is fed to.
    var side: TableSide = .left
    /// Halves the speed of the table, ball and flippers alike, for learning
    /// the movement before doing it at full speed.
    var slowMotion = false
    var isPaused = false

    /// Called once the tenth attempt is in, to save the run.
    var onFinished: ((DrillRun) -> Void)?

    init(drill: DrillID) {
        self.drill = drill
        self.run = DrillRun(drill: drill)
    }

    var isFinished: Bool { run.isFinished }

    func record(_ result: DrillAttemptResult) {
        guard !run.isFinished else { return }
        run.record(result)
        lastResult = result
        resultCount += 1
        if run.isFinished { onFinished?(run) }
    }

    func restart() {
        run = DrillRun(drill: drill)
        lastResult = nil
        resultCount = 0
    }
}
