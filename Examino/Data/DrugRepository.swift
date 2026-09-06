import Foundation
import UIKit

/// 數據倉庫:載入內嵌 JSON,提供搜尋/ATC 樹/CSV/外部鏈接
final class DrugRepository {

    static let clsOrder: [(code: String, label: String)] = [
        ("PMO", "處方藥物"),
        ("OTC", "非處方"),
        ("UH", "醫院專用"),
        ("VET", "獸醫用藥"),
        ("?", "未分類"),
    ]

    private var all: [Drug] = []
    private var blobs: [String] = []
    private var atcNames: [String: String] = [:]
    private var l2Names: [String: String] = [:]
    private var links: [String: [String]] = [:]
    private var origAtc: [String: String] = [:]
    private var origRoute: [String: String] = [:]
    private var forms: [String] = []

    private(set) var loaded = false

    var total: Int { all.count }

    /// 主執行緒外的使用者佇列中呼叫
    func load() {
        guard !loaded else { return }
        do {
            let rows = try decodeRows("drugs")
            all = rows.map { r in
                Drug(
                    id: r.get(0), name: r.get(1), form: r.get(2), route: r.get(3),
                    ingredient: r.get(4), manufacturer: r.get(5), distributor: r.get(6),
                    atc: r.get(7), atcL1: r.get(8), cls: r.get(9)
                )
            }
            blobs = all.map { $0.searchBlob() }
            atcNames = try decodeStrMap("atc_names")
            l2Names = try decodeStrMap("l2_names")
            links = try decodeStrListMap("links")
            origAtc = try decodeStrMap("orig_atc")
            origRoute = try decodeStrMap("orig_route")
            forms = try decodeStrList("forms")
            loaded = true
        } catch {
            NSLog("Examino load error: %@", error.localizedDescription)
        }
    }

    // MARK: - 搜尋

    /// 多詞搜尋:空格分隔,每個詞都須為 blob 子串(天然支援前綴,如 amox → amoxicillin)
    func search(query: String, filters: Filters) -> [Drug] {
        guard loaded else { return [] }
        let tokens = query.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        var out: [Drug] = []
        out.reserveCapacity(300)
        for (i, d) in all.enumerated() {
            if let l1 = filters.l1, (d.atcL1.isEmpty ? "?" : d.atcL1) != l1 { continue }
            if let l2 = filters.l2, d.atcL2 != l2 { continue }
            if let l3 = filters.l3, d.atcCode != l3 { continue }
            if let form = filters.form, d.form != form { continue }
            if let cls = filters.cls, d.cls != cls { continue }
            if !tokens.isEmpty {
                let b = blobs[i]
                var ok = true
                for t in tokens where !b.contains(t) { ok = false; break }
                if !ok { continue }
            }
            out.append(d)
        }
        return out
    }

    // MARK: - ATC 樹

    func atcTree() -> [AtcLevel] {
        var byL1: [String: [Drug]] = [:]
        for d in all {
            let key = d.atcL1.isEmpty ? "?" : d.atcL1
            byL1[key, default: []].append(d)
        }
        return byL1.keys.sorted().map { l1 -> AtcLevel in
            let drugs = byL1[l1] ?? []
            // L2 分組
            var byL2: [String: [Drug]] = [:]
            for d in drugs {
                let key = d.atcL2.isEmpty ? l1 : d.atcL2
                byL2[key, default: []].append(d)
            }
            let l2s = byL2.keys.sorted().map { l2c -> AtcLevel in
                let ds = byL2[l2c] ?? []
                var byL3: [String: [Drug]] = [:]
                for d in ds {
                    let key = d.atcCode.isEmpty ? l2c : d.atcCode
                    byL3[key, default: []].append(d)
                }
                let l3s = byL3.keys.sorted().map { l3c -> AtcLevel in
                    AtcLevel(code: l3c, name: (byL3[l3c]?.first?.atcName ?? "").isEmpty ? l3c : byL3[l3c]!.first!.atcName, count: byL3[l3c]?.count ?? 0)
                }
                return AtcLevel(code: l2c, name: l2Name(l2c, ds: ds), count: ds.count, children: l3s)
            }
            let name = atcNames[l1] ?? l1
            return AtcLevel(code: l1, name: name, count: drugs.count, children: l2s)
        }
    }

