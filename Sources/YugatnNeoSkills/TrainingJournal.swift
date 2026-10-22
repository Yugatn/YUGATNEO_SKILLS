import Foundation
import SwiftUI

struct TrainingRecord: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    var discipline: String
    var lesson: String
    var durationSeconds: Int
    var completedSteps: Int
    var totalSteps: Int
    var perceivedEffort: Int // 0...10
    var comfort: Int // 0...10
    var note: String
    var heartRateBPM: Double? // Optional measured HealthKit value; never invented.
}

@MainActor
@Observable
final class TrainingJournal {
    private(set) var sessions: [TrainingRecord] = []
    private let key = "neo.skills.training.v1"
    let rewards = PracticeRewards()

    init() { load() }

    func append(_ record: TrainingRecord) {
        sessions.insert(record, at: 0)
        rewards.grant(sessionID: record.id, date: record.date,
                      completed: record.completedSteps == record.totalSteps,
                      reflected: !record.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        save()
    }

    func delete(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([TrainingRecord].self, from: data) else { return }
        sessions = decoded
    }

    var completedCount: Int { sessions.filter { $0.completedSteps == $0.totalSteps }.count }
    var totalMinutes: Int { sessions.reduce(0) { $0 + $1.durationSeconds } / 60 }
}

struct TrainingJournalView: View {
    @Bindable var journal: TrainingJournal

    var body: some View {
        List {
            Section("Результаты") {
                LabeledContent("Тренировок завершено", value: "\(journal.completedCount)")
                LabeledContent("Всего минут", value: "\(journal.totalMinutes)")
                LabeledContent("Очки практики", value: "\(journal.rewards.totalXP) XP")
                LabeledContent("Дней с практикой", value: "\(journal.rewards.activeDays)")
            }
            Section("Журнал") {
                if journal.sessions.isEmpty {
                    Text("После первой тренировки здесь появится запись.")
                        .foregroundStyle(.secondary)
                }
                ForEach(journal.sessions) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.lesson).font(.headline)
                        Text(entry.date, style: .date)
                            .foregroundStyle(.secondary)
                        Text("\(entry.durationSeconds / 60) мин · этапы \(entry.completedSteps)/\(entry.totalSteps) · нагрузка \(entry.perceivedEffort)/10 · комфорт \(entry.comfort)/10")
                            .font(.caption)
                        if let bpm = entry.heartRateBPM {
                            Text("Пульс: \(Int(bpm.rounded())) уд/мин (HealthKit)")
                                .font(.caption)
                        }
                        if !entry.note.isEmpty { Text(entry.note).font(.subheadline) }
                    }
                }
                .onDelete(perform: journal.delete)
            }
        }
        .navigationTitle("Прогресс")
    }
}
