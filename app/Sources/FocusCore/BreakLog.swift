import Foundation

/// Reads the break log that src/unfocus.sh and src/common.sh append to.
/// One event per line: "start <epoch> <deadline>" or "end <epoch>".
public enum BreakLog {
    public struct Interval: Equatable {
        public let start: Date
        public let end: Date

        public init(start: Date, end: Date) {
            self.start = start
            self.end = end
        }
    }

    /// Every break in the log, each ending at its "end" event or its deadline,
    /// whichever comes first. A break with no "end" (cut short by a reboot, or
    /// still running) ends at the next start, `now` or its deadline. Nothing counts past `now`.
    public static func intervals(from log: String, now: Date) -> [Interval] {
        var result: [Interval] = []
        var open: (start: TimeInterval, deadline: TimeInterval)?

        func close(at time: TimeInterval) {
            guard let current = open else { return }
            let end = min(time, current.deadline, now.timeIntervalSince1970)
            if end > current.start {
                result.append(Interval(start: Date(timeIntervalSince1970: current.start),
                                       end: Date(timeIntervalSince1970: end)))
            }
            open = nil
        }

        for line in log.split(whereSeparator: \.isNewline) {
            let fields = line.split(separator: " ").map(String.init)
            switch (fields.first, fields.count) {
            case ("start", 3):
                guard let start = TimeInterval(fields[1]), let deadline = TimeInterval(fields[2]) else { continue }
                // A second unfocus restarts the countdown, so the previous break ends here
                close(at: start)
                open = (start, deadline)
            case ("end", 2):
                guard let end = TimeInterval(fields[1]) else { continue }
                close(at: end)
            default:
                continue
            }
        }
        close(at: now.timeIntervalSince1970)
        return result
    }

    /// Seconds spent on breaks during the calendar day containing `day`.
    public static func total(on day: Date, log: String, now: Date, calendar: Calendar = .current) -> TimeInterval {
        let dayStart = calendar.startOfDay(for: day)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return 0 }
        return intervals(from: log, now: now).reduce(0) { sum, interval in
            sum + max(0, min(interval.end, dayEnd).timeIntervalSince(max(interval.start, dayStart)))
        }
    }
}
