import SwiftUI

struct WheelRay: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String = ""
    var current: Int = 0
    var desired: Int = 0
}

@MainActor
@Observable
final class WheelStore {
    var rays: [WheelRay] = Array(repeating: 0, count: 12).map { _ in WheelRay() }
    var template: String = "Свободное"

    static let matrix = [
        "Подвижность", "Сила", "Выносливость", "Равновесие",
        "Координация", "Восстановление", "Энергия", "Комфорт движений",
        "Ловкость", "Дыхательный комфорт", "Регулярность", "Техника"
    ]

    func addRay() { rays.append(WheelRay()) }
    func removeRay(at index: Int) {
        guard rays.count > 1, rays.indices.contains(index) else { return }
        rays.remove(at: index)
    }
}

struct ContentView: View {
    @State private var store = WheelStore()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                List {
                    Section {
                        Text("12 лучей по умолчанию. Измени количество и выбери свои характеристики.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Picker("Шаблон", selection: $store.template) {
                            ForEach(["Свободное", "Подростки", "Старшее поколение"], id: \.self) { Text($0) }
                        }
                    }
                    ForEach(store.rays.indices, id: \.self) { index in
                        NavigationLink {
                            RayEditor(ray: $store.rays[index])
                        } label: {
                            HStack {
                                Text("\(index + 1).")
                                Text(store.rays[index].name.isEmpty ? "Выбрать сферу" : store.rays[index].name)
                                Spacer()
                                Text("\(store.rays[index].current) → \(store.rays[index].desired)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets.sorted(by: >) { store.removeRay(at: index) }
                    }
                    Button("Добавить луч", systemImage: "plus") { store.addRay() }
                }
                .navigationTitle("Моё колесо")
            }
            .tabItem { Label("Колесо", systemImage: "circle.hexagongrid") }
            .tag(0)

            NavigationStack {
                List {
                    NavigationLink("Бабочка — мягкая практика") { ButterflyLessonView() }
                    Text("Новые практики появятся в следующих версиях.")
                        .foregroundStyle(.secondary)
                }
                .navigationTitle("Практики")
            }
            .tabItem { Label("Практики", systemImage: "figure.cooldown") }
            .tag(1)
        }
    }
}

struct RayEditor: View {
    @Binding var ray: WheelRay

    var body: some View {
        Form {
            TextField("Название своей сферы", text: $ray.name)
            Section("Выбрать из матрицы") {
                ForEach(WheelStore.matrix, id: \.self) { option in
                    Button(option) { ray.name = option }
                }
            }
            Section("Самооценка (не диагноз)") {
                Stepper("Сейчас: \(ray.current)", value: $ray.current, in: 0...10)
                Stepper("Хочу: \(ray.desired)", value: $ray.desired, in: 0...10)
            }
        }
        .navigationTitle("Характеристика")
    }
}
