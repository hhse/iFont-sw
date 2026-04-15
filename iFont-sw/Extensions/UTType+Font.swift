import UniformTypeIdentifiers

// MARK: - UTType 字体扩展

extension UTType {
    static var ttfFont: UTType {
        UTType(filenameExtension: "ttf") ?? .data
    }
    static var otfFont: UTType {
        UTType(filenameExtension: "otf") ?? .data
    }
    static var ttcFont: UTType {
        UTType(filenameExtension: "ttc") ?? .data
    }
}