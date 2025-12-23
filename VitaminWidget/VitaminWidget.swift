import WidgetKit
import SwiftUI
import AppIntents

extension Color {
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hexString.count {
        case 8: (r, g, b, a) = ((int >> 24) & 0xff, (int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
        case 6: (r, g, b, a) = ((int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff, 0xff)
        case 3: (r, g, b, a) = (((int >> 8) & 0xf) * 17, ((int >> 4) & 0xf) * 17, (int & 0xf) * 17, 0xff)
        default: (r, g, b, a) = (0, 0, 0, 0xff)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// 1. 刷新按鈕動作
struct ReloadWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "重新整理"
    
    func perform() async throws -> some IntentResult {
        // 強制清除緩存並重新讀取數據
        if let defaults = UserDefaults(suiteName: "group.xfw.Vitamin-Manager") {
            defaults.synchronize()
        }
        
        // 重新載入所有 Widget 時間線
        WidgetCenter.shared.reloadAllTimelines()
        
        // 添加延遲確保數據同步
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 秒
        
        return .result()
    }
}

// 2. 資料結構
struct VitaminWidgetEntry: TimelineEntry {
    let date: Date
    let lastAction: String?
    let lastActionTime: Date?
    let todayProgress: Double
}

// 3. 時間線提供者
struct Provider: TimelineProvider {
    private let suiteName = "group.xfw.Vitamin-Manager"
    
    func placeholder(in context: Context) -> VitaminWidgetEntry {
        VitaminWidgetEntry(
            date: Date(),
            lastAction: "維他命管家",
            lastActionTime: nil,
            todayProgress: 0.0
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (VitaminWidgetEntry) -> ()) {
        let entry = createEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<VitaminWidgetEntry>) -> ()) {
        let entry = createEntry()
        
        // 設定較短的刷新間隔以保持數據同步
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    // 安全的數據讀取方法
    private func createEntry() -> VitaminWidgetEntry {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("❌ Widget 無法建立 UserDefaults 連接")
            return VitaminWidgetEntry(
                date: Date(),
                lastAction: "無法連接",
                lastActionTime: nil,
                todayProgress: 0.0
            )
        }
        
        let lastAction = defaults.string(forKey: "lastAction")
        let lastActionTime = defaults.object(forKey: "lastActionTime") as? Date
        let todayProgress = defaults.double(forKey: "todayProgress")
        
        print("📱 Widget 讀取數據: \(lastAction ?? "無"), 進度: \(todayProgress)")
        
        return VitaminWidgetEntry(
            date: Date(),
            lastAction: lastAction,
            lastActionTime: lastActionTime,
            todayProgress: todayProgress
        )
    }
}

// 4. 畫面設計
struct VitaminWidgetEntryView : View {
    var entry: Provider.Entry
    
    // 根據 Widget 大小調整版面
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "pills.fill").foregroundStyle(Color(hex: "#66AD89"))
                    Text("維他命管家").font(.caption2).bold().foregroundStyle(.secondary)
                }
                
                Text(entry.lastAction ?? "尚未服用")
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                if let lastDate = UserDefaults(suiteName: "group.xfw.Vitamin-Manager")?.object(forKey: "lastActionTime") as? Date {
                    // ⚠️ 修改重點：使用自訂格式顯示完整日期時間
                    // 格式範例：2023年12月07日 星期四 22:15
                    Text(dateFormatter.string(from: lastDate))
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            }
            
            Spacer()
            
            // 右側：如果是中型 Widget，顯示更多資訊或按鈕
            VStack(alignment: .trailing) {
                // 刷新按鈕
                Button(intent: ReloadWidgetIntent()) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.gray.opacity(0.5))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // 進度圈
                ZStack {
                    Circle().stroke(Color.gray.opacity(0.2), lineWidth: 5)
                    Circle().trim(from: 0, to: CGFloat(entry.todayProgress))
                        .stroke(
                            LinearGradient(colors: [Color(hex: "#66AD89"), Color(hex: "#66AD89").opacity(0.7)], startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(entry.todayProgress * 100))%")
                        .font(.system(size: 10, weight: .bold))
                }
                .frame(width: 40, height: 40)
            }
        }
        .containerBackground(for: .widget) { Color(uiColor: .systemBackground) }
    }
}

// 建立一個日期格式化工具
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_TW") // 強制使用繁體中文
    // 設定格式：年-月-日 星期幾 時:分
    formatter.dateFormat = "yyyy年MM月dd日 EEEE HH:mm"
    return formatter
}()

// 5. 設定入口
@main
struct VitaminWidget: Widget {
    let kind: String = "VitaminWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                VitaminWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                VitaminWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("服藥紀錄")
        .description("顯示最近服藥紀錄")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

