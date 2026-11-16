import XCTest
@testable import iVidiPinball

/// The Flipper Academy referee, fed the same reports the table sends it.
final class AcademyTests: XCTestCase {

    // MARK: Cradle

    func testHoldingABallStillForASecondIsACradle() {
        let judge = DrillJudge(goal: .cradle, at: 0)
        judge.flipperPressed(.left, bladePosition: nil, at: 0.2)
        judge.flipperTouched(.left, at: 0.5)
        judge.tick(at: 0.6, ballY: 0.22, cradledOn: .left)
        judge.tick(at: 1.2, ballY: 0.22, cradledOn: .left)
        XCTAssertNil(judge.result, "not yet a full second")
        judge.tick(at: 1.61, ballY: 0.22, cradledOn: .left)
        XCTAssertEqual(judge.result?.success, true)
        XCTAssertEqual(judge.result?.feedback, .cradled)
        XCTAssertEqual(judge.result?.timingMs, -300)
    }

    func testACradleThatSlipsStartsTheSecondAgain() {
        let judge = DrillJudge(goal: .cradle, at: 0)
        judge.tick(at: 0.5, ballY: 0.22, cradledOn: .left)
        judge.tick(at: 1.2, ballY: 0.22, cradledOn: nil)
        judge.tick(at: 1.3, ballY: 0.22, cradledOn: .left)
        judge.tick(at: 2.0, ballY: 0.22, cradledOn: .left)
        XCTAssertNil(judge.result)
        judge.tick(at: 2.31, ballY: 0.22, cradledOn: .left)
        XCTAssertEqual(judge.result?.success, true)
    }

    func testDrainingWithoutEverFlippingSaysSo() {
        let judge = DrillJudge(goal: .cradle, at: 0)
        judge.drained(at: 2)
        XCTAssertEqual(judge.result, DrillAttemptResult(success: false, feedback: .noFlip,
                                                        bladePosition: nil, timingMs: nil))
    }

    func testFlippingAsTheBallLandsIsFlippingIntoIt() {
        let judge = DrillJudge(goal: .cradle, at: 0)
        judge.flipperTouched(.right, at: 1.0)
        judge.flipperPressed(.right, bladePosition: 0.6, at: 1.05)
        judge.drained(at: 2)
        XCTAssertEqual(judge.result?.feedback, .flippedIntoIt)
        XCTAssertEqual(judge.result?.timingMs, 50)
    }

    // MARK: Dead catch

    func testADeadCatchNeedsTheFlipperUpBeforeTheBallLands() {
        let early = DrillJudge(goal: .deadCatch, at: 0)
        early.flipperPressed(.left, bladePosition: nil, at: 0.3)
        early.flipperTouched(.left, at: 0.6)
        early.tick(at: 1.0, ballY: 0.22, cradledOn: .left)
        early.tick(at: 2.01, ballY: 0.22, cradledOn: .left)
        XCTAssertEqual(early.result?.feedback, .caught)

        let late = DrillJudge(goal: .deadCatch, at: 0)
        late.flipperTouched(.left, at: 0.6)
        late.flipperPressed(.left, bladePosition: 0.5, at: 0.65)
        late.tick(at: 1.0, ballY: 0.22, cradledOn: .left)
        late.tick(at: 2.01, ballY: 0.22, cradledOn: .left)
        XCTAssertEqual(late.result?.success, false)
        XCTAssertEqual(late.result?.feedback, .flippedLate)
    }

    // MARK: Pass

    func testAPassEndsCradledOnTheOtherFlipper() {
        let judge = DrillJudge(goal: .transfer, at: 0)
        judge.tick(at: 1.0, ballY: 0.22, cradledOn: .left)
        judge.tick(at: 2.1, ballY: 0.22, cradledOn: .left)
        judge.flipperPressed(.left, bladePosition: 0.88, at: 2.5)
        judge.tick(at: 3.0, ballY: 0.30, cradledOn: nil)
        judge.tick(at: 3.5, ballY: 0.22, cradledOn: .right)
        XCTAssertNil(judge.result)
        judge.tick(at: 4.6, ballY: 0.22, cradledOn: .right)
        XCTAssertEqual(judge.result?.success, true)
        XCTAssertEqual(judge.result?.feedback, .passed)
        XCTAssertEqual(judge.result?.bladePosition, 0.88)
    }

