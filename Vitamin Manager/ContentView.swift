import SwiftUI
import SwiftData
import PhotosUI
import SwiftDate // 記得確認左側 Package Dependencies 有安裝 SwiftDate
import WidgetKit
import UserNotifications

// MARK: - 0. APP圖示生成器
struct IconGeneratorView: View {
    var body: some View {
        ZStack {
            // 背景漸層
            LinearGradient(
                colors: [Color(red: 0.2, green: 0.6, blue: 1.0), Color(red: 0.0, green: 0.4, blue: 0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                // 主要藥丸圖示
                ZStack {
                    // 外圈白色邊框
                    Circle()
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                    
                    // 內圈藥丸容器
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 100, height: 100)
                    
                    // 藥丸圖示
                    VStack(spacing: 4) {
                        // 上排藥丸
                        HStack(spacing: 6) {
                            Capsule()
                                .fill(Color.red)
                                .frame(width: 16, height: 8)
                            Capsule()
                                .fill(Color.green)
                                .frame(width: 16, height: 8)
                        }
                        
                        // 中排藥丸
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 12, height: 12)
                            Capsule()
                                .fill(Color.blue)
                                .frame(width: 20, height: 10)
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 12, height: 12)
                        }
                        
                        // 下排藥丸
                        HStack(spacing: 6) {
                            Capsule()
                                .fill(Color.pink)
                                .frame(width: 16, height: 8)
                            Capsule()
                                .fill(Color.yellow)
                                .frame(width: 16, height: 8)
                        }
                    }
                }
                
                // APP 標題
                Text("維他命")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
        }
        .aspectRatio(1, contentMode: .fit) // 保持正方形比例
    }
}

// MARK: - 圖示生成器
class IconGenerator {
    static func generateAppIcon() -> UIImage? {
        let iconView = IconGeneratorView()
        let controller = UIHostingController(rootView: iconView)
        controller.view.frame = CGRect(x: 0, y: 0, width: 1024, height: 1024)
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1024, height: 1024))
        return renderer.image { context in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
    
    static func saveIconToDocuments() {
        guard let image = generateAppIcon() else {
            print("❌ 無法生成圖示")
            return
        }
        
        guard let data = image.pngData() else {
            print("❌ 無法轉換圖片為PNG格式")
            return
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let iconPath = documentsPath.appendingPathComponent("VitaminManagerIcon.png")
        
        do {
            try data.write(to: iconPath)
            print("✅ APP圖示已儲存至: \(iconPath.path)")
        } catch {
            print("❌ 儲存圖示失敗: \(error.localizedDescription)")
        }
    }
}

// MARK: - 1. 資料模型
@Model
class VitaminItem {
    var name: String
    var category: String
    var lastTakenDate: Date?
    var photoData: Data?
    var quantity: Int
    var colorHex: String // 新增顏色屬性
    var medicationTime: String // 服藥時間 (飯前/飯後等)
    var reminderTime: Date? // 提醒時間
    var enableReminder: Bool // 是否啟用提醒
    
    init(name: String, category: String = "一般", lastTakenDate: Date? = nil, photoData: Data? = nil, quantity: Int = 1, colorHex: String = "blue", medicationTime: String = "飯後", reminderTime: Date? = nil, enableReminder: Bool = false) {
        self.name = name
        self.category = category
        self.lastTakenDate = lastTakenDate
        self.photoData = photoData
        self.quantity = quantity
        self.colorHex = colorHex
        self.medicationTime = medicationTime
        self.reminderTime = reminderTime
        self.enableReminder = enableReminder
    }
    
    // 將顏色字符串轉換為 Color
    var color: Color {
        switch colorHex {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "gray": return .gray
        default: return .blue
        }
    }
}

// MARK: - 1.1 分類統計數據模型
struct CategoryStat {
    let name: String
    let total: Int
    let todayTaken: Int
    let color: Color
    
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(todayTaken) / Double(total)
    }
}

// MARK: - 2. App Group 管理
class GroupManager {
    static let suiteName = "group.xfw.Vitamin-Manager"
    
