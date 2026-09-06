import SwiftUI

struct HomeView: View {
    @ObservedObject var vm: AppViewModel
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                resultBar
                if vm.ready {
                    resultsList
                } else {
                    Spacer()
                    ProgressView("載入中…")
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $vm.sheetOpen) {
            FilterSheet(vm: vm)
        }
        .onAppear { searchFocused = false }
    }

    // MARK: 頭部

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("澳門藥物庫")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                    Text("ISAF 全庫 · \(Theme.fmt(vm.repo.total)) 種登記藥品")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Button { vm.openSheet(true) } label: {
                    Text((vm.filters.isActive ? "● " : "") + "篩選")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }

            // 搜索框
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("搜尋商品名、成分、製造商、ATC…", text: $vm.query)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .onSubmit { vm.search() }
                if !vm.query.isEmpty {
                    Button {
                        vm.clearQuery()
                        searchFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.white)
            )
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)

            if !vm.history.isEmpty && vm.query.isEmpty {
                historyRow
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .background(Theme.headerGradient.ignoresSafeArea(edges: .top))
    }

    private var historyRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("最近搜尋")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Button {
                    vm.clearHistory()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("清除")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.history, id: \.self) { h in
                        Button {
                            vm.query = h
                            vm.search()
                        } label: {
                            Text(h)
                                .font(.footnote)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(Color.white.opacity(0.14))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: 結果欄

    private var resultBar: some View {
        HStack {
            Text("\(Theme.fmt(vm.results.count)) 筆結果")
                .font(.headline)
            Spacer()
            if vm.exporting {
                Text("匯出中…")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Button { vm.exportCsv() } label: {
                    Label("匯出 CSV", systemImage: "square.and.arrow.up")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if vm.results.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("沒有符合條件的藥品")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(vm.results) { drug in
                        DrugCard(drug: drug, clsColor: Theme.clsColor(drug.cls)) {
                            vm.openDetail(drug)
                        }
                    }
                    Color.clear.frame(height: 24)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - 藥品卡片

struct DrugCard: View {
    let drug: Drug
    let clsColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(clsColor)
                        .frame(width: 10, height: 10)
                        .padding(.top, 5)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(drug.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        if !drug.ingredient.isEmpty {
                            Text(drug.ingredient)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                HStack(spacing: 6) {
                    if !drug.form.isEmpty {
                        Tag(text: drug.form,
                            bg: Color(hex: 0xCCFBF1),
                            fg: Color(hex: 0x134E4A))
                    }
                    if !drug.atcCode.isEmpty {
                        Tag(text: drug.atcCode,
                            bg: Color(hex: 0xCFFAFE),
                            fg: Color(hex: 0x164E63))
                    }
                    if !drug.manufacturer.isEmpty {
                        Text(drug.manufacturer.replacingOccurrences(of: "--", with: "").trimmingCharacters(in: .whitespaces))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.card)
            )
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct Tag: View {
    let text: String
    let bg: Color
    let fg: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundColor(fg)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(bg))
    }
}