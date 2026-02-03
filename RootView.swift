//
//  RootView.swift
//  Hourglass 4
//
//  Affiche LoginView tant que l'utilisateur n'est pas authentifié via Firebase,
//  puis bascule sur le contenu principal une fois connecté.
//

import SwiftUI
import FirebaseAuth
import SwiftData

struct RootView: View {
    let modelContext: ModelContext

    @State private var isAuthenticated: Bool = false
    @State private var authListenerHandle: AuthStateDidChangeListenerHandle?
    @State private var showSplash = true
    @ObservedObject private var notificationManager = NotificationPermissionManager.shared
    @ObservedObject private var deepLinkHandler = DeepLinkHandler.shared
    @State private var showNotificationPrompt = false
    @State private var showValidateGoalSheet = false
    @EnvironmentObject private var tutorialManager: TutorialManager

    var body: some View {
        ZStack {
            Group {
                if isAuthenticated {
                    ContentView(modelContext: modelContext)
                } else {
                    // LoginView gère la création et la connexion Email/Password
                    // Le RootView observe l'état Auth et bascule automatiquement
                    LoginView()
                }
            }

            if showSplash {
                SplashView()
                    .transition(.opacity)
            }

            if showNotificationPrompt {
                NotificationPermissionView(onDismiss: {
                    showNotificationPrompt = false
                }, onAllow: {
                    showNotificationPrompt = false
                    Task {
                        _ = await notificationManager.requestAuthorization()
                        await notificationManager.checkAuthorizationStatus()
                    }
                })
            }
        }
        .coordinateSpace(name: TutorialManager.coordinateSpaceName)
        .overlayPreferenceValue(TutorialFrameKey.self) { frames in
            GeometryReader { proxy in
                if tutorialManager.isActive, let step = tutorialManager.currentStep {
                    if let rect = frames[step.anchorId], rect.width > 0, rect.height > 0 {
                        let localRect = rect.insetBy(dx: -step.highlightPadding, dy: -step.highlightPadding)
                        let mainHighlight = TutorialHighlight(rect: localRect, cornerRadius: step.cornerRadius)
                        let secondaryHighlight: TutorialHighlight? = {
                            guard let secondaryId = step.secondaryAnchorId,
                                  let secondaryRect = frames[secondaryId],
                                  secondaryRect.width > 0,
                                  secondaryRect.height > 0 else { return nil }
                            let secondaryPadding = step.secondaryHighlightPadding ?? step.highlightPadding
                            let localSecondaryRect = secondaryRect.insetBy(dx: -secondaryPadding, dy: -secondaryPadding)
                            return TutorialHighlight(rect: localSecondaryRect, cornerRadius: step.secondaryCornerRadius)
                        }()
                        let highlights = [mainHighlight] + (secondaryHighlight.map { [$0] } ?? [])

                        TutorialOverlayView(
                            step: step,
                            stepIndex: tutorialManager.currentStepIndex,
                            totalSteps: tutorialManager.steps.count,
                            highlightRect: localRect,
                            highlights: highlights,
                            onNext: { tutorialManager.next() },
                            onSkip: { tutorialManager.skip() }
                        )
                        .onAppear {
                            tutorialManager.reportFoundAnchor()
                        }
                    } else {
                        Color.clear
                            .allowsHitTesting(false)
                            .onAppear {
                                tutorialManager.reportMissingAnchor(for: step.id)
                            }
                    }
                }
            }
        }
        .sheet(isPresented: $deepLinkHandler.showFriendRequestSheet) {
            if let username = deepLinkHandler.pendingFriendRequest {
                DeepLinkFriendRequestView(username: username)
            }
        }
        .sheet(isPresented: $showValidateGoalSheet) {
            // Sheet pour valider les objectifs depuis les notifications
            NavigationStack {
                ValidateGoalCameraView()
            }
        }
        .onOpenURL { url in
            deepLinkHandler.handle(url)
        }
        .onAppear {
            // État initial
            isAuthenticated = Auth.auth().currentUser != nil
            // Observer les changements d'état
            authListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
                DispatchQueue.main.async {
                    isAuthenticated = (user != nil)
                }
            }

            // Écouter les notifications pour ouvrir la caméra
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("OpenValidateGoal"),
                object: nil,
                queue: .main
            ) { _ in
                showValidateGoalSheet = true
            }