    func testAPassThatGoesUpTheTableIsTooHard() {
        let judge = DrillJudge(goal: .transfer, at: 0)
        judge.tick(at: 1.0, ballY: 0.22, cradledOn: .left)
        judge.tick(at: 2.1, ballY: 0.22, cradledOn: .left)
        judge.tick(at: 2.6, ballY: 0.7, cradledOn: nil)
        XCTAssertEqual(judge.result?.feedback, .tooHard)
    }

    func testRecradlingOnTheSameFlipperIsNotAPass() {
        let judge = DrillJudge(goal: .transfer, at: 0)
        judge.tick(at: 1.0, ballY: 0.22, cradledOn: .left)
        judge.tick(at: 2.1, ballY: 0.22, cradledOn: .left)
        judge.tick(at: 2.2, ballY: 0.24, cradledOn: nil)
        judge.tick(at: 2.3, ballY: 0.22, cradledOn: .left)
        judge.tick(at: 3.5, ballY: 0.22, cradledOn: .left)
        XCTAssertNil(judge.result)
    }

    // MARK: Shots

    func testAShotScoresOnItsTargetAndRemembersTheBladePosition() {
        let judge = DrillJudge(goal: .shot(.ramp), at: 0)
        judge.flipperPressed(.left, bladePosition: 0.74, at: 2)
        judge.tick(at: 2.2, ballY: 0.7, cradledOn: nil)
        judge.tableEvent(.rampCompleted(side: .right), at: 3)
        XCTAssertEqual(judge.result?.success, true)
        XCTAssertEqual(judge.result?.bladePosition, 0.74)
    }

    func testAShotIsJudgedByTheFirstThingItStrikes() {
        let judge = DrillJudge(goal: .shot(.standup), at: 0)
        judge.flipperPressed(.left, bladePosition: 0.5, at: 2)
        // Slingshots are not shots: the ball can clip one on its way.
        judge.tableEvent(.slingshot(side: .left), at: 2.1)
        XCTAssertNil(judge.result)
        judge.tableEvent(.dropTarget(index: 2), at: 2.3)
        judge.tableEvent(.standupTarget(index: 0), at: 2.5)
        XCTAssertEqual(judge.result?.success, false)
        XCTAssertEqual(judge.result?.struck, .dropTarget)
    }

    func testAShotThatComesBackDownHasMissed() {
        let judge = DrillJudge(goal: .shot(.dropTarget), at: 0)
        judge.flipperPressed(.right, bladePosition: 0.3, at: 2)
        judge.tick(at: 2.3, ballY: 0.8, cradledOn: nil)
        judge.tick(at: 3.0, ballY: 0.3, cradledOn: nil)
        XCTAssertEqual(judge.result?.feedback, .missed)
    }

    func testNothingCountsOnceTheAttemptIsOver() {
        let judge = DrillJudge(goal: .shot(.ramp), at: 0)
        judge.drained(at: 1)
        let verdict = judge.result
        judge.tableEvent(.rampCompleted(side: .left), at: 1.5)
        XCTAssertEqual(judge.result, verdict)
    }

    func testEveryDrillTimesOut() {
        for drill in DrillID.allCases {
            let judge = DrillJudge(goal: drill.goal, at: 0)
            judge.tick(at: 30, ballY: 0.4, cradledOn: nil)
            XCTAssertEqual(judge.result?.success, false, drill.rawValue)
        }
    }

    // MARK: Runs and records

    func testATenAttemptRunEarnsStars() {
        var run = DrillRun(drill: .cradle)
        for index in 0..<12 {
            run.record(DrillAttemptResult(success: index < 7, feedback: index < 7 ? .cradled : .drained,
                                          bladePosition: nil, timingMs: nil))
        }
        XCTAssertTrue(run.isFinished)
        XCTAssertEqual(run.results.count, 10, "a run stops at ten")
        XCTAssertEqual(run.successes, 7)
        XCTAssertEqual(run.stars, 2)
        XCTAssertEqual(Mastery.stars(forSuccesses: 4), 0)
        XCTAssertEqual(Mastery.stars(forSuccesses: 9), 3)
    }

