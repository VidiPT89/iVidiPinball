import SwiftUI

/// The list of Flipper Academy drills, in the order a player should learn
/// them, with the stars each one has earned.
struct AcademyView: View {

    let onDrill: (DrillID) -> Void
    let onBack: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.palette) private var palette

    private let control: [DrillID] = [.cradle, .deadCatch, .tapPass]
    private let aim: [DrillID] = [.rampShot, .dropShot, .standupShot]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .black))
                        Text(settings.t("academy.back"))
                            .font(Typography.label(15))
                    }
                    .foregroundStyle(palette.textColor)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(Capsule().fill(palette.surfaceRaisedColor))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                Spacer()
                StarTally(stars: settings.academyStars, total: DrillID.allCases.count * 3)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(settings.t("academy.title"))
                        .font(Typography.display(30))
                        .foregroundStyle(palette.textColor)
                        .accessibilityAddTraits(.isHeader)
                    Text(settings.t("academy.intro"))
                        .font(Typography.body(14))
                        .foregroundStyle(palette.dimColor)
                        .fixedSize(horizontal: false, vertical: true)

                    SectionLabel(text: settings.t("academy.group.control"))
                    ForEach(control) { drillCard($0) }

                    SectionLabel(text: settings.t("academy.group.aim"))
                    ForEach(aim) { drillCard($0) }
                }
                .frame(maxWidth: 460)
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private func drillCard(_ drill: DrillID) -> some View {
        let record = settings.record(for: drill)
        return Button { onDrill(drill) } label: {
            GlowCard(padding: 16) {
                HStack(spacing: 14) {
                    Image(systemName: drill.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(palette.accentColor)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(palette.surfaceRaisedColor))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(settings.t("drill.\(drill.rawValue).name"))
                            .font(Typography.title(17))
                            .foregroundStyle(palette.textColor)
                        Text(settings.t("drill.\(drill.rawValue).skill"))
                            .font(Typography.body(13))
                            .foregroundStyle(palette.dimColor)
                        Text(record.runs == 0
                             ? settings.t("academy.notTried")
                             : settings.t("academy.best", record.bestSuccesses))
                            .font(Typography.label(11))
                            .foregroundStyle(palette.faintColor)
                    }
                    Spacer(minLength: 6)
                    StarRow(stars: record.stars, size: 13)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// Three stars, filled up to `stars`.
struct StarRow: View {
    let stars: Int
    var size: CGFloat = 14
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < stars ? "star.fill" : "star")
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(index < stars ? palette.accentLightColor : palette.faintColor)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: "\(stars)/3 ★"))
    }
}

private struct StarTally: View {
    let stars: Int
    let total: Int
    @Environment(AppSettings.self) private var settings
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 12, weight: .bold))
            Text(verbatim: "\(stars)/\(total)")
                .font(Typography.mono(14))
        }
        .foregroundStyle(palette.accentLightColor)
        .padding(.horizontal, 14)
        .frame(height: 36)
        .background(Capsule().fill(palette.surfaceRaisedColor))
        .accessibilityElement()
        .accessibilityLabel(Text(settings.t("academy.stars", stars, total)))
    }
}