    // 只有在實際服用藥物時才應該調用此方法
    static func updateLog(pillName: String) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("❌ 無法訪問 App Groups: \(suiteName)")
            return
        }
        
        let actionText = "剛剛服用了 \(pillName)"
        let currentTime = Date()
        
        defaults.set(actionText, forKey: "lastAction")
        defaults.set(currentTime, forKey: "lastActionTime")
        
        // 強制同步到磁盤
        defaults.synchronize()
        
        print("✅ 已更新 Widget 數據(實際服藥): \(actionText) at \(currentTime)")
    }
    
    static func setTodayProgress(_ progress: Double) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("❌ 無法訪問 App Groups: \(suiteName)")
            return
        }
        
        defaults.set(progress, forKey: "todayProgress")
        defaults.synchronize()
        
        print("✅ 已更新進度: \(Int(progress * 100))%")
    }
    
    // 新增：清除錯誤的服藥記錄
    static func clearLastAction() {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("❌ 無法訪問 App Groups: \(suiteName)")
            return
        }
        
        defaults.removeObject(forKey: "lastAction")
        defaults.removeObject(forKey: "lastActionTime")
        defaults.synchronize()
        
        print("🧹 已清除錯誤的服藥記錄")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // 新增：緊急修復 Widget 方法
    static func emergencyFixWidget() {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("❌ 無法訪問 App Groups: \(suiteName)")
            return
        }
        
        // 清除所有 Widget 相關數據
        defaults.removeObject(forKey: "lastAction")
        defaults.removeObject(forKey: "lastActionTime")
        defaults.removeObject(forKey: "todayProgress")
        defaults.synchronize()
        
        // 重新載入所有 Widget 時間線
        WidgetCenter.shared.reloadAllTimelines()
        
        print("🔧 Widget 緊急修復完成")
    }
}

// MARK: - 3. 主入口
struct ContentView: View {
    @Query private var pills: [VitaminItem]
    
    var body: some View {
        TabView {
            PillListView().tabItem { Label("我的藥盒", systemImage: "pills.fill") }
            StatsView().tabItem { Label("統計", systemImage: "chart.pie.fill") }
            SettingsView().tabItem { Label("設定", systemImage: "gearshape.fill") }
        }
        .onAppear {
            // 請求通知權限
            requestNotificationPermission()
            // 重新安排所有已啟用的提醒
            rescheduleAllNotifications()
            // 檢查並清理可能錯誤的服藥記錄
            checkAndCleanupWidgetData()
        }
    }
    
    // MARK: - 通知權限請求
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ 通知權限已授予")
                } else {
                    print("❌ 通知權限被拒絕")
                    if let error = error {
                        print("通知權限錯誤: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - 重新安排所有通知
    private func rescheduleAllNotifications() {
        // 清除所有現有的通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // 為所有啟用提醒的藥物重新設定通知
        for pill in pills {
            if pill.enableReminder {
                scheduleNotificationForPill(pill)
            }
        }
        
        print("🔄 已重新安排 \(pills.filter { $0.enableReminder }.count) 個藥物提醒")
    }
    
    // MARK: - 檢查並清理Widget數據
    private func checkAndCleanupWidgetData() {
        // 如果沒有任何藥物被實際服用，但Widget顯示有服用記錄，則清除錯誤數據
        let todayTaken = pills.filter { pill in
            guard let lastTaken = pill.lastTakenDate else { return false }
            return DateInRegion(lastTaken, region: .current).isToday
        }
        
        if todayTaken.isEmpty {
            // 沒有任何藥物今天被服用，檢查Widget是否有錯誤的服藥記錄
            if let defaults = UserDefaults(suiteName: GroupManager.suiteName),
               let lastAction = defaults.string(forKey: "lastAction"),
               lastAction.contains("剛剛服用了") {
                print("🚨 發現錯誤的服藥記錄，正在清除...")
                GroupManager.clearLastAction()
            }
        }
    }
    
    // MARK: - 通知排程 (統一方法)
    private func scheduleNotificationForPill(_ pill: VitaminItem) {
        guard pill.enableReminder, let reminderTime = pill.reminderTime else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "💊 服藥提醒"
        content.body = "該服用 \(pill.name) 了！\n服藥時間：\(pill.medicationTime.isEmpty ? "請查看藥物說明" : pill.medicationTime)"
        content.sound = .default
        content.badge = 1
        
        // 添加自定義數據
        content.userInfo = [
            "pillName": pill.name,
            "pillCategory": pill.category,
            "pillQuantity": pill.quantity
        ]
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "pill_\(pill.name)_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 通知排程失敗 - \(pill.name): \(error.localizedDescription)")
            } else {
                print("✅ 已為 \(pill.name) 設定提醒: \(timeFormatter.string(from: reminderTime))")
            }
        }
    }
}

