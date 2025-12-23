import SwiftUI
import SwiftData
import SwiftDate
import PhotosUI
import UserNotifications
import WidgetKit

// MARK: - 新增藥物頁面
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
                        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
                        let newPill = VitaminItem(
                            name: name,
                            category: trimmedCategory,
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
                            print("[AddPillView] 儲存成功，name=\(newPill.name), category=\(newPill.category)")
                        } catch {
                            print("儲存新藥物失敗: \(error)")
                        }
                        
                        // 如果啟用提醒，則設置通知
                        if enableReminder {
                            NotificationManager.shared.scheduleNotificationForPill(newPill)
                        }
                        
                        WidgetCenter.shared.reloadTimelines(ofKind: "VitaminWidget")
                        dismiss()
                    }.disabled(name.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showReminderTimePicker) {
            ReminderTimePickerView(reminderTime: $reminderTime, isPresented: $showReminderTimePicker)
        }
    }
}

// MARK: - 編輯藥物頁面
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
    
    private let categories = ["維他命", "礦物質", "保健食品", "處方藥", "中藥", "一般"]
    
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
                        pill.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
                        pill.photoData = selectedImageData
                        pill.quantity = quantity
                        pill.colorHex = selectedColorHex
                        pill.medicationTime = medicationTime
                        pill.enableReminder = enableReminder
                        pill.reminderTime = enableReminder ? reminderTime : nil
                        
                        do {
                            try context.save()
                            print("[EditPillView] 儲存成功，name=\(pill.name), category=\(pill.category)")
                        } catch {
                            print("儲存編輯藥物失敗: \(error)")
                        }
                        
                        // 更新通知設定
                        if enableReminder {
                            NotificationManager.shared.scheduleNotificationForPill(pill)
                        } else {
                            NotificationManager.shared.removeNotification(for: pill)
                        }
                        
                        WidgetCenter.shared.reloadAllTimelines()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showReminderTimePicker) {
            ReminderTimePickerView(reminderTime: $reminderTime, isPresented: $showReminderTimePicker)
        }
    }
}

// MARK: - 提醒時間選擇器視圖
struct ReminderTimePickerView: View {
    @Binding var reminderTime: Date
    @Binding var isPresented: Bool
    
    var body: some View {
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
                    Button("取消") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("確定") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
