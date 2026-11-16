import SpriteKit
import SwiftUI

/// One Flipper Academy drill: the lesson card first, then ten attempts on the
/// real table with a verdict after each one, then the result.
struct DrillView: View {

    let drill: DrillID
    let audio: AudioEngine
    let haptics: HapticsEngine
    let onNext: (DrillID) -> Void
    let onBack: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var model: DrillModel
    @State private var gameModel = GameModel()
    @State private var scene = PinballScene()
    @State private var isConfigured = false
    @State private var showsLesson = true
    /// The record as it stood before this run, to tell a new best.
    @State private var bestBefore = 0

    init(drill: DrillID, audio: AudioEngine, haptics: HapticsEngine,
         onNext: @escaping (DrillID) -> Void, onBack: @escaping () -> Void) {
        self.drill = drill
        self.audio = audio
        self.haptics = haptics
        self.onNext = onNext
        self.onBack = onBack
        _model = State(initialValue: DrillModel(drill: drill))
        _showsLesson = State(initialValue: !QAFlags.autoplay)
    }

    private var nextDrill: DrillID? {
        let all = DrillID.allCases
        guard let index = all.firstIndex(of: drill), index + 1 < all.count else { return nil }
        return all[index + 1]
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ZStack {
                    Color(platform: CabinetColors.cabinet).ignoresSafeArea()

                    SpriteView(scene: prepared(for: proxy.size),
                               preferredFramesPerSecond: 60,
                               options: [.ignoresSiblingOrder])
                        .ignoresSafeArea()
                        .accessibilityHidden(true)

                    if !showsLesson && !model.isFinished && !model.isPaused
                        && PlatformTraits.usesTouchControls {
                        HStack(spacing: 0) {
                            zone(.left, label: settings.t("a11y.leftFlipper"))
                            zone(.right, label: settings.t("a11y.rightFlipper"))
                        }
                    }

                    VStack(spacing: 10) {
                        coachBar
                        if let result = model.lastResult, !showsLesson {
                            VerdictCard(result: result, drill: drill)
                                .frame(maxWidth: 460)
                                .id(model.resultCount)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                .allowsHitTesting(false)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .animation(Motion.respectingReduceMotion(Motion.snappy,
                                                             reduceMotion: reduceMotion),
                               value: model.resultCount)
                }
                .gameKeyboardControls(scene: scene, model: gameModel,
                                      pause: {}, resume: {})

                if showsLesson {
                    LessonCard(drill: drill, onStart: start, onBack: leave)
                        .transition(.opacity)
                }

                if model.isFinished {
                    DrillResultCard(run: model.run, bestBefore: bestBefore,
                                    hasNext: nextDrill != nil,
                                    onAgain: again,
                                    onNext: { if let next = nextDrill { scene.setPaused(true); onNext(next) } },
                                    onList: leave)
                        .transition(.opacity)
                }
            }
        }
        .onChange(of: model.slowMotion) { _, _ in scene.applyTableSpeed() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { scene.setPaused(true) }
            else if !showsLesson && !model.isFinished { scene.setPaused(false) }
        }
        .onDisappear { scene.setPaused(true) }
    }

    // MARK: - Pieces