// MARK: - 4. 我的藥盒頁面
struct PillListView: View {
    @Query(sort: \VitaminItem.name) private var pills: [VitaminItem]
    @Environment(\.modelContext) private var context
    @State private var showAddSheet = false
    @State private var editingPill: VitaminItem? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                if pills.isEmpty {
                    ContentUnavailableView("藥盒是空的", systemImage: "pills.circle", description: Text("點擊右上角 + 新增"))
                } else {
                    List {
                        ForEach(pills) { pill in
                            PillRowView(pill: pill, onTake: { takePill(pill) })
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingPill = pill
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("我的藥盒")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddPillView()
            }
            .sheet(item: $editingPill) { pill in
                EditPillView(pill: pill)
            }
        }
    }

    func takePill(_ pill: VitaminItem) {
        withAnimation {
            pill.lastTakenDate = Date()
        }
        
        // 更新 App Groups 數據
        GroupManager.updateLog(pillName: pill.name)
        
        // 強制同步數據
        if let defaults = UserDefaults(suiteName: GroupManager.suiteName) {
            defaults.synchronize()
        }
        
        // 重新載入 Widget 時間線
        WidgetCenter.shared.reloadAllTimelines()
        
        // 添加輕微延遲確保數據已寫入
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            WidgetCenter.shared.reloadTimelines(ofKind: "VitaminWidget")
        }
    }
    
    func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets { context.delete(pills[index]) }
        }
    }
}

// MARK: - 5. 統計頁面
struct StatsView: View {
    @Query private var pills: [VitaminItem]
    
    var progress: Double {
        guard !pills.isEmpty else {
            GroupManager.setTodayProgress(0)
            return 0
        }
        
        let taken = pills.filter { pill in
            guard let lastTaken = pill.lastTakenDate else { return false }
            return DateInRegion(lastTaken, region: .current).isToday
        }.count
        
        let progressValue = Double(taken) / Double(pills.count)
        GroupManager.setTodayProgress(progressValue)
        
        return progressValue
    }
    
    var weekStats: ([String], [Int]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var labels: [String] = []
        var counts: [Int] = []
        for i in (0...6).reversed() {
            let day = calendar.date(byAdding: .day, value: -i, to: today)!
            let label = dateFormatter.shortWeekdaySymbols[calendar.component(.weekday, from: day)-1]
            labels.append(label)
            let count = pills.filter { pill in
                guard let taken = pill.lastTakenDate else { return false }
                return calendar.isDate(taken, inSameDayAs: day)
            }.count
            counts.append(count)
        }
        return (labels, counts)
    }
    
