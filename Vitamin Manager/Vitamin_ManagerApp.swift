import SwiftUI
import SwiftData
import UserNotifications

@main
struct Vitamin_ManagerApp: App {
    var container: ModelContainer
    
    init() {
        do {
            // 使用最簡單的本地資料庫配置
            container = try ModelContainer(for: VitaminItem.self)
            print("✅ 成功初始化 ModelContainer")
        } catch {
            print("❌ ModelContainer 初始化失敗: \(error)")
            // 如果失敗，使用內存模式作為備用
            do {
                container = try ModelContainer(
                    for: VitaminItem.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
                print("⚠️ 已降級到內存模式")
            } catch {
                fatalError("💥 完全無法初始化 ModelContainer: \(error)")
            }
        }
        
        // 初始化通知管理器
        setupNotifications()
        
        // 舊資料色碼遷移
        migrateLegacyColors()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // 當應用程式出現時重新安排通知
                    rescheduleNotificationsIfNeeded()
                }
        }
        .modelContainer(container)
    }
    
    // MARK: - 通知設置
    private func setupNotifications() {
        // 請求通知權限
        NotificationManager.shared.requestNotificationPermission()
        
        // 設定通知代理
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    // MARK: - 重新安排通知
    private func rescheduleNotificationsIfNeeded() {
        // 獲取所有藥物數據並重新安排通知
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                let context = container.mainContext
                let descriptor = FetchDescriptor<VitaminItem>()
                let pills = try context.fetch(descriptor)
                
                // 重新安排所有通知
                NotificationManager.shared.rescheduleAllNotifications(for: pills)
            } catch {
                print("❌ 無法獲取藥物數據以重新安排通知: \(error)")
            }
        }
    }
    
    // MARK: - 舊資料色碼遷移
    private func migrateLegacyColors() {
        let mapping: [String: String] = [
            "green": "#66AD89",
            "red": "#C76B6B",
            "orange": "#E0A15F",
            "yellow": "#E6D37A",
            "blue": "#6B9FC7",
            "purple": "#9A7BC7",
            "pink": "#D88AA8",
            "gray": "#9AA7A0"
        ]
        do {
            let context = container.mainContext
            var descriptor = FetchDescriptor<VitaminItem>()
            descriptor.fetchLimit = 10000
            let items = try context.fetch(descriptor)
            var changed = false
            for item in items {
                let key = item.colorHex.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if let newHex = mapping[key] {
                    if item.colorHex != newHex {
                        item.colorHex = newHex
                        changed = true
                    }
                }
            }
            if changed {
                try context.save()
                print("✅ 已完成舊資料色碼遷移")
            } else {
                print("ℹ️ 無需色碼遷移或已是最新")
            }
        } catch {
            print("❌ 色碼遷移失敗: \(error)")
        }
    }
}

// MARK: - 通知代理
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // 當應用程式在前景時收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 在前景顯示通知
        completionHandler([.banner, .sound, .badge])
    }
    
    // 當用戶點擊通知時
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let pillName = userInfo["pillName"] as? String {
            print("🔔 用戶點擊了 \(pillName) 的提醒通知")
            // 這裡可以添加更多操作，比如直接跳轉到該藥物的詳細頁面
        }
        
        completionHandler()
    }
}

