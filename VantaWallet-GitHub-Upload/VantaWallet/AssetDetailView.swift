import SwiftUI
import SwiftData

struct AssetDetailView: View {
    let a: Asset
    @Query private var logs: [LogEntry]
    @AppStorage("cur") private var cur = Currency.USD
    @State private var days = 7

    init(a: Asset) {
        self.a = a
        let id = a.id
        _logs = Query(filter: #Predicate<LogEntry> { $0.assetID == id }, sort: \LogEntry.date, order: .reverse)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    CoinIcon(a: a).scaleEffect(1.25).padding(.trailing, 4)
                    VStack(alignment: .leading) { Text(a.name).font(.title2.bold()); Text(a.ticker).foregroundStyle(.secondary) }
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 8) {
                    DemoBadge()
                    Text(cur.fmt(a.price)).font(.system(size: 36, weight: .bold, design: .rounded))
                    HStack {
                        Text("Количество: \(a.amount.formatted()) \(a.ticker)")
                        Spacer()
                        Text(cur.fmt(a.value)).bold()
                    }.font(.subheadline).foregroundStyle(.secondary)
                    Picker("Период", selection: $days) { Text("7 дней").tag(7); Text("30 дней").tag(29) }.pickerStyle(.segmented)
                    PriceChart(values: Array(a.history.suffix(days + 1))).id(days).frame(height: 180)
                }.card()

                HStack(spacing: 10) {
                    stat("День", a.change(1)); stat("Неделя", a.change(7)); stat("Месяц", a.change(29))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("История демонстрационных изменений").font(.headline)
                    if logs.isEmpty { Text("Изменений из редактора пока нет").font(.caption).foregroundStyle(.secondary) }
                    ForEach(logs) { l in
                        VStack(alignment: .leading) {
                            Text(l.text).font(.subheadline)
                            Text(l.date.formatted(date: .abbreviated, time: .shortened)).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    if a.history.count >= 8 {
                        Divider()
                        Text("Дневная динамика (демо)").font(.subheadline.weight(.semibold))
                        ForEach(1..<8, id: \.self) { k in
                            let i = a.history.count - k
                            HStack {
                                Text((Calendar.current.date(byAdding: .day, value: -(k - 1), to: .now) ?? .now)
                                    .formatted(date: .abbreviated, time: .omitted)).font(.caption)
                                Spacer()
                                Text(cur.fmt(a.history[i])).font(.caption)
                                ChangeLabel(pct: a.history[i - 1] == 0 ? 0 : a.history[i] / a.history[i - 1] - 1)
                            }
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).card()
            }.padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { Haptics.tap() }
    }

    private func stat(_ t: String, _ v: Double) -> some View {
        VStack(spacing: 6) { Text(t).font(.caption).foregroundStyle(.secondary); ChangeLabel(pct: v) }
            .frame(maxWidth: .infinity).card()
    }
}