    // 新增：分類統計數據
    var categoryStats: [CategoryStat] {
        let categories = ["維他命", "礦物質", "保健食品", "處方藥", "中藥", "一般"]
        
        return categories.compactMap { category in
            let categoryPills = pills.filter { $0.category == category }
            guard !categoryPills.isEmpty else { return nil }
            
            let todayTaken = categoryPills.filter { pill in
                guard let lastTaken = pill.lastTakenDate else { return false }
                return DateInRegion(lastTaken, region: .current).isToday
            }.count
            
            // 使用該分類中藥物的主要顏色（取最常用的顏色）
            let colorCounts = Dictionary(grouping: categoryPills) { $0.colorHex }
                .mapValues { $0.count }
            let mostCommonColorHex = colorCounts.max { $0.value < $1.value }?.key ?? "blue"
            
            // 創建一個臨時的VitaminItem來取得顏色
            let tempPill = VitaminItem(name: "", colorHex: mostCommonColorHex)
            let categoryColor = tempPill.color
            
            return CategoryStat(
                name: category,
                total: categoryPills.count,
                todayTaken: todayTaken,
                color: categoryColor
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // 今日進度圓環
                    ZStack {
                        Circle().stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        Circle().trim(from: 0, to: progress)
                            .stroke(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .rotationEffect(.degrees(-90)).animation(.easeOut, value: progress)
                        VStack {
                            Text("\(Int(progress * 100))%").font(.system(size: 50, weight: .bold, design: .rounded))
                            Text("今日達成").font(.caption).foregroundStyle(.secondary)
                        }
                    }.frame(width: 200, height: 200).padding(.top, 40)
                    
                    // 總覽統計
                    VStack(spacing: 15) {
                        StatRow(icon: "pill.fill", color: Color.blue, title: "總藥物數", value: "\(pills.count) 種")
                        StatRow(icon: "checkmark.circle.fill", color: Color.green, title: "今日已服", value: "\(Int(progress * Double(pills.count))) 次")
                        StatRow(icon: "list.bullet", color: Color.purple, title: "分類數量", value: "\(categoryStats.count) 類")
                    }
                    .padding().frame(maxWidth: .infinity).background(Color.white).cornerRadius(16).padding(.horizontal, 16)
                    
                    // 分類詳細統計
                    if !categoryStats.isEmpty {
                        CategoryStatsView(categoryStats: categoryStats)
                            .padding(.horizontal, 16)
                    }
                    
                    // 一週統計圖表
                    let (labels, counts) = weekStats
                    VStack {
                        BarChartView(data: counts, labels: labels, maxValue: counts.max() ?? 1)
                    }.padding().frame(maxWidth: .infinity).background(Color.white).cornerRadius(16).padding(.horizontal, 16)
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("統計")
        }
    }
}

// MARK: - 5.1 圓餅圖
struct PieChartView: View {
    let categoryStats: [CategoryStat]
    
    var body: some View {
        ZStack {
            ForEach(Array(categoryStats.enumerated()), id: \.offset) { index, stat in
                PieSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    color: stat.color
                )
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func startAngle(for index: Int) -> Angle {
        let totalCount = categoryStats.reduce(0) { $0 + $1.total }
        guard totalCount > 0 else { return .degrees(0) }
        
        let previousCount = categoryStats.prefix(index).reduce(0) { $0 + $1.total }
        return .degrees(Double(previousCount) / Double(totalCount) * 360 - 90)
    }
    
    private func endAngle(for index: Int) -> Angle {
        let totalCount = categoryStats.reduce(0) { $0 + $1.total }
        guard totalCount > 0 else { return .degrees(0) }
        
        let currentCount = categoryStats.prefix(index + 1).reduce(0) { $0 + $1.total }
        return .degrees(Double(currentCount) / Double(totalCount) * 360 - 90)
    }
}

// MARK: - 圓餅圖扇形
struct PieSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: 60, y: 60) // 假設圖表大小為120x120
            let radius: CGFloat = 50
            
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(color)
    }
}

// MARK: - 5.2 長條圖
struct BarChartView: View {
    let data: [Int]
    let labels: [String]
    let maxValue: Int
    var body: some View {
        VStack(alignment: .leading) {
            Text("一週服藥紀錄").font(.headline).padding(.bottom, 4)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.offset) { i, value in
                    VStack {
                        ZStack(alignment: .bottom) {
                            Capsule().frame(width: 18, height: 80).foregroundColor(Color.gray.opacity(0.15))
                            Capsule().frame(width: 18, height: maxValue == 0 ? 0 : CGFloat(value) / CGFloat(maxValue) * 80).foregroundColor(.blue)
                        }
                        Text(labels[i]).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }.frame(height: 100)
        }
    }
}

// MARK: - 6. 設定頁面
struct SettingsView: View {
    @AppStorage("enableCloud") private var enableCloud = false
    @Query private var pills: [VitaminItem]
    @Environment(\.modelContext) private var context
    
