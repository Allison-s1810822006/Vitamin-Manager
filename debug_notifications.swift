// 通知除錯檢查程式碼
import UserNotifications
import Foundation

// 檢查通知權限狀態
UNUserNotificationCenter.current().getNotificationSettings { settings in
    print("通知權限狀態: \(settings.authorizationStatus)")
    print("Alert 設定: \(settings.alertSetting)")
    print("Sound 設定: \(settings.soundSetting)")
    print("Badge 設定: \(settings.badgeSetting)")
}

// 檢查已排程的通知
UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
    print("已排程的通知數量: \(requests.count)")
    for request in requests {
        print("通知ID: \(request.identifier)")
        if let trigger = request.trigger as? UNCalendarNotificationTrigger {
            print("觸發時間: \(trigger.dateComponents)")
        }
    }
}