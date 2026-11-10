import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var ctx
    @AppStorage("name") private var name = "Main Portfolio"
    @AppStorage("cur") private var cur = Currency.USD
    @AppStorage("dark") private var dark = true
    @State private var confirm = false

    var body: some View {
        NavigationStack {
            List {
                Section("Портфель") { TextField("Название портфеля", text: $name) }
                Section("Отображение") {
                    Picker("Валюта", selection: $cur) { ForEach(Currency.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                        .pickerStyle(.segmented)
                    Toggle("Тёмная тема", isOn: $dark)
                }
                Section("О приложении") {
                    LabeledContent("Версия", value: "1.0")
                    Text("VANTA WALLET — демонстрационное приложение. Все балансы, цены и графики вымышленные. Реальные средства не хранятся, транзакции не выполняются. Курсы валют — условные.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section { Button("Сбросить демо-данные", role: .destructive) { confirm = true } }
            }
            .scrollContentBackground(.hidden).background(Color.bg)
            .navigationTitle("Настройки")
            .confirmationDialog("Сбросить портфель к исходным данным?", isPresented: $confirm, titleVisibility: .visible) {
                Button("Сбросить", role: .destructive) { Seed.reset(ctx); Haptics.tap() }
            }
        }
    }
}
