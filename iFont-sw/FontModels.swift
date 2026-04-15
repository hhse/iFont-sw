import Foundation

// MARK: - 枚举定义 (从 FontConverter.swift 分离)

enum WeightMode: String, CaseIterable, Identifiable {
    case single = "全局统配"
    case dual = "粗细分离"
    case triple = "三阶层次"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .single: return "全部使用常规体"
        case .dual: return "区分常规与中黑"
        case .triple: return "细/常/粗组合"
        }
    }
}

enum CompatLayer: String, CaseIterable, Identifiable {
    case ios18 = "iOS 18-26"
    case ios9 = "iOS 9-17"

    var id: String { rawValue }
}

enum OutputFormat: String, CaseIterable, Identifiable {
    case ttc = "TTC"
    case ttf = "TTF"

    var id: String { rawValue }
}

// MARK: - 结果结构

struct ConversionResult: Identifiable {
    let id = UUID()
    let name: String
    let data: Data
    let size: Int64

    var sizeDescription: String {
        let mb = Double(size) / 1_048_576
        return String(format: "%.1f MB", mb)
    }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let time: Date
    let level: LogLevel
    let text: String

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: time)
    }

    enum LogLevel {
        case info
        case step
        case ok
        case err
    }
}