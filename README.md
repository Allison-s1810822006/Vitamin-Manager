# 💊 Vitamin Manager（維他命管家）

一款 **極簡的一頁式 iOS App**，協助使用者記錄每日維他命／保健食品的服用狀態，並透過清楚的視覺化介面，快速掌握「今日是否完成服用」。

本專案為課程期末作業，著重於 **SwiftUI 畫面設計、SwiftData 本機資料管理、SwiftDate 時間處理、App Group 與 Widget / 通知整合**。

---

# 🏗️ 系統架構（System Architecture）

> 本系統採用 SwiftUI 作為使用者介面，資料以 SwiftData 儲存在本機。  
> 使用者操作畫面後，相關資料會同步更新至資料層，並由本地通知模組負責服藥提醒。  
> Widget 透過 App Group 讀取共享資料，僅進行顯示，不直接修改資料。
> ❌ 未啟用 iCloud / CloudKit（因專案穩定性考量）

```
flowchart TB
  subgraph App[iOS App]
    UI[SwiftUI Views]
    SD[SwiftData (Local)]
    NM[NotificationManager]
    GM[App Group Manager]
    UI --> SD
    UI --> NM
    SD --> GM
  end

  subgraph Widget[Widget Extension]
    W[WidgetKit]
  end

  GM --> W
```

---

# 📁 專案結構（Project Structure）

```
VitaminManager
├── README.md
├── assets/
│   ├── screenshots/
│   │   ├── pill-list.png
│   │   ├── stats-overview.png
│   │   ├── stats-category.png
│   │   ├── weekly-chart.png
│   │   └── settings.png
│   ├── widget/
│   │   ├── home-widget.png
│   │   └── notification.png
│   └── demo/
│       └── demo.mov
│
├── Models/
│   └── VitaminItem.swift
│
├── Views/
│   ├── PillListView.swift
│   ├── StatsView.swift
│   ├── SettingsView.swift
│   └── Components/
│
├── Utils/
│   ├── NotificationManager.swift
│   ├── GroupManager.swift
│   └── Helpers.swift
│
├── VitaminWidgetExtension/
│   ├── VitaminWidget.swift
│   ├── AppIntent.swift
│   └── VitaminWidgetLiveActivity.swift
│
└── VitaminManagerApp.swift

```
---

# 📌 專案特色

- 一頁式設計，操作直覺、學習成本低  
- 使用 **SwiftData（Local Store）** 儲存服藥資料  
- 使用 **SwiftDate（第三方套件）** 顯示相對時間  
- 支援 **服藥提醒通知（Local Notification）**  
- 使用 **App Group** 與 Widget 共用資料  
- 提供 **桌面 Widget** 顯示最新服藥狀態  
- 內建 **統計視覺化（完成率、分類、一週紀錄）**

---

# 🧩 系統功能說明

### 1️⃣ 我的藥盒
- 顯示所有已建立的維他命／保健食品
- 每筆項目包含：
  - 名稱
  - 分類（維他命 / 保健食品）
  - 服藥時間（飯前 / 飯後）
  - 提醒時間
  - 每次服用顆數
- 點擊「已服用」即可完成紀錄

---

### 2️⃣ 統計頁面
- 今日完成率（圓環進度）
- 總藥物數量
- 今日已服用次數
- 分類統計（今日 / 總數）
- 一週服藥紀錄視覺化

---

### 3️⃣ 設定頁面
- 清除所有資料
- 顯示 App 版本資訊

---

### 4️⃣ 服藥提醒通知
- 依設定時間推送提醒
- 通知內容包含藥品名稱與服藥時間

---

### 5️⃣ Widget
- 顯示最近一次服藥紀錄
- 顯示今日完成率
- 與 App 透過 App Group 共用資料

---

## 📱 App Screenshots

### 我的藥盒（清單與已服用狀態）
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-25 at 22 56 09" src="https://github.com/user-attachments/assets/63fa95ef-12dc-4fa9-9c01-1f466e9823d5" />

### 今日統計（完成率）
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-25 at 22 57 42" src="https://github.com/user-attachments/assets/629484a4-8210-4cac-8a31-964217031f1f" />


### 分類統計（維他命 / 保健食品）
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-25 at 22 57 42" src="https://github.com/user-attachments/assets/21f3195e-4467-4925-9fc5-c2d14d75258c" />


### 一週服藥紀錄
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-25 at 22 57 48" src="https://github.com/user-attachments/assets/fb71cd2e-7e81-4f2a-a8f4-57ebb0ba6b9f" />


### 設定頁面
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-25 at 22 57 52" src="https://github.com/user-attachments/assets/bd0d75b2-78aa-4a8e-8144-ed9ca6dc373b" />


---

## 🧩 Widget & Notification

### 桌面 Widget
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-25 at 22 59 41" src="https://github.com/user-attachments/assets/b2749d18-0d5f-493d-9c16-abcbd391b2f8" />


### 服藥提醒通知
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-25 at 23 01 20" src="https://github.com/user-attachments/assets/287e9c22-cb34-4d98-ba99-987933af8adf" />
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-25 at 22 57 01" src="https://github.com/user-attachments/assets/525f6c17-1a41-4708-9464-767970ba3249" />
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-25 at 22 57 04" src="https://github.com/user-attachments/assets/86f0b703-9c76-467d-9f54-5a2dfcababdf" />



---

## 🎥 Demo（影片操作示範）
https://github.com/user-attachments/assets/8cf485db-db8c-44bc-93e0-f64e5275052b



---

