import FocusCore
import XCTest

final class BreakLogTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    // 2026-10-18 00:00:00 UTC
    private let midnight: TimeInterval = 1_792_281_600

    private func total(_ log: String, now: TimeInterval) -> TimeInterval {
        BreakLog.total(on: Date(timeIntervalSince1970: now), log: log,
                       now: Date(timeIntervalSince1970: now), calendar: calendar)
    }

    func testNaturalEndCountsFullBreak() {
        let start = midnight + 3600
        let log = "start \(Int(start)) \(Int(start + 300))\nend \(Int(start + 300))\n"
        XCTAssertEqual(total(log, now: start + 1000), 300)
    }

    func testEarlyEndCountsUntilEnd() {
        let start = midnight + 3600
        let log = "start \(Int(start)) \(Int(start + 900))\nend \(Int(start + 120))\n"
        XCTAssertEqual(total(log, now: start + 1000), 120)
    }

    func testOpenBreakCountsUntilNow() {
        let start = midnight + 3600
        let log = "start \(Int(start)) \(Int(start + 600))\n"
        XCTAssertEqual(total(log, now: start + 90), 90)
    }

    func testUnterminatedBreakIsCappedAtDeadline() {
        // e.g. the Mac rebooted during the break
        let start = midnight + 3600
        let log = "start \(Int(start)) \(Int(start + 300))\n"
        XCTAssertEqual(total(log, now: start + 5000), 300)
    }

    func testRestartedBreakEndsPreviousOne() {
        let start = midnight + 3600
        let log = """
        start \(Int(start)) \(Int(start + 300))
        start \(Int(start + 60)) \(Int(start + 660))
        end \(Int(start + 660))
        """
        XCTAssertEqual(total(log, now: start + 5000), 660)
    }

    func testBreakAcrossMidnightIsSplit() {
        let start = midnight - 120
        let log = "start \(Int(start)) \(Int(start + 300))\nend \(Int(start + 300))\n"
        XCTAssertEqual(total(log, now: midnight + 1000), 180)
        XCTAssertEqual(total(log, now: midnight - 1), 119)
    }

    func testOtherDaysAndGarbageAreIgnored() {
        let yesterday = midnight - 50_000
        let log = """
        start \(Int(yesterday)) \(Int(yesterday + 300))
        end \(Int(yesterday + 300))
        nonsense
        start abc def

        """
        XCTAssertEqual(total(log, now: midnight + 10), 0)
    }
}
