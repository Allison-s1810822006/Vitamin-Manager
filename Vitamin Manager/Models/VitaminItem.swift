import SwiftUI
import SwiftData

// MARK: - 維他命項目資料模型
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
