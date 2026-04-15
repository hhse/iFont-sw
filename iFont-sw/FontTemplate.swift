import Foundation

struct FontTemplate: Codable, Identifiable {
    var id: String { family + subfamily }
    let family: String
    let subfamily: String
    let weightClass: UInt16
    let fsType: UInt16
    let nameB64: String
    
    var nameData: Data? {
        return Data(base64Encoded: nameB64)
    }
}

struct FontTemplateFamily {
    let family: String
    let templates: [FontTemplate]
    
    var subfamilies: [String] {
        return templates.map { $0.subfamily }
    }
}

class FontTemplates {
    static let shared = FontTemplates()
    
    private(set) var templates: [FontTemplate] = []
    private(set) var families: Set<String> = []
    
    private init() {
        loadTemplates()
    }
    
    private func loadTemplates() {
        guard let url = Bundle.main.url(forResource: "templates", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([FontTemplate].self, from: data) else {
            print("Failed to load templates")
            return
        }
        self.templates = decoded
        self.families = Set(decoded.map { $0.family })
        print("Loaded \(templates.count) templates for \(families.count) families")
    }
    
    func getTemplates() -> [FontTemplate] {
        return templates
    }
    
    func getFamilyCount() -> Int {
        return families.count
    }
}
