import SpriteKit

/// Switches for playing the table without a person at it, read from the
/// environment. Always off in a release build.
///
/// - `IVIDIPINBALL_AUTOSTART=1` skips the title card and the menu and goes
///   straight to a game.
/// - `IVIDIPINBALL_AUTOPLAY=1` plunges every ball and works the flippers, so a
///   game plays itself: for recording the README demo, and for leaving a
///   build running on a device to see that nothing breaks.
/// - `IVIDIPINBALL_PANEL=howToPlay` (or `settings`, `highScores`, `about`)
///   opens that panel over the menu, for App Store screenshots.
enum QAFlags {
    static var startsInGame: Bool { value("IVIDIPINBALL_AUTOSTART") != nil }
    static var autoplay: Bool { value("IVIDIPINBALL_AUTOPLAY") != nil }
    static var panel: Panel? { value("IVIDIPINBALL_PANEL").flatMap(Panel.init(rawValue:)) }
    /// `IVIDIPINBALL_DRILL=cradle` (any `DrillID`) opens that Academy drill.
    static var drill: DrillID? { value("IVIDIPINBALL_DRILL").flatMap(DrillID.init(rawValue:)) }
    /// `IVIDIPINBALL_ACADEMY=1` opens the Academy list.
    static var academy: Bool { value("IVIDIPINBALL_ACADEMY") != nil }

    private static func value(_ name: String) -> String? {
        #if DEBUG
        ProcessInfo.processInfo.environment[name]
        #else
        nil
        #endif
    }
}

#if DEBUG

/// Instruments for finding faults on the table. Debug builds only: none of
/// this is compiled into a release build.
///
/// - `IVIDIPINBALL_DROP="x,y"` drops every new ball at that layout point instead
///   of serving it to the plunger, so a trap can be reproduced on demand
///   rather than waited for. `"x,y,vx,vy"` fires it, in table widths per
///   second, to test a shot.
/// - `IVIDIPINBALL_QA_LOG=1` prints each place the stuck-ball watchdog had to act,
///   and at the end of every game how often each part of the table was hit —
///   which is how to tell a trap, or a shot nobody can reach, from bad luck.
extension PinballScene {

    private static var tallies: [String: Int] = [:]
    private static var isLogging: Bool {
        ProcessInfo.processInfo.environment["IVIDIPINBALL_QA_LOG"] != nil
    }

    func dropForQA(_ ball: BallNode) {
        guard let spec = ProcessInfo.processInfo.environment["IVIDIPINBALL_DROP"] else { return }
        let values = spec.split(separator: ",").compactMap { Double($0) }
        guard values.count == 2 || values.count == 4 else { return }
        let point = CGPoint(x: values[0], y: values[1])
        // Optional velocity, in table widths per second, to fire a shot.
        let velocity = values.count == 4
            ? CGVector(dx: values[2], dy: values[3]) : CGVector(dx: 0, dy: 0)
        run(.sequence([.wait(forDuration: 0.5), .run { [weak self, weak ball] in
            guard let self, let ball else { return }
            ball.park(at: self.geometry.point(point))
            ball.physicsBody?.isDynamic = true
            ball.physicsBody?.velocity = CGVector(dx: self.geometry.length(velocity.dx),
                                                  dy: self.geometry.length(velocity.dy))
            self.model?.showLaunchHint = false
            self.dispatch(.ballLaunched)
        }]))
    }

    /// Flips whichever flipper a falling ball reaches the outer half of, as
    /// one short stroke followed by a rest. Holding on while a ball was near
    /// cradled it, and letting go dropped it straight back into the next
    /// press: the ball rocked on the flipper for ever and never left it.
    func autoFlipForQA() {
        for flipper in parts.flippers {
            let side = flipper.side
            if flipper.isPressed {
                if sceneTime >= Self.flipEnds[side, default: 0] {
                    releaseFlipper(side: side)
                    Self.flipRestEnds[side] = sceneTime + 0.25
                }
                continue
            }
            guard sceneTime >= Self.flipRestEnds[side, default: 0] else { continue }
            let onTheBlade = balls.contains { ball in
                let reach = ball.position.distance(to: flipper.pivotInScene)
                return !ball.isOnRamp
                    && reach > flipper.reach * 0.45 && reach < flipper.reach * 1.1
                    && (ball.physicsBody?.velocity.dy ?? 0) < 0
            }
            if onTheBlade {
                pressFlipper(side: side)
                Self.flipEnds[side] = sceneTime + 0.18
            }
        }
    }

