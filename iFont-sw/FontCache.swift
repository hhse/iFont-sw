import SwiftUI
import UIKit

// MARK: - Font Cache (字体缓存)

class FontCache {
    static let shared = FontCache()
    private let cache = NSCache<NSData, NSString>()

    private init() {}

    func font(from data: Data, size: CGFloat) -> Font? {
        let dataObj = data as NSData
        if let fontName = cache.object(forKey: dataObj) {
            return .custom(fontName as String, size: size)
        }

        guard let provider = CGDataProvider(data: data as CFData),
              let cgFont = CGFont(provider),
              let postScriptName = cgFont.postScriptName as String? else {
            return nil
        }

        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterGraphicsFont(cgFont, &error)
        if success {
            cache.setObject(postScriptName as NSString, forKey: dataObj)
            return .custom(postScriptName, size: size)
        } else {
            return .custom(postScriptName, size: size)
        }
    }
}