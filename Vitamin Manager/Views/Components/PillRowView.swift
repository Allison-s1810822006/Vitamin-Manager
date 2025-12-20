import SwiftUI
import SwiftDate

// MARK: - 藥物行視圖
struct PillRowView: View {
    let pill: VitaminItem
    let onTake: () -> Void
    
    var isOverdue: Bool {
        guard let date = pill.lastTakenDate else { return true }
        return DateInRegion() > (DateInRegion(date, region: .current) + 1.days)
    }
    
    var isTakenToday: Bool {
        guard let lastTaken = pill.lastTakenDate else { return false }
        return DateInRegion(lastTaken, region: .current).isToday
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // 藥物圖片或圖示
            if let data = pill.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(pill.color, lineWidth: 3)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(pill.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle().stroke(pill.color, lineWidth: 3)
                        )
                    Image(systemName: "pills.fill")
                        .foregroundStyle(pill.color)
                        .font(.title2)
                }
            }
            
            // 藥物資訊
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(pill.name).font(.headline)
                    Spacer()
                    // 分類標籤
                    Text(pill.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(pill.color.opacity(0.1))
                        .foregroundStyle(pill.color)
                        .clipShape(Capsule())
                }
                
                if !pill.medicationTime.isEmpty {
                    Text("服藥時間：\(pill.medicationTime)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // 提醒時間顯示
                if pill.enableReminder, let reminderTime = pill.reminderTime {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.badge")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("提醒時間：\(timeFormatter.string(from: reminderTime))")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                Text("每次 \(pill.quantity) 顆")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let date = pill.lastTakenDate {
                    HStack(spacing: 4) {
                        Image(systemName: isOverdue ? "exclamationmark.circle.fill" : "clock")
                        Text(dateFormatter.string(from: date))
                    }
                    .font(.caption)
                    .bold()
                    .foregroundStyle(isOverdue ? .red : .secondary)
                } else {
                    Text("尚未服用")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // 服藥按鈕
            Button(action: onTake) {
                HStack(spacing: 6) {
                    if isTakenToday {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                    }
                    Text(isTakenToday ? "已服用" : "吃藥")
                        .bold()
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(isTakenToday ? pill.color : Color.gray.opacity(0.3))
            .foregroundStyle(isTakenToday ? .white : .black)
            .clipShape(Capsule())
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
