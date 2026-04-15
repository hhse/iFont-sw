import Foundation
import Combine

// MARK: - 字体表结构 (内部使用)

struct FontTable {
    let tag: String
    let data: Data
}

struct SFNTInfo {
    let sfVersion: UInt32
    let tables: [FontTable]
}

struct FontNameInfo {
    let family: String
    let subfamily: String
    let copyright: String
    let version: String
    let designer: String
    let license: String
}

// MARK: - 读取工具函数

private func readU16(_ dv: Data, _ offset: Int) -> UInt16 {
    return UInt16(dv[offset]) << 8 | UInt16(dv[offset + 1])
}

private func readU32(_ dv: Data, _ offset: Int) -> UInt32 {
    return UInt32(dv[offset]) << 24 | UInt32(dv[offset + 1]) << 16 | UInt32(dv[offset + 2]) << 8 | UInt32(dv[offset + 3])
}

private func readTag(_ dv: Data, _ offset: Int) -> String {
    guard offset + 3 < dv.count else { return "" }
    let s0 = String(UnicodeScalar(dv[offset]))
    let s1 = String(UnicodeScalar(dv[offset + 1]))
    let s2 = String(UnicodeScalar(dv[offset + 2]))
    let s3 = String(UnicodeScalar(dv[offset + 3]))
    return s0 + s1 + s2 + s3
}

private func align4(_ n: Int) -> Int {
    return (n + 3) & ~3
}

// MARK: - 字体解析

private func isTTC(_ data: Data) -> Bool {
    return readTag(data, 0) == "ttcf"
}

private func parseTTC(_ data: Data) -> (numFonts: UInt32, offsets: [UInt32]) {
    guard data.count >= 12 else { return (0, []) }
    let numFonts = readU32(data, 8)
    var offsets: [UInt32] = []
    for i in 0..<Int(numFonts) {
        let offset = readU32(data, 12 + i * 4)
        offsets.append(offset)
    }
    return (numFonts, offsets)
}

private func parseSFNT(_ data: Data, offset: Int) -> SFNTInfo {
    guard offset + 12 < data.count else { return SFNTInfo(sfVersion: 0, tables: []) }
    let sfVersion = readU32(data, offset)
    let numTables = readU16(data, offset + 4)
    var tables: [FontTable] = []
    for i in 0..<Int(numTables) {
        let r = offset + 12 + i * 16
        guard r + 16 <= data.count else { continue }
        let tag = readTag(data, r)
        let tableOffset = Int(readU32(data, r + 8))
        let length = Int(readU32(data, r + 12))
        let end = min(tableOffset + length, data.count)
        let start = min(tableOffset, data.count)
        let tableData = data.subdata(in: start..<end)
        tables.append(FontTable(tag: tag, data: tableData))
    }
    return SFNTInfo(sfVersion: sfVersion, tables: tables)
}

// MARK: - 名称解析

private func decodeUTF16BE(_ data: Data, _ offset: Int, _ length: Int) -> String {
    var s = ""
    var i = offset
    var count = 0
    while count < length && i + 1 < data.count {
        let code = (UInt16(data[i]) << 8) | UInt16(data[i + 1])
        if code == 0 { break }
        s.append(Character(UnicodeScalar(code)!))
        i += 2
        count += 2
    }
    return s
}

private func decodeMacRoman(_ data: Data, _ offset: Int, _ length: Int) -> String {
    var s = ""
    for i in 0..<length {
        if offset + i < data.count {
            let byte = data[offset + i]
            let scalar = UnicodeScalar(byte)
            s.append(Character(scalar))
        }
    }
    return s
}

private func getNameStr(_ nameData: Data, nameID: UInt16, platformID: UInt16, langID: UInt16) -> String? {
    guard nameData.count >= 6 else { return nil }
    let count = readU16(nameData, 2)
    let strOff = Int(readU16(nameData, 4))

    for i in 0..<Int(count) {
        let r = 6 + i * 12
        guard r + 12 <= nameData.count else { continue }

        if readU16(nameData, r) != platformID { continue }
        if readU16(nameData, r + 4) != langID { continue }
        if readU16(nameData, r + 6) != nameID { continue }

        let len = Int(readU16(nameData, r + 8))
        let off = Int(readU16(nameData, r + 10))

        guard strOff + off + len <= nameData.count else { continue }

        if platformID == 3 {
            return decodeUTF16BE(nameData, strOff + off, len)
        } else if platformID == 1 {
            return decodeMacRoman(nameData, strOff + off, len)
        }
    }
    return nil
}

