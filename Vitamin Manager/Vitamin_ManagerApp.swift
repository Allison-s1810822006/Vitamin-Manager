import SwiftUI
import SwiftData

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
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
