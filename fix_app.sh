#!/bin/bash

# 維他命管家 App 重啟腳本
echo "🔄 開始修復維他命管家 App..."

# 1. 殺死所有相關進程
echo "📱 關閉模擬器中的 App..."
xcrun simctl terminate booted com.yourcompany.Vitamin-Manager 2>/dev/null || true

# 2. 清理 App Groups 緩存
echo "🧹 清理 App Groups 緩存..."
CONTAINER_PATH=$(xcrun simctl get_app_container booted com.yourcompany.Vitamin-Manager groups 2>/dev/null)
if [ -n "$CONTAINER_PATH" ]; then
    rm -rf "$CONTAINER_PATH/group.xfw.Vitamin-Manager/VitaminManager.sqlite"* 2>/dev/null || true
    echo "   已清理資料庫檔案"
fi

# 3. 重新安裝 App
echo "🚀 重新安裝 App..."
cd "$(dirname "$0")"
xcodebuild -project "Vitamin Manager.xcodeproj" -scheme "Vitamin Manager" -destination 'platform=iOS Simulator,name=iPhone 15 Pro' clean build 2>/dev/null

# 4. 啟動 App
echo "📱 啟動 App..."
xcrun simctl launch booted com.yourcompany.Vitamin-Manager

echo "✅ 修復完成！請查看模擬器中的 App 是否正常運行"