import CoreGraphics
import Foundation

// MARK: - The drills

/// The Flipper Academy: drills for the skills a real pinball player learns on
/// a real machine, each one judged on the table itself.
///
/// Nothing here knows about SpriteKit. The scene reports what the flippers
/// and the ball did, `DrillJudge` decides whether the attempt worked and why
/// it did not, and the coach screen shows the verdict.
enum DrillID: String, CaseIterable, Codable, Identifiable {
    case cradle
    case deadCatch
    case tapPass
    case rampShot
    case standupShot
    case dropShot

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cradle:    return "hand.raised.fill"
        case .deadCatch: return "arrow.down.to.line"
        case .tapPass:   return "arrow.left.arrow.right"
        case .rampShot:  return "arrow.up.forward"
        case .standupShot: return "target"
        case .dropShot:  return "square.stack.3d.down.right.fill"
        }
    }

    /// How the ball arrives at the flippers for each attempt.
    var feed: DrillFeed {
        switch self {
        case .deadCatch: return .centreDrop
        default:         return .inlane
        }
    }

    var goal: DrillGoal {
        switch self {
        case .cradle:    return .cradle
        case .deadCatch: return .deadCatch
        case .tapPass:   return .transfer
        case .rampShot:  return .shot(.ramp)
        case .standupShot: return .shot(.standup)
        case .dropShot:  return .shot(.dropTarget)
        }
    }

    /// Whether the drill builds on another one. The list shows the order a
    /// player should learn them in; nothing is locked.
    var isShot: Bool {
        if case .shot = goal { return true }
        return false
    }

    /// Whether the drill is about where on the blade the ball is struck, so
    /// the coach shows the blade guide.
    var usesBladeGuide: Bool { isShot || self == .tapPass }
}

enum DrillFeed: Equatable {
    /// Rolled down an inlane on to the flipper, as a ramp returns it.
    case inlane
    /// Dropped from the middle of the table on to the blade.
    case centreDrop
}

enum DrillGoal: Equatable {
    case cradle
    case deadCatch
    case transfer
    case shot(ShotTarget)
}

enum ShotTarget: String, Equatable {
    case ramp, standup, dropTarget

    func isHit(by event: TableEvent) -> Bool {
        switch (self, event) {
        case (.ramp, .rampCompleted), (.standup, .standupTarget), (.dropTarget, .dropTarget):
            return true
        default:
            return false
        }
    }
}

/// The part of the table a shot struck first, for telling the player what
/// they hit instead of the target.
enum StruckPart: String, Equatable {
    case ramp, dropTarget, standup, bumper, saucer, orbit, spinner, lane

    /// Slingshots, the drain and the like are not shots, so they are nil.
    init?(_ event: TableEvent) {
        switch event {
        case .rampCompleted:   self = .ramp
        case .dropTarget:      self = .dropTarget
        case .standupTarget:   self = .standup
        case .popBumper:       self = .bumper
        case .saucerEntered:   self = .saucer
        case .orbitCompleted:  self = .orbit
        case .spinnerRotation: self = .spinner
        case .rolloverLane:    self = .lane
        default:               return nil
        }
    }
}

// MARK: - Verdicts

/// Why an attempt ended the way it did. Each case is a coaching line in
/// `Strings`, keyed `academy.fb.<rawValue>`.
enum DrillFeedback: String, Equatable {
    case cradled
    case caught
    case passed
    case hit

    case noFlip
    case flippedIntoIt
    case flippedLate
    case drained
    case timeout
    case tooHard
    case neverCradled
    case missed
}

struct DrillAttemptResult: Equatable {
    let success: Bool
    let feedback: DrillFeedback
    /// For shots: where along the blade the ball was when the flipper fired,
    /// 0 at the pivot and 1 at the tip. This is how a player aims.
    let bladePosition: Double?
    /// For catches: how far the press was from the ball landing, in
    /// milliseconds. Negative is before the ball landed.
    let timingMs: Int?
    /// For a missed shot: what the ball hit first instead.
    var struck: StruckPart? = nil
}

// MARK: - Judge

/// Referee for one attempt at a drill. The scene feeds it, frame by frame,
/// what the player and the ball did; it answers with a verdict once the
/// attempt is over.
final class DrillJudge {

    enum Tuning {
        /// How long the ball has to sit still on a held flipper to count as
        /// under control.
        static let cradleHold: TimeInterval = 1.0
        static let catchTimeLimit: TimeInterval = 7.0
        static let passTimeLimit: TimeInterval = 14.0
        static let shotTimeLimit: TimeInterval = 14.0
        /// A press this close before the ball lands is a flip into it,
        /// not a flipper raised and waiting.
        static let flipIntoWindow: TimeInterval = 0.12
        /// Above this height the ball has left the flipper area: in a pass
        /// it was hit too hard, in a shot it is on its way.
        static let upTableY: CGFloat = 0.60
        /// Back below this after going up the table, a shot has missed.
        static let returnY: CGFloat = 0.34
    }

