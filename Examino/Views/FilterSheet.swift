import SwiftUI

/// 篩選彈窗:固定高度 560,一/二/三級下拉始終顯示(未選上級時禁用),高度不變不跳動
struct FilterSheet: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var l1: String?
    @State private var l2: String?
    @State private var l3: String?
    @State private var form: String?
    @State private var cls: String?

    private let tree: [AtcLevel]
    private let forms: [String]

    init(vm: AppViewModel) {
        self.vm = vm
        _l1 = State(initialValue: vm.filters.l1)
        _l2 = State(initialValue: vm.filters.l2)
        _l3 = State(initialValue: vm.filters.l3)
        _form = State(initialValue: vm.filters.form)
        _cls = State(initialValue: vm.filters.cls)
        tree = vm.repo.atcTree()
        forms = vm.repo.releaseForms()
    }

    private var l1Sel: AtcLevel? { tree.first { $0.code == l1 } }
    private var l2s: [AtcLevel] { l1Sel?.children ?? [] }
    private var l2Sel: AtcLevel? { l2s.first { $0.code == l2 } }
    private var l3s: [AtcLevel] { l2Sel?.children ?? [] }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 法律分類
                    Text("法律分類").font(.subheadline.weight(.semibold))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)],
                              alignment: .leading, spacing: 8) {
                        chip("全部", selected: cls == nil) { cls = nil }
                        ForEach(DrugRepository.clsOrder, id: \.code) { c in
                            chip(c.label, selected: cls == c.code) {
                                cls = (cls == c.code) ? nil : c.code
                            }
                        }
                    }

                    // ATC 分類
                    Text("ATC 分類").font(.subheadline.weight(.semibold))
                    dropDown(label: "一級",
                             options: tree.map { ($0.name, $0.code) },
                             selection: $l1,
                             enabled: true,
                             onSelect: { l2 = nil; l3 = nil })
                    dropDown(label: "二級",
                             options: l2s.map { ("\($0.code) \($0.name)", $0.code) },
                             selection: $l2,
                             enabled: l1 != nil,
                             onSelect: { l3 = nil })
                    dropDown(label: "三級",
                             options: l3s.map { ("\($0.code) \($0.name)", $0.code) },
                             selection: $l3,
                             enabled: l2 != nil,
                             onSelect: {})

                    // 劑型
                    Text("劑型").font(.subheadline.weight(.semibold))
                    dropDown(label: "劑型",
                             options: forms.map { ($0, $0) },
                             selection: $form,
                             enabled: true,
                             onSelect: {})

                    // 套用
                    Button {
                        vm.setFilters(Filters(l1: l1, l2: l2, l3: l3, form: form, cls: cls))
                        dismiss()
                    } label: {
                        Text("套用篩選")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(20)
            }
            .navigationTitle("篩選")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("重置") {
                        l1 = nil; l2 = nil; l3 = nil; form = nil; cls = nil
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("關閉") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(560)])
        .presentationDragIndicator(.visible)
    }

    private func chip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.footnote.weight(.medium))
                .foregroundColor(selected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(selected ? Theme.primary : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(selected ? Color.clear : Color(.systemGray3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func dropDown(
        label: String,
        options: [(label: String, value: String)],
        selection: Binding<String?>,
        enabled: Bool,
        onSelect: @escaping () -> Void
    ) -> some View {
        let current = options.first { $0.value == selection.wrappedValue }?.label ?? "\(label)(全部)"
        return Menu {
            Button("全部") {
                selection.wrappedValue = nil
                onSelect()
            }
            ForEach(options, id: \.value) { opt in
                Button(opt.label) {
                    selection.wrappedValue = opt.value
                    onSelect()
                }
            }
        } label: {
            HStack {
                Text(current)
                    .font(.subheadline)
                    .foregroundColor(enabled ? .primary : Color(.systemGray2))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundColor(enabled ? .secondary : Color(.systemGray3))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(enabled ? Color(.systemGray3) : Color(.systemGray4), lineWidth: 1)
            )
        }
        .disabled(!enabled)
    }
}