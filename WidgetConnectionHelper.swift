import Foundation
import WidgetKit

/// Widget 連接診斷和修復工具
class WidgetConnectionHelper {
    
    private static let appGroupID = "group.xfw.Vitamin-Manager"
    
    /// 診斷 Widget 連接狀態
    static func diagnoseConnection() -> (isValid: Bool, error: String?) {
        // 檢查 App Groups 是否可用
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return (false, "無法建立 App Groups 連接：\(appGroupID)")
        }
        
        // 測試寫入/讀取
        let testKey = "connection_test"
        let testValue = "test_\(Date().timeIntervalSince1970)"
        
        defaults.set(testValue, forKey: testKey)
        let success = defaults.synchronize()
        
        if !success {
            return (false, "UserDefaults 同步失敗")
        }
        
        let readValue = defaults.string(forKey: testKey)
        defaults.removeObject(forKey: testKey)
        
        if readValue != testValue {
            return (false, "讀取/寫入測試失敗")
        }
        
        return (true, nil)
    }
    
    /// 重新建立 Widget 連接
    static func reestablishConnection() {
        // 強制重新同步 UserDefaults
        if let defaults = UserDefaults(suiteName: appGroupID) {
            defaults.synchronize()
        }
        
        // 等待一段時間後重新載入 Widget
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        print("🔄 已嘗試重新建立 Widget 連接")
    }
    
    /// 緊急重置 Widget 數據
    static func emergencyReset() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            print("❌ 緊急重置失敗：無法訪問 App Groups")
            return
        }
        
        // 清除所有相關數據
        ["lastAction", "lastActionTime", "todayProgress"].forEach { key in
            defaults.removeObject(forKey: key)
        }
        
        defaults.synchronize()
        
        // 重新載入 Widget
        WidgetCenter.shared.reloadAllTimelines()
        
        print("🆘 Widget 緊急重置完成")
    }
    
    /// 檢查 Widget 狀態
    static func checkWidgetStatus() {
        WidgetCenter.shared.getCurrentConfigurations { result in
            switch result {
            case .success(let configurations):
                print("📱 當前 Widget 配置數量：\(configurations.count)")
                for config in configurations {
                    print("   - \(config.displayName): \(config.kind)")
                }
            case .failure(let error):
                print("❌ 無法獲取 Widget 配置：\(error.localizedDescription)")
            }
        }
    }
}