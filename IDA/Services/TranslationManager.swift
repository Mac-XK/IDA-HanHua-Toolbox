import Foundation
import SwiftUI
import Combine

struct TranslationItem: Identifiable, Equatable {
    let id = UUID()
    let original: String
    let translated: String

    var isCustom: Bool {
        true
    }
}

@MainActor
class TranslationManager: ObservableObject {
    @Published var translations: [String: String] = [:]
    @Published var searchText = ""
    @Published var isLoading = false

    var filteredTranslations: [(key: String, value: String)] {
        let all = translations.sorted(by: { $0.key < $1.key })
        if searchText.isEmpty {
            return all
        }
        let lower = searchText.lowercased()
        return all.filter {
            $0.key.lowercased().contains(lower) ||
            $0.value.lowercased().contains(lower)
        }
    }

    var totalCount: Int {
        translations.count
    }

    var translatedCount: Int {
        translations.filter { $0.key != $0.value }.count
    }

    var customCount: Int {
        UserDefaults.standard.dictionary(forKey: "CustomTranslations")?.count ?? 0
    }

    private var builtInTranslations: [String: String] {
        IDABundle.translations
    }

    private var customTranslationsURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = appSupport.appendingPathComponent("IDA汉化工具箱")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("custom_translations.json")
    }

    init() {
        loadTranslations()
    }

    func loadTranslations() {
        isLoading = true

        var merged = builtInTranslations

        if let url = customTranslationsURL,
           let data = try? Data(contentsOf: url),
           let custom = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            for (key, value) in custom {
                merged[key] = value
            }
        }

        translations = merged
        isLoading = false
    }

    func addTranslation(original: String, translated: String) -> Bool {
        guard !original.isEmpty else { return false }


        var custom = loadCustomTranslations()
        custom[original] = translated
        saveCustomTranslations(custom)


        translations[original] = translated

        return true
    }

    func deleteTranslation(original: String) {

        var custom = loadCustomTranslations()
        custom.removeValue(forKey: original)
        saveCustomTranslations(custom)


        loadTranslations()
    }

    func updateTranslation(original: String, newTranslated: String) -> Bool {
        return addTranslation(original: original, translated: newTranslated)
    }

    private func loadCustomTranslations() -> [String: String] {
        guard let url = customTranslationsURL,
              let data = try? Data(contentsOf: url),
              let custom = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return [:]
        }
        return custom
    }

    private func saveCustomTranslations(_ custom: [String: String]) {
        guard let url = customTranslationsURL else { return }
        do {
            let data = try JSONSerialization.data(withJSONObject: custom, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: url)
        } catch {
            print("保存自定义翻译失败: \(error)")
        }
    }

    func isCustomTranslation(_ key: String) -> Bool {
        let custom = loadCustomTranslations()
        return custom[key] != nil
    }

    func exportCustomTranslations(to url: URL) -> Bool {
        let custom = loadCustomTranslations()
        do {
            let data = try JSONSerialization.data(withJSONObject: custom, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: url)
            return true
        } catch {
            print("导出失败: \(error)")
            return false
        }
    }

    func importCustomTranslations(from url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            guard let imported = try JSONSerialization.jsonObject(with: data) as? [String: String] else {
                return false
            }

            var custom = loadCustomTranslations()
            for (key, value) in imported {
                custom[key] = value
            }
            saveCustomTranslations(custom)
            loadTranslations()
            return true
        } catch {
            print("导入失败: \(error)")
            return false
        }
    }
}
