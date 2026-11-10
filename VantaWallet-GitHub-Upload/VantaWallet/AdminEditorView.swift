import SwiftUI
import SwiftData
import LocalAuthentication

enum AdminAuth {
    static func run() async -> Bool {
        let c = LAContext()
        var e: NSError?
        guard c.canEvaluatePolicy(.deviceOwnerAuthentication, error: &e) else { return false }
        return (try? await c.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Вход в демо-редактор VANTA")) ?? false
    }
}

struct AdminEditorView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Asset.order) private var assets: [Asset]
    @State private var target = 0.0
    @State private var addOpen = false
    @State private var confirmReset = false

    private var total: Double { assets.reduce(0) { $0 + $1.value } }

    var body: some View {
        NavigationStack {
            List {
                Section { DemoBadge() }
                Section("Общий демо-баланс (USD)") {
                    TextField("Сумма", value: $target, format: .number).keyboardType(.decimalPad)
                    Button("Применить (пропорционально всем монетам)") { apply() }
                }
                Section("Токены") {
                    ForEach(assets) { a in
                        NavigationLink { EditAssetView(a: a) } label: {
                            HStack { Text(a.ticker).bold(); Spacer(); Text(a.value.formatted(.currency(code: "USD"))).foregroundStyle(.secondary) }
                        }
                    }.onDelete { idx in idx.forEach { ctx.delete(assets[$0]) }; try? ctx.save() }
                    Button("Добавить токен", systemImage: "plus") { addOpen = true }
                }
                Section { Button("Восстановить исходные данные", role: .destructive) { confirmReset = true } }
            }
            .navigationTitle("Редактор")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Готово") { dismiss() } } }
            .sheet(isPresented: $addOpen) { AddTokenView() }
            .confirmationDialog("Сбросить портфель к исходным данным?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Сбросить", role: .destructive) { Seed.reset(ctx); Haptics.tap() }
            }
            .onAppear { target = total }
        }
    }

    private func apply() {
        let cur = total
        guard target > 0, cur > 0 else { return }
        let k = target / cur
        for a in assets { a.amount *= k; ctx.insert(LogEntry(assetID: a.id, text: "Баланс масштабирован ×\(k.formatted(.number.precision(.fractionLength(3))))")) }
        try? ctx.save(); Haptics.tap()
    }
}

struct EditAssetView: View {
    let a: Asset
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var ticker: String
    @State private var amount: Double
    @State private var price: Double

    init(a: Asset) {
        self.a = a
        _name = State(initialValue: a.name); _ticker = State(initialValue: a.ticker)
        _amount = State(initialValue: a.amount); _price = State(initialValue: a.price)
    }

    var body: some View {
        Form {
            TextField("Название", text: $name)
            TextField("Тикер", text: $ticker).textInputAutocapitalization(.characters)
            LabeledContent("Количество") { TextField("0", value: $amount, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
            LabeledContent("Цена (USD)") { TextField("0", value: $price, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
            Button("Сохранить") { save() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || ticker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !amount.isFinite || !price.isFinite || amount < 0 || price < 0)
        }.navigationTitle(a.ticker)
    }

    private func save() {
        var notes: [String] = []
        if amount != a.amount { notes.append("Количество: \(a.amount.formatted()) → \(amount.formatted())") }
        if price != a.price {
            notes.append("Цена: $\(a.price.formatted()) → $\(price.formatted())")
            var h = a.history
            if !h.isEmpty { h[h.count - 1] = price; a.history = h }
        }
        a.name = name.trimmingCharacters(in: .whitespacesAndNewlines); a.ticker = ticker.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(); a.amount = amount; a.price = price
        for n in notes { ctx.insert(LogEntry(assetID: a.id, text: n)) }
        try? ctx.save(); Haptics.tap(); dismiss()
    }
}

struct AddTokenView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query private var assets: [Asset]
    @State private var name = ""
    @State private var ticker = ""
    @State private var amount = 0.0
    @State private var price = 0.0
    @State private var color = "8B5CF6"
    private let palette = ["8B5CF6", "F7931A", "627EEA", "14F195", "26A17B", "F3BA2F", "00AAE4", "E84142"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название", text: $name)
                TextField("Тикер", text: $ticker).textInputAutocapitalization(.characters)
                LabeledContent("Количество") { TextField("0", value: $amount, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                LabeledContent("Цена (USD)") { TextField("0", value: $price, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                HStack {
                    ForEach(palette, id: \.self) { c in
                        Circle().fill(Color(hex: c)).frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.primary, lineWidth: color == c ? 2 : 0))
                            .onTapGesture { color = c }
                    }
                }
            }
            .navigationTitle("Новый токен")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        let order = (assets.map(\.order).max() ?? -1) + 1
                        let t = ticker.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                        ctx.insert(Asset(name: name.trimmingCharacters(in: .whitespacesAndNewlines), ticker: t, amount: amount, price: price, colorHex: color, order: order,
                                         history: makeHistory(price: price, vol: 0.04, seed: UInt64(abs(t.hashValue % 100000)) + 1)))
                        try? ctx.save(); Haptics.tap(); dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || ticker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !amount.isFinite || !price.isFinite || amount < 0 || price < 0)
                }
            }
        }
    }
}