private func getFamily(_ nameData: Data) -> String {
    return getNameStr(nameData, nameID: 1, platformID: 3, langID: 0x0409) ??
           getNameStr(nameData, nameID: 1, platformID: 1, langID: 0) ??
           "Unknown"
}

private func getSubfamily(_ nameData: Data) -> String {
    return getNameStr(nameData, nameID: 2, platformID: 3, langID: 0x0409) ??
           getNameStr(nameData, nameID: 2, platformID: 1, langID: 0) ??
           "Regular"
}

private func getNameInfo(_ nameData: Data) -> FontNameInfo {
    let f1 = getNameStr(nameData, nameID: 1, platformID: 3, langID: 0x0409) ?? ""
    let f2 = getNameStr(nameData, nameID: 2, platformID: 3, langID: 0x0409) ?? ""
    let f3 = getNameStr(nameData, nameID: 0, platformID: 3, langID: 0x0409) ?? ""
    let f4 = getNameStr(nameData, nameID: 5, platformID: 3, langID: 0x0409) ?? ""
    let f5 = getNameStr(nameData, nameID: 9, platformID: 3, langID: 0x0409) ?? ""
    let f6 = getNameStr(nameData, nameID: 13, platformID: 3, langID: 0x0409) ?? ""
    return FontNameInfo(
        family: f1,
        subfamily: f2,
        copyright: f3,
        version: f4,
        designer: f5,
        license: f6
    )
}

// MARK: - 字体转换器

class FontConverter: ObservableObject {
    @Published var logs: [LogEntry] = []
    @Published var progress: Double = 0
    @Published var isConverting: Bool = false
    @Published var results: [ConversionResult] = []
    @Published var errorMessage: String?

    private let weightKeywords: [String: String] = [
        "ultralight": "ultralight", "extralight": "ultralight",
        "thin": "thin", "light": "light",
        "regular": "regular", "default": "regular",
        "medium": "medium",
        "semibold": "semibold", "demibold": "semibold",
        "bold": "bold",
        "heavy": "heavy", "extrabold": "heavy", "ultrabold": "heavy", "black": "heavy"
    ]

    private let fallbackMap: [String: [String]] = [
        "ultralight": ["thin", "light", "regular"],
        "thin": ["ultralight", "light", "regular"],
        "light": ["thin", "regular", "ultralight"],
        "regular": ["medium", "light", "thin"],
        "medium": ["regular", "semibold", "light"],
        "semibold": ["bold", "medium", "heavy", "regular"],
        "bold": ["semibold", "heavy", "medium", "regular"],
        "heavy": ["bold", "semibold", "medium", "regular"]
    ]

    struct FontSourceData {
        let sfVersion: UInt32
        let tables: [FontTable]
    }

    func addLog(_ level: LogEntry.LogLevel, _ text: String) {
        DispatchQueue.main.async {
            self.logs.append(LogEntry(time: Date(), level: level, text: text))
        }
    }

    func classifyWeight(subfamily: String) -> String {
        let lower = subfamily.lowercased()
        for (kw, cat) in weightKeywords {
            if lower.contains(kw) {
                return cat
            }
        }
        return "regular"
    }

    func pickSource(sources: [String: FontSourceData], targetWeight: String, mode: WeightMode) -> FontSourceData? {
        var mappedWeight = "regular"

        switch mode {
        case .single:
            mappedWeight = "regular"
        case .dual:
            if ["medium", "semibold", "bold", "heavy"].contains(targetWeight) {
                mappedWeight = "medium"
            } else {
                mappedWeight = "regular"
            }
        case .triple:
            if ["medium", "semibold", "bold", "heavy"].contains(targetWeight) {
                mappedWeight = "bold"
            } else if ["ultralight", "thin", "light"].contains(targetWeight) {
                mappedWeight = "light"
            } else {
                mappedWeight = "regular"
            }
        }

        if let source = sources[mappedWeight] {
            return source
        }
        if let regular = sources["regular"] {
            return regular
        }
        return sources.values.first
    }

