import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ChallengeDashboardView: View {
    @ObservedObject var store: ChallengeStore
    @Binding var showingNewChallenge: Bool
    let onSelect: (Challenge) -> Void
    @State private var showsEmptyState = false
    @State private var showingActiveArchive = false
    @State private var showingFinishedArchive = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    dashboardHeader
                        .listRowInsets(EdgeInsets(top: 32, leading: 24, bottom: 18, trailing: 24))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                if showsEmptyState {
                    EmptyChallengeList {
                        showingNewChallenge = true
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 8, trailing: 24))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else if !store.challenges.isEmpty {
                    ChallengeSection(
                        title: "진행 중",
                        challenges: displayedActiveChallenges,
                        emptyText: "진행 중인 금욕이 없어요",
                        store: store,
                        onSelect: onSelect
                    )

                    if hasHiddenActiveChallenges {
                        Button {
                            showingActiveArchive = true
                        } label: {
                            ChallengeArchiveButton(
                                title: "진행 중 금욕 더 보기",
                                subtitle: "전체 \(store.activeChallenges.count)개 진행 중",
                                iconName: "flame.fill"
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 5, leading: 24, bottom: 5, trailing: 24))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    ChallengeSection(
                        title: "지난 금욕",
                        challenges: displayedFinishedChallenges,
                        emptyText: "아직 끝난 금욕이 없어요",
                        store: store,
                        onSelect: onSelect
                    )

                    if hasHiddenFinishedChallenges {
                        Button {
                            showingFinishedArchive = true
                        } label: {
                            ChallengeArchiveButton(
                                title: "지난 금욕 더 보기",
                                subtitle: "전체 \(store.finishedChallenges.count)개 기록",
                                iconName: "clock.arrow.circlepath"
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 5, leading: 24, bottom: 5, trailing: 24))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .onAppear {
                showsEmptyState = store.challenges.isEmpty
            }
            .onChange(of: store.challenges.isEmpty) { _, isEmpty in
                guard isEmpty else {
                    showsEmptyState = false
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    guard store.challenges.isEmpty else { return }
                    withAnimation(.easeOut(duration: 0.18)) {
                        showsEmptyState = true
                    }
                }
            }
            .navigationDestination(isPresented: $showingActiveArchive) {
                ChallengeArchiveView(store: store, kind: .active) { challenge in
                    showingActiveArchive = false
                    onSelect(challenge)
                }
            }
            .navigationDestination(isPresented: $showingFinishedArchive) {
                ChallengeArchiveView(store: store, kind: .finished) { challenge in
                    showingFinishedArchive = false
                    onSelect(challenge)
                }
            }
        }
    }

    private var displayedActiveChallenges: [Challenge] {
        Array(store.activeChallenges.prefix(5))
    }

    private var displayedFinishedChallenges: [Challenge] {
        Array(store.finishedChallenges.prefix(5))
    }

    private var hasHiddenActiveChallenges: Bool {
        store.activeChallenges.count > displayedActiveChallenges.count
    }

    private var hasHiddenFinishedChallenges: Bool {
        store.finishedChallenges.count > displayedFinishedChallenges.count
    }

    private var dashboardHeader: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("금욕")
                    .font(.system(size: 42, weight: .black))

                Text("오늘 이어갈 금욕을 골라주세요")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Button {
                showingNewChallenge = true
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.black))
                    .frame(width: 44, height: 44)
                    .background(Color.mint)
                    .foregroundStyle(Color.black)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("금욕 만들기")
        }
    }
}

struct EmptyChallengeList: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "flag")
                .font(.title.weight(.bold))
                .foregroundStyle(.mint)
                .frame(width: 48, height: 48)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                Text("아직 금욕이 없어요")
                    .font(.title2.weight(.black))
                Text("금연, 야식 끊기, SNS 줄이기처럼 따로 관리할 목표를 만들어보세요.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Button {
                onCreate()
            } label: {
                Label("첫 금욕 만들기", systemImage: "plus.circle.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Color.mint)
                    .foregroundStyle(Color.black)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.largeCard, style: .continuous))
    }
}

struct ChallengeSection: View {
    let title: String
    let challenges: [Challenge]
    let emptyText: String
    @ObservedObject var store: ChallengeStore
    let onSelect: (Challenge) -> Void

    var body: some View {
        Section {
            if challenges.isEmpty {
                Text(emptyText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.52))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card, style: .continuous))
                    .listRowInsets(EdgeInsets(top: 5, leading: 24, bottom: 5, trailing: 24))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(challenges) { challenge in
                    Button {
                        onSelect(challenge)
                    } label: {
                        ChallengeRow(challenge: challenge)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            store.deleteChallenge(challenge)
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                    .listRowInsets(EdgeInsets(top: 5, leading: 24, bottom: 5, trailing: 24))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        } header: {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))
                .textCase(nil)
                .padding(.horizontal, 8)
        }
    }
}


