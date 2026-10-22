import Foundation
import SwiftUI

struct WheelSnapshot: Codable {
    var rays: [WheelRay]
    var template: String
    var savedAt: Date
}

@MainActor
@Observable
final class WheelStore {
    var rays: [WheelRay] = (0..<12).map { _ in WheelRay() }
    var template = "Свободное"
    var lastSaved: Date?
    static let storageKey = "neo.skills.wheel.v1"
    static let matrix = ["Подвижность", "Сила", "Выносливость", "Равновесие",
                         "Координация", "Восстановление", "Энергия", "Комфорт движений",
                         "Ловкость", "Дыхательный комфорт", "Регулярность", "Техника"]

    init() { load() }

    func addRay() { rays.append(WheelRay()); save() }
    func removeRay(at index: Int) {
        guard rays.count > 1, rays.indices.contains(index) else { return }
        rays.remove(at: index)
        save()
    }
    func save() {
        let snapshot = WheelSnapshot(rays: rays, template: template, savedAt: Date())
        guard let encoded = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(encoded, forKey: Self.storageKey)
        lastSaved = snapshot.savedAt
    }
    func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let snapshot = try? JSONDecoder().decode(WheelSnapshot.self, from: data),
              !snapshot.rays.isEmpty else { return }
        rays = snapshot.rays
        template = snapshot.template
        lastSaved = snapshot.savedAt
    }
}
