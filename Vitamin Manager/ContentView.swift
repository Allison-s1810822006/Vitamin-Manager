import SwiftUI
import SwiftData
import PhotosUI
import SwiftDate // 記得確認左側 Package Dependencies 有安裝 SwiftDate
import WidgetKit
import UserNotifications

// MARK: - 1. 資料模型
@Model
class VitaminItem {
    var name: String
    var lastTakenDate: Date?
    @Attribute(.externalStorage) var photoData: Data?
    var quantity: Int
    
    init(name: String, lastTakenDate: Date? = nil, photoData: Data? = nil, quantity: Int = 1) {
        self.name = name
        self.lastTakenDate = lastTakenDate
        self.photoData = photoData
        self.quantity = quantity
    }
}

// MARK: - 2. App Group 管理
class GroupManager {
    static let suiteName = "group.xfw.Vitamin-Manager"
    
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
        
        print("✅ 已更新 Widget 數據: \(actionText) at \(currentTime)")
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
}

// MARK: - 3. 主入口
struct ContentView: View {
    var body: some View {
        TabView {
            PillListView().tabItem { Label("我的藥盒", systemImage: "pills.fill") }
            StatsView().tabItem { Label("統計", systemImage: "chart.pie.fill") }
            SettingsView().tabItem { Label("設定", systemImage: "gearshape.fill") }
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
                            // ⚠️ 修正：移除外層 Button，改用 onTapGesture，避免與「吃藥」按鈕衝突
                            PillRowView(pill: pill, onTake: { takePill(pill) })
                                .contentShape(Rectangle()) // 讓整個區域都可點擊
                                .onTapGesture {
                                    editingPill = pill // 點擊卡片空白處 -> 編輯
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 20) {
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
                    
                    VStack(spacing: 15) {
                        StatRow(icon: "pill.fill", color: Color.blue, title: "總藥物數", value: "\(pills.count) 種")
                        StatRow(icon: "checkmark.circle.fill", color: Color.green, title: "今日已服", value: "\(Int(progress * Double(pills.count))) 次")
                    }
                    .padding().frame(maxWidth: .infinity).background(Color.white).cornerRadius(16).padding(.horizontal, 16)
                    
                    let (labels, counts) = weekStats
                    VStack {
                        BarChartView(data: counts, labels: labels, maxValue: counts.max() ?? 1)
                    }.padding().frame(maxWidth: .infinity).background(Color.white).cornerRadius(16).padding(.horizontal, 16)
                    
                    Spacer()
                }
            }
            .navigationTitle("統計")
        }
    }
}

