import Foundation
import Combine
import SwiftUI

/// 應用狀態:即時搜尋(250ms 防抖) + 歷史自動記錄(1.2s 防抖)
/// 注意:所有 @Published 更新都發生在主執行緒(Combine sink / DispatchQueue.main)
final class AppViewModel: ObservableObject {

    @Published var ready = false
    @Published var query = ""
    @Published var filters = Filters()
    @Published var results: [Drug] = []
    @Published var history: [String] = []
    @Published var sheetOpen = false
    @Published var detail: Drug?
    @Published var exporting = false
    @Published var shareURL: URL?

    let repo = DrugRepository()
    private var cancellables = Set<AnyCancellable>()

    init() {
        history = loadHistory()

        // 載入資料(後台)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            self.repo.load()
            Task { @MainActor in
                self.ready = true
                self.runSearch()
            }
        }

        // 輸入即搜:250ms 防抖更新結果
        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.runSearch() }
            .store(in: &cancellables)

        // 搜索歷史:1.2s 防抖後自動記錄
        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(1200), scheduler: DispatchQueue.main)
            .sink { [weak self] q in self?.recordHistory(q) }
            .store(in: &cancellables)
    }

    // MARK: - 動作

    func search() { runSearch() }

    func setFilters(_ f: Filters) {
        filters = f
        sheetOpen = false
        runSearch()
    }

    func clearFilters() {
        filters = Filters()
        sheetOpen = false
        runSearch()
    }

    func clearQuery() {
        query = ""
        runSearch()
    }

    func openSheet(_ open: Bool) { sheetOpen = open }
    func openDetail(_ d: Drug) { detail = d }
    func closeDetail() { detail = nil }

    func clearHistory() {
        history = []
        saveHistory([])
    }

    /// 導出當前結果為 CSV 並彈出系統分享
    func exportCsv() {
        let drugs = results
        guard !drugs.isEmpty else { return }
        exporting = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let csv = self.repo.toCsv(drugs)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("isaf-\(drugs.count)-條.csv")
            do {
                try csv.write(to: url, atomically: true, encoding: .utf8)
                Task { @MainActor in
                    self.shareURL = url
                    self.exporting = false
                }
            } catch {
                NSLog("Examino export error: %@", error.localizedDescription)
                Task { @MainActor in self.exporting = false }
            }
        }
    }

    // MARK: - 內部

    private func runSearch() {
        let q = query
        let f = filters
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let r = self.repo.search(query: q, filters: f)
            Task { @MainActor in
                // 防止舊查詢覆蓋新輸入
                if self.query == q { self.results = r }
            }
        }
    }

    private func recordHistory(_ q: String) {
        let q = q.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        if history.first == q { return }
        history = ([q] + history).prefix(12).map { $0 }
        saveHistory(history)
    }

    private func loadHistory() -> [String] {
        UserDefaults.standard.stringArray(forKey: "history") ?? []
    }

    private func saveHistory(_ h: [String]) {
        UserDefaults.standard.set(h, forKey: "history")
    }
}