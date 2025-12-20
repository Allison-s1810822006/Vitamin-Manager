import Foundation
import SwiftUI
import SwiftData

// MARK: - 分類統計數據結構
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

// MARK: - 日期格式設定工具
let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_TW")
    formatter.dateFormat = "yyyy年MM月dd日 EEEE HH:mm"
    return formatter
}()

let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_TW")
    formatter.timeStyle = .short
    return formatter
}()