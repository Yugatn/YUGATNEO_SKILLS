import Foundation

/// Локальные очки за регулярность, не за нагрузку или показатели здоровья.
/// Серверные лиги и публичные профили здесь НЕ реализованы.
struct PracticeXPEvent: Codable, Identifiable {
    var id: UUID
    var sessionID: UUID
    var dayKey: String
    var points: Int
    var reason: String
}

@MainActor
@Observable
final class PracticeRewards {
    private(set) var events: [PracticeXPEvent] = []
    private let storageKey = "neo.skills.rewards.v1"
    private let dailyCap = 30

    init() { restore() }

    private func key(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    @discardableResult
    func grant(sessionID: UUID, date: Date, completed: Bool, reflected: Bool) -> Int {
        guard completed, !events.contains(where: { $0.sessionID == sessionID }) else { return 0 }
        let today = key(for: date)
        let used = events.filter { $0.dayKey == today }.reduce(0) { $0 + $1.points }
        let earned = min(max(0, dailyCap - used), 10 + (reflected ? 5 : 0))
        guard earned > 0 else { return 0 }
        events.append(PracticeXPEvent(id: UUID(), sessionID: sessionID, dayKey: today,
                                      points: earned, reason: "Завершение занятия"))
        persist()
        return earned
    }

    var totalXP: Int { events.reduce(0) { $0 + $1.points } }
    var activeDays: Int { Set(events.map(\.dayKey)).count }

    func resetLocalRewards() {
        events = []
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([PracticeXPEvent].self, from: data) else { return }
        events = saved
    }
}
