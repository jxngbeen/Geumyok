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
    var id: UUID
    var name: String
    var startDate: Date
    var targetDays: Int
    var records: [DailyCheckIn]
    var outcome: ChallengeOutcome
    var endedDate: Date?

    init(
        id: UUID = UUID(),
        name: String = "금욕",
        startDate: Date,
        targetDays: Int,
        records: [DailyCheckIn],
        outcome: ChallengeOutcome,
        endedDate: Date?
    ) {
        self.id = id
        self.name = Self.normalizedName(name)
        self.startDate = startDate
        self.targetDays = targetDays
        self.records = records
        self.outcome = outcome
        self.endedDate = endedDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = Self.normalizedName(try container.decodeIfPresent(String.self, forKey: .name) ?? "금욕")
        startDate = try container.decode(Date.self, forKey: .startDate)
        targetDays = try container.decode(Int.self, forKey: .targetDays)
        records = try container.decode([DailyCheckIn].self, forKey: .records)
        outcome = try container.decode(ChallengeOutcome.self, forKey: .outcome)
        endedDate = try container.decodeIfPresent(Date.self, forKey: .endedDate)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case startDate
        case targetDays
        case records
        case outcome
        case endedDate
    }

    private static func normalizedName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "금욕" }
        return String(trimmed.prefix(24))
    }

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
