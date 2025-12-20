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
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-20 at 19 51 28" src="https://github.com/user-attachments/assets/ff8c77ee-eaa0-4987-aa1e-4de6fa4984f1" />

### 今日統計（完成率）
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-20 at 19 51 57" src="https://github.com/user-attachments/assets/a0dc9559-77a2-4739-b734-cb768c9274f1" />

### 分類統計（維他命 / 保健食品）
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-20 at 19 51 57" src="https://github.com/user-attachments/assets/a0dc9559-77a2-4739-b734-cb768c9274f1" />

### 一週服藥紀錄
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-20 at 19 52 00" src="https://github.com/user-attachments/assets/4f2a583a-7c40-4649-850d-ae75c3f9cfaa" />

### 設定頁面
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-20 at 19 52 04" src="https://github.com/user-attachments/assets/b5841f56-cdac-4baa-910c-65907269b259" />


---

## 🧩 Widget & Notification

### 桌面 Widget
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-20 at 19 52 10" src="https://github.com/user-attachments/assets/e09634fb-51ce-4963-8029-1f35fe6f11a1" />


### 服藥提醒通知
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-20 at 19 51 03" src="https://github.com/user-attachments/assets/62bf882e-420b-4627-a311-92fc0df4b24d" />
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-20 at 19 51 05" src="https://github.com/user-attachments/assets/1ef38d85-4d21-49b4-b4d8-b76a13659b18" />
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-20 at 19 51 07" src="https://github.com/user-attachments/assets/bef13217-564a-408f-ba07-974595dfebf1" />
<img width="201" height="437" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-20 at 19 52 23" src="https://github.com/user-attachments/assets/a490f99b-5e5e-4fc9-8c5a-fbada5b16ea1" />


---

## 🎥 Demo（影片操作示範）
https://github.com/user-attachments/assets/ea050126-8f20-4e7b-b99e-da47217b9a87

---

