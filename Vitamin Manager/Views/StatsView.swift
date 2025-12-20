import SwiftUI
import SwiftData
import SwiftDate

// MARK: - 統計頁面
struct StatsView: View {
    @Query private var pills: [VitaminItem]
    
    var progress: Double {
        guard !pills.isEmpty else {
            GroupManager.setTodayProgress(0)
            return 0
        }
        
        let taken = pills.filter { pill in
            guard let lastTaken = pill.lastTakenDate else { return false }
            return DateInRegion(lastTaken, region: .current).isToday
        }.count
        
        let progressValue = Double(taken) / Double(pills.count)
        GroupManager.setTodayProgress(progressValue)
        
        return progressValue
    }
    
    var weekStats: ([String], [Int]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var labels: [String] = []
        var counts: [Int] = []
        for i in (0...6).reversed() {
            let day = calendar.date(byAdding: .day, value: -i, to: today)!
            let label = dateFormatter.shortWeekdaySymbols[calendar.component(.weekday, from: day)-1]
            labels.append(label)
            let count = pills.filter { pill in
                guard let taken = pill.lastTakenDate else { return false }
                return calendar.isDate(taken, inSameDayAs: day)
            }.count
            counts.append(count)
        }
        return (labels, counts)
    }
    
    // 分類統計數據
    var categoryStats: [CategoryStat] {
        let categories = ["維他命", "礦物質", "保健食品", "處方藥", "中藥", "一般"]
        
        return categories.compactMap { category in
            let categoryPills = pills.filter { $0.category == category }
            guard !categoryPills.isEmpty else { return nil }
            
            let todayTaken = categoryPills.filter { pill in
                guard let lastTaken = pill.lastTakenDate else { return false }
                return DateInRegion(lastTaken, region: .current).isToday
            }.count
            
            // 使用該分類中藥物的主要顏色（取最常用的顏色）
            let colorCounts = Dictionary(grouping: categoryPills) { $0.colorHex }
                .mapValues { $0.count }
            let mostCommonColorHex = colorCounts.max { $0.value < $1.value }?.key ?? "blue"
            
            // 創建一個臨時的VitaminItem來取得顏色
            let tempPill = VitaminItem(name: "", colorHex: mostCommonColorHex)
            let categoryColor = tempPill.color
            
            return CategoryStat(
                name: category,
                total: categoryPills.count,
                todayTaken: todayTaken,
                color: categoryColor
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // 今日進度圓環
                    ZStack {
                        Circle().stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        Circle().trim(from: 0, to: progress)
                            .stroke(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .rotationEffect(.degrees(-90)).animation(.easeOut, value: progress)
                        VStack {
                            Text("\(Int(progress * 100))%").font(.system(size: 50, weight: .bold, design: .rounded))
                            Text("今日達成").font(.caption).foregroundStyle(.secondary)
                        }
                    }.frame(width: 200, height: 200).padding(.top, 40)
                    
                    // 總覽統計
                    VStack(spacing: 15) {
                        StatRow(icon: "pill.fill", color: Color.blue, title: "總藥物數", value: "\(pills.count) 種")
                        StatRow(icon: "checkmark.circle.fill", color: Color.green, title: "今日已服", value: "\(Int(progress * Double(pills.count))) 次")
                        StatRow(icon: "list.bullet", color: Color.purple, title: "分類數量", value: "\(categoryStats.count) 類")
                    }
                    .padding().frame(maxWidth: .infinity).background(Color.white).cornerRadius(16).padding(.horizontal, 16)
                    
                    // 分類詳細統計
                    if !categoryStats.isEmpty {
                        CategoryStatsView(categoryStats: categoryStats)
                            .padding(.horizontal, 16)
                    }
                    
                    // 一週統計圖表
                    let (labels, counts) = weekStats
                    VStack {
                        BarChartView(data: counts, labels: labels, maxValue: counts.max() ?? 1)
                    }.padding().frame(maxWidth: .infinity).background(Color.white).cornerRadius(16).padding(.horizontal, 16)
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("統計")
        }
    }
}

// MARK: - 統計行視圖
struct StatRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).frame(width: 24, height: 24)
            VStack(alignment: .leading) {
                Text(title).font(.subheadline).foregroundColor(.secondary)
                Text(value).font(.headline)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 分類統計視圖
struct CategoryStatsView: View {
    let categoryStats: [CategoryStat]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
                Text("分類統計")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(categoryStats, id: \.name) { stat in
                    CategoryRowView(stat: stat)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}

// MARK: - 分類行視圖
struct CategoryRowView: View {
    let stat: CategoryStat
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(stat.color)
                        .frame(width: 12, height: 12)
                    Text(stat.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(stat.todayTaken)/\(stat.total)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(stat.color)
                    Text("今日/總數")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // 進度條
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(stat.color)
                        .frame(width: geometry.size.width * stat.progress, height: 6)
                        .cornerRadius(3)
                        .animation(.easeOut(duration: 0.5), value: stat.progress)
                }
            }
            .frame(height: 6)
        }
    }
}

