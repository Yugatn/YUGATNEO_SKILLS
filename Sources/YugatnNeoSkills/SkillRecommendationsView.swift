import SwiftUI

struct SkillRecommendationsView: View {
    let rays: [WheelRay]
    @State private var discipline: SkillDiscipline = .qigong
    @State private var minutes = 15
    @State private var painOrDizziness = false

    private var choices: [LessonSuggestion] {
        SkillPlanner.recommend(
            PracticePreferences(discipline: discipline, minutesAvailable: minutes,
                                instructorPresent: false, painOrDizziness: painOrDizziness),
            wheel: rays
        )
    }

    var body: some View {
        Form {
            Section("Направление и время") {
                Picker("Навык", selection: $discipline) {
                    ForEach(SkillDiscipline.allCases, id: \.self) { Text($0.rawValue) }
                }
                Picker("Длительность", selection: $minutes) {
                    ForEach([5, 10, 15, 20, 30], id: \.self) { Text("\($0) минут") }
                }
                Toggle("Сейчас испытываю боль или головокружение", isOn: $painOrDizziness)
            }
            Section("Подходящие вводные уроки") {
                if choices.isEmpty {
                    Text(painOrDizziness ? "Останови занятие и оцени своё состояние." :
                         "В каталоге пока нет подходящего короткого урока.")
                }
                ForEach(choices, id: \.lesson.id) { suggestion in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(suggestion.lesson.title).font(.headline)
                        Text("\(suggestion.lesson.minutes) мин · \(suggestion.reason)")
                        Text(suggestion.lesson.description).foregroundStyle(.secondary)
                        if let source = suggestion.lesson.sourceURL,
                           let url = URL(string: source) {
                            Link("Источник / контекст практики", destination: url)
                        }
                    }
                }
            }
        }
        .navigationTitle("Выбор навыка")
    }
}
