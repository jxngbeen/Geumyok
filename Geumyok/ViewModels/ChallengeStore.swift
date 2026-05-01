import Foundation
import SwiftUI

@MainActor
final class ChallengeStore: ObservableObject {
    @Published private(set) var challenge: Challenge?
    @Published var selectedTargetDays = 30

    private let storageKey = "geumyok.challenge.v1"
    private let calendar: Calendar
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(calendar: Calendar = .current, defaults: UserDefaults = .standard) {
        self.calendar = calendar
        self.defaults = defaults
        load()
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

    func startChallenge(targetDays: Int) {
        let normalizedTarget = min(max(targetDays, 1), 365)
        selectedTargetDays = normalizedTarget
        challenge = Challenge(
            startDate: calendar.startOfDay(for: Date()),
            targetDays: normalizedTarget,
            records: [],
            outcome: .inProgress,
            endedDate: nil
        )
        save()
    }

    func recordToday(_ status: DayStatus) {
        guard var challenge, challenge.isActive else { return }

        let today = calendar.startOfDay(for: Date())
        if let index = challenge.records.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            challenge.records[index].status = status
            challenge.records[index].date = today
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
        self.challenge = challenge
        save()
    }

    func resetChallenge() {
        challenge = nil
        defaults.removeObject(forKey: storageKey)
    }

    private func record(for date: Date, in challenge: Challenge) -> DailyCheckIn? {
        let day = calendar.startOfDay(for: date)
        return challenge.records.first { calendar.isDate($0.date, inSameDayAs: day) }
    }

    private func save() {
        guard let challenge else {
            defaults.removeObject(forKey: storageKey)
            return
        }

        do {
            let data = try encoder.encode(challenge)
            defaults.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Failed to save challenge: \(error)")
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }

        do {
            challenge = try decoder.decode(Challenge.self, from: data)
            selectedTargetDays = challenge?.targetDays ?? selectedTargetDays
        } catch {
            defaults.removeObject(forKey: storageKey)
        }
    }
}