    /// Works the flippers for a drill the way a learner would, so a drill
    /// can be left running to see that every feed reaches a flipper and
    /// every goal can be met: holds the flipper the ball is heading for,
    /// and once the ball is cradled, taps (pass) or flips (shots).
    func autoDrillForQA() {
        guard let drill = drillModel?.drill, let ball = balls.first, drillJudge != nil else {
            Self.bot = .idle
            return
        }
        let local = geometry.localPoint(ball.position)
        let side: TableSide = local.x < 0.5 ? .left : .right
        let cradled = ball.speed2D < geometry.length(0.12)
            && parts.flippers.contains { $0.isCradling(ball.position) }
        Self.cradledFor = cradled ? Self.cradledFor + 1.0 / 60 : 0
        let held = parts.flippers.first { $0.side == side }?.isPressed ?? false

        switch Self.bot {
        case .idle:
            // Hold the flipper the ball is coming down to: early, or with
            // `IVIDIPINBALL_HOLDAT=<blade fraction>` only once the ball is that
            // close to the pivot, to compare techniques.
            if local.y < 0.42, !held {
                if let holdAt = Self.holdAt {
                    if let blade = bladePosition(on: side), blade < holdAt { pressFlipper(side: side) }
                } else {
                    pressFlipper(side: side)
                }
            }
            if Self.cradledFor > 1.1, drill.goal != .cradle, drill.goal != .deadCatch {
                // Let it roll down the blade and act at a chosen point.
                let target = drill.goal == .transfer
                    ? Double.random(in: 0.75...0.95) : Double.random(in: 0.35...0.95)
                Self.bot = .rolling(side: side, target: target, since: sceneTime)
                releaseFlipper(side: side)
            }
        case let .rolling(rollSide, target, since):
            let blade = bladePosition(on: rollSide) ?? 1.2
            if blade >= target || sceneTime - since > 1.5 {
                pressFlipper(side: rollSide)
                let hold = drill.goal == .transfer ? Self.tapLength : 0.25
                Self.bot = .flipping(side: rollSide, until: sceneTime + hold)
            }
        case let .flipping(flipSide, until):
            if sceneTime >= until {
                releaseFlipper(side: flipSide)
                Self.bot = .settling(until: sceneTime + 0.25)
            }
        case let .settling(until):
            if sceneTime >= until { Self.bot = .idle }
        }
    }

    private enum DrillBot {
        case idle
        case rolling(side: TableSide, target: Double, since: TimeInterval)
        case flipping(side: TableSide, until: TimeInterval)
        case settling(until: TimeInterval)
    }

    private static var bot = DrillBot.idle
    private static var cradledFor: TimeInterval = 0
    static var holdAt: Double? {
        Double(ProcessInfo.processInfo.environment["IVIDIPINBALL_HOLDAT"] ?? "")
    }

    static var tapLength: TimeInterval {
        Double(ProcessInfo.processInfo.environment["IVIDIPINBALL_TAP"] ?? "") ?? 0.05
    }

    /// With `IVIDIPINBALL_TRACE=1`, the ball's position and the flippers'
    /// state ten times a second, to see what a drill attempt actually did.
    func traceDrillForQA() {
        guard ProcessInfo.processInfo.environment["IVIDIPINBALL_TRACE"] != nil,
              let ball = balls.first else { return }
        Self.traceTick += 1
        guard Self.traceTick % 6 == 0 else { return }
        let p = geometry.localPoint(ball.position)
        let flips = parts.flippers.map { $0.isPressed ? "^" : "_" }.joined()
        qaPrint(String(format: "[TRACE] t%.1f (%.3f,%.3f) v%.2f %@", sceneTime, p.x, p.y,
                       ball.speed2D / geometry.length(1), flips))
    }

    private static var traceTick = 0

    func logDrillForQA(_ result: DrillAttemptResult, attempt: Int) {
        guard Self.isLogging else { return }
        let blade = result.bladePosition.map { String(format: " blade %.2f", $0) } ?? ""
        let timing = result.timingMs.map { " \($0) ms" } ?? ""
        let events = Self.tallies.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }
        Self.tallies.removeAll()
        qaPrint("[DRILL] \(drillModel?.drill.rawValue ?? "?") #\(attempt) "
                + "\(result.success ? "OK  " : "FAIL") \(result.feedback.rawValue)\(blade)\(timing) "
                + events.joined(separator: " "))
    }

    private static var flipEnds: [TableSide: TimeInterval] = [:]
    private static var flipRestEnds: [TableSide: TimeInterval] = [:]

    func logWatchdogForQA(at position: CGPoint, strength: CGFloat) {
        guard Self.isLogging else { return }
        let spot = geometry.localPoint(position)
        qaPrint(String(format: "[QA] watchdog x%.0f at (%.3f, %.3f)", strength, spot.x, spot.y))
        Self.tallies["watchdog", default: 0] += 1
    }

    func tallyForQA(_ event: TableEvent) {
        guard Self.isLogging else { return }
        // "popBumper(index: 2)" and "popBumper(index: 0)" count together.
        let name = String(describing: event).prefix { $0 != "(" }
        Self.tallies[String(name), default: 0] += 1
    }

    func reportForQA() {
        guard Self.isLogging else { return }
        let lines = Self.tallies.sorted { $0.key < $1.key }.map { "  \($0.key): \($0.value)" }
        qaPrint("[QA] game over\n" + lines.joined(separator: "\n"))
        Self.tallies.removeAll()
    }

    /// Straight to standard error: `print` is buffered when the output is a
    /// file, and the log would only appear once the app quit.
    private func qaPrint(_ line: String) {
        FileHandle.standardError.write(Data((line + "\n").utf8))
    }
}
#endif
