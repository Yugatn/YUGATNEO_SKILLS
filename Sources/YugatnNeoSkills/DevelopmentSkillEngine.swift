import Foundation

/// Educational decision support, not a diagnosis or a moral score of a person.
/// Canonical source: BOOK/06_LAW_OF_DEVELOPMENT.md (Yugatn/ambivalent-solipsism).
enum DevelopmentStage: String, CaseIterable, Codable {
    case recognize = "Р — Распознай"
    case assess = "А — Анализируй"
    case alternatives = "З — Заметь возможности"
    case forecast = "В — Взвесь последствия"
    case inspect = "И — Исследуй ограничения"
    case choose = "Т — Твори решение"
    case reflect = "И — Испытай и исправь"
    case transfer = "Е — Ещё раз примени"

    var prompt: String {
        switch self {
        case .recognize: return "Что произошло, а что пока только предположение?"
        case .assess: return "Чего хочешь ты и что может быть важно другим?"
        case .alternatives: return "Какие есть варианты, включая паузу и просьбу о помощи?"
        case .forecast: return "Что может произойти и можно ли исправить последствия?"
        case .inspect: return "Есть ли согласие? Не нарушаются ли чьи-то границы?"
        case .choose: return "Какой допустимый вариант оставляет больше возможностей?"
        case .reflect: return "Что получилось? Как исправить ошибку?"
        case .transfer: return "Где ещё можно применить этот урок?"
        }
    }
}

enum DevelopmentAgeBand: String, Codable {
    case preschool, earlySchool, middleSchool, adolescent, adult

    var adultFacilitatorRequired: Bool { self == .preschool }
}

struct DevelopmentOption: Equatable, Codable, Identifiable {
    let id: String
    let label: String
    let requiresConsent: Bool
    let consentGranted: Bool
    let violatesRights: Bool
    let irreversibleHarmRisk: Bool
    let requiresAdultAuthorization: Bool
    let adultAuthorized: Bool
}

enum DevelopmentDecision: Equatable {
    case eligible([DevelopmentOption])
    case needsClarification
}

struct DevelopmentSkillEngine {
    /// A hard constraint gate: perceived usefulness never overrides rights or consent.
    func evaluate(_ options: [DevelopmentOption]) -> DevelopmentDecision {
        let permitted = options.filter {
            !$0.violatesRights &&
            !$0.irreversibleHarmRisk &&
            (!$0.requiresConsent || $0.consentGranted) &&
            (!$0.requiresAdultAuthorization || $0.adultAuthorized)
        }
        return permitted.isEmpty ? .needsClarification : .eligible(permitted)
    }

    /// No scoring of children's character, personality, or "virtue".
    func prompts(for age: DevelopmentAgeBand) -> [String] {
        if age == .preschool {
            return [
                "Что случилось?",
                "Как можно попросить или позвать взрослого?",
                "Что получилось и что можно попробовать иначе?"
            ]
        }
        return DevelopmentStage.allCases.map(\.prompt)
    }
}