    let goal: DrillGoal
    private let startedAt: TimeInterval

    private var pressedAt: [TableSide: TimeInterval] = [:]
    private var anyPress = false
    private var firstContact: (side: TableSide, time: TimeInterval)?
    private var cradle: (side: TableSide, since: TimeInterval)?
    /// For a pass: the flipper the ball was first brought under control on.
    private var firstCradleSide: TableSide?
    private var wentUpTable = false
    /// For a shot: where along the blade the ball was at the last flip
    /// that touched it.
    private var lastShotBlade: Double?
    private(set) var result: DrillAttemptResult?

    init(goal: DrillGoal, at time: TimeInterval) {
        self.goal = goal
        self.startedAt = time
    }

    var isOver: Bool { result != nil }

    private var timeLimit: TimeInterval {
        switch goal {
        case .cradle, .deadCatch: return Tuning.catchTimeLimit
        case .transfer:           return Tuning.passTimeLimit
        case .shot:               return Tuning.shotTimeLimit
        }
    }

    // MARK: Inputs

    /// A flipper button went down. `bladePosition` is where the ball was
    /// along that blade, or nil if the ball was nowhere near it.
    func flipperPressed(_ side: TableSide, bladePosition: Double?, at time: TimeInterval) {
        guard !isOver else { return }
        anyPress = true
        pressedAt[side] = time
        switch goal {
        case .shot:
            if let bladePosition { lastShotBlade = bladePosition }
        case .transfer:
            // The tap that matters comes after the ball is under control.
            if firstCradleSide != nil, let bladePosition { lastShotBlade = bladePosition }
        default:
            break
        }
    }

    func flipperReleased(_ side: TableSide, at time: TimeInterval) {
        guard !isOver else { return }
        pressedAt[side] = nil
    }

    /// The ball touched a flipper blade.
    func flipperTouched(_ side: TableSide, at time: TimeInterval) {
        guard !isOver, firstContact == nil else { return }
        firstContact = (side, time)
    }

    func tableEvent(_ event: TableEvent, at time: TimeInterval) {
        guard !isOver else { return }
        guard case .shot(let target) = goal else { return }
        // A shot is judged by the first thing it strikes. One that bounces
        // off the drop targets into a standup did not hit the standup.
        if target.isHit(by: event) {
            finish(success: true, .hit, blade: lastShotBlade)
        } else if let part = StruckPart(event) {
            finish(success: false, .missed, blade: lastShotBlade, struck: part)
        }
    }

    func drained(at time: TimeInterval) {
        guard !isOver else { return }
        switch goal {
        case .cradle, .deadCatch:
            finish(success: false, catchFailure(), timing: catchTiming())
        case .transfer:
            finish(success: false, firstCradleSide == nil ? .neverCradled : .drained,
                   blade: lastShotBlade)
        case .shot:
            finish(success: false, wentUpTable ? .missed : .drained, blade: lastShotBlade)
        }
    }

    /// Called every frame with the ball's height in layout units and the
    /// flipper it is cradled on, if any.
    func tick(at time: TimeInterval, ballY: CGFloat, cradledOn side: TableSide?) {
        guard !isOver else { return }
        trackCradle(side, at: time)

        switch goal {
        case .cradle:
            if heldLongEnough(at: time) {
                finish(success: true, .cradled, timing: catchTiming())
            }

        case .deadCatch:
            if heldLongEnough(at: time) {
                // The ball has to land on a flipper that was already up.
                // One flipped into it and then settled is luck, not a catch.
                if let timing = catchTiming(), Double(timing) / 1000 > -Tuning.flipIntoWindow {
                    finish(success: false, .flippedLate, timing: timing)
                } else {
                    finish(success: true, .caught, timing: catchTiming())
                }
            }

        case .transfer:
            if ballY > Tuning.upTableY {
                finish(success: false, firstCradleSide == nil ? .neverCradled : .tooHard,
                       blade: lastShotBlade)
                return
            }
            if let cradle, time - cradle.since >= Tuning.cradleHold {
                if firstCradleSide == nil {
                    firstCradleSide = cradle.side
                } else if cradle.side != firstCradleSide {
                    finish(success: true, .passed, blade: lastShotBlade)
                    return
                }
            }

        case .shot:
            if ballY > Tuning.upTableY { wentUpTable = true }
            if wentUpTable, ballY < Tuning.returnY {
                finish(success: false, .missed, blade: lastShotBlade)
                return
            }
        }

        if !isOver, time - startedAt > timeLimit {
            switch goal {
            case .cradle, .deadCatch:
                finish(success: false, anyPress ? .timeout : .noFlip)
            case .transfer:
                finish(success: false, firstCradleSide == nil ? .neverCradled : .timeout)
            case .shot:
                finish(success: false, wentUpTable ? .missed : .timeout, blade: lastShotBlade)
            }
        }
    }

