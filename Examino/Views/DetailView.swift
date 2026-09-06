import SwiftUI

struct DetailView: View {
    @ObservedObject var vm: AppViewModel
    let drug: Drug

    private var links: DrugLinks? { vm.repo.linksFor(drug) }
    private var origAtc: String? { vm.repo.origAtcFor(drug) }
    private var origRoute: String? { vm.repo.origRouteFor(drug) }
    private var clsColor: Color { Theme.clsColor(drug.cls) }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    // 名稱卡
                    card {
                        HStack {
                            HStack(spacing: 6) {
                                Circle().fill(clsColor).frame(width: 10, height: 10)
                                Text(Theme.clsName(drug.cls))
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(clsColor)
                            }
                            Spacer()
                            Text("編號 \(drug.id)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(drug.name)
                            .font(.title3.weight(.bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                        if !drug.ingredient.isEmpty {
                            Text(drug.ingredient)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)
                        }
                    }

                    field("劑型", drug.form)
                    field("給藥途徑", drug.route)
                    field("製造商", drug.manufacturer)
                    field("分銷商", drug.distributor)
                    field("ATC 分類", drug.atc.isEmpty ? "—" : drug.atc)

                    // 資料修正
                    if origAtc != nil || origRoute != nil {
                        card {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("資料修正").font(.subheadline.weight(.bold))
                                if let a = origAtc {
                                    Text("原 ISAF 分類: \(a)")
                                        .font(.footnote).foregroundColor(.secondary)
                                }
                                if let r = origRoute {
                                    Text("原 ISAF 途徑: \(r)")
                                        .font(.footnote).foregroundColor(.secondary)
                                }
                                Text("（本庫已修正）")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    // 外部鏈接
                    if let links {
                        card {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("藥物介紹及劑量").font(.subheadline.weight(.bold))
                                Text("來源: \(links.sourceName)")
                                    .font(.caption2).foregroundColor(.secondary)
                                HStack(spacing: 8) {
                                    linkButton("💊 介紹", url: links.infoUrl)
                                    linkButton("📏 劑量", url: links.dosageUrl)
                                }
                                if let alt = links.altUrl {
                                    linkButton("🔍 補充來源", url: alt)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Text("資料來源: 澳門藥物監督管理局（ISAF）登記藥品資料庫。本應用為非官方離線查詢工具，用藥請以官方登記資料及醫囑為準。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                }
                .padding(16)
                .padding(.top, 64) // 給頂欄留位
            }
        }
        .overlay(alignment: .top) {
            topBar
        }
    }

    private var topBar: some View {
        HStack(spacing: 4) {
            Button { vm.closeDetail() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Text("藥品詳情")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Theme.headerGradient.ignoresSafeArea(edges: .top))
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white)
            )
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private func field(_ label: String, _ value: String) -> some View {
        guard !value.trimmingCharacters(in: .whitespaces).isEmpty else {
            return AnyView(EmptyView())
        }
        return AnyView(
            card {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        )
    }

    private func linkButton(_ title: String, url: String) -> some View {
        Button {
            if let u = URL(string: url) {
                UIApplication.shared.open(u)
            }
        } label: {
            Text(title)
                .font(.footnote.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: 0xE0F2FE))
                )
        }
        .buttonStyle(.plain)
    }
}