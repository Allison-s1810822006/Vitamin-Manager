import SwiftUI
import SwiftData
import Foundation

// 測試 SwiftData 連接的獨立腳本
func testSwiftDataConnection() {
    print("🔍 開始測試 SwiftData 連接...")
    
    do {
        // 測試 1: 檢查 App Groups 路徑
        let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.xfw.Vitamin-Manager"
        )
        
        if let appGroupURL = appGroupURL {
            print("✅ App Groups 路徑可訪問: \(appGroupURL)")
            
            // 檢查目錄是否存在且可寫
            let isWritable = FileManager.default.isWritableFile(atPath: appGroupURL.path)
            print("📝 目錄可寫: \(isWritable)")
        } else {
            print("❌ 無法訪問 App Groups 路徑")
        }
        
        // 測試 2: 創建 Schema
        let schema = Schema([VitaminItem.self])
        print("✅ Schema 創建成功")
        
        // 測試 3: 嘗試創建內存容器
        let memoryConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let memoryContainer = try ModelContainer(for: schema, configurations: [memoryConfig])
        print("✅ 內存容器創建成功")
        
        // 測試 4: 嘗試創建持久化容器
        if let appGroupURL = appGroupURL {
            let dbURL = appGroupURL.appendingPathComponent("VitaminManager.sqlite")
            let persistentConfig = ModelConfiguration(
                schema: schema,
                url: dbURL,
                allowsSave: true
            )
            let persistentContainer = try ModelContainer(for: schema, configurations: [persistentConfig])
            print("✅ 持久化容器創建成功")
        }
        
        print("🎉 所有測試通過！")
        
    } catch {
        print("❌ 測試失敗: \(error)")
        
        // 詳細錯誤分析
        if let swiftDataError = error as? any Error {
            print("錯誤類型: \(type(of: swiftDataError))")
            print("錯誤描述: \(swiftDataError.localizedDescription)")
        }
    }
}

// 在 ContentView 中調用此函數進行調試