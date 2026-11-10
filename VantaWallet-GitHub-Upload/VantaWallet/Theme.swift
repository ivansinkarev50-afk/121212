import SwiftUI
import Charts
import UIKit

extension Color {
    init(hex: String) {
        var v: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&v)
        self.init(red: Double((v >> 16) & 255) / 255, green: Double((v >> 8) & 255) / 255, blue: Double(v & 255) / 255)
    }
    static let accent = Color(hex: "8B5CF6")
    static let bg = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 9.0/255.0, green: 9.0/255.0, blue: 13.0/255.0, alpha: 1)
        : UIColor(red: 0.96, green: 0.95, blue: 0.98, alpha: 1) })
}

enum Haptics { @MainActor static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() } }

struct Card: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(16)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.primary.opacity(0.08)))
    }
}
extension View { func card() -> some View { modifier(Card()) } }

struct VantaLogo: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [Color.accent, Color(hex: "4C1D95")], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("V").font(.system(size: 20, weight: .black, design: .rounded)).foregroundStyle(.white)
            }.frame(width: 36, height: 36)
            Text("VANTA").font(.system(size: 18, weight: .heavy)).tracking(3)
        }
    }
}

struct DemoBadge: View {
    var body: some View {
        Label("DEMO · не реальные средства", systemImage: "exclamationmark.shield")
            .font(.caption2.weight(.bold)).foregroundStyle(Color.accent)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Color.accent.opacity(0.15), in: Capsule())
    }
}

struct ChangeLabel: View {
    let pct: Double
    var body: some View {
        Label(String(format: "%+.2f%%", pct * 100), systemImage: pct >= 0 ? "arrow.up.right" : "arrow.down.right")
            .font(.caption.weight(.semibold)).foregroundStyle(pct >= 0 ? Color.green : Color.red)
    }
}

struct CoinIcon: View {
    let a: Asset
    var body: some View {
        Circle().fill(LinearGradient(colors: [Color(hex: a.colorHex), Color(hex: a.colorHex).opacity(0.5)], startPoint: .top, endPoint: .bottom))
            .frame(width: 42, height: 42)
            .overlay(Text(String(a.ticker.prefix(3))).font(.system(size: 12, weight: .heavy)).foregroundStyle(.white))
    }
}

struct PriceChart: View {
    let values: [Double]
    @State private var reveal = 0.0
    var body: some View {
        let lo = values.min() ?? 0
        let hi = max(values.max() ?? 1, lo + 0.0001)
        Chart {
            ForEach(Array(values.enumerated()), id: \.offset) { i, v in
                LineMark(x: .value("t", i), y: .value("v", v)).interpolationMethod(.catmullRom).foregroundStyle(Color.accent)
                AreaMark(x: .value("t", i), y: .value("v", v)).interpolationMethod(.catmullRom)
                    .foregroundStyle(LinearGradient(colors: [Color.accent.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom))
            }
        }
        .chartXAxis(.hidden).chartYAxis(.hidden).chartYScale(domain: lo...hi)
        .mask { Rectangle().scaleEffect(x: reveal, y: 1, anchor: .leading) }
        .onAppear { withAnimation(.easeOut(duration: 1)) { reveal = 1 } }
    }
}
