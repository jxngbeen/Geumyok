import Foundation

enum DayStatus: String, Codable, Equatable {
    case success
    case failure
}

enum ChallengeOutcome: String, Codable, Equatable {
    case inProgress
    case completed
    case failed
}

struct DailyCheckIn: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var status: DayStatus
}

struct Challenge: Identifiable, Codable, Equatable {
    var id = UUID()
    var startDate: Date
    var targetDays: Int
    var records: [DailyCheckIn]
    var outcome: ChallengeOutcome
    var endedDate: Date?

    var isActive: Bool {
        outcome == .inProgress
    }

    var successCount: Int {
        records.filter { $0.status == .success }.count
    }

    var progress: Double {
        guard targetDays > 0 else { return 0 }
        return min(Double(successCount) / Double(targetDays), 1)
    }

    var remainingDays: Int {
        max(targetDays - successCount, 0)
    }
}
