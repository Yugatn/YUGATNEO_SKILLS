import XCTest
@testable import YugatnNeoSkills

/// Regression tests for the local, non-clinical lesson recommender.
/// These tests check safety gates only; they do not validate exercise technique.
final class SkillPlannerSafetyTests: XCTestCase {
    private func preferences(
        minutes: Int = 15,
        instructorPresent: Bool = false,
        painOrDizziness: Bool = false
    ) -> PracticePreferences {
        PracticePreferences(
            discipline: .yoga,
            minutesAvailable: minutes,
            instructorPresent: instructorPresent,
            painOrDizziness: painOrDizziness
        )
    }

    private let catalog: [SkillLesson] = [
        SkillLesson(id: "solo", title: "Вводное занятие", discipline: .yoga,
                    minutes: 5, focus: "Подвижность", description: "Без боли",
                    sourceURL: nil, instructorRequired: false),
        SkillLesson(id: "supervised", title: "Только с инструктором", discipline: .yoga,
                    minutes: 10, focus: "Подвижность", description: "Нужен инструктор",
                    sourceURL: nil, instructorRequired: true)
    ]

    func testPainOrDizzinessStopsAllRecommendations() {
        XCTAssertTrue(SkillPlanner.recommend(
            preferences(painOrDizziness: true), wheel: [], catalog: catalog
        ).isEmpty)
        XCTAssertTrue(SkillPlanner.recommend(
            preferences(instructorPresent: true, painOrDizziness: true),
            wheel: [], catalog: catalog
        ).isEmpty)
    }

    func testNonpositiveAndInsufficientTimeProduceNoSuggestions() {
        for minutes in [-1, 0, 4] {
            XCTAssertTrue(SkillPlanner.recommend(
                preferences(minutes: minutes), wheel: [], catalog: catalog
            ).isEmpty)
        }
    }

    func testInstructorOnlyLessonIsNotSuggestedForSoloPractice() {
        let solo = SkillPlanner.recommend(preferences(), wheel: [], catalog: catalog)
        XCTAssertEqual(solo.map { $0.lesson.id }, ["solo"])

        let supervised = SkillPlanner.recommend(
            preferences(instructorPresent: true), wheel: [], catalog: catalog
        )
        XCTAssertEqual(Set(supervised.map { $0.lesson.id }), Set(["solo", "supervised"]))
    }
}
