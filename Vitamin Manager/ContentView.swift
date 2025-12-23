import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("shouldShowWelcome") private var shouldShowWelcome: Bool = true

    var body: some View {
        ZStack {
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
        .onAppear { shouldShowWelcome = true }
        .fullScreenCover(isPresented: $shouldShowWelcome) {
            WelcomeView(onContinue: { shouldShowWelcome = false })
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: VitaminItem.self, inMemory: true)
}
