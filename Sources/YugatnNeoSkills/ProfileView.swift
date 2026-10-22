import SwiftUI
import Foundation

struct LocalUserProfile: Codable {
    var displayName: String = ""
    var ageGroup: String = "Не указывать"
    var primaryGoal: String = ""
    var preferredMinutes: Int = 15
    var allowReminders: Bool = false
}

@MainActor
@Observable
final class ProfileStore {
    var profile = LocalUserProfile()
    private let key = "neo.skills.profile.v1"
    init() { load() }
    func save() {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode(LocalUserProfile.self, from: data) else { return }
        profile = saved
    }
    func clear() {
        profile = LocalUserProfile()
        UserDefaults.standard.removeObject(forKey: key)
    }
}

struct ProfileView: View {
    @Bindable var store: ProfileStore
    @State private var showReset = false
    var body: some View {
        Form {
            Section("Личный профиль — хранится на устройстве") {
                TextField("Имя или псевдоним (необязательно)", text: $store.profile.displayName)
                Picker("Возрастной режим", selection: $store.profile.ageGroup) {
                    ForEach(["Не указывать", "Подросток", "Взрослый", "Старшее поколение"], id: \.self) {
                        Text($0)
                    }
                }
                TextField("Моя цель", text: $store.profile.primaryGoal, axis: .vertical)
                Picker("Обычно есть времени", selection: $store.profile.preferredMinutes) {
                    ForEach([5, 10, 15, 20, 30, 45, 60], id: \.self) { Text("\($0) минут") }
                }
            }
            Section {
                Button("Сохранить профиль") { store.save() }
                    .buttonStyle(.borderedProminent)
                Button("Удалить локальный профиль", role: .destructive) { showReset = true }
            } footer: {
                Text("Регистрация не требуется. Профиль не отправляется на сервер. Удаление профиля не удаляет журнал тренировок и колесо: их управление будет отдельным.")
            }
        }
        .navigationTitle("Профиль")
        .onDisappear { store.save() }
        .confirmationDialog("Удалить профиль с этого устройства?", isPresented: $showReset) {
            Button("Удалить", role: .destructive) { store.clear() }
        }
    }
}
