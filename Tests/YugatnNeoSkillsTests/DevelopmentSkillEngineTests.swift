import XCTest
@testable import YugatnNeoSkills

final class DevelopmentSkillEngineTests: XCTestCase {
    private let engine = DevelopmentSkillEngine()

    func testEightStagesHavePrompts() {
        XCTAssertEqual(DevelopmentStage.allCases.count, 8)
        XCTAssertEqual(engine.prompts(for: .adolescent).count, 8)
        XCTAssertEqual(engine.prompts(for: .preschool).count, 3)
        XCTAssertTrue(DevelopmentAgeBand.preschool.adultFacilitatorRequired)
    }

    func testConsentAndRightsCannotBeOverridden() {
        let covertMonitoring = DevelopmentOption(
            id: "monitor", label: "Тайно наблюдать", requiresConsent: true,
            consentGranted: false, violatesRights: true,
            irreversibleHarmRisk: false, requiresAdultAuthorization: false,
            adultAuthorized: false
        )
        XCTAssertEqual(engine.evaluate([covertMonitoring]), .needsClarification)
    }

    func testSafeAlternativeRemainsAvailable() {
        let unsafe = DevelopmentOption(
            id: "share", label: "Разослать чужое фото", requiresConsent: true,
            consentGranted: false, violatesRights: false,
            irreversibleHarmRisk: false, requiresAdultAuthorization: false,
            adultAuthorized: false
        )
        let safe = DevelopmentOption(
            id: "ask", label: "Спросить согласие", requiresConsent: false,
            consentGranted: false, violatesRights: false,
            irreversibleHarmRisk: false, requiresAdultAuthorization: false,
            adultAuthorized: false
        )
        XCTAssertEqual(engine.evaluate([unsafe, safe]), .eligible([safe]))
    }

    func testAdultAuthorizationGate() {
        let action = DevelopmentOption(
            id: "sensitive", label: "Чувствительная функция", requiresConsent: false,
            consentGranted: false, violatesRights: false,
            irreversibleHarmRisk: false, requiresAdultAuthorization: true,
            adultAuthorized: false
        )
        XCTAssertEqual(engine.evaluate([action]), .needsClarification)
    }

    func testIrreversibleHarmExcluded() {
        let option = DevelopmentOption(
            id: "harm", label: "Необратимый вред", requiresConsent: false,
            consentGranted: false, violatesRights: false,
            irreversibleHarmRisk: true, requiresAdultAuthorization: false,
            adultAuthorized: false
        )
        XCTAssertEqual(engine.evaluate([option]), .needsClarification)
    }
}