    // MARK: Helpers

    private func trackCradle(_ side: TableSide?, at time: TimeInterval) {
        guard let side else {
            cradle = nil
            return
        }
        if cradle?.side != side {
            cradle = (side, time)
        }
    }

    private func heldLongEnough(at time: TimeInterval) -> Bool {
        guard let cradle else { return false }
        return time - cradle.since >= Tuning.cradleHold
    }

    /// Milliseconds from the ball landing to the press on that flipper.
    private func catchTiming() -> Int? {
        guard let contact = firstContact, let press = pressedAt[contact.side] else { return nil }
        return Int(((press - contact.time) * 1000).rounded())
    }

    private func catchFailure() -> DrillFeedback {
        guard anyPress else { return .noFlip }
        if let timing = catchTiming() {
            // Pressed just before or after the ball landed: the blade was
            // still moving and batted the ball away.
            return Double(timing) / 1000 > -Tuning.flipIntoWindow ? .flippedIntoIt : .drained
        }
        return .drained
    }

    private func finish(success: Bool, _ feedback: DrillFeedback,
                        blade: Double? = nil, timing: Int? = nil, struck: StruckPart? = nil) {
        result = DrillAttemptResult(success: success, feedback: feedback,
                                    bladePosition: blade, timingMs: timing, struck: struck)
    }
}

// MARK: - A session of attempts

/// Ten attempts at one drill, and the running tally the coach screen shows.
struct DrillRun: Equatable {
    static let attemptsPerRun = 10

    let drill: DrillID
    private(set) var results: [DrillAttemptResult] = []

    init(drill: DrillID) { self.drill = drill }

    var attempt: Int { min(results.count + 1, Self.attemptsPerRun) }
    var successes: Int { results.filter(\.success).count }
    var isFinished: Bool { results.count >= Self.attemptsPerRun }
    var last: DrillAttemptResult? { results.last }

    mutating func record(_ result: DrillAttemptResult) {
        guard !isFinished else { return }
        results.append(result)
    }

    var stars: Int { Mastery.stars(forSuccesses: successes) }
}

enum Mastery {
    /// Successes out of ten for bronze, silver and gold.
    static let thresholds = [5, 7, 9]

    static func stars(forSuccesses successes: Int) -> Int {
        thresholds.filter { successes >= $0 }.count
    }
}

/// What the Academy remembers about a drill between launches.
struct DrillRecord: Codable, Equatable {
    var bestSuccesses = 0
    var runs = 0
    var attempts = 0
    var successes = 0
    /// Blade positions of recent successful shots, newest last. They become
    /// the player's own aiming guide on the flipper.
    var hitBlades: [Double] = []
    /// And of recent misses, so the guide can show both.
    var missBlades: [Double] = []

    static let bladeMemory = 30

    var stars: Int { Mastery.stars(forSuccesses: bestSuccesses) }

    mutating func absorb(_ run: DrillRun) {
        guard run.isFinished else { return }
        runs += 1
        bestSuccesses = max(bestSuccesses, run.successes)
        attempts += run.results.count
        successes += run.successes
        for result in run.results {
            guard let blade = result.bladePosition else { continue }
            if result.success {
                hitBlades.append(blade)
            } else {
                missBlades.append(blade)
            }
        }
        hitBlades = Array(hitBlades.suffix(Self.bladeMemory))
        missBlades = Array(missBlades.suffix(Self.bladeMemory))
    }

    /// The middle half of the player's successful shots, as a band along the
    /// blade, once there are enough of them to mean something.
    var sweetSpot: ClosedRange<Double>? {
        guard hitBlades.count >= 3 else { return nil }
        let sorted = hitBlades.sorted()
        let low = sorted[sorted.count / 4]
        let high = sorted[min(sorted.count - 1, (sorted.count * 3) / 4)]
        return low...high
    }
}

extension DrillRecord {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        bestSuccesses = try c.decodeIfPresent(Int.self, forKey: .bestSuccesses) ?? 0
        runs = try c.decodeIfPresent(Int.self, forKey: .runs) ?? 0
        attempts = try c.decodeIfPresent(Int.self, forKey: .attempts) ?? 0
        successes = try c.decodeIfPresent(Int.self, forKey: .successes) ?? 0
        hitBlades = try c.decodeIfPresent([Double].self, forKey: .hitBlades) ?? []
        missBlades = try c.decodeIfPresent([Double].self, forKey: .missBlades) ?? []
    }
}
