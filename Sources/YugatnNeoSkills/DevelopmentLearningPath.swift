import Foundation

/// Temporary, on-device learning trajectory. No persistence, network calls, or profiling.
enum DevelopmentLearningFocus: String, CaseIterable, Codable {
    case consent = "Согласие и границы"
    case cooperation = "Сотрудничество"
    case repair = "Исправление ошибок"
}

struct DevelopmentPracticeRecord: Equatable {
    let scenarioTitle: String
    let focus: DevelopmentLearningFocus
    let reflected: Bool
}

struct DevelopmentLearningPath {
    private(set) var completed: [DevelopmentPracticeRecord] = []

    /// Reflective completion is a practice event, never a moral score or diagnosis.
    mutating func complete(scenarioTitle: String, focus: DevelopmentLearningFocus) {
        guard !completed.contains(where: { $0.scenarioTitle == scenarioTitle }) else { return }
        completed.append(.init(scenarioTitle: scenarioTitle, focus: focus, reflected: true))
    }

    mutating func clear() { completed.removeAll() }

    func suggestedIndex(in scenarios: [DevelopmentScenario], excluding index: Int? = nil) -> Int? {
        guard !scenarios.isEmpty else { return nil }
        let counts = Dictionary(grouping: completed, by: \.focus).mapValues(\.count)
        let candidates = scenarios.indices.filter { $0 != index }
        return candidates.sorted {
            let left = scenarios[$0]
            let right = scenarios[$1]
            let leftDone = completed.contains { $0.scenarioTitle == left.title }
            let rightDone = completed.contains { $0.scenarioTitle == right.title }
            if leftDone != rightDone { return !leftDone }
            let leftCount = counts[left.focus, default: 0]
            let rightCount = counts[right.focus, default: 0]
            if leftCount != rightCount { return leftCount < rightCount }
            return $0 < $1
        }.first
    }
}
