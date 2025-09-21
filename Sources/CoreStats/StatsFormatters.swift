import Foundation

public enum StatsFormatters {
    public static func memoryString(used: UInt64, total: UInt64, fractionDigits: Int = 1) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .memory
        formatter.includesActualByteCount = false
        formatter.allowsNonnumericFormatting = false
        formatter.isAdaptive = true

        let usedString = formatter.string(fromByteCount: Int64(used))
        let totalString = formatter.string(fromByteCount: Int64(total))
        let percentage = total > 0 ? (Double(used) / Double(total)) : 0
        let formattedPercentage = NumberFormatter.percent(fractionDigits: fractionDigits).string(from: NSNumber(value: percentage)) ?? ""
        return "\(usedString)/\(totalString) \(formattedPercentage)"
    }
}

private extension NumberFormatter {
    static func percent(fractionDigits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumFractionDigits = fractionDigits
        return formatter
    }
}
