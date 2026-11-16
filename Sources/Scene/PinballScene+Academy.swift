import SpriteKit

/// The Flipper Academy on the real table: feeding the ball for each attempt,
/// telling the judge what the flippers and the ball did, and moving on once
/// it has ruled.
extension PinballScene {

    /// How fast the table runs: half speed in a drill's slow motion.
    var tableSpeed: CGFloat {
        (drillModel?.slowMotion ?? false) ? 0.5 : 1
    }

    /// Keeps the physics and the scripted moves (ramps, saucers) at the
    /// table's speed, so slow motion slows everything together.
    func applyTableSpeed() {
        let target = tableSpeed
        if physicsWorld.speed != target { physicsWorld.speed = target }
        if speed != target { speed = target }
    }

    func startDrill() {
        removeAllActions()
        gameGeneration += 1
        releaseAllFlippers()
        saucerReadyAt.removeAll()
        bonusCountdown = 0
        _ = session.startGame(ballCount: 1, at: sceneTime)
        // The contact handlers only listen while a ball is in play.
        _ = session.launchBall(at: sceneTime)
        setGeneralIllumination(on: true)
        drillModel?.restart()
        feedDrillBall()
    }

    /// Puts a fresh ball on its way to the flippers for the next attempt.
    func feedDrillBall() {
        guard let drillModel else { return }
        balls.forEach { $0.removeFromParent() }
        balls.removeAll()
        ballsOnRamp.removeAll()
        heldSaucers.removeAll()
        resetTableElements()

        // Alternate the sides, so both hands get the same practice.
        let side: TableSide = drillModel.run.results.count.isMultiple(of: 2) ? .left : .right
        drillModel.side = side
        // The playfield, not the cabinet, is symmetric about x = 0.5.
        let mirror: (CGFloat) -> CGFloat = { side == .left ? $0 : 1 - $0 }

        let ball: BallNode
        let velocity: CGVector
        switch drillModel.drill.feed {
        case .inlane:
            // From the foot of the inlane, rolling slowly on to the flipper.
            // Fed from the top of the inlane, as a ramp returns it, the ball
            // arrived with just enough speed to climb a raised flipper to its
            // tip, and on a narrow screen it went over the end every time.
            let start = CGPoint(x: mirror(0.250), y: 0.246)
            ball = spawnBall(at: start)
            let along = CGVector(dx: 0.085, dy: -0.032).normalized()
            velocity = CGVector(dx: geometry.length(0.10 * along.dx * (side == .left ? 1 : -1)),
                                dy: geometry.length(0.10 * along.dy))
        case .centreDrop:
            ball = spawnBall(at: CGPoint(x: mirror(0.405), y: 0.56))
            velocity = CGVector(dx: geometry.length(.random(in: -0.04...0.04)),
                                dy: -geometry.length(.random(in: 0.30...0.55)))
        }
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.velocity = velocity
        drillJudge = DrillJudge(goal: drillModel.drill.goal, at: sceneTime)
    }

    /// Where the ball is along `side`'s blade, from the pivot (0) to the tip
    /// (1), or nil when it is not on or right by that flipper.
    func bladePosition(on side: TableSide) -> Double? {
        guard let flipper = parts.flippers.first(where: { $0.side == side }) else { return nil }
        let nearest = balls
            .filter { !$0.isOnRamp }
            .map { $0.position.distance(to: flipper.pivotInScene) }
            .min()
        guard let distance = nearest, distance < flipper.reach * 1.15 else { return nil }
        return Double(min(1, distance / flipper.reach))
    }

    func tickDrill() {
        #if DEBUG
        traceDrillForQA()
        #endif
        guard let judge = drillJudge, !judge.isOver, let ball = balls.first else { return }
        let slowEnough = ball.speed2D < geometry.length(0.12)
        let cradledOn = slowEnough
            ? parts.flippers.first(where: { $0.isCradling(ball.position) })?.side
            : nil
        judge.tick(at: sceneTime, ballY: geometry.localPoint(ball.position).y,
                   cradledOn: cradledOn)
        concludeAttemptIfOver()
    }

    func drillEvent(_ event: TableEvent) {
        guard let judge = drillJudge else { return }
        #if DEBUG
        tallyForQA(event)
        #endif
        if case .ballDrained = event {
            judge.drained(at: sceneTime)
        } else {
            judge.tableEvent(event, at: sceneTime)
            // The table still lights up and sounds as it would in a game.
            playDrillSound(for: event)
        }
        concludeAttemptIfOver()
    }

    private func playDrillSound(for event: TableEvent) {
        switch event {
        case .popBumper:      audio?.play(.bumper)
        case .slingshot:      audio?.play(.slingshot)
        case .standupTarget:  audio?.play(.target)
        case .dropTarget:     audio?.play(.dropTarget)
        case .rampCompleted:  audio?.play(.ramp)
        case .orbitCompleted: audio?.play(.orbit)
        case .spinnerRotation: audio?.play(.spinner)
        default: break
        }
    }

    private func concludeAttemptIfOver() {
        guard let judge = drillJudge, let result = judge.result, let drillModel else { return }
        drillJudge = nil
        drillModel.record(result)
        #if DEBUG
        logDrillForQA(result, attempt: drillModel.run.results.count)
        #endif

        if result.success {
            audio?.play(.laneSet)
            haptics?.tap(.medium)
            if let ball = balls.first {
                flash(at: ball.position, color: palette.accentLight, radius: geometry.length(0.10))
            }
        } else {
            audio?.play(result.feedback == .drained ? .drain : .missionFail)
            haptics?.tap(.light)
        }

        // A beat to read the verdict, then the next ball, unless that was
        // the tenth.
        afterDelay(1.1) { [weak self] in
            guard let self, let model = self.drillModel else { return }
            self.releaseAllFlippers()
            if model.isFinished {
                self.balls.forEach { $0.removeFromParent() }
                self.balls.removeAll()
            } else {
                self.feedDrillBall()
            }
        }
    }

    /// Starts the same drill again from attempt one.
    func restartDrill() {
        startDrill()
    }
}
