import SwiftUI
import SwiftData

struct AssetRow: View {
    let a: Asset
    @AppStorage("cur") private var cur = Currency.USD
    var body: some View {
        HStack(spacing: 12) {
            CoinIcon(a: a)
            VStack(alignment: .leading, spacing: 2) {
                Text(a.name).font(.headline)
                Text("\(a.amount.formatted()) \(a.ticker) · \(cur.fmt(a.price))").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(cur.fmt(a.value)).font(.headline)
                ChangeLabel(pct: a.change(1))
            }
        }.card()
    }
}

struct HomeView: View {
    @Query(sort: \Asset.order) private var assets: [Asset]
    @AppStorage("name") private var name = "Main Portfolio"
    @AppStorage("cur") private var cur = Currency.USD
    var go: (Int) -> Void
    @State private var shown = false
    @State private var taps = 0
    @State private var showEditor = false

    private var total: Double { assets.reduce(0) { $0 + $1.value } }
    private var series: [Double] {
        (0..<30).map { i in assets.reduce(0) { $0 + $1.amount * ($1.history.indices.contains(i) ? $1.history[i] : $1.price) } }
    }
    private var day: Double { let p = series[28]; return p == 0 ? 0 : series[29] / p - 1 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        VantaLogo().onTapGesture { taps += 1; if taps >= 5 { taps = 0; openEditor() } }
                        Spacer()
                        Button { Haptics.tap(); go(2) } label: { Image(systemName: "gearshape").font(.title3).foregroundStyle(.primary) }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        DemoBadge()
                        Text(name).font(.subheadline).foregroundStyle(.secondary)
                        Text(cur.fmt(total)).font(.system(size: 40, weight: .bold, design: .rounded))
                            .contentTransition(.numericText()).minimumScaleFactor(0.5).lineLimit(1)
                        HStack(spacing: 6) { ChangeLabel(pct: day); Text("за 24 ч").font(.caption).foregroundStyle(.secondary) }
                        PriceChart(values: series).frame(height: 160).padding(.top, 6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).card()
                    .opacity(shown ? 1 : 0).offset(y: shown ? 0 : 16)

                    HStack {
                        Text("Активы").font(.title3.bold())
                        Spacer()
                        Button("Все") { Haptics.tap(); go(1) }.foregroundStyle(Color.accent)
                    }
                    ForEach(assets.prefix(6)) { a in
                        NavigationLink { AssetDetailView(a: a) } label: { AssetRow(a: a) }.buttonStyle(.plain)
                    }
                }.padding(20)
            }
            .scrollIndicators(.hidden)
            .onAppear { withAnimation(.spring(duration: 0.7)) { shown = true } }
        }
        .fullScreenCover(isPresented: $showEditor) { AdminEditorView() }
    }

    private func openEditor() {
        Task { if await AdminAuth.run() { showEditor = true } }
    }
}

struct AssetsView: View {
    @Query(sort: \Asset.order) private var assets: [Asset]
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    DemoBadge().frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(assets) { a in
                        NavigationLink { AssetDetailView(a: a) } label: { AssetRow(a: a) }.buttonStyle(.plain)
                    }
                }.padding(20)
            }
            .navigationTitle("Активы")
        }
    }
}
