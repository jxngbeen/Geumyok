import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ChallengeArchiveButton: View {
    let title: String
    let subtitle: String
    let iconName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.headline.weight(.bold))
                .foregroundStyle(.mint)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.34))
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card, style: .continuous))
    }
}

enum ChallengeArchiveKind {
    case active
    case finished

    var title: String {
        switch self {
        case .active:
            return "진행 중 금욕"
        case .finished:
            return "지난 금욕"
        }
    }

    var emptyText: String {
        switch self {
        case .active:
            return "진행 중인 금욕이 없어요"
        case .finished:
            return "아직 끝난 금욕이 없어요"
        }
    }

    var coordinateSpaceName: String {
        switch self {
        case .active:
            return "activeArchiveList"
        case .finished:
            return "finishedArchiveList"
        }
    }

    @MainActor
    func challenges(from store: ChallengeStore) -> [Challenge] {
        switch self {
        case .active:
            return store.activeChallenges
        case .finished:
            return store.finishedChallenges
        }
    }
}
struct ChallengeArchiveView: View {
    @ObservedObject var store: ChallengeStore
    let kind: ChallengeArchiveKind
    let onSelect: (Challenge) -> Void
    @State private var selectedIDs: Set<UUID> = []
#if os(iOS)
    @State private var editMode: EditMode = .inactive
#else
    @State private var fallbackIsSelecting = false
#endif

    var body: some View {
        List(selection: $selectedIDs) {
            Section {
                if archiveChallenges.isEmpty {
                    Text(kind.emptyText)
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
                    ForEach(archiveChallenges) { challenge in
                        archiveRow(for: challenge)
                            .tag(challenge.id)
                            .listRowInsets(EdgeInsets(top: 5, leading: 24, bottom: 5, trailing: 24))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            } header: {
                Text("전체 \(archiveChallenges.count)개")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.82))
                    .textCase(nil)
                    .padding(.horizontal, 8)
            }
        }
#if os(iOS)
        .environment(\.editMode, $editMode)
#endif
        .navigationTitle(kind.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if !archiveChallenges.isEmpty {
                    Button(isSelecting ? "완료" : "선택") {
                        toggleSelecting()
                    }
                    .foregroundStyle(.mint)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isSelecting {
                selectionDeleteButton
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .onChange(of: archiveChallenges.map(\.id)) { _, ids in
            selectedIDs.formIntersection(Set(ids))
            if ids.isEmpty {
#if os(iOS)
                editMode = .inactive
#else
                fallbackIsSelecting = false
#endif
            }
        }
    }

    private var archiveChallenges: [Challenge] {
        kind.challenges(from: store)
    }

    private var isSelecting: Bool {
#if os(iOS)
        editMode == .active
#else
        fallbackIsSelecting
#endif
    }

    @ViewBuilder
    private func archiveRow(for challenge: Challenge) -> some View {
        if isSelecting {
            ChallengeRow(challenge: challenge)
        } else {
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
        }
    }

    private var selectionDeleteButton: some View {
        HStack {
            Spacer()

            Button {
                deleteSelectedChallenges()
            } label: {
                Label("삭제", systemImage: "trash.fill")
                    .font(.headline.weight(.bold))
                    .padding(.horizontal, 16)
                    .frame(height: 46)
                    .background(deleteButtonBackground)
                    .foregroundStyle(deleteButtonForeground)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(selectedIDs.isEmpty)
            .padding(.trailing, 24)
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
    }

    private var deleteButtonBackground: Color {
        selectedIDs.isEmpty ? Color.white.opacity(0.08) : Color.red.opacity(0.18)
    }

    private var deleteButtonForeground: Color {
        selectedIDs.isEmpty ? Color.white.opacity(0.28) : Color.red.opacity(0.94)
    }

    private func toggleSelecting() {
        withoutSelectionAnimation {
#if os(iOS)
            if isSelecting {
                editMode = .inactive
                selectedIDs.removeAll()
            } else {
                editMode = .active
            }
#else
            fallbackIsSelecting.toggle()
            if !fallbackIsSelecting {
                selectedIDs.removeAll()
            }
#endif
        }
    }

    private func deleteSelectedChallenges() {
        let selectedChallenges = archiveChallenges.filter { selectedIDs.contains($0.id) }
        guard !selectedChallenges.isEmpty else { return }

        withoutSelectionAnimation {
            store.deleteChallenges(selectedChallenges)
            selectedIDs.removeAll()
#if os(iOS)
            editMode = .inactive
#else
            fallbackIsSelecting = false
#endif
        }
    }

    private func withoutSelectionAnimation(_ updates: () -> Void) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            updates()
        }
    }
}


