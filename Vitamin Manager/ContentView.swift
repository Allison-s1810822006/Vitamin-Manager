import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            PillListView()
                .tabItem {
                    Image(systemName: "pills.circle")
                    Text("我的藥盒")
                }
            
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("統計")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("設定")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: VitaminItem.self, inMemory: true)
}
