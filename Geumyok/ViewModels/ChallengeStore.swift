import Foundation
import SwiftUI

@MainActor
final class ChallengeStore: ObservableObject {
    @Published private(set) var challenges: [Challenge] = []
    @Published var selectedChallengeID: UUID?
    @Published var selectedChallengeName = ""
    @Published var selectedTargetDays = 30

    private let storageKey = "geumyok.challenges.v2"
    private let legacyStorageKey = "geumyok.challenge.v1"
    private let calendar: Calendar
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(calendar: Calendar = .current, defaults: UserDefaults = .standard) {
        self.calendar = calendar
        self.defaults = defaults
        load()
    }

    var challenge: Challenge? {
        guard let selectedChallengeID else { return nil }
        return challenges.first { $0.id == selectedChallengeID }
    }

    var activeChallenges: [Challenge] {
        challenges
            .filter(\.isActive)
            .sorted { $0.startDate > $1.startDate }
    }

    var finishedChallenges: [Challenge] {
        challenges
            .filter { !$0.isActive }
            .sorted { ($0.endedDate ?? $0.startDate) > ($1.endedDate ?? $1.startDate) }
    }

    var hasFinishedChallenge: Bool {
        guard let challenge else { return false }
        return challenge.outcome != .inProgress
    }

    var todayStatus: DayStatus? {
        guard let challenge else { return nil }
        return record(for: Date(), in: challenge)?.status
    }

    var dayNumber: Int {
        guard let challenge else { return 0 }
        let start = calendar.startOfDay(for: challenge.startDate)
        let today = calendar.startOfDay(for: Date())
        return max((calendar.dateComponents([.day], from: start, to: today).day ?? 0) + 1, 1)
    }

    @discardableResult
    func startChallenge(name: String, targetDays: Int) -> Bool {
        guard let normalizedName = normalizedChallengeName(name) else { return false }
        let normalizedTarget = min(max(targetDays, 1), 365)
        let newChallenge = Challenge(
            name: normalizedName,
            startDate: calendar.startOfDay(for: Date()),
            targetDays: normalizedTarget,
            records: [],
            outcome: .inProgress,
            endedDate: nil
        )

        challenges.append(newChallenge)
        selectedChallengeID = newChallenge.id
        selectedChallengeName = ""
        selectedTargetDays = normalizedTarget
        save()
        return true
    }

    func selectChallenge(_ challenge: Challenge) {
        selectedChallengeID = challenge.id
        selectedChallengeName = challenge.isActive ? challenge.name : ""
        selectedTargetDays = challenge.targetDays
    }

    func clearSelection() {
        selectedChallengeID = nil
        selectedChallengeName = ""
    }

    func toggleTodaySuccess() {
        if todayStatus == .success {
            removeTodayRecord()
        } else {
            recordToday(.success)
        }
    }

    func recordToday(_ status: DayStatus) {
        guard let selectedChallengeID,
              let index = challenges.firstIndex(where: { $0.id == selectedChallengeID }),
              challenges[index].isActive else { return }

        var challenge = challenges[index]
        let today = calendar.startOfDay(for: Date())
        if let recordIndex = challenge.records.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            challenge.records[recordIndex].status = status
            challenge.records[recordIndex].date = today
        } else {
            challenge.records.append(DailyCheckIn(date: today, status: status))
        }

        if status == .failure {
            challenge.outcome = .failed
            challenge.endedDate = today
        } else if challenge.successCount >= challenge.targetDays {
            challenge.outcome = .completed
            challenge.endedDate = today
        }

        challenge.records.sort { $0.date < $1.date }
        challenges[index] = challenge
        if !challenge.isActive {
            self.selectedChallengeID = nil
            selectedChallengeName = ""
        }
        save()
    }

    private func removeTodayRecord() {
        guard let selectedChallengeID,
              let index = challenges.firstIndex(where: { $0.id == selectedChallengeID }) else { return }

        var challenge = challenges[index]
        let today = calendar.startOfDay(for: Date())
        challenge.records.removeAll { calendar.isDate($0.date, inSameDayAs: today) }

        if challenge.outcome == .completed && challenge.successCount < challenge.targetDays {
            challenge.outcome = .inProgress
            challenge.endedDate = nil
        }

        challenges[index] = challenge
        save()
    }

    func resetChallenge() {
        guard let selectedChallengeID else { return }
        deleteChallenges(with: [selectedChallengeID])
    }

    func deleteChallenge(_ challenge: Challenge) {
        deleteChallenges(with: [challenge.id])
    }

    private func deleteChallenges(with ids: [UUID]) {
        let idsToDelete = Set(ids)
        challenges.removeAll { idsToDelete.contains($0.id) }

        if let selectedChallengeID, idsToDelete.contains(selectedChallengeID) {
            self.selectedChallengeID = nil
            selectedChallengeName = ""
        }

        save()
    }

    private func normalizedChallengeName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(24))
    }

    private func record(for date: Date, in challenge: Challenge) -> DailyCheckIn? {
        let day = calendar.startOfDay(for: date)
        return challenge.records.first { calendar.isDate($0.date, inSameDayAs: day) }
    }

    private func save() {
        let payload = ChallengeStorage(challenges: challenges, selectedChallengeID: selectedChallengeID)

        do {
            let data = try encoder.encode(payload)
            defaults.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Failed to save challenges: \(error)")
        }
    }

    private func load() {
        if let data = defaults.data(forKey: storageKey),
           let payload = try? decoder.decode(ChallengeStorage.self, from: data) {
            challenges = payload.challenges
            selectedChallengeID = nil
            selectedChallengeName = ""
            return
        }

        loadLegacyChallengeIfNeeded()
    }

    private func loadLegacyChallengeIfNeeded() {
        guard let data = defaults.data(forKey: legacyStorageKey),
              let legacyChallenge = try? decoder.decode(Challenge.self, from: data) else { return }

        challenges = [legacyChallenge]
        selectedChallengeID = nil
        selectedChallengeName = ""
        selectedTargetDays = legacyChallenge.targetDays
        save()
    }
}

private struct ChallengeStorage: Codable {
    var challenges: [Challenge]
    var selectedChallengeID: UUID?
}
