import XCTest
@testable import YugatnNeoSkills

final class DevelopmentLearningPathTests: XCTestCase {
    func testCompletionIsUniqueAndCanBeCleared() {
        var path = DevelopmentLearningPath()
        path.complete(scenarioTitle: "A", focus: .consent)
        path.complete(scenarioTitle: "A", focus: .consent)
        XCTAssertEqual(path.completed.count, 1)
        path.clear()
        XCTAssertTrue(path.completed.isEmpty)
    }

    func testSuggestionPrefersUnpracticedFocus() {
        var path = DevelopmentLearningPath()
        let scenarios = DevelopmentScenario.examples
        XCTAssertEqual(path.suggestedIndex(in: scenarios), 0)
        path.complete(scenarioTitle: scenarios[0].title, focus: scenarios[0].focus)
        XCTAssertEqual(path.suggestedIndex(in: scenarios), 1)
        path.complete(scenarioTitle: scenarios[1].title, focus: scenarios[1].focus)
        XCTAssertEqual(path.suggestedIndex(in: scenarios), 2)
    }

    func testEmptyScenarioListDoesNotCrash() {
        let path = DevelopmentLearningPath()
        XCTAssertNil(path.suggestedIndex(in: []))
    }

    func testCompletionDoesNotDependOnChoiceOrCharacterRating() {
        var path = DevelopmentLearningPath()
        path.complete(scenarioTitle: "Безопасная рефлексия", focus: .repair)
        XCTAssertEqual(path.completed.first?.reflected, true)
        XCTAssertEqual(path.completed.first?.focus, .repair)
    }
}