    @State private var showExportSheet = false
    @State private var exportedCSV: String = ""
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("資料管理") {
                    Button(action: { exportToCSV() }) {
                        Label { Text("匯出紀錄 (CSV)") } icon: {
                            Image(systemName: "square.and.arrow.up").foregroundStyle(.green)
                        }
                    }
                    
                    Button(action: { clearAllData() }) {
                        Label { Text("清除所有資料") } icon: {
                            Image(systemName: "trash.fill").foregroundStyle(.red)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "pills.circle.fill").font(.largeTitle).foregroundStyle(.blue.opacity(0.5))
                            Text("維他命管家 v1.0.0").font(.caption).bold()
                            Text("Designed by Allison").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }.listRowBackground(Color.clear)
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showExportSheet) {
                ShareSheet(items: [exportedCSV])
            }
            .alert("確認刪除", isPresented: $showDeleteConfirmation) {
                Button("取消", role: .cancel) { }
                Button("刪除", role: .destructive) {
                    performClearAllData()
                }
            } message: {
                Text("此操作將清除所有藥物資料，無法復原。確定要繼續嗎？")
            }
        }
    }
    
    // MARK: - CSV 匯出功能
    private func exportToCSV() {
        var csvContent = "藥物名稱,分類,最後服用時間,每次劑量\n"
        
        for pill in pills {
            let lastTakenString = pill.lastTakenDate?.formatted(date: .numeric, time: .shortened) ?? "尚未服用"
            csvContent += "\(pill.name),\(pill.category),\(lastTakenString),\(pill.quantity)顆\n"
        }
        
        exportedCSV = csvContent
        showExportSheet = true
    }
    
    // MARK: - 清除資料功能
    private func clearAllData() {
        showDeleteConfirmation = true
    }
    
    private func performClearAllData() {
        // 清除所有藥物資料
        for pill in pills {
            context.delete(pill)
        }
        
        // 清除App Groups中的資料
        if let defaults = UserDefaults(suiteName: GroupManager.suiteName) {
            defaults.removeObject(forKey: "lastAction")
            defaults.removeObject(forKey: "lastActionTime")
            defaults.removeObject(forKey: "todayProgress")
            defaults.synchronize()
        }
        
        // 更新Widget
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - 分享功能
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 7. 新增藥物頁面
struct AddPillView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var context
    @State private var name = ""
    @State private var category = "一般"
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var quantity = 1
    @State private var selectedColorHex = "blue"
    @State private var medicationTime = ""
    @State private var enableReminder = false
    @State private var reminderTime = Date()
    @State private var showReminderTimePicker = false
    
    // 預設分類選項
    private let categories = ["維他命", "礦物質", "保健食品", "處方藥", "中藥", "一般"]
    
    // 顏色選項
    private let colorOptions = [
        ("red", Color.red, "紅色"),
        ("orange", Color.orange, "橙色"),
        ("yellow", Color.yellow, "黃色"),
        ("green", Color.green, "綠色"),
        ("blue", Color.blue, "藍色"),
        ("purple", Color.purple, "紫色"),
        ("pink", Color.pink, "粉色"),
        ("gray", Color.gray, "灰色")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // 1. 基本資訊（藥物名稱）
                Section {
                    TextField("藥物名稱 (例如: B群)", text: $name).font(.title3)
                } header: { Text("基本資訊") }
                
                // 2. 服藥時間
                Section {
                    TextField("服藥時間", text: $medicationTime, prompt: Text("例如：早飯前"))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                } header: { Text("服藥時間") } footer: { Text("請輸入適合的服藥時間說明，例如：早飯前、晚飯後、睡前等") }
                
                // 3. 分類
                Section {
                    Picker("分類", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                } header: { Text("分類") }
                
                // 4. 藥物顏色
                Section {
                    HStack {
                        // 顯示目前選擇的顏色
                        let currentColor = colorOptions.first { $0.0 == selectedColorHex }?.1 ?? .blue
                        let currentColorName = colorOptions.first { $0.0 == selectedColorHex }?.2 ?? "藍色"
                        
                        Circle()
                            .fill(currentColor)
                            .frame(width: 24, height: 24)
                        
                        Text(currentColorName)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Picker("", selection: $selectedColorHex) {
                            ForEach(colorOptions, id: \.0) { colorHex, color, colorName in
                                HStack {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 16, height: 16)
                                    Text(colorName)
                                    Spacer()
                                }
                                .tag(colorHex)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .labelsHidden()
                    }
                } header: { Text("藥物顏色") } footer: { Text("選擇顏色有助於辨識重要性，如紅色代表必須服用") }
                
                // 5. 服用劑量
                Section {
                    Stepper(value: $quantity, in: 1...10) {
                        HStack { Text("每次服用"); Spacer(); Text("\(quantity) 顆").bold().foregroundStyle(.blue) }
                    }
                } header: { Text("服用劑量") }
                
                // 6. 提醒設定
                Section {
                    Toggle(isOn: $enableReminder) {
                        Label { Text("啟用每日提醒") } icon: {
                            Image(systemName: "bell.fill").foregroundStyle(.orange)
                        }
                    }
                    
                    if enableReminder {
                        Button(action: { showReminderTimePicker = true }) {
                            Label {
                                HStack {
                                    Text("提醒時間")
                                    Spacer()
                                    Text(timeFormatter.string(from: reminderTime))
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "clock.fill").foregroundStyle(.blue)
                            }
                        }
                    }
                } header: { Text("提醒設定") } footer: { Text("系統將在指定時間提醒您服藥") }
                
                // 7. 藥物外觀
                Section {
                    HStack {
                        Spacer()
                        ZStack(alignment: .topTrailing) {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 180, height: 180).clipShape(RoundedRectangle(cornerRadius: 20)).shadow(radius: 5)
                                } else {
                                    VStack(spacing: 10) {
                                        Image(systemName: "camera.circle.fill").font(.system(size: 50)).foregroundStyle(.blue)
                                        Text("點擊選擇照片").font(.caption).foregroundStyle(.secondary)
                                    }.frame(width: 180, height: 180).background(Color.gray.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 20)).overlay(RoundedRectangle(cornerRadius: 20).stroke(style: StrokeStyle(lineWidth: 2, dash: [5])).foregroundStyle(.gray.opacity(0.3)))
                                }
                            }
                            .onChange(of: selectedItem) { Task { if let data = try? await selectedItem?.loadTransferable(type: Data.self) { selectedImageData = data } } }
                            if selectedImageData != nil {
                                Button(action: { withAnimation { selectedImageData = nil; selectedItem = nil } }) {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red).background(Color.white.clipShape(Circle())).font(.title)
                                }.offset(x: 10, y: -10)
                            }
                        }
                        Spacer()
                    }.padding(.vertical, 10)
                } header: { Text("藥物外觀") }
            }
            .navigationTitle("新增藥物")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        let newPill = VitaminItem(
                            name: name,
                            category: category,
                            photoData: selectedImageData,
                            quantity: quantity,
                            colorHex: selectedColorHex,
                            medicationTime: medicationTime,
                            reminderTime: enableReminder ? reminderTime : nil,
                            enableReminder: enableReminder
                        )
                        context.insert(newPill)
                        
                        do {
                            try context.save()
                            print("[AddPillView] 儲存成功，name=\(newPill.name)")
                        } catch {
                            print("儲存新藥物失敗: \(error)")
                        }
                        
                        // 如果啟用提醒，則設置通知
                        if enableReminder {
                            scheduleNotificationForPill(newPill)
                        }
                        
                        WidgetCenter.shared.reloadTimelines(ofKind: "VitaminWidget")
                        dismiss()
                    }.disabled(name.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showReminderTimePicker) {
            NavigationStack {
                VStack {
                    DatePicker("提醒時間", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding()
                    Spacer()
                }
                .navigationTitle("設定提醒時間")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("取消") { showReminderTimePicker = false }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("確定") {
                            showReminderTimePicker = false
                        }
                    }
                }
            }
        }
    }
    
    // 為單一藥物安排通知
    private func scheduleNotificationForPill(_ pill: VitaminItem) {
        guard pill.enableReminder, let reminderTime = pill.reminderTime else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "服藥提醒"
        content.body = "該服用 \(pill.name) 了！服藥時間：\(pill.medicationTime)"
        content.sound = .default
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "pill_\(pill.name)_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知排程失敗 - \(pill.name): \(error)")
            } else {
                print("✅ 已為 \(pill.name) 設定提醒: \(timeFormatter.string(from: reminderTime))")
            }
        }
    }
}

