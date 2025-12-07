import SwiftUI
import SwiftData

@main
struct Vitamin_ManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // ⚠️ 關鍵修正：這裡必須改成 VitaminItem.self
        // 這樣才能跟 ContentView 裡面的新模型對上
        .modelContainer(for: VitaminItem.self)
    }
}
