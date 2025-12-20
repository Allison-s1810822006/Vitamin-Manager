import Foundation
import WidgetKit
import UserNotifications

// MARK: - 通知管理
class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // MARK: - 通知權限請求
    func requestNotificationPermission() {
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
    
    // MARK: - 通知排程 (統一方法)
    func scheduleNotificationForPill(_ pill: VitaminItem) {
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
    
    // MARK: - 重新安排所有通知
    func rescheduleAllNotifications(for pills: [VitaminItem]) {
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
    
    // 移除特定藥物的通知
    func removeNotification(for pill: VitaminItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["pill_\(pill.name)_reminder"])
        print("🗑️ 已移除 \(pill.name) 的提醒")
    }
}


