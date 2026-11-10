import SwiftUI
import SwiftData

@main
struct VantaWalletApp: App {
    @AppStorage("dark") private var dark = true
    let container: ModelContainer = {
        do { return try ModelContainer(for: Asset.self, LogEntry.self) }
        catch { fatalError("SwiftData: \(error)") }
    }()
    var body: some Scene {
        WindowGroup { RootView().preferredColorScheme(dark ? .dark : .light) }
            .modelContainer(container)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var ctx
    @AppStorage("seeded") private var seeded = false
    @State private var tab = 0
    @Namespace private var ns

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            Group {
                switch tab {
                case 0: HomeView(go: { tab = $0 })
                case 1: AssetsView()
                default: SettingsView()
                }
            }
            .id(tab)
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
        }
        .animation(.spring(duration: 0.4), value: tab)
        .safeAreaInset(edge: .bottom) { tabBar }
        .task { if !seeded { Seed.populate(ctx); seeded = true } }
    }

    private var tabBar: some View {
        HStack {
            ForEach(Array(["house.fill", "square.grid.2x2.fill", "gearshape.fill"].enumerated()), id: \.offset) { i, icon in
                Button { Haptics.tap(); tab = i } label: {
                    Image(systemName: icon).font(.title3)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .foregroundStyle(tab == i ? Color.accent : Color.secondary)
                        .background {
                            if tab == i { Capsule().fill(Color.accent.opacity(0.18)).matchedGeometryEffect(id: "pill", in: ns) }
                        }
                }
            }
        }
        .padding(6).background(.ultraThinMaterial, in: Capsule())
        .padding(.horizontal, 24).padding(.bottom, 4)
    }
}
