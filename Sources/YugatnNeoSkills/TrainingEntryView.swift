import SwiftUI

struct TrainingEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let journal: TrainingJournal
    @State private var discipline = "Йога"
    @State private var title = "Домашняя практика"
    @State private var minutes = 10
    @State private var totalSteps = 4
    @State private var completedSteps = 4
    @State private var effort = 4
    @State private var comfort = 8
    @State private var note = ""

    var body: some View {
        Form {
            Section("Занятие") {
                TextField("Направление", text: $discipline)
                TextField("Название", text: $title)
                Stepper("Минут: \(minutes)", value: $minutes, in: 0...300)
                Stepper("Этапов всего: \(totalSteps)", value: $totalSteps, in: 1...100)
                Stepper("Этапов выполнено: \(completedSteps)", value: $completedSteps, in: 0...totalSteps)
            }
            Section("Самооценка") {
                Stepper("Нагрузка: \(effort)/10", value: $effort, in: 0...10)
                Stepper("Комфорт: \(comfort)/10", value: $comfort, in: 0...10)
                TextField("Заметка (необязательно)", text: $note, axis: .vertical)
            }
            Button("Сохранить результат") {
                journal.append(TrainingRecord(
                    discipline: discipline, lesson: title,
                    durationSeconds: minutes * 60,
                    completedSteps: min(completedSteps, totalSteps),
                    totalSteps: totalSteps, perceivedEffort: effort,
                    comfort: comfort, note: note
                ))
                dismiss()
            }
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .navigationTitle("Результат тренировки")
    }
}
