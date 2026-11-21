import WidgetKit
import SwiftUI

struct MasareefWidgetEntry: TimelineEntry {
    let date: Date
    let monthLabel: String
    let totalSpent: Double
    let monthlyBudget: Double
    let remaining: Double
    let percentUsed: Int
    let currency: String
    let decimals: Int
    let privacy: Bool
    let activeListName: String
    let uncheckedCount: Int
    let topItems: [String]
}

struct MasareefWidgetProvider: TimelineProvider {
    static let appGroupId = "group.com.alhawari.masareef"
    static let snapshotKey = "masareef_widget_snapshot_v1"

    func placeholder(in context: Context) -> MasareefWidgetEntry {
        MasareefWidgetEntry(
            date: Date(), monthLabel: "نوفمبر 2026", totalSpent: 0.0, monthlyBudget: 500.0,
            remaining: 500.0, percentUsed: 0, currency: "OMR", decimals: 3, privacy: false,
            activeListName: "السوبرماركت", uncheckedCount: 2,
            topItems: ["حليب طازج / Fresh Milk", "خبز أسمر / Brown Bread"]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MasareefWidgetEntry) -> Void) {
        completion(loadFromAppGroup())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MasareefWidgetEntry>) -> Void) {
        let entry = loadFromAppGroup()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadFromAppGroup() -> MasareefWidgetEntry {
        let defaults = UserDefaults(suiteName: Self.appGroupId)
        guard let rawJson = defaults?.string(forKey: Self.snapshotKey),
              let data = rawJson.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return placeholder(in: TimelineProviderContext(family: .systemSmall, displaySize: .zero))
        }
        let topRaw = obj["topChecklistItems"] as? [[String: Any]] ?? []
        let topNames = topRaw.compactMap { $0["name"] as? String }
        return MasareefWidgetEntry(
            date: Date(),
            monthLabel: obj["monthLabel"] as? String ?? "",
            totalSpent: obj["totalSpent"] as? Double ?? 0.0,
            monthlyBudget: obj["monthlyBudget"] as? Double ?? 500.0,
            remaining: obj["remaining"] as? Double ?? 500.0,
            percentUsed: obj["percentUsed"] as? Int ?? 0,
            currency: obj["currency"] as? String ?? "OMR",
            decimals: obj["decimals"] as? Int ?? 3,
            privacy: obj["privacy"] as? Bool ?? false,
            activeListName: obj["activeListName"] as? String ?? "",
            uncheckedCount: obj["uncheckedInActiveList"] as? Int ?? 0,
            topItems: topNames
        )
    }

    static func formatMoney(_ amount: Double, decimals: Int, currency: String, privacy: Bool) -> String {
        if privacy { return "•••• \(currency)" }
        let safeDecimals = max(0, min(6, decimals))
        return String(format: "%.*f \(currency)", safeDecimals, amount)
    }
}

struct MasareefWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MasareefWidgetEntry

    private var emerald: Color { Color(red: 0.063, green: 0.725, blue: 0.506) }
    private var cyan: Color { Color(red: 0.024, green: 0.714, blue: 0.831) }

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("مصاريف • \(entry.percentUsed)%").font(.caption.bold())
                Text(MasareefWidgetProvider.formatMoney(entry.totalSpent, decimals: entry.decimals, currency: entry.currency, privacy: entry.privacy)).font(.headline.monospacedDigit())
                Text("المتبقي: \(MasareefWidgetProvider.formatMoney(entry.remaining, decimals: entry.decimals, currency: entry.currency, privacy: entry.privacy))").font(.caption2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .systemMedium:
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("مصاريف").font(.headline.bold()).foregroundColor(emerald)
                        Spacer()
                        Link(destination: URL(string: "masareef://add-expense")!) {
                            Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(cyan)
                        }
                    }
                    Text(MasareefWidgetProvider.formatMoney(entry.totalSpent, decimals: entry.decimals, currency: entry.currency, privacy: entry.privacy))
                        .font(.system(.title3, design: .monospaced).bold()).foregroundColor(.white).lineLimit(1)
                    Text("المتبقي: \(MasareefWidgetProvider.formatMoney(entry.remaining, decimals: entry.decimals, currency: entry.currency, privacy: entry.privacy))")
                        .font(.caption2).foregroundColor(Color.white.opacity(0.7))
                    ProgressView(value: Double(min(100, max(0, entry.percentUsed))), total: 100.0).tint(emerald)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider().background(Color.white.opacity(0.14))

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("المشتريات (\(entry.uncheckedCount))").font(.caption.bold()).foregroundColor(.white)
                        Spacer()
                        Link("فتح", destination: URL(string: "masareef://checklist")!).font(.caption2.bold()).foregroundColor(emerald)
                    }
                    if entry.topItems.isEmpty {
                        Text("القائمة فارغة").font(.caption2).foregroundColor(Color.white.opacity(0.55))
                    } else {
                        ForEach(entry.topItems.prefix(3), id: \.self) { item in
                            Text("• \(item)").font(.caption2).foregroundColor(Color.white.opacity(0.88)).lineLimit(1)
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .containerBackground(Color(red: 0.039, green: 0.055, blue: 0.090), for: .widget)

        default:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("مصاريف").font(.headline.bold()).foregroundColor(emerald)
                    Spacer()
                    Link(destination: URL(string: "masareef://add-expense")!) {
                        Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(cyan)
                    }
                }
                Text(MasareefWidgetProvider.formatMoney(entry.totalSpent, decimals: entry.decimals, currency: entry.currency, privacy: entry.privacy))
                    .font(.system(.title3, design: .monospaced).bold()).foregroundColor(.white).lineLimit(1)
                Text("المتبقي: \(MasareefWidgetProvider.formatMoney(entry.remaining, decimals: entry.decimals, currency: entry.currency, privacy: entry.privacy))")
                    .font(.caption2).foregroundColor(Color.white.opacity(0.7))
                Spacer()
                HStack {
                    Text("\(entry.percentUsed)%").font(.caption2.bold().monospacedDigit()).foregroundColor(emerald)
                    Spacer()
                    Link("المشتريات (\(entry.uncheckedCount))", destination: URL(string: "masareef://checklist")!).font(.caption2.bold()).foregroundColor(cyan)
                }
            }
            .padding()
            .containerBackground(Color(red: 0.039, green: 0.055, blue: 0.090), for: .widget)
        }
    }
}

@main
struct MasareefWidget: Widget {
    let kind: String = "MasareefWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MasareefWidgetProvider()) { entry in
            MasareefWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("مصاريف | Masareef")
        .description("ملخص المصروفات الشهرية والمشتريات واختصار إضافة مصروف.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
