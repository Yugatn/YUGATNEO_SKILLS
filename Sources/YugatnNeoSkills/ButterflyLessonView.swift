import SwiftUI

/// An offline, self-paced introductory lesson. No camera or cloud required.
/// The journal is written only after the user explicitly saves the result.
struct ButterflyLessonView: View {
    @Environment(\.dismiss) private var dismiss
    let journal: TrainingJournal

    @State private var step = 0
    @State private var elapsedSeconds = 0
    @State private var isRunning = false
    @State private var showingSummary = false
    @State private var completedIndices: Set<Int> = []
    @State private var perceivedEffort = 3
    @State private var comfort = 8
    @State private var note = ""

    private let steps: [(title: String, instruction: String, suggestedSeconds: Int)] = [
        ("Подготовка", "Сядь устойчиво. Дыши спокойно и найди положение без боли.", 120),
        ("Мягкая разминка", "Плавно разомни плечи, таз и ноги в комфортной амплитуде.", 180),
        ("Бабочка", "Соедини стопы. Не дави на колени и не тянись через боль. При необходимости подложи опоры под бёдра.", 360),
        ("Завершение", "Медленно выпрями ноги, отдохни и отметь ощущения.", 120)
    ]

    private var clockText: String {
        String(format: "%02d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
    }

    var body: some View {
        Group {
            if showingSummary {
                Form {
                    Section("Результат практики") {
                        LabeledContent("Продолжительность", value: clockText)
                        LabeledContent("Пройдено этапов", value: "\(completedIndices.count) из \(steps.count)")
                        Stepper("Субъективная нагрузка: \(perceivedEffort)/10", value: $perceivedEffort, in: 0...10)
                        Stepper("Комфорт: \(comfort)/10", value: $comfort, in: 0...10)
                        TextField("Заметка (необязательно)", text: $note, axis: .vertical)
                    }
                    Section {
                        Button("Сохранить в локальный журнал") {
                            journal.append(TrainingRecord(
                                discipline: "Мягкая йога",
                                lesson: "Бабочка",
                                durationSeconds: elapsedSeconds,
                                completedSteps: completedIndices.count,
                                totalSteps: steps.count,
                                perceivedEffort: perceivedEffort,
                                comfort: comfort,
                                note: note
                            ))
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Выйти без сохранения", role: .cancel) { dismiss() }
                    } footer: {
                        Text("Результат остаётся на устройстве. Непройденные этапы не считаются выполненными.")
                    }
                }
            } else {
                VStack(spacing: 18) {
                    Text("Этап \(step + 1) из \(steps.count)")
                        .foregroundStyle(.secondary)
                    Text(steps[step].title).font(.title.bold())
                    Text(steps[step].instruction)
                        .multilineTextAlignment(.center)
                        .padding()
                    Text(clockText)
                        .font(.system(.largeTitle, design: .monospaced))
                        .accessibilityLabel("Время занятия: \(elapsedSeconds / 60) минут \(elapsedSeconds % 60) секунд")
                    Text("Ориентир для этапа: \(steps[step].suggestedSeconds / 60) мин. Переходи дальше в своём темпе.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button(isRunning ? "Пауза" : (elapsedSeconds == 0 ? "Начать таймер" : "Продолжить")) {
                        isRunning.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    HStack {
                        Button("Назад") { step = max(0, step - 1) }
                            .disabled(step == 0)
                        Spacer()
                        Button("Пропустить") { advance(completed: false) }
                        Spacer()
                        Button(step == steps.count - 1 ? "Завершить" : "Далее") {
                            advance(completed: true)
                        }
                    }
                    Button("Остановить занятие", role: .destructive) {
                        isRunning = false
                        showingSummary = true
                    }
                    Spacer()
                    Text("При боли, головокружении или дискомфорте остановись. Не дави на колени. Это вводная практика, а не медицинская рекомендация.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .navigationTitle("Практика «Бабочка»")
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if isRunning { elapsedSeconds += 1 }
        }
        .onDisappear { isRunning = false }
    }

    private func advance(completed: Bool) {
        if completed { completedIndices.insert(step) }
        if step == steps.count - 1 {
            isRunning = false
            showingSummary = true
        } else {
            step += 1
        }
    }
}
