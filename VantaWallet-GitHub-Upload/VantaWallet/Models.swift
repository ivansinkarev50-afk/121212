import SwiftData
import Foundation

@Model final class Asset {
    var id = UUID()
    var name: String
    var ticker: String
    var amount: Double
    var price: Double
    var colorHex: String
    var order: Int
    var history: [Double]
    init(name: String, ticker: String, amount: Double, price: Double, colorHex: String, order: Int, history: [Double]) {
        self.name = name; self.ticker = ticker; self.amount = amount; self.price = price
        self.colorHex = colorHex; self.order = order; self.history = history
    }
    var value: Double { amount * price }
    func change(_ days: Int) -> Double {
        guard let last = history.last, !history.isEmpty else { return 0 }
        let base = history[max(0, history.count - 1 - days)]
        return base == 0 ? 0 : last / base - 1
    }
}

@Model final class LogEntry {
    var assetID: UUID
    var date: Date
    var text: String
    init(assetID: UUID, text: String) { self.assetID = assetID; self.date = .now; self.text = text }
}

enum Currency: String, CaseIterable {
    case USD, EUR, UAH
    var rate: Double { switch self { case .USD: 1; case .EUR: 0.92; case .UAH: 41.5 } }
    func fmt(_ usd: Double) -> String { (usd * rate).formatted(.currency(code: rawValue)) }
}

struct SeededRNG: RandomNumberGenerator {
    var s: UInt64
    mutating func next() -> UInt64 {
        s &+= 0x9E3779B97F4A7C15
        var z = s
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

func makeHistory(price: Double, vol: Double, seed: UInt64) -> [Double] {
    var g = SeededRNG(s: seed)
    var a = [price]
    for _ in 0..<29 { a.append(a[a.count - 1] / (1 + Double.random(in: -vol...vol, using: &g))) }
    return Array(a.reversed())
}

enum Seed {
    static let items: [(String, String, Double, Double, String, Double)] = [
        ("Bitcoin", "BTC", 0.42, 67000, "F7931A", 0.03), ("Ethereum", "ETH", 3.5, 3200, "627EEA", 0.035),
        ("Solana", "SOL", 40, 150, "14F195", 0.05), ("Tether", "USDT", 2500, 1, "26A17B", 0.0008),
        ("BNB", "BNB", 6, 580, "F3BA2F", 0.03), ("XRP", "XRP", 3000, 0.52, "8A9BB0", 0.04),
        ("Toncoin", "TON", 400, 6.2, "0098EA", 0.045), ("Dogecoin", "DOGE", 12000, 0.15, "C2A633", 0.06),
        ("Litecoin", "LTC", 20, 85, "345D9D", 0.035), ("USD Coin", "USDC", 1800, 1, "2775CA", 0.0008),
        ("TRON", "TRX", 15000, 0.12, "E84142", 0.03), ("Cardano", "ADA", 5000, 0.45, "3468D1", 0.045)
    ]
    @MainActor static func populate(_ ctx: ModelContext) {
        for (i, t) in items.enumerated() {
            ctx.insert(Asset(name: t.0, ticker: t.1, amount: t.2, price: t.3, colorHex: t.4, order: i,
                             history: makeHistory(price: t.3, vol: t.5, seed: UInt64(i + 1) * 7919)))
        }
        try? ctx.save()
    }
    @MainActor static func reset(_ ctx: ModelContext) {
        try? ctx.delete(model: Asset.self)
        try? ctx.delete(model: LogEntry.self)
        populate(ctx)
    }
}
