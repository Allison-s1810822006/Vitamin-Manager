import SwiftUI

extension Color {
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hexString.count {
        case 8: // RRGGBBAA
            (r, g, b, a) = ((int >> 24) & 0xff, (int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
        case 6: // RRGGBB
            (r, g, b, a) = ((int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff, 0xff)
        case 3: // RGB (12-bit)
            (r, g, b, a) = (((int >> 8) & 0xf) * 17, ((int >> 4) & 0xf) * 17, (int & 0xf) * 17, 0xff)
        default:
            (r, g, b, a) = (0, 0, 0, 0xff)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

struct WelcomeView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#66AD89").opacity(0.25), Color(hex: "#66AD89").opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "pills.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(Color(hex: "#66AD89"))
                VStack(spacing: 8) {
                    Text("歡迎使用 維他命管家")
                        .font(.largeTitle).bold()
                    Text("幫助你紀錄每日用藥、提醒時間，還能快速查看今日進度。")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
                Button(action: onContinue) {
                    Text("開始使用")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#66AD89"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
