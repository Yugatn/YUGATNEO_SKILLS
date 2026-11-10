import SwiftUI

/// Self-contained, offline practice. No profiles, telemetry, or moral scores.
struct DevelopmentLessonView: View {
    @State private var age: DevelopmentAgeBand = .middleSchool
    @State private var scenarioIndex = 0
    @State private var selectedOptionID: String?
    @State private var showReflection = false

    private let engine = DevelopmentSkillEngine()

    private var scenario: DevelopmentScenario {
        DevelopmentScenario.examples[scenarioIndex]
    }

    var body: some View {
        Form {
            Section("Формат занятия") {
                Picker("Возрастной маршрут", selection: $age) {
                    Text("3–5 · со взрослым").tag(DevelopmentAgeBand.preschool)
                    Text("6–8").tag(DevelopmentAgeBand.earlySchool)
                    Text("9–12").tag(DevelopmentAgeBand.middleSchool)
                    Text("13–17").tag(DevelopmentAgeBand.adolescent)
                    Text("Взрослые").tag(DevelopmentAgeBand.adult)
                }
                if age.adultFacilitatorRequired {
                    Label("Проходите это занятие вместе со взрослым.", systemImage: "person.2")
                        .foregroundStyle(.secondary)
                }
            }
            Section("Ситуация") {
                Text(scenario.title).font(.headline)
                Text(scenario.story)
                Picker("Другая ситуация", selection: $scenarioIndex) {
                    ForEach(DevelopmentScenario.examples.indices, id: \.self) { index in
                        Text(DevelopmentScenario.examples[index].title).tag(index)
                    }
                }
                .onChange(of: scenarioIndex) { _, _ in reset() }
            }
            Section("Как можно поступить?") {
                Text("Выбирай свободно: это упражнение, а не оценка личности.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                ForEach(scenario.options) { option in
                    Button {
                        selectedOptionID = option.id
                        showReflection = false
                    } label: {
                        HStack {
                            Text(option.label)
                            Spacer()
                            if selectedOptionID == option.id {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                    }
                    .tint(.primary)
                }
            }
            if let selected = scenario.options.first(where: { $0.id == selectedOptionID }) {
                Section("Последствия и ограничения") {
                    Text(selected.explanation)
                    switch engine.evaluate([selected.decision]) {
                    case .eligible:
                        Label("В учебной модели нет отмеченных жёстких запретов.", systemImage: "checkmark.shield")
                    case .needsClarification:
                        Label("Этот вариант требует пересмотра или дополнительного согласия.", systemImage: "hand.raised")
                    }
                    Text("Оценка основана только на заранее написанном сценарии, не на анализе реального человека.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Перейти к размышлению") { showReflection = true }
                }
            }
            if showReflection {
                Section("РАЗВИТИЕ: вопросы для обсуждения") {
                    ForEach(engine.prompts(for: age), id: \.self) { prompt in
                        Text(prompt)
                    }
                    Text("Обсудите, как можно исправить ошибку и применить урок в другой ситуации.")
                        .foregroundStyle(.secondary)
                    Button("Начать заново") { reset() }
                }
            }
            Section {
                Text("Без сохранения ответов, камеры, микрофона и сетевой передачи. ИИ не ставит диагнозов и не оценивает нравственность.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Закон Развития")
    }

    private func reset() {
        selectedOptionID = nil
        showReflection = false
    }
}

struct DevelopmentScenario {
    struct Choice: Identifiable {
        let id: String
        let label: String
        let explanation: String
        let decision: DevelopmentOption
    }

    let title: String
    let story: String
    let options: [Choice]

    static let examples: [DevelopmentScenario] = [
        DevelopmentScenario(
            title: "Общая игрушка",
            story: "Двое детей хотят играть одной игрушкой. Как поступить, чтобы услышать обоих?",
            options: [
                choice("ask", "Предложить очередь и спросить согласие", "Можно договориться, но другой человек вправе не согласиться.", consent: false),
                choice("take", "Забрать силой", "Это нарушает границы другого. Нужна безопасная альтернатива.", rights: true),
                choice("help", "Попросить взрослого помочь договориться", "Обращение за помощью — допустимая стратегия.")
            ]
        ),
        DevelopmentScenario(
            title: "Чужая фотография",
            story: "Друг просит переслать фотографию другого человека, который не давал согласия.",
            options: [
                choice("forward", "Переслать без разрешения", "Нет согласия человека, чья фотография распространяется.", consent: true),
                choice("decline", "Отказаться и объяснить почему", "Отказ защищает чужую приватность."),
                choice("request", "Сначала спросить согласие", "Спросить можно, но отправлять допустимо только после согласия.")
            ]
        ),
        DevelopmentScenario(
            title: "Ошибка в совместном деле",
            story: "Ты случайно испортил часть общего проекта и боишься признаться.",
            options: [
                choice("hide", "Обвинить другого", "Ложное обвинение нарушает права другого участника.", rights: true),
                choice("repair", "Признать ошибку и предложить исправление", "Это даёт шанс восстановить доверие и результат."),
                choice("pause", "Сделать паузу и попросить поддержки", "Если страшно, можно сначала обратиться за поддержкой.")
            ]
        )
    ]

    private static func choice(
        _ id: String, _ label: String, _ explanation: String,
        consent: Bool = false, rights: Bool = false
    ) -> Choice {
        Choice(
            id: id, label: label, explanation: explanation,
            decision: DevelopmentOption(
                id: id, label: label,
                requiresConsent: consent, consentGranted: false,
                violatesRights: rights, irreversibleHarmRisk: false,
                requiresAdultAuthorization: false, adultAuthorized: false
            )
        )
    }
}
