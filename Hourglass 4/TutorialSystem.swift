//
//  TutorialSystem.swift
//  Hourglass 4
//
//  In-app tutorial spotlight system
//

import SwiftUI
import Combine
import FirebaseAuth

enum TutorialCardPlacement {
    case automatic
    case bottom
    case top
}

struct TutorialHighlight {
    let rect: CGRect
    let cornerRadius: CGFloat
}

struct TutorialStep: Identifiable {
    let id: String
    let title: String
    let message: String
    let anchorId: String
    let tab: Int
    let cornerRadius: CGFloat
    let highlightPadding: CGFloat
    let cardPlacement: TutorialCardPlacement
    let secondaryAnchorId: String?
    let secondaryCornerRadius: CGFloat
    let secondaryHighlightPadding: CGFloat?

    init(
        id: String,
        title: String,
        message: String,
        anchorId: String,
        tab: Int,
        cornerRadius: CGFloat,
        highlightPadding: CGFloat,
        cardPlacement: TutorialCardPlacement = .automatic,
        secondaryAnchorId: String? = nil,
        secondaryCornerRadius: CGFloat = 14,
        secondaryHighlightPadding: CGFloat? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.anchorId = anchorId
        self.tab = tab
        self.cornerRadius = cornerRadius
        self.highlightPadding = highlightPadding
        self.cardPlacement = cardPlacement
        self.secondaryAnchorId = secondaryAnchorId
        self.secondaryCornerRadius = secondaryCornerRadius
        self.secondaryHighlightPadding = secondaryHighlightPadding
    }

    static let allSteps: [TutorialStep] = [
        TutorialStep(
            id: "sablier.header",
            title: "Bienvenue sur Hourglass",
            message: "Ici, tu vois ta journée et l’accès rapide à ton profil.",
            anchorId: "sablier.header",
            tab: 1,
            cornerRadius: 14,
            highlightPadding: 6,
            cardPlacement: .automatic
        ),
        TutorialStep(
            id: "sablier.card",
            title: "Ton sablier du jour",
            message: "Ce cercle montre les grains gagnés grâce à tes objectifs journaliers, par rapport à ton potentiel du jour.",
            anchorId: "sablier.card",
            tab: 1,
            cornerRadius: 24,
            highlightPadding: 8,
            cardPlacement: .bottom
        ),
        TutorialStep(
            id: "objectives.header",
            title: "Tes objectifs",
            message: "Tout ce qui concerne tes objectifs du jour est ici.",
            anchorId: "objectives.header",
            tab: 2,
            cornerRadius: 14,
            highlightPadding: 6,
            cardPlacement: .automatic,
            secondaryAnchorId: "objectives.add",
            secondaryCornerRadius: 14,
            secondaryHighlightPadding: 2
        ),
        TutorialStep(
            id: "objectives.budget",
            title: "Budget quotidien",
            message: "Chaque jour, l'app te donne des grains à gagner en accomplissant tes objectifs quotidiens, que tu te définis toi-même.",
            anchorId: "objectives.budget",
            tab: 2,
            cornerRadius: 20,
            highlightPadding: 8,
            cardPlacement: .automatic
        ),
        TutorialStep(
            id: "feed.header",
            title: "Fil des victoires",
            message: "Retrouve les victoires de tes amis ici.",
            anchorId: "feed.header",
            tab: 0,
            cornerRadius: 14,
            highlightPadding: 6,
            cardPlacement: .automatic,
            secondaryAnchorId: "feed.tab",
            secondaryCornerRadius: 18
        ),
        TutorialStep(
            id: "feed.filters",
            title: "Filtres du feed",
            message: "Complices: les posts actifs de tes amis.\nSemaine: les victoires marquantes de la communauté.\nMes victoires: tes propres posts en cours.",
            anchorId: "feed.filters",
            tab: 0,
            cornerRadius: 14,
            highlightPadding: 6,
            cardPlacement: .automatic
        ),
        TutorialStep(
            id: "feed.grains",
            title: "Grains disponibles",
            message: "Ce sont les grains que tu as gagnés aujourd'hui en réalisant tes objectifs. Ils te servent à récompenser les posts de tes complices.",
            anchorId: "feed.grains",
            tab: 0,
            cornerRadius: 14,
            highlightPadding: 6,
            cardPlacement: .top
        )
    ]
}

final class TutorialManager: ObservableObject {
    static let shared = TutorialManager()
    static let coordinateSpaceName = "TutorialCoordinateSpace"

    @Published var isActive = false
    @Published var currentStepIndex = 0
    @Published var currentTab = 1
    @Published var currentPageId: String?

    let steps: [TutorialStep] = TutorialStep.allSteps
    private var lastCheckedUserId: String?
    private let localDefaults = UserDefaults.standard
    private var missingAnchorWorkItem: DispatchWorkItem?
    private var missingAnchorStepId: String?

    var currentStep: TutorialStep? {
        guard isActive, steps.indices.contains(currentStepIndex) else { return nil }
        return steps[currentStepIndex]
    }

    func startIfNeeded() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if lastCheckedUserId == uid { return }
        lastCheckedUserId = uid

        if hasShownLocally(for: uid) {
            return
        }

