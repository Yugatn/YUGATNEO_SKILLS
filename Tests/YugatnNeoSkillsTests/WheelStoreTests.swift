import XCTest
@testable import YugatnNeoSkills

final class WheelStoreTests: XCTestCase {
    @MainActor
    func testDefaultWheelAndSnapshotRestore() {
        let suite = "org.yugatn.skills.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Could not create isolated test defaults")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = WheelStore(defaults: defaults)
        XCTAssertEqual(store.rays.count, 12)
        XCTAssertTrue(store.history.isEmpty)

        store.rays[0].name = "Подвижность"
        store.rays[0].current = 0
        store.rays[0].desired = 10
        store.save()
        XCTAssertEqual(store.history.count, 1)

        store.save() // unchanged content must not create another checkpoint
        XCTAssertEqual(store.history.count, 1)

        store.rays[0].current = 4
        store.save()
        XCTAssertEqual(store.history.count, 2)

        let reloaded = WheelStore(defaults: defaults)
        XCTAssertEqual(reloaded.rays[0].current, 4)
        XCTAssertEqual(reloaded.history.count, 2)
        reloaded.restore(reloaded.history[1])
        XCTAssertEqual(reloaded.rays[0].current, 0)
        XCTAssertEqual(reloaded.rays[0].desired, 10)
    }

    @MainActor
    func testCannotDeleteLastRay() {
        let suite = "org.yugatn.skills.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Could not create isolated test defaults")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = WheelStore(defaults: defaults)
        for _ in 0..<11 { store.removeRay(at: 0) }
        XCTAssertEqual(store.rays.count, 1)
        store.removeRay(at: 0)
        XCTAssertEqual(store.rays.count, 1)
    }
}
