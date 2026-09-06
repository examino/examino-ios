import SwiftUI

@main
struct ExaminoApp: App {
    @StateObject private var vm = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView(vm: vm)
        }
    }
}

struct RootView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        ZStack {
            if let detail = vm.detail {
                DetailView(vm: vm, drug: detail)
                    .transition(.opacity)
            } else {
                HomeView(vm: vm)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: vm.detail != nil)
        .sheet(item: $vm.shareURL) { url in
            ActivityView(items: [url])
        }
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}

/// 系統分享面板(UIActivityViewController 橋接)
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}