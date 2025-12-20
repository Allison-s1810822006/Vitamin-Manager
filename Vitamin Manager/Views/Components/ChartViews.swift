import SwiftUI
import SwiftData
import SwiftDate

// MARK: - 圓餅圖
struct PieChartView: View {
    let categoryStats: [CategoryStat]
    
    var body: some View {
        ZStack {
            ForEach(Array(categoryStats.enumerated()), id: \.offset) { index, stat in
                PieSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    color: stat.color
                )
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func startAngle(for index: Int) -> Angle {
        let totalCount = categoryStats.reduce(0) { $0 + $1.total }
        guard totalCount > 0 else { return .degrees(0) }
        
        let previousCount = categoryStats.prefix(index).reduce(0) { $0 + $1.total }
        return .degrees(Double(previousCount) / Double(totalCount) * 360 - 90)
    }
    
    private func endAngle(for index: Int) -> Angle {
        let totalCount = categoryStats.reduce(0) { $0 + $1.total }
        guard totalCount > 0 else { return .degrees(0) }
        
        let currentCount = categoryStats.prefix(index + 1).reduce(0) { $0 + $1.total }
        return .degrees(Double(currentCount) / Double(totalCount) * 360 - 90)
    }
}

// MARK: - 圓餅圖扇形
struct PieSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: 60, y: 60) // 假設圖表大小為120x120
            let radius: CGFloat = 50
            
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(color)
    }
}

// MARK: - 長條圖
struct BarChartView: View {
    let data: [Int]
    let labels: [String]
    let maxValue: Int
    var body: some View {
        VStack(alignment: .leading) {
            Text("一週服藥紀錄").font(.headline).padding(.bottom, 4)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.offset) { i, value in
                    VStack {
                        ZStack(alignment: .bottom) {
                            Capsule().frame(width: 18, height: 80).foregroundColor(Color.gray.opacity(0.15))
                            Capsule().frame(width: 18, height: maxValue == 0 ? 0 : CGFloat(value) / CGFloat(maxValue) * 80).foregroundColor(.blue)
                        }
                        Text(labels[i]).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }.frame(height: 100)
        }
    }
}

// 注意：CategoryStatsView 和 CategoryRowView 已經在 StatsView.swift 中定義
// 為了避免重複定義，這裡移除了這些視圖