            if showSplash {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                    // Vérifier les notifications après le splash screen
                    checkNotificationStatus()
                }
            } else {
                // Vérifier immédiatement si le splash est déjà passé
                checkNotificationStatus()
            }
        }
        .onDisappear {
            if let handle = authListenerHandle {
                Auth.auth().removeStateDidChangeListener(handle)
                authListenerHandle = nil
            }
        }
        .onChange(of: notificationManager.authorizationStatus) { _, newStatus in
            // Cacher le prompt si l'utilisateur a autorisé ou refusé
            if newStatus == .authorized || newStatus == .denied {
                showNotificationPrompt = false
            }
        }
    }

    private func checkNotificationStatus() {
        Task {
            await notificationManager.checkAuthorizationStatus()
            // Afficher le prompt seulement si pas encore demandé ou refusé
            showNotificationPrompt = notificationManager.shouldShowPermissionPrompt
        }
    }
}

struct SplashView: View {
    @State private var glow = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.99, blue: 0.97),
                    Color(red: 1.0, green: 0.95, blue: 0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.orange.opacity(0.10))
                .frame(width: glow ? 300 : 240, height: glow ? 300 : 240)
                .blur(radius: 22)
                .opacity(glow ? 1 : 0.75)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: glow)

            VStack(spacing: 20) {
                RotatingHourglassView()

                Text("Hourglass")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.53, blue: 0.08), Color(red: 0.95, green: 0.66, blue: 0.21)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Ton temps devient héritage.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, -10)
        }
        .onAppear {
            glow = true
        }
    }
}

struct RotatingHourglassView: View {
    @State private var rotation: Double = 0
    @State private var sandProgress: CGFloat = 0
    @State private var sandOpacity: Double = 1
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.orange.opacity(0.14), lineWidth: 1)
                .frame(width: 132, height: 132)

            Circle()
                .stroke(Color.orange.opacity(0.09), lineWidth: 1)
                .frame(width: 152, height: 152)

            Image(systemName: "hourglass")
                .font(.system(size: 92, weight: .regular))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.53, blue: 0.08),
                            Color(red: 0.95, green: 0.66, blue: 0.21)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.orange.opacity(0.28), radius: 14, x: 0, y: 7)
                .rotationEffect(.degrees(rotation))

            Circle()
                .fill(Color.orange.opacity(0.85))
                .frame(width: 8, height: 8)
                .offset(y: -18 + (sandProgress * 36))
                .opacity(sandOpacity)
        }
        .frame(width: 120, height: 120)
        .onAppear {
            startAnimationLoop()
        }
        .onDisappear {
            animationTask?.cancel()
            animationTask = nil
        }
    }

    private func startAnimationLoop() {
        animationTask?.cancel()
        animationTask = Task {
            while !Task.isCancelled {
                await MainActor.run {
                    sandProgress = 0
                    sandOpacity = 1
                }

                await MainActor.run {
                    withAnimation(.linear(duration: 1.4)) {
                        sandProgress = 1
                    }
                }

                try? await Task.sleep(nanoseconds: 1_450_000_000)

                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        sandOpacity = 0
                    }
                }

                try? await Task.sleep(nanoseconds: 250_000_000)

                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        rotation += 180
                    }
                }

                try? await Task.sleep(nanoseconds: 650_000_000)

                await MainActor.run {
                    sandProgress = 0
                    withAnimation(.easeInOut(duration: 0.2)) {
                        sandOpacity = 1
                    }
                }
            }
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: UserProfile.self, Goal.self, Grain.self,
            configurations: config
        )
        return RootView(modelContext: container.mainContext)
    } catch {
        return Text("Erreur de prévisualisation: \(error.localizedDescription)")
    }
}