// MARK: - 7.1 編輯藥物頁面
struct EditPillView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    var pill: VitaminItem
    @State private var name: String
    @State private var category: String
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var quantity: Int
    @State private var selectedColorHex: String
    @State private var medicationTime: String
    @State private var enableReminder: Bool
    @State private var reminderTime: Date
    @State private var showReminderTimePicker = false
    
    // 預設分類選項
    private let categories = ["維他命", "礦物質", "保健食品", "處方藥", "中藥", "一般"]
    
    // 顏色選項
    private let colorOptions = [
        ("red", Color.red, "紅色"),
        ("orange", Color.orange, "橙色"),
        ("yellow", Color.yellow, "黃色"),
        ("green", Color.green, "綠色"),
        ("blue", Color.blue, "藍色"),
        ("purple", Color.purple, "紫色"),
        ("pink", Color.pink, "粉色"),
        ("gray", Color.gray, "灰色")
    ]

    init(pill: VitaminItem) {
        self.pill = pill
        _name = State(initialValue: pill.name)
        _category = State(initialValue: pill.category)
        _selectedImageData = State(initialValue: pill.photoData)
        _quantity = State(initialValue: pill.quantity)
        _selectedColorHex = State(initialValue: pill.colorHex)
        _medicationTime = State(initialValue: pill.medicationTime)
        _enableReminder = State(initialValue: pill.enableReminder)
        _reminderTime = State(initialValue: pill.reminderTime ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                // 1. 基本資訊（藥物名稱）
                Section {
                    TextField("名稱", text: $name).font(.title3)
                } header: { Text("基本資訊") }
                
                // 2. 服藥時間
                Section {
                    TextField("服藥時間 (例如: 早飯前)", text: $medicationTime)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                } header: { Text("服藥時間") } footer: { Text("請輸入適合的服藥時間說明") }
                
                // 3. 分類
                Section {
                    Picker("分類", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                } header: { Text("分類") }
                
                // 4. 藥物顏色
                Section {
                    HStack {
                        // 顯示目前選擇的顏色
                        let currentColor = colorOptions.first { $0.0 == selectedColorHex }?.1 ?? .blue
                        let currentColorName = colorOptions.first { $0.0 == selectedColorHex }?.2 ?? "藍色"
                        
                        Circle()
                            .fill(currentColor)
                            .frame(width: 24, height: 24)
                        
                        Text(currentColorName)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Picker("", selection: $selectedColorHex) {
                            ForEach(colorOptions, id: \.0) { colorHex, color, colorName in
                                HStack {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 16, height: 16)
                                    Text(colorName)
                                    Spacer()
                                }
                                .tag(colorHex)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .labelsHidden()
                    }
                } header: { Text("藥物顏色") } footer: { Text("選擇顏色有助於辨識重要性，如紅色代表必須服用") }
                
                // 5. 服用劑量
                Section {
                    Stepper(value: $quantity, in: 1...10) {
                        HStack { Text("每次服用"); Spacer(); Text("\(quantity) 顆").bold().foregroundStyle(.blue) }
                    }
                } header: { Text("服用劑量") }
                
                // 6. 提醒設定
                Section {
                    Toggle(isOn: $enableReminder) {
                        Label { Text("啟用每日提醒") } icon: {
                            Image(systemName: "bell.fill").foregroundStyle(.orange)
                        }
                    }
                    
                    if enableReminder {
                        Button(action: { showReminderTimePicker = true }) {
                            Label {
                                HStack {
                                    Text("提醒時間")
                                    Spacer()
                                    Text(timeFormatter.string(from: reminderTime))
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "clock.fill").foregroundStyle(.blue)
                            }
                        }
                    }
                } header: { Text("提醒設定") } footer: { Text("系統將在指定時間提醒您服藥") }
                
                // 7. 藥物外觀
                Section {
                    HStack {
                        Spacer()
                        ZStack(alignment: .topTrailing) {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 180, height: 180).clipShape(RoundedRectangle(cornerRadius: 20)).shadow(radius: 5)
                                } else {
                                    VStack(spacing: 10) {
                                        Image(systemName: "camera.circle.fill").font(.system(size: 50)).foregroundStyle(.blue)
                                        Text("更換照片").font(.caption).foregroundStyle(.secondary)
                                    }.frame(width: 180, height: 180).background(Color.gray.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 20)).overlay(RoundedRectangle(cornerRadius: 20).stroke(style: StrokeStyle(lineWidth: 2, dash: [5])).foregroundStyle(.gray.opacity(0.3)))
                                }
                            }
                            .onChange(of: selectedItem) { Task { if let data = try? await selectedItem?.loadTransferable(type: Data.self) { selectedImageData = data } } }
                            if selectedImageData != nil {
                                Button(action: { withAnimation { selectedImageData = nil; selectedItem = nil } }) {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red).background(Color.white.clipShape(Circle())).font(.title)
                                }.offset(x: 10, y: -10)
                            }
                        }
                        Spacer()
                    }.padding(.vertical, 10)
                } header: { Text("藥物外觀") }
            }
            .navigationTitle("編輯")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        pill.name = name
                        pill.category = category
                        pill.photoData = selectedImageData
                        pill.quantity = quantity
                        pill.colorHex = selectedColorHex
                        pill.medicationTime = medicationTime
                        pill.enableReminder = enableReminder
                        pill.reminderTime = enableReminder ? reminderTime : nil
                        
                        do {
                            try context.save()
                            print("[EditPillView] 儲存成功，name=\(pill.name)")
                        } catch {
                            print("儲存編輯藥物失敗: \(error)")
                        }
                        
                        // 更新通知設定
                        scheduleNotificationForPill(pill)
                        
                        // 只重新載入Widget時間線，不要更新服藥記錄
                        WidgetCenter.shared.reloadAllTimelines()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showReminderTimePicker) {
            NavigationStack {
                VStack {
                    DatePicker("提醒時間", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding()
                    Spacer()
                }
                .navigationTitle("設定提醒時間")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("取消") { showReminderTimePicker = false }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("確定") {
                            showReminderTimePicker = false
                        }
                    }
                }
            }
        }
    }
    
    // 為編輯藥物安排通知
    private func scheduleNotificationForPill(_ pill: VitaminItem) {
        // 先清除舊的通知
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["pill_\(pill.name)_reminder"])
        
        guard pill.enableReminder, let reminderTime = pill.reminderTime else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "服藥提醒"
        content.body = "該服用 \(pill.name) 了！服藥時間：\(pill.medicationTime)"
        content.sound = .default
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "pill_\(pill.name)_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知排程失敗 - \(pill.name): \(error)")
            } else {
                print("✅ 已為 \(pill.name) 更新提醒: \(timeFormatter.string(from: reminderTime))")
            }
        }
    }
}

