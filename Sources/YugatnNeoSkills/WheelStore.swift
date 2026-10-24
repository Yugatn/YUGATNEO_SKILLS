import Foundation
import SwiftUI

struct WheelSnapshot: Codable {
    var rays: [WheelRay]
    var template: String
    var savedAt: Date
}

/// Local-first storage. No account, network requests or automatic cloud sync.
@MainActor
@Observable
final class WheelStore {
    var rays: [WheelRay] = (0..<12).map { _ in WheelRay() }
    var template = "Свободное"
    private(set) var history: [WheelSnapshot] = []
    var lastSaved: Date?

    static let storageKey = "neo.skills.wheel.v1"
    static let historyKey = "neo.skills.wheel.history.v1"
    static let matrix = ["Подвижность", "Сила", "Выносливость", "Равновесие",
                         "Координация", "Восстановление", "Энергия", "Комфорт движений",
                         "Ловкость", "Дыхательный комфорт", "Регулярность", "Техника"]

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func addRay() {
        rays.append(WheelRay())
        save()
    }

    func removeRay(at index: Int) {
        guard rays.count > 1, rays.indices.contains(index) else { return }
        rays.remove(at: index)
        save()
    }

    func save() {
        let snapshot = WheelSnapshot(rays: rays, template: template, savedAt: Date())
        guard let encoded = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(encoded, forKey: Self.storageKey)
        lastSaved = snapshot.savedAt

        // Keep the latest 100 checkpoints, including snapshots with 0/10 values.
        // Saving a second time without changing a ray or template does not add noise.
        let newState = try? JSONEncoder().encode(rays)
        let oldState = history.first.flatMap { try? JSONEncoder().encode($0.rays) }
        if newState != oldState || history.first?.template != template {
            history.insert(snapshot, at: 0)
            if history.count > 100 { history.removeLast(history.count - 100) }
            if let data = try? JSONEncoder().encode(history) {
                defaults.set(data, forKey: Self.historyKey)
            }
        }
    }

    func restore(_ snapshot: WheelSnapshot) {
        guard !snapshot.rays.isEmpty else { return }
        rays = snapshot.rays
        template = snapshot.template
        save()
    }

    func load() {
        if let data = defaults.data(forKey: Self.storageKey),
           let snapshot = try? JSONDecoder().decode(WheelSnapshot.self, from: data),
           !snapshot.rays.isEmpty {
            rays = snapshot.rays
            template = snapshot.template
            lastSaved = snapshot.savedAt
        }
        if let data = defaults.data(forKey: Self.historyKey),
           let saved = try? JSONDecoder().decode([WheelSnapshot].self, from: data) {
            history = Array(saved.prefix(100))
        }
    }
}

struct WheelHistoryView: View {
    @Bindable var store: WheelStore

    var body: some View {
        List {
            if store.history.isEmpty {
                ContentUnavailableView("История пуста", systemImage: "clock",
                    description: Text("Измени луч или оценку и сохрани колесо."))
            }
            ForEach(store.history.indices, id: \.self) { index in
                let snapshot = store.history[index]
                VStack(alignment: .leading, spacing: 8) {
                    Text(snapshot.savedAt, format: .dateTime.day().month().year().hour().minute())
                        .font(.headline)
                    Text("\(snapshot.rays.count) лучей · \(snapshot.template)")
                        .foregroundStyle(.secondary)
                    Button("Восстановить этот снимок") {
                        store.restore(snapshot)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("История колеса")
    }
}