    func testTheRecordKeepsTheBestRunAndTheSweetSpot() {
        var record = DrillRecord()
        var run = DrillRun(drill: .rampShot)
        let blades = [0.70, 0.72, 0.75, 0.78, 0.30, 0.95, 0.74, 0.71, 0.20, 0.76]
        for (index, blade) in blades.enumerated() {
            let hit = ![4, 5, 8].contains(index)
            run.record(DrillAttemptResult(success: hit, feedback: hit ? .hit : .missed,
                                          bladePosition: blade, timingMs: nil))
        }
        record.absorb(run)
        XCTAssertEqual(record.bestSuccesses, 7)
        XCTAssertEqual(record.hitBlades.count, 7)
        XCTAssertEqual(record.missBlades.count, 3)
        let spot = try? XCTUnwrap(record.sweetSpot)
        XCTAssertNotNil(spot)
        XCTAssertGreaterThanOrEqual(spot?.lowerBound ?? 0, 0.70)
        XCTAssertLessThanOrEqual(spot?.upperBound ?? 1, 0.78)

        var worse = DrillRun(drill: .rampShot)
        for _ in 0..<10 {
            worse.record(DrillAttemptResult(success: false, feedback: .missed,
                                            bladePosition: 0.5, timingMs: nil))
        }
        record.absorb(worse)
        XCTAssertEqual(record.bestSuccesses, 7, "a worse run does not lower the best")
        XCTAssertEqual(record.runs, 2)
    }

    func testAnUnfinishedRunIsNotSaved() {
        var record = DrillRecord()
        var run = DrillRun(drill: .cradle)
        run.record(DrillAttemptResult(success: true, feedback: .cradled,
                                      bladePosition: nil, timingMs: nil))
        record.absorb(run)
        XCTAssertEqual(record.runs, 0)
    }

    func testAnOldSaveWithoutAcademyStillLoads() throws {
        let old = #"{"version":1,"highScores":[],"settings":{"ballCount":5}}"#
        let decoded = try JSONDecoder().decode(SavedData.self, from: Data(old.utf8))
        XCTAssertEqual(decoded.settings.ballCount, 5)
        XCTAssertTrue(decoded.academy.isEmpty)

        var saved = decoded
        saved.academy[DrillID.cradle.rawValue] = DrillRecord(bestSuccesses: 8, runs: 1)
        let round = try JSONDecoder().decode(SavedData.self, from: JSONEncoder().encode(saved))
        XCTAssertEqual(round.academy["cradle"]?.bestSuccesses, 8)
    }

    // MARK: Words

    func testEveryDrillAndVerdictIsTranslated() {
        var keys: [String] = []
        for drill in DrillID.allCases {
            keys += ["name", "skill", "what", "how", "why"].map { "drill.\(drill.rawValue).\($0)" }
        }
        let verdicts: [DrillFeedback] = [.cradled, .caught, .passed, .hit, .noFlip, .flippedIntoIt,
                                         .flippedLate, .drained, .timeout, .tooHard, .neverCradled,
                                         .missed]
        for verdict in verdicts {
            keys += ["academy.fb.\(verdict.rawValue)", "academy.fb.\(verdict.rawValue).tip"]
        }
        let parts: [StruckPart] = [.ramp, .dropTarget, .standup, .bumper, .saucer, .orbit,
                                   .spinner, .lane]
        keys += parts.map { "academy.struck.\($0.rawValue)" }
        keys += (0...3).map { "academy.mastery.\($0)" }
        for key in keys {
            let pair = Strings.all[key]
            XCTAssertNotNil(pair, "missing \(key)")
            XCTAssertFalse(pair?.pt.isEmpty ?? true, key)
            XCTAssertFalse(pair?.en.isEmpty ?? true, key)
        }
    }
}