    func convert(
        sourceData: Data,
        fileName: String,
        mode: WeightMode,
        outputFormat: OutputFormat,
        outputTemplate: String
    ) {
        isConverting = true
        results = []
        errorMessage = nil
        progress = 0

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                self.addLog(.info, "开始处理: \(fileName)")

                let templates = FontTemplates.shared.getTemplates()
                self.addLog(.info, "环境就绪: 覆盖 \(FontTemplates.shared.getFamilyCount()) 个字体族")

                let sources = try self.loadSource(data: sourceData)
                self.addLog(.info, "检测到字重: \(sources.keys.joined(separator: ", "))")

                let fonts = self.convertOne(sources: sources, mode: mode)

                let fontName = (fileName as NSString).deletingPathExtension
                let outName = outputTemplate.isEmpty ? "\(fontName)UI" : outputTemplate.replacingOccurrences(of: "${fontName}", with: fontName)

                if outputFormat == .ttf {
                    let ttfs = self.convertToTTFs(fonts: fonts)
                    for (index, ttfData) in ttfs.enumerated() {
                        let tpl = templates[index]
                        let ttfName = "\(tpl.family).ttf"
                        let result = ConversionResult(name: ttfName, data: ttfData, size: Int64(ttfData.count))
                        DispatchQueue.main.async {
                            self.results.append(result)
                        }
                    }
                    self.addLog(.ok, "拆分完成: \(ttfs.count) 个 TTF")
                } else {
                    let ttcData = self.convertToTTC(fonts: fonts)
                    let ttcName = "\(outName).ttc"
                    let result = ConversionResult(name: ttcName, data: ttcData, size: Int64(ttcData.count))
                    DispatchQueue.main.async {
                        self.results.append(result)
                    }
                    let sizeMB = Double(ttcData.count) / 1_048_576
                    self.addLog(.ok, "封装成功: \(ttcName) (\(String(format: "%.1f", sizeMB)) MB)")
                }

                self.addLog(.ok, "全部完成")

                DispatchQueue.main.async {
                    self.progress = 1.0
                    self.isConverting = false
                }

            } catch {
                self.addLog(.err, "错误: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isConverting = false
                }
            }
        }
    }

    func loadSource(data: Data) throws -> [String: FontSourceData] {
        var sources: [String: FontSourceData] = [:]

        if isTTC(data) {
            let ttc = parseTTC(data)
            addLog(.info, "  TTC 包含 \(ttc.numFonts) 个子字体")

            for offset in ttc.offsets {
                let sfnt = parseSFNT(data, offset: Int(offset))
                let nameRec = sfnt.tables.first { $0.tag == "name" }

                if let nameRec = nameRec {
                    let subfamily = getSubfamily(nameRec.data)
                    let cat = classifyWeight(subfamily: subfamily)

                    if !sources.keys.contains(cat) {
                        sources[cat] = FontSourceData(
                            sfVersion: sfnt.sfVersion,
                            tables: sfnt.tables.map { FontTable(tag: $0.tag, data: $0.data) }
                        )
                    }
                }
            }
        } else {
            let sfnt = parseSFNT(data, offset: 0)
            let nameRec = sfnt.tables.first { $0.tag == "name" }

            if let nameRec = nameRec {
                let info = getNameInfo(nameRec.data)
                if !info.family.isEmpty { addLog(.info, "  字体名称: \(info.family)") }
                if !info.subfamily.isEmpty { addLog(.info, "  子族: \(info.subfamily)") }
            }

            let fontData = FontSourceData(
                sfVersion: sfnt.sfVersion,
                tables: sfnt.tables.map { FontTable(tag: $0.tag, data: $0.data) }
            )

            for weight in ["ultralight", "thin", "light", "regular", "medium", "semibold", "bold", "heavy"] {
                sources[weight] = fontData
            }
        }

        return sources
    }

    func convertOne(sources: [String: FontSourceData], mode: WeightMode) -> [(sfVersion: UInt32, tables: [FontTable])] {
        addLog(.info, "  映射配置: \(mode.rawValue), 开始组装数据结构...")

        let templates = FontTemplates.shared.getTemplates()
        var fonts: [(sfVersion: UInt32, tables: [FontTable])] = []

        for tpl in templates {
            guard let nameData = tpl.nameData else { continue }
            guard let src = pickSource(sources: sources, targetWeight: tpl.subfamily.lowercased(), mode: mode) else { continue }

            var tables: [FontTable] = []

            for t in src.tables {
                if t.tag == "name" {
                    tables.append(FontTable(tag: "name", data: nameData))
                } else if t.tag == "OS/2" {
                    tables.append(FontTable(tag: "OS/2", data: modifyOS2(t.data, weight: tpl.weightClass, fsType: tpl.fsType)))
                } else {
                    tables.append(t)
                }
            }

            fonts.append((sfVersion: src.sfVersion, tables: tables))
        }

        return fonts
    }

    func modifyOS2(_ data: Data, weight: UInt16, fsType: UInt16) -> Data {
        var modified = Data(data)
        if modified.count >= 10 {
            modified[4] = UInt8((weight >> 8) & 0xFF)
            modified[5] = UInt8(weight & 0xFF)
            modified[8] = UInt8((fsType >> 8) & 0xFF)
            modified[9] = UInt8(fsType & 0xFF)
        }
        return modified
    }

    func convertToTTC(fonts: [(sfVersion: UInt32, tables: [FontTable])]) -> Data {
        addLog(.info, "  执行二进制打包 (引用级查重优化)...")

        var pool: [Data] = []
        var refMap: [Data: Int] = [:]

        func getPoolIndex(_ data: Data) -> Int {
            if let idx = refMap[data] {
                return idx
            }
            let idx = pool.count
            pool.append(data)
            refMap[data] = idx
            return idx
        }

        var fontRefs: [(sfVersion: UInt32, tables: [(tag: String, poolIdx: Int, length: Int)])] = []

        for font in fonts {
            let sortedTables = font.tables.sorted { $0.tag < $1.tag }
            var tables: [(tag: String, poolIdx: Int, length: Int)] = []
            for t in sortedTables {
                let poolIdx = getPoolIndex(t.data)
                tables.append((tag: t.tag, poolIdx: poolIdx, length: t.data.count))
            }
            fontRefs.append((sfVersion: font.sfVersion, tables: tables))
        }

        let numFonts = fonts.count
        let ttcHdrSize = 12 + 4 * numFonts
        var offset = ttcHdrSize
        var dirOffsets: [Int] = []

        for fr in fontRefs {
            dirOffsets.append(offset)
            offset += 12 + 16 * fr.tables.count
        }
        offset = align4(offset)

        var poolOffsets: [Int] = []
        for d in pool {
            poolOffsets.append(offset)
            offset += align4(d.count)
        }

        let totalSize = offset
        var result = Data(count: totalSize)

        result[0] = 0x74; result[1] = 0x74; result[2] = 0x63; result[3] = 0x66
        writeU16(&result, 4, 2)
        writeU16(&result, 6, 0)
        writeU32(&result, 8, UInt32(numFonts))
        for i in 0..<numFonts {
            writeU32(&result, 12 + i * 4, UInt32(dirOffsets[i]))
        }

        for fi in 0..<numFonts {
            let fr = fontRefs[fi]
            let o = dirOffsets[fi]
            let nt = fr.tables.count

            writeU32(&result, o, fr.sfVersion)
            writeU16(&result, o + 4, UInt16(nt))

            var p2 = 1, lg = 0
            while p2 * 2 <= nt { p2 *= 2; lg += 1 }
            writeU16(&result, o + 6, UInt16(p2 * 16))
            writeU16(&result, o + 8, UInt16(lg))
            writeU16(&result, o + 10, UInt16(nt * 16 - p2 * 16))

            for ti in 0..<nt {
                let t = fr.tables[ti]
                let r = o + 12 + ti * 16

                let tagBytes = t.tag.utf8
                if tagBytes.count >= 4 {
                    result[r] = tagBytes[tagBytes.startIndex]
                    result[r + 1] = tagBytes[tagBytes.index(tagBytes.startIndex, offsetBy: 1)]
                    result[r + 2] = tagBytes[tagBytes.index(tagBytes.startIndex, offsetBy: 2)]
                    result[r + 3] = tagBytes[tagBytes.index(tagBytes.startIndex, offsetBy: 3)]
                }

                writeU32(&result, r + 4, calcChecksum(pool[t.poolIdx]))
                writeU32(&result, r + 8, UInt32(poolOffsets[t.poolIdx]))
                writeU32(&result, r + 12, UInt32(t.length))
            }
        }

        for i in 0..<pool.count {
            let start = poolOffsets[i]
            let end = start + pool[i].count
            if end <= result.count {
                result.replaceSubrange(start..<end, with: pool[i])
            }
        }

        return result
    }

    func convertToTTFs(fonts: [(sfVersion: UInt32, tables: [FontTable])]) -> [Data] {
        addLog(.info, "  拆分为独立 TTF 文件...")

        return fonts.map { font in
            let sorted = font.tables.sorted { $0.tag < $1.tag }
            let nt = sorted.count

            var offset = 12 + 16 * nt
            var tableOffsets: [Int] = []
            for t in sorted {
                tableOffsets.append(offset)
                offset += align4(t.data.count)
            }

            var result = Data(count: offset)

            writeU32(&result, 0, font.sfVersion)
            writeU16(&result, 4, UInt16(nt))

            var p2 = 1, lg = 0
            while p2 * 2 <= nt { p2 *= 2; lg += 1 }
            writeU16(&result, 6, UInt16(p2 * 16))
            writeU16(&result, 8, UInt16(lg))
            writeU16(&result, 10, UInt16(nt * 16 - p2 * 16))

            for i in 0..<nt {
                let r = 12 + i * 16
                let tagBytes = sorted[i].tag.utf8
                if tagBytes.count >= 4 {
                    result[r] = tagBytes[tagBytes.startIndex]
                    result[r + 1] = tagBytes[tagBytes.index(tagBytes.startIndex, offsetBy: 1)]
                    result[r + 2] = tagBytes[tagBytes.index(tagBytes.startIndex, offsetBy: 2)]
                    result[r + 3] = tagBytes[tagBytes.index(tagBytes.startIndex, offsetBy: 3)]
                }

                writeU32(&result, r + 4, calcChecksum(sorted[i].data))
                writeU32(&result, r + 8, UInt32(tableOffsets[i]))
                writeU32(&result, r + 12, UInt32(sorted[i].data.count))
            }

            for i in 0..<nt {
                let start = tableOffsets[i]
                let end = start + sorted[i].data.count
                if end <= result.count {
                    result.replaceSubrange(start..<end, with: sorted[i].data)
                }
            }

            return result
        }
    }

    private func writeU16(_ data: inout Data, _ offset: Int, _ value: UInt16) {
        if offset + 1 < data.count {
            data[offset] = UInt8((value >> 8) & 0xFF)
            data[offset + 1] = UInt8(value & 0xFF)
        }
    }

    private func writeU32(_ data: inout Data, _ offset: Int, _ value: UInt32) {
        if offset + 3 < data.count {
            data[offset] = UInt8((value >> 24) & 0xFF)
            data[offset + 1] = UInt8((value >> 16) & 0xFF)
            data[offset + 2] = UInt8((value >> 8) & 0xFF)
            data[offset + 3] = UInt8(value & 0xFF)
        }
    }

    private func calcChecksum(_ data: Data) -> UInt32 {
        let padLen = align4(data.count)
        var sum: UInt32 = 0
        var i = 0
        while i + 3 < padLen && i + 3 < data.count {
            let v = UInt32(data[i]) << 24 | UInt32(data[i + 1]) << 16 | UInt32(data[i + 2]) << 8 | UInt32(data[i + 3])
            sum = (sum &+ v) & 0xFFFFFFFF
            i += 4
        }
        return sum
    }
}