// MARK: - 5.1 長條圖
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
    @AppStorage("enableNotification") private var enableNotification = true
    @AppStorage("enableCloud") private var enableCloud = false
    @AppStorage("notificationTime") private var notificationTimeData = Data()
    @Query private var pills: [VitaminItem]
    @Environment(\.modelContext) private var context
    
    @State private var showNotificationTimePicker = false
    @State private var notificationTime = Date()
    @State private var showExportSheet = false
    @State private var exportedCSV: String = ""
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("一般設定") {
                    Toggle(isOn: $enableNotification) { 
                        Label { Text("服藥提醒") } icon: { 
                            Image(systemName: "bell.fill").foregroundStyle(.red) 
                        } 
                    }
                    .onChange(of: enableNotification) { _, newValue in
                        if newValue {
                            requestNotificationPermission()
                            scheduleNotifications()
                        } else {
                            removeScheduledNotifications()
                        }
                    }
                    
                    if enableNotification {
                        Button(action: { showNotificationTimePicker = true }) {
                            Label {
                                HStack {
                                    Text("提醒時間")
                                    Spacer()
                                    Text(timeFormatter.string(from: notificationTime))
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "clock.fill").foregroundStyle(.blue)
                            }
                        }
                    }
                    
                    Toggle(isOn: $enableCloud) { 
                        Label { Text("iCloud 同步") } icon: { 
                            Image(systemName: "icloud.fill").foregroundStyle(.blue) 
                        } 
                    }
                    if enableCloud { 
                        Text("⚠️ 目前使用本地資料庫模式").font(.caption).foregroundStyle(.secondary) 
                    }
                }
                
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
            .onAppear {
                loadNotificationTime()
            }
            .sheet(isPresented: $showNotificationTimePicker) {
                NavigationStack {
                    VStack {
                        DatePicker("提醒時間", selection: $notificationTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .padding()
                        Spacer()
                    }
                    .navigationTitle("設定提醒時間")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("取消") { showNotificationTimePicker = false }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("確定") {
                                saveNotificationTime()
                                scheduleNotifications()
                                showNotificationTimePicker = false
                            }
                        }
                    }
                }
            }
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
    
    // MARK: - 通知相關功能
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("通知權限請求失敗: \(error)")
            }
        }
    }
    
    private func scheduleNotifications() {
        guard enableNotification else { return }
        
        removeScheduledNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = "服藥提醒"
        content.body = "該服用維他命囉！"
        content.sound = .default
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: notificationTime)
        let minute = calendar.component(.minute, from: notificationTime)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyVitaminReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知排程失敗: \(error)")
            }
        }
    }
    
    private func removeScheduledNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyVitaminReminder"])
    }
    
    private func loadNotificationTime() {
        if let data = try? JSONDecoder().decode(Date.self, from: notificationTimeData) {
            notificationTime = data
        } else {
            // 預設時間為早上 8:00
            let calendar = Calendar.current
            notificationTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        }
    }
    
    private func saveNotificationTime() {
        if let encoded = try? JSONEncoder().encode(notificationTime) {
            notificationTimeData = encoded
        }
    }
    
    // MARK: - CSV 匯出功能
    private func exportToCSV() {
        var csvContent = "藥物名稱,最後服用時間,每次劑量\n"
        
        for pill in pills {
            let lastTakenString = pill.lastTakenDate?.formatted(date: .numeric, time: .shortened) ?? "尚未服用"
            csvContent += "\(pill.name),\(lastTakenString),\(pill.quantity)顆\n"
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
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var quantity = 1
    
    var body: some View {
        NavigationStack {
            Form {
                Section { TextField("藥物名稱 (例如: B群)", text: $name).font(.title3) } header: { Text("基本資訊") }
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
                Section {
                    Stepper(value: $quantity, in: 1...10) {
                        HStack { Text("每次服用"); Spacer(); Text("\(quantity) 顆").bold().foregroundStyle(.blue) }
                    }
                } header: { Text("服用劑量") }
            }
            .navigationTitle("新增藥物")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        let newPill = VitaminItem(name: name, photoData: selectedImageData, quantity: quantity)
                        context.insert(newPill)
                        dismiss()
                    }.disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - 7.1 編輯藥物頁面
struct EditPillView: View {
    @Environment(\.dismiss) var dismiss
    var pill: VitaminItem
    @State private var name: String
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var quantity: Int

    init(pill: VitaminItem) {
        self.pill = pill
        _name = State(initialValue: pill.name)
        _selectedImageData = State(initialValue: pill.photoData)
        _quantity = State(initialValue: pill.quantity)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section { TextField("名稱", text: $name).font(.title3) } header: { Text("基本資訊") }
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
                Section {
                    Stepper(value: $quantity, in: 1...10) {
                        HStack { Text("每次服用"); Spacer(); Text("\(quantity) 顆").bold().foregroundStyle(.blue) }
                    }
                } header: { Text("服用劑量") }
            }
            .navigationTitle("編輯")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        pill.name = name
                        pill.photoData = selectedImageData
                        pill.quantity = quantity
                        dismiss()
                    }
                }
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
    
    var body: some View {
        HStack(spacing: 15) {
            if let data = pill.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 60, height: 60).clipShape(Circle())
            } else {
                ZStack {
                    Circle().fill(isOverdue ? Color.orange.opacity(0.1) : Color.green.opacity(0.1)).frame(width: 60, height: 60)
                    Image(systemName: "pills.fill").foregroundStyle(isOverdue ? .orange : .green).font(.title2)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(pill.name).font(.headline)
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
            // ⚠️ 按鈕在這裡，現在不會被蓋住了
            Button(action: onTake) {
                Text("吃藥").bold().padding(.horizontal, 20).padding(.vertical, 10)
                    .background(isOverdue ? Color.blue : Color(uiColor: .systemGray5))
                    .foregroundStyle(isOverdue ? .white : .primary)
                    .clipShape(Capsule())
            }
            // 使用 borderedProminent 或 plain 都可以，這裡保持原本設計
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

#Preview {
    ContentView().modelContainer(for: VitaminItem.self, inMemory: true)
}
