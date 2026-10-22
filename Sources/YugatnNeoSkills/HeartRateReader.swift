import Foundation
import HealthKit

/// Только чтение, после явного разрешения. Нет пульсометра — нет выдуманных значений.
@MainActor
final class HeartRateReader {
    private let store = HKHealthStore()

    func requestAccess() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthError.unavailable
        }
        try await store.requestAuthorization(
            toShare: [],
            read: [HKQuantityType(.heartRate)]
        )
    }

    /// Последний доступный образец не старше указанного интервала.
    /// nil = нет доступного измерения, в том числе если доступ не дан.
    func latestBPM(within seconds: TimeInterval = 600) async throws -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        let type = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-seconds),
            end: Date(),
            options: .strictStartDate
        )
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil); return
                }
                let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: bpm)
            }
            store.execute(query)
        }
    }

    enum HealthError: Error { case unavailable }
}