// MARK: - 8. 列表卡片樣式
struct PillRowView: View {
    let pill: VitaminItem
    let onTake: () -> Void
    var isOverdue: Bool {
        guard let date = pill.lastTakenDate else { return true }
        return DateInRegion() > (DateInRegion(date, region: .current) + 1.days)
    }
    
    var isTakenToday: Bool {
        guard let lastTaken = pill.lastTakenDate else { return false }
        return DateInRegion(lastTaken, region: .current).isToday
    }
    
    var body: some View {
        HStack(spacing: 15) {
            if let data = pill.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 60, height: 60).clipShape(Circle())
                    .overlay(
                        Circle().stroke(pill.color, lineWidth: 3)
                    )
            } else {
                ZStack {
                    Circle().fill(pill.color.opacity(0.2)).frame(width: 60, height: 60)
                        .overlay(
                            Circle().stroke(pill.color, lineWidth: 3)
                        )
                    Image(systemName: "pills.fill").foregroundStyle(pill.color).font(.title2)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(pill.name).font(.headline)
                    Spacer()
                    // 新增分類標籤，使用藥物的顏色
                    Text(pill.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(pill.color.opacity(0.1))
                        .foregroundStyle(pill.color)
                        .clipShape(Capsule())
                }
                if !pill.medicationTime.isEmpty {
                    Text("服藥時間：\(pill.medicationTime)")
                        .font(.headline) // 粗體
                        .foregroundStyle(.secondary)
                }
                Text("每次 \(pill.quantity) 顆").font(.subheadline).foregroundStyle(.secondary)
                
                if let date = pill.lastTakenDate {
                    HStack(spacing: 4) {
                        Image(systemName: isOverdue ? "exclamationmark.circle.fill" : "clock")
                        Text(dateFormatter.string(from: date))
                    }
                    .font(.caption)
                    .bold()
                    .foregroundStyle(isOverdue ? .red : .secondary)
                } else {
                    Text("尚未服用").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            // Button that shows different states based on whether pill was taken today
            Button(action: onTake) {
                HStack(spacing: 6) {
                    if isTakenToday {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                    }
                    Text(isTakenToday ? "已服用" : "吃藥")
                        .bold()
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(isTakenToday ? pill.color : Color.gray.opacity(0.3))
            .foregroundStyle(isTakenToday ? .white : .black)
            .clipShape(Capsule())
            .buttonStyle(PlainButtonStyle())
        }
        .padding().background(Color.white).cornerRadius(16).shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// ⚠️ 日期格式設定工具
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_TW")
    // 設定格式：2023年12月07日 星期四 10:30
    formatter.dateFormat = "yyyy年MM月dd日 EEEE HH:mm"
    return formatter
}()

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_TW")
    formatter.timeStyle = .short
    return formatter
}()

struct StatRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).frame(width: 24, height: 24)
            VStack(alignment: .leading) {
                Text(title).font(.subheadline).foregroundColor(.secondary)
                Text(value).font(.headline)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 分類統計視圖
struct CategoryStatsView: View {
    let categoryStats: [CategoryStat]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
                Text("分類統計")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(categoryStats, id: \.name) { stat in
                    CategoryRowView(stat: stat)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}

// MARK: - 分類行視圖
struct CategoryRowView: View {
    let stat: CategoryStat
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(stat.color)
                        .frame(width: 12, height: 12)
                    Text(stat.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(stat.todayTaken)/\(stat.total)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(stat.color)
                    Text("今日/總數")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // 進度條
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(stat.color)
                        .frame(width: geometry.size.width * stat.progress, height: 6)
                        .cornerRadius(3)
                        .animation(.easeOut(duration: 0.5), value: stat.progress)
                }
            }
            .frame(height: 6)
        }
    }
}

#Preview {
    @Previewable @State var previewContainer: ModelContainer = {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: VitaminItem.self, configurations: config)
        } catch {
            fatalError("Failed to create preview container")
        }
    }()
    
    return ContentView()
        .modelContainer(previewContainer)
}
