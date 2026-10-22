import Foundation

enum SkillDiscipline: String, Codable, CaseIterable, Hashable {
    case yoga = "Йога"
    case kungFu = "Кунг-фу"
    case qigong = "Цигун"
    case judo = "Дзюдо"
    case jiuJitsu = "Джиу-джитсу"
}

struct SkillLesson: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let discipline: SkillDiscipline
    let minutes: Int
    let focus: String
    let description: String
    let sourceURL: String?
    let instructorRequired: Bool
}

struct PracticePreferences {
    let discipline: SkillDiscipline
    let minutesAvailable: Int
    let instructorPresent: Bool
    let painOrDizziness: Bool
}

struct LessonSuggestion {
    let lesson: SkillLesson
    let reason: String
}

/// Проверяемый локальный каталог; упражнения с партнёром и опасные техники не включены.
enum SkillCatalog {
    static let lessons: [SkillLesson] = [
        SkillLesson(id: "yoga-butterfly", title: "Мягкая практика «Бабочка»",
                    discipline: .yoga, minutes: 10, focus: "Подвижность",
                    description: "Без боли и давления на колени.", sourceURL: nil,
                    instructorRequired: false),
        SkillLesson(id: "qigong-breath", title: "Цигун: дыхание и осанка",
                    discipline: .qigong, minutes: 5, focus: "Дыхательный комфорт",
                    description: "Спокойное естественное дыхание стоя или сидя, без задержек и форсирования. Вводная современная адаптация, не аттестованный традиционный комплекс.",
                    sourceURL: "https://www.nccih.nih.gov/health/qigong-what-you-need-to-know",
                    instructorRequired: false),
        SkillLesson(id: "qigong-movement", title: "Цигун: плавные движения",
                    discipline: .qigong, minutes: 10, focus: "Координация",
                    description: "Мягкие движения в комфортной амплитуде с вниманием к дыханию. Не выдавать за конкретную линию передачи.",
                    sourceURL: "https://www.nccih.nih.gov/health/qigong-what-you-need-to-know",
                    instructorRequired: false),
        SkillLesson(id: "kungfu-steps", title: "Кунг-фу: базовое перемещение",
                    discipline: .kungFu, minutes: 10, focus: "Координация",
                    description: "Неспешные одиночные перемещения без ударов и акробатики.",
                    sourceURL: "https://shaolincn.org/templates/EN_T_new_list/index.aspx?nodeid=378",
                    instructorRequired: false),
        SkillLesson(id: "judo-balance", title: "Дзюдо: равновесие без партнёра",
                    discipline: .judo, minutes: 10, focus: "Равновесие",
                    description: "Общая физическая подготовка, без бросков и падений.",
                    sourceURL: nil, instructorRequired: false),
        SkillLesson(id: "jiujitsu-mobility", title: "Джиу-джитсу: базовая мобильность",
                    discipline: .jiuJitsu, minutes: 10, focus: "Подвижность",
                    description: "Разминка без захватов, болевых и удушающих приёмов.",
                    sourceURL: nil, instructorRequired: false)
    ]
}

enum SkillPlanner {
    static func recommend(
        _ preferences: PracticePreferences,
        wheel: [WheelRay],
        catalog: [SkillLesson] = SkillCatalog.lessons
    ) -> [LessonSuggestion] {
        guard preferences.minutesAvailable > 0, !preferences.painOrDizziness else { return [] }
        let goals = Dictionary(wheel.filter { !$0.name.isEmpty }.map {
            ($0.name, max(0, $0.desired - $0.current))
        }, uniquingKeysWith: max)
        return catalog.filter {
            $0.discipline == preferences.discipline &&
            $0.minutes <= preferences.minutesAvailable &&
            (!$0.instructorRequired || preferences.instructorPresent)
        }
        .sorted {
            let a = goals[$0.focus, default: 0], b = goals[$1.focus, default: 0]
            if a != b { return a > b }
            if $0.minutes != $1.minutes { return $0.minutes < $1.minutes }
            return $0.id < $1.id
        }
        .map {
            LessonSuggestion(lesson: $0, reason: goals[$0.focus, default: 0] > 0
                ? "Соответствует выбранной цели «\($0.focus)» и доступному времени"
                : "Соответствует направлению и доступному времени")
        }
    }
}