    private var coachBar: some View {
        VStack(spacing: 8) {
            coachRow
            // At the top, not the bottom: down there it covered the very
            // flippers it is about.
            if drill.usesBladeGuide && !showsLesson {
                BladeGuide(results: model.run.results,
                           sweetSpot: settings.record(for: drill).sweetSpot)
                    .allowsHitTesting(false)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(palette.surfaceColor.opacity(0.92)))
        .frame(maxWidth: 460)
    }

    private var coachRow: some View {
        @Bindable var model = model
        return HStack(spacing: 10) {
            Button(action: leave) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(palette.textColor)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(palette.surfaceRaisedColor))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(settings.t("academy.back")))

            VStack(alignment: .leading, spacing: 2) {
                Text(settings.t("drill.\(drill.rawValue).name"))
                    .font(Typography.title(17))
                    .foregroundStyle(palette.textColor)
                Text("\(settings.t("academy.attempt", model.run.attempt, DrillRun.attemptsPerRun)) · \(settings.t("academy.successes", model.run.successes))")
                    .font(Typography.mono(12))
                    .foregroundStyle(palette.dimColor)
                    .contentTransition(.numericText())
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 6)

            Button {
                model.slowMotion.toggle()
            } label: {
                Image(systemName: "tortoise.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(model.slowMotion ? Color(platform: .hex(0x14100A))
                                                      : palette.dimColor)
                    .frame(width: 44, height: 38)
                    .background(
                        Capsule().fill(model.slowMotion ? AnyShapeStyle(palette.accentGradient)
                                                        : AnyShapeStyle(palette.surfaceRaisedColor)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(settings.t("academy.slowMotion")))
            .accessibilityAddTraits(model.slowMotion ? [.isSelected] : [])
        }
    }

    private func zone(_ side: TableSide, label: String) -> some View {
        FlipperZone(label: label,
                    onPress: { scene.pressFlipper(side: side) },
                    onRelease: { scene.releaseFlipper(side: side) },
                    onNudge: { scene.nudge(direction: $0) })
    }

    // MARK: - Scene wiring

    private func prepared(for size: CGSize) -> PinballScene {
        guard !isConfigured, size.width > 0, size.height > 0 else { return scene }
        scene.size = size
        scene.scaleMode = .resizeFill
        scene.drillModel = model
        scene.audio = audio
        scene.haptics = haptics
        scene.palette = palette
        scene.reduceMotion = reduceMotion
        bestBefore = settings.record(for: drill).bestSuccesses
        let settings = settings
        model.onFinished = { run in settings.recordDrill(run) }

        DispatchQueue.main.async {
            isConfigured = true
            scene.startGame()
            // The table waits behind the lesson card until the player is ready.
            if showsLesson { scene.setPaused(true) }
        }
        return scene
    }

    // MARK: - Commands

    private func start() {
        withAnimation(Motion.standard) { showsLesson = false }
        scene.restartDrill()
        scene.setPaused(false)
        audio.play(.uiTap)
    }

    private func again() {
        bestBefore = settings.record(for: drill).bestSuccesses
        scene.restartDrill()
        scene.setPaused(false)
    }

    private func leave() {
        scene.setPaused(true)
        onBack()
    }
}

// MARK: - Lesson

private struct LessonCard: View {
    let drill: DrillID
    let onStart: () -> Void
    let onBack: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: drill.icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(palette.accentColor)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(palette.surfaceRaisedColor))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(settings.t("drill.\(drill.rawValue).name"))
                                .font(Typography.display(24))
                                .foregroundStyle(palette.textColor)
                            Text(settings.t("drill.\(drill.rawValue).skill"))
                                .font(Typography.body(13))
                                .foregroundStyle(palette.dimColor)
                        }
                    }
                    section("academy.what", "drill.\(drill.rawValue).what")
                    section("academy.how", "drill.\(drill.rawValue).how")
                    section("academy.why", "drill.\(drill.rawValue).why")

                    NeonButton(title: settings.t("academy.start"), systemImage: "play.fill",
                               kind: .primary, action: onStart)
                        .keyboardShortcut(.defaultAction)
                    NeonButton(title: settings.t("academy.back"), systemImage: "chevron.left",
                               kind: .ghost, action: onBack)
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(palette.surfaceColor))
                .frame(maxWidth: 440)
                .padding(16)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            SectionLabel(text: settings.t(title))
            Text(settings.t(body))
                .font(Typography.body(14))
                .foregroundStyle(palette.textColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Verdict

private struct VerdictCard: View {
    let result: DrillAttemptResult
    let drill: DrillID

    @Environment(AppSettings.self) private var settings
    @Environment(\.palette) private var palette

    var body: some View {
        let key = "academy.fb.\(result.feedback.rawValue)"
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(result.success ? palette.accentLightColor : palette.dangerColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(settings.t(key))
                    .font(Typography.title(16))
                    .foregroundStyle(palette.textColor)
                Text(settings.t(key + ".tip"))
                    .font(Typography.body(13))
                    .foregroundStyle(palette.dimColor)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(detail)
                        .font(Typography.mono(12))
                        .foregroundStyle(palette.accentLightColor)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(palette.surfaceColor.opacity(0.94)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder((result.success ? palette.accentColor : palette.dangerColor).opacity(0.5),
                          lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private var detail: String? {
        if let blade = result.bladePosition {
            var line = settings.t("academy.blade", Int((blade * 100).rounded()))
            if let struck = result.struck {
                line += "\n" + settings.t("academy.struck", settings.t("academy.struck.\(struck.rawValue)"))
            }
            return line
        }
        if let timing = result.timingMs, drill.goal == .deadCatch || !result.success {
            return timing < 0 ? settings.t("academy.timing", -timing)
                              : settings.t("academy.timingLate", timing)
        }
        return nil
    }
}

// MARK: - Blade guide

/// A flipper drawn as a bar from base to tip, with a mark where each shot of
/// this run was flipped: the player's own aiming chart.
private struct BladeGuide: View {
    let results: [DrillAttemptResult]
    let sweetSpot: ClosedRange<Double>?

    @Environment(AppSettings.self) private var settings
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(settings.t("academy.bladeBase"))
                GeometryReader { proxy in
                    let width = proxy.size.width
                    ZStack(alignment: .leading) {
                        Capsule().fill(palette.surfaceRaisedColor)
                        if let sweetSpot {
                            Capsule()
                                .fill(palette.accentColor.opacity(0.3))
                                .frame(width: max(8, width * (sweetSpot.upperBound - sweetSpot.lowerBound)))
                                .offset(x: width * sweetSpot.lowerBound)
                        }
                        ForEach(Array(results.enumerated()), id: \.offset) { _, result in
                            if let blade = result.bladePosition {
                                Circle()
                                    .fill(result.success ? palette.accentLightColor : palette.dangerColor)
                                    .frame(width: 9, height: 9)
                                    .offset(x: width * blade - 4.5)
                            }
                        }
                    }
                }
                .frame(height: 11)
                Text(settings.t("academy.bladeTip"))
            }
            .font(Typography.label(10))
            .foregroundStyle(palette.faintColor)
            Text(sweetSpot.map {
                settings.t("academy.sweetSpot", Int(($0.lowerBound * 100).rounded()),
                           Int(($0.upperBound * 100).rounded()))
            } ?? settings.t("academy.sweetSpotNone"))
                .font(Typography.body(11))
                .foregroundStyle(palette.dimColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(settings.t("academy.bladeTitle")))
    }
}

// MARK: - Result

private struct DrillResultCard: View {
    let run: DrillRun
    let bestBefore: Int
    let hasNext: Bool
    let onAgain: () -> Void
    let onNext: () -> Void
    let onList: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 14) {
                Text(settings.t("academy.done"))
                    .font(Typography.label(12))
                    .kerning(2)
                    .textCase(.uppercase)
                    .foregroundStyle(palette.dimColor)
                Text(settings.t("drill.\(run.drill.rawValue).name"))
                    .font(Typography.display(26))
                    .foregroundStyle(palette.textColor)
                StarRow(stars: run.stars, size: 30)
                Text(settings.t("academy.score", run.successes))
                    .font(Typography.score(34))
                    .foregroundStyle(palette.accentLightColor)
                if run.successes > bestBefore {
                    Text(settings.t("academy.newBest"))
                        .font(Typography.label(13))
                        .kerning(2)
                        .foregroundStyle(palette.accentColor)
                }
                Text(settings.t("academy.mastery.\(run.stars)"))
                    .font(Typography.body(14))
                    .foregroundStyle(palette.dimColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                NeonButton(title: settings.t("academy.again"), systemImage: "arrow.counterclockwise",
                           kind: .primary, action: onAgain)
                    .keyboardShortcut(.defaultAction)
                if hasNext {
                    NeonButton(title: settings.t("academy.next"), systemImage: "forward.fill",
                               kind: .secondary, action: onNext)
                }
                NeonButton(title: settings.t("academy.toList"), systemImage: "list.bullet",
                           kind: .ghost, action: onList)
            }
            .padding(22)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(palette.surfaceColor))
            .frame(maxWidth: 400)
            .padding(16)
        }
    }
}
