import Foundation

/// 單筆登記藥品 (對應原站 DATA 行)
struct Drug: Identifiable, Hashable {
    let id: String          // 註冊編號
    let name: String        // 商品名
    let form: String        // 劑型
    let route: String       // 給藥途徑
    let ingredient: String  // 成分
    let manufacturer: String// 製造商
    let distributor: String // 分銷商/註冊證持有人
    let atc: String         // ATC 代碼 + 名稱, e.g. "J01M  喹諾酮類抗菌藥"
    let atcL1: String       // ATC 一級字母
    let cls: String         // 法律分類 PMO/OTC/UH/VET/?

    /// 三級/細類代碼(完整 token)
    var atcCode: String {
        atc.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines).first ?? ""
    }
    /// 三級名稱
    var atcName: String {
        let t = atc.trimmingCharacters(in: .whitespacesAndNewlines)
        if atcCode.isEmpty { return t }
        return t.dropFirst(atcCode.count).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    /// 二級代碼(與原站 atcL2 一致)
    var atcL2: String {
        let c = atcCode
        if c.count >= 4 && c.hasPrefix("Q") { return String(c.prefix(4)) }
        if c.count >= 3 { return String(c.prefix(3)) }
        return c
    }

    /// 搜尋用全文(小寫);多詞匹配時每個詞都須為其子串
    func searchBlob() -> String {
        [id, name, form, route, ingredient, manufacturer, distributor, atc, cls]
            .joined(separator: " ").lowercased()
    }
}

/// 篩選條件
struct Filters: Equatable {
    var l1: String?
    var l2: String?
    var l3: String?
    var form: String?
    var cls: String?

    var isActive: Bool { l1 != nil || l2 != nil || l3 != nil || form != nil || cls != nil }
}

/// ATC 樹結點(層級 = 一/二/三級)
struct AtcLevel: Identifiable, Hashable {
    var id: String { code }
    let code: String
    let name: String
    let count: Int
    var children: [AtcLevel] = []
}

/// 外部藥物資訊鏈接(對應原站 DRUG_LINKS)
struct DrugLinks {
    let q: String
    let infoUrl: String
    let dosageUrl: String
    let sourceName: String
    let altUrl: String?
}