import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @StateObject private var store = ChallengeStore()
    @AppStorage("geumyok.hasSeenOnboarding.v1") private var hasSeenOnboarding = false
    @State private var selectedTab: MainTab = .home
    @State private var showingNewChallenge = false
    @State private var showingIntro = true
    @State private var introContentVisible = false
    @State private var showingOnboarding = false
    @State private var didPlayIntro = false

    var body: some View {
        ZStack {
            AppBackground()

            if store.challenge != nil {
                DetailTabView(
                    store: store,
                    selectedTab: $selectedTab,
                    showingNewChallenge: $showingNewChallenge
                )
            } else {
                HomeOnlyTabView(
                    store: store,
                    selectedTab: $selectedTab,
                    showingNewChallenge: $showingNewChallenge
                )
            }

            if showingIntro {
                IntroSplashView(
                    showsContent: shouldShowFirstLaunchFlow,
                    isVisible: introContentVisible
                )
                    .zIndex(10)
                    .transition(.opacity)
            }
        }
        .task {
            await playIntroIfNeeded()
        }
        .onChange(of: store.selectedChallengeID) { _, newValue in
            selectedTab = newValue == nil ? .home : .detail
        }
        .sheet(isPresented: $showingNewChallenge) {
            StartChallengeView(store: store) {
                showingNewChallenge = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingOnboarding, onDismiss: completeOnboarding) {
            OnboardingTutorialView(onDone: completeOnboarding)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func playIntroIfNeeded() async {
        guard !didPlayIntro else { return }
        didPlayIntro = true

        if shouldShowFirstLaunchFlow {
            try? await Task.sleep(nanoseconds: 120_000_000)
            withAnimation(.easeOut(duration: 0.3)) {
                introContentVisible = true
            }

            try? await Task.sleep(nanoseconds: 820_000_000)
            withAnimation(.easeInOut(duration: 0.24)) {
                introContentVisible = false
                showingIntro = false
            }

            try? await Task.sleep(nanoseconds: 180_000_000)
            showingOnboarding = true
        } else {
            try? await Task.sleep(nanoseconds: 360_000_000)
            withAnimation(.easeOut(duration: 0.18)) {
                showingIntro = false
            }
        }
    }

    private var shouldShowFirstLaunchFlow: Bool {
        !hasSeenOnboarding && store.challenges.isEmpty
    }

    private func completeOnboarding() {
        hasSeenOnboarding = true
        showingOnboarding = false
    }
}


enum MainTab: Hashable {
    case home
    case detail
}


struct HomeOnlyTabView: View {
    @ObservedObject var store: ChallengeStore
    @Binding var selectedTab: MainTab
    @Binding var showingNewChallenge: Bool

    var body: some View {
        TabView(selection: $selectedTab) {
            ChallengeDashboardView(
                store: store,
                showingNewChallenge: $showingNewChallenge
            ) { challenge in
                store.selectChallenge(challenge)
            }
            .tabItem {
                Label("홈", systemImage: "list.bullet")
            }
            .tag(MainTab.home)
        }
        .tint(.mint)
        .onAppear {
            selectedTab = .home
        }
    }
}

struct DetailTabView: View {
    @ObservedObject var store: ChallengeStore
    @Binding var selectedTab: MainTab
    @Binding var showingNewChallenge: Bool

    var body: some View {
        TabView(selection: $selectedTab) {
            ChallengeDashboardView(
                store: store,
                showingNewChallenge: $showingNewChallenge
            ) { challenge in
                store.selectChallenge(challenge)
                selectedTab = .detail
            }
            .tabItem {
                Label("홈", systemImage: "list.bullet")
            }
            .tag(MainTab.home)

            if let challenge = store.challenge {
                ActiveChallengeView(
                    store: store,
                    challenge: challenge,
                    showingNewChallenge: $showingNewChallenge
                )
                    .tabItem {
                        Label(challenge.name, systemImage: "circle.circle.fill")
                    }
                    .tag(MainTab.detail)
            }
        }
        .tint(.mint)
        .onAppear {
            selectedTab = .detail
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

