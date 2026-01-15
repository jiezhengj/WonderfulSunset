import Foundation

class LocalizationHelper {
    
    static let shared = LocalizationHelper()
    
    private init() {}
    
    func localizedString(for key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
    func getCurrentLanguage() -> String {
        return Locale.current.language.languageCode?.identifier ?? "en"
    }
    
    func getLanguageName(for code: String) -> String {
        let locale = Locale(identifier: code)
        return locale.localizedString(forLanguageCode: code) ?? code
    }
    
    func getSupportedLanguages() -> [String] {
        return ["en", "zh-Hans", "ja", "es", "fr"]
    }
}

// Extension for String to easily access localized strings
extension String {
    var localized: String {
        return LocalizationHelper.shared.localizedString(for: self)
    }
}