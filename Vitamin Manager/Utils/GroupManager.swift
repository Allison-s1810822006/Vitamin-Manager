import SwiftUI
import SwiftDate
import WidgetKit

// MARK: - App Group 管理
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