import SwiftUI
import SwiftData
import SwiftDate
import WidgetKit

// MARK: - 我的藥盒頁面
struct PillListView: View {
    @Query(sort: \VitaminItem.name) private var pills: [VitaminItem]
    @Environment(\.modelContext) private var context
    @State private var showAddSheet = false
    @State private var editingPill: VitaminItem? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                if pills.isEmpty {
                    ContentUnavailableView("藥盒是空的", systemImage: "pills.circle", description: Text("點擊右上角 + 新增"))
                } else {
                    List {
                        ForEach(pills) { pill in
                            PillRowView(pill: pill, onTake: { takePill(pill) })
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingPill = pill
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("我的藥盒")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddPillView()
            }
            .sheet(item: $editingPill) { pill in
                EditPillView(pill: pill)
            }
        }
    }

    func takePill(_ pill: VitaminItem) {
        withAnimation {
            pill.lastTakenDate = Date()
        }
        
        // 更新 App Groups 數據
        GroupManager.updateLog(pillName: pill.name)
        
        // 強制同步數據
        if let defaults = UserDefaults(suiteName: GroupManager.suiteName) {
            defaults.synchronize()
        }
        
        // 重新載入 Widget 時間線
        WidgetCenter.shared.reloadAllTimelines()
        
        // 添加輕微延遲確保數據已寫入
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            WidgetCenter.shared.reloadTimelines(ofKind: "VitaminWidget")
        }
    }
    
    func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets { 
                let pill = pills[index]
                // 移除該藥物的通知
                NotificationManager.shared.removeNotification(for: pill)
                context.delete(pill) 
            }
        }
    }
}
