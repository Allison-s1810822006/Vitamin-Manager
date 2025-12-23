import SwiftUI

struct AppIconGeneratorView: View {
    private let iconSize: CGFloat = 1024
    private let bgColor = Color(hex: "#86c888")

    var body: some View {
        ZStack {
            bgColor
                .frame(width: iconSize, height: iconSize)
                .overlay(
                    // Centered symbol
                    Image(systemName: "pills.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .frame(width: iconSize * 0.5, height: iconSize * 0.5)
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 220, style: .continuous))
        .overlay(
            VStack(spacing: 8) {
                Text("App Icon 生成器 (1024x1024)")
                    .font(.headline)
                    .padding(.top)
                Text("說明：在預覽中選擇 1x 尺寸，或在裝置上截圖後裁切成 1024x1024 PNG，拖入 Assets 的 AppIcon (Single Size)。")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            .padding(), alignment: .top
        )
    }
}

// Minimal hex initializer so this file is self-contained
private extension Color {
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hexString.count {
        case 8: (r, g, b, a) = ((int >> 24) & 0xff, (int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
        case 6: (r, g, b, a) = ((int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff, 0xff)
        case 3: (r, g, b, a) = (((int >> 8) & 0xf) * 17, ((int >> 4) & 0xf) * 17, (int & 0xf) * 17, 0xff)
        default: (r, g, b, a) = (0, 0, 0, 0xff)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

#Preview("AppIcon 1024x1024") {
    AppIconGeneratorView()
        .previewLayout(.sizeThatFits)
}
