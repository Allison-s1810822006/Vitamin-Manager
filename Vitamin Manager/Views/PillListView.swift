import SwiftUI
import SwiftData
import SwiftDate
import WidgetKit

// 篩選選項
private enum PillFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case incomplete = "未服用"
    case completed = "已服用"
    var id: Self { self }
}

// MARK: - 我的藥盒頁面
struct PillListView: View {
    @Query(sort: \VitaminItem.name) private var pills: [VitaminItem]
    @Environment(\.modelContext) private var context
    @State private var showAddSheet = false
    @State private var editingPill: VitaminItem? = nil
    @State private var selectedFilter: PillFilter = .all
    @State private var searchText: String = ""

    // 依今天是否已服用分組
    private var incompleteToday: [VitaminItem] {
        return pills.filter { pill in
            guard let last = pill.lastTakenDate else { return true }
            return !DateInRegion(last, region: .current).isToday
        }
    }
    
    private var completedToday: [VitaminItem] {
        return pills.filter { pill in
            guard let last = pill.lastTakenDate else { return false }
            return DateInRegion(last, region: .current).isToday
        }
    }
    
    private var filteredPills: [VitaminItem] {
        switch selectedFilter {
        case .all:
            return pills
        case .incomplete:
            return incompleteToday
        case .completed:
            return completedToday
        }
    }
    
    // 依搜尋字串再次過濾
    private var searchedPills: [VitaminItem] {
        let base = filteredPills
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return base }
        return base.filter { pill in
            pill.name.localizedCaseInsensitiveContains(keyword)
            || pill.category.localizedCaseInsensitiveContains(keyword)
            || pill.medicationTime.localizedCaseInsensitiveContains(keyword)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                if pills.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "pills.circle")
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(Color(red: 0.4, green: 0.678, blue: 0.537)) // #66AD89
                            .font(.system(size: 48, weight: .regular))
                        Text("藥盒是空的")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("點擊右上角 + 新增")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            EmptyView()
                        } header: {
                            Picker("篩選", selection: $selectedFilter) {
                                ForEach(PillFilter.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        
                        if selectedFilter == .all {
                            if !incompleteToday.isEmpty {
                                Section(header: Text("未完成")) {
                                    ForEach(searchText.isEmpty ? incompleteToday : incompleteToday.filter { pill in
                                        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                                        return pill.name.localizedCaseInsensitiveContains(keyword)
                                            || pill.category.localizedCaseInsensitiveContains(keyword)
                                            || pill.medicationTime.localizedCaseInsensitiveContains(keyword)
                                    }) { pill in
                                        PillRowView(pill: pill, onTake: { takePill(pill) })
                                            .contentShape(Rectangle())
                                            .onTapGesture { editingPill = pill }
                                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                            .listRowBackground(Color.clear)
                                            .listRowSeparator(.hidden)
                                    }
                                    .onDelete(perform: deleteItems)
                                }
                            }
                            if !completedToday.isEmpty {
                                Section(header: Text("已完成")) {
                                    ForEach(searchText.isEmpty ? completedToday : completedToday.filter { pill in
                                        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                                        return pill.name.localizedCaseInsensitiveContains(keyword)
                                            || pill.category.localizedCaseInsensitiveContains(keyword)
                                            || pill.medicationTime.localizedCaseInsensitiveContains(keyword)
                                    }) { pill in
                                        PillRowView(pill: pill, onTake: { takePill(pill) })
                                            .contentShape(Rectangle())
                                            .onTapGesture { editingPill = pill }
                                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                            .listRowBackground(Color.clear)
                                            .listRowSeparator(.hidden)
                                    }
                                    .onDelete(perform: deleteItems)
                                }
                            }
                        } else {
                            ForEach(searchedPills) { pill in
                                PillRowView(pill: pill, onTake: { takePill(pill) })
                                    .contentShape(Rectangle())
                                    .onTapGesture { editingPill = pill }
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: deleteItems)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("我的藥盒")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "搜尋藥物或分類")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { showAddSheet = true }) {
                            Image(systemName: "plus.circle.fill").font(.title2)
                        }
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

