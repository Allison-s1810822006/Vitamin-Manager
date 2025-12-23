import SwiftUI
import SwiftData
import WidgetKit

// MARK: - 設定頁面
struct SettingsView: View {
    @AppStorage("enableCloud") private var enableCloud = false
    @Query private var pills: [VitaminItem]
    @Environment(\.modelContext) private var context
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("資料管理") {
                    Button(action: { clearAllData() }) {
                        Label { Text("清除所有資料").foregroundStyle(.black) } icon: {
                            Image(systemName: "trash.fill").foregroundStyle(.red)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "pills.circle.fill").font(.largeTitle).foregroundStyle(AppColor.green.opacity(0.5))
                            Text("維他命管家 v1.0.0").font(.caption).bold()
                            Text("Designed by Allison").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }.listRowBackground(Color.clear)
            }
            .navigationTitle("設定")
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
    
    // MARK: - 清除資料功能
    private func clearAllData() {
        showDeleteConfirmation = true
    }
    
    private func performClearAllData() {
        // 清除所有通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🗑️ 已清除所有提醒通知")
        
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

