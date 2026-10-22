import SwiftUI

struct ButterflyLessonView: View {
    @State private var step = 0
    private let steps: [(title: String, instruction: String)] = [
        ("Подготовка", "Сядь устойчиво и спокойно подыши."),
        ("Мягкая разминка", "Разомни плечи, таз и ноги в комфортной амплитуде."),
        ("Бабочка", "Соедини стопы, не дави на колени и не допускай боли."),
        ("Завершение", "Медленно выпрями ноги и отметь ощущения.")
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text("Этап \(step + 1) из \(steps.count)")
                .foregroundStyle(.secondary)
            Text(steps[step].title).font(.title.bold())
            Text(steps[step].instruction)
                .multilineTextAlignment(.center)
                .padding()
            Text("Ориентир: 10–15 минут на весь комплекс. Темп выбираешь самостоятельно.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack {
                Button("Назад") { step = max(0, step - 1) }
                    .disabled(step == 0)
                Spacer()
                Button(step == steps.count - 1 ? "Завершить" : "Далее") {
                    if step < steps.count - 1 { step += 1 }
                    else { step = 0 }
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
            Text("При боли, головокружении или дискомфорте остановись. Приложение не заменяет инструктора.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Практика")
    }
}