        let completed = (try? await UserManager.shared.getTutorialCompleted(uid: uid)) ?? true
        if completed == false {
            await MainActor.run {
                self.start(force: true)
            }
            setShownLocally(for: uid)
        } else {
            setShownLocally(for: uid)
        }
    }

    @MainActor
    func start(force: Bool = false) {
        guard force || !isActive else { return }
        currentStepIndex = 0
        currentTab = steps.first?.tab ?? 1
        currentPageId = steps.first?.anchorId
        isActive = true
    }

    @MainActor
    func next() {
        let nextIndex = currentStepIndex + 1
        if steps.indices.contains(nextIndex) {
            currentStepIndex = nextIndex
            currentTab = steps[nextIndex].tab
            currentPageId = steps[nextIndex].anchorId
        } else {
            finish()
        }
    }

    @MainActor
    func skip() {
        isActive = false
        Task { await markCompleted() }
    }

    @MainActor
    func finish() {
        isActive = false
        Task { await markCompleted() }
    }

    @MainActor
    func reportMissingAnchor(for stepId: String) {
        // Auto-skip disabled: keep the step visible until user taps.
        missingAnchorWorkItem?.cancel()
        missingAnchorWorkItem = nil
        missingAnchorStepId = stepId
    }

    @MainActor
    func reportFoundAnchor() {
        missingAnchorWorkItem?.cancel()
        missingAnchorWorkItem = nil
        missingAnchorStepId = nil
    }

    private func markCompleted() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        setShownLocally(for: uid)
        try? await UserManager.shared.setTutorialCompleted(uid: uid, completed: true)
    }

    private func localKey(for uid: String) -> String {
        "tutorial.shown.\(uid)"
    }

    private func hasShownLocally(for uid: String) -> Bool {
        localDefaults.bool(forKey: localKey(for: uid))
    }

    private func setShownLocally(for uid: String) {
        localDefaults.set(true, forKey: localKey(for: uid))
    }
}

extension View {
    func tutorialAnchor(_ id: String) -> some View {
        modifier(TutorialAnchorModifier(id: id))
    }
}

struct TutorialFrameKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct TutorialAnchorModifier: ViewModifier {
    let id: String
    @EnvironmentObject private var tutorialManager: TutorialManager

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                let isPrimary = tutorialManager.currentStep?.anchorId == id
                let isSecondary = tutorialManager.currentStep?.secondaryAnchorId == id
                Color.clear.preference(
                    key: TutorialFrameKey.self,
                    value: (isPrimary || isSecondary)
                        ? [id: proxy.frame(in: .named(TutorialManager.coordinateSpaceName))]
                        : [:]
                )
            }
        )
    }
}

struct TutorialOverlayView: View {
    let step: TutorialStep
    let stepIndex: Int
    let totalSteps: Int
    let highlightRect: CGRect?
    let highlights: [TutorialHighlight]
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if !highlights.isEmpty {
                    SpotlightDimmer(highlights: highlights)
                        .ignoresSafeArea()
                        .onTapGesture { }
                }

                TutorialCardView(
                    step: step,
                    stepIndex: stepIndex,
                    totalSteps: totalSteps,
                    highlightRect: highlightRect,
                    containerSize: proxy.size,
                    onNext: onNext,
                    onSkip: onSkip
                )
            }
            .transition(.opacity)
        }
    }
}

struct SpotlightDimmer: View {
    let highlights: [TutorialHighlight]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.85)
                Rectangle()
                    .fill(Color.black.opacity(0.25))
                ForEach(highlights.indices, id: \.self) { index in
                    let highlight = highlights[index]
                    RoundedRectangle(cornerRadius: highlight.cornerRadius, style: .continuous)
                        .frame(width: highlight.rect.width, height: highlight.rect.height)
                        .position(x: highlight.rect.midX, y: highlight.rect.midY)
                        .blendMode(.destinationOut)
                }
            }
            .compositingGroup()
        }
    }
}

struct TutorialCardView: View {
    let step: TutorialStep
    let stepIndex: Int
    let totalSteps: Int
    let highlightRect: CGRect?
    let containerSize: CGSize
    let onNext: () -> Void
    let onSkip: () -> Void

    @State private var cardSize: CGSize = .zero

    private var cardWidth: CGFloat {
        min(containerSize.width - 32, 320)
    }

    private func cardYPosition() -> CGFloat {
        guard cardSize.height > 0 else {
            return containerSize.height * 0.7
        }

        if step.cardPlacement == .bottom {
            let bottomInset: CGFloat = 92
            let target = containerSize.height - bottomInset - (cardSize.height / 2)
            return max(target, 16 + (cardSize.height / 2))
        }

        if step.cardPlacement == .top {
            let topInset: CGFloat = 110
            let target = topInset + (cardSize.height / 2)
            return min(target, containerSize.height - 16 - (cardSize.height / 2))
        }

        guard let rect = highlightRect else {
            return containerSize.height * 0.7
        }

        let spaceAbove = rect.minY - 16
        let spaceBelow = containerSize.height - rect.maxY - 16
        let needsBelow = spaceBelow >= cardSize.height || spaceBelow >= spaceAbove

        if needsBelow {
            let target = rect.maxY + 16 + (cardSize.height / 2)
            return min(target, containerSize.height - 16 - (cardSize.height / 2))
        } else {
            let target = rect.minY - 16 - (cardSize.height / 2)
            return max(target, 16 + (cardSize.height / 2))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Étape \(stepIndex + 1) / \(totalSteps)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                )

            Text(step.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text(step.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Button("Passer") {
                    onSkip()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

                Spacer()

                Button(stepIndex == totalSteps - 1 ? "Terminer" : "Suivant") {
                    onNext()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color(red: 1.0, green: 0.6, blue: 0.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
        }
        .padding(16)
        .frame(width: cardWidth)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.9),
                                    Color.orange.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
        )
        .readSize { size in
            cardSize = size
        }
        .position(x: containerSize.width / 2, y: cardYPosition())
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private extension View {
    func readSize(_ onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: proxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}