    /// 二級名稱:標準表 → 獸藥去 Q 對照 → 組內最多記錄的三級名
    private func l2Name(_ code: String, ds: [Drug]) -> String {
        if let n = l2Names[code] { return n }
        if code.hasPrefix("Q"), let n = l2Names[String(code.dropFirst())] { return n }
        var counts: [String: Int] = [:]
        for d in ds where !d.atcName.isEmpty {
            counts[d.atcName, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? code
    }

    func releaseForms() -> [String] { forms }

    // MARK: - 外部鏈接

    func linksFor(_ d: Drug) -> DrugLinks? {
        guard let l = links[d.id], l.count >= 5 else { return nil }
        let q = l[0], it = l[1], ir = l[2], dt = l[3], dr = l[4]
        let info = buildLink(q: q, kind: it, path: ir)
        let dose = buildLink(q: q, kind: dt, path: dr)
        let infoHost: String = host(kind: it)
        let doseHost: String = host(kind: dt)
        let sn: String
        if it == "o" || dt == "o" { sn = "OpenDrug 台灣藥品" }
        else if it == "m" || dt == "m" { sn = "Medscape" }
        else { sn = "Drugs.com" }
        var alt: String?
        if infoHost != doseHost, info != dose { alt = dose }
        return DrugLinks(q: q, infoUrl: info, dosageUrl: dose, sourceName: sn, altUrl: alt)
    }

    private func host(kind: String) -> String {
        switch kind {
        case "o": return "opendrug"
        case "m": return "medscape"
        case "p", "d": return "drugs"
        default: return ""
        }
    }

    private func buildLink(q: String, kind: String, path: String) -> String {
        func enc(_ s: String) -> String {
            s.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? s
        }
        func odUrl(_ p: String) -> String {
            let parts = p.split(separator: "/").map(String.init)
            let tail = parts.dropFirst().joined(separator: "/")
            return "https://www.opendrug.com.tw/\(parts.first ?? "")/\(enc(tail))"
        }
        switch kind {
        case "d": return "https://www.drugs.com/\(q).html"
        case "p": return "https://www.drugs.com\(path)"
        case "o": return odUrl(path)
        case "m": return "https://search.medscape.com/search/?q=\(enc(q))"
        default:  return "https://www.drugs.com/search.php?searchterm=\(enc(q))"
        }
    }

    func origAtcFor(_ d: Drug) -> String? { origAtc[d.id] }
    func origRouteFor(_ d: Drug) -> String? { origRoute[d.id] }

    // MARK: - CSV

    /// BOM + 逗號分隔,Excel 直接開啟
    func toCsv(_ drugs: [Drug]) -> String {
        var out = "\u{FEFF}編號,商品名,劑型,給藥途徑,成分,製造商,分銷商,ATC,分類\n"
        for d in drugs {
            let fields = [d.id, d.name, d.form, d.route, d.ingredient, d.manufacturer, d.distributor, d.atc, d.cls]
            let line = fields
                .map { $0.replacingOccurrences(of: ",", with: "，").replacingOccurrences(of: "\"", with: "'") }
                .joined(separator: ",")
            out += line + "\n"
        }
        return out
    }

    // MARK: - 解碼

    private func bundleURL(_ name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "json")
    }

    private func decodeRows(_ name: String) throws -> [[String]] {
        guard let url = bundleURL(name) else { throw NSError(domain: "Examino", code: 1) }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([[String]].self, from: data)
    }

    private func decodeStrMap(_ name: String) throws -> [String: String] {
        guard let url = bundleURL(name) else { throw NSError(domain: "Examino", code: 1) }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([String: String].self, from: data)
    }

    private func decodeStrListMap(_ name: String) throws -> [String: [String]] {
        guard let url = bundleURL(name) else { throw NSError(domain: "Examino", code: 1) }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([String: [String]].self, from: data)
    }

    private func decodeStrList(_ name: String) throws -> [String] {
        guard let url = bundleURL(name) else { throw NSError(domain: "Examino", code: 1) }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([String].self, from: data)
    }
}

private extension Array where Element == String {
    func get(_ i: Int) -> String {
        indices.contains(i) ? self[i] : ""
    }
}