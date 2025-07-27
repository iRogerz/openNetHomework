# 即時賽事賠率監控系統

## 專案概述

這是一個 iOS 應用程式，用於即時監控賽事賠率變化。系統採用 WebSocket 連接來接收即時數據，並使用 MVVM 架構模式來管理狀態和 UI 更新。

### 主要功能

- **即時賠率監控**：透過 WebSocket 即時接收賠率更新
- **比賽列表顯示**：顯示所有比賽的基本資訊和當前賠率
- **連接狀態指示**：顯示 WebSocket 連接狀態（已連線、已斷線、重連中）
- **動畫效果**：當賠率變化時，對應的比賽項目會有閃爍動畫提示
- **模擬資料**：使用本地 JSON 檔案提供模擬資料，方便開發和測試

## 專案架構

```
openNetHomeWork/
├── AppDelegate.swift              # 應用程式入口點，處理應用程式生命週期
├── SceneDelegate.swift            # 場景委託，管理 UI 生命週期和主視窗設置
├── Model/                        # 數據模型層
│   ├── Match.swift               # 賽事模型，包含比賽ID、隊伍名稱、開始時間
│   └── Odds.swift                # 賠率模型，包含比賽ID和各隊伍賠率
├── View/                         # 視圖層
│   └── MatchListViewController.swift  # 賽事列表視圖控制器，負責UI顯示和互動
├── ViewModel/                    # 視圖模型層
│   └── MatchListViewModel.swift  # 賽事列表視圖模型，處理業務邏輯和資料管理
├── Service/                      # 服務層
│   ├── APIService.swift          # API 服務，提供資料獲取介面（模擬和真實實作）
│   └── WebSocketManager.swift    # WebSocket 連接管理，處理即時資料推送
└── Resource/                     # 資源文件
    └── mock_data.json           # 模擬數據，包含100場比賽和對應的賠率資料
```

## 技術特色

### Swift Concurrency / Combine 使用場景

#### **Swift Concurrency (async/await)**

- **API 資料獲取**：使用 `async/await` 處理非同步 API 呼叫

  ```swift
  func fetchInitialData() {
      Task {
          let matches = try await apiService.fetchMatches()
          let odds = try await apiService.fetchOdds()
          // 處理資料...
      }
  }
  ```

- **背景資料處理**：使用 `Task.detached` 在背景線程處理大量資料
  ```swift
  let processedData = await Task.detached(priority: .userInitiated) {
      let sortedMatches = matches.sorted { $0.startTime > $1.startTime }
      let oddsDict = Dictionary(uniqueKeysWithValues: odds.map { ($0.matchID, $0) })
      return (sortedMatches, oddsDict)
  }.value
  ```

#### **Combine 框架**

- **WebSocket 即時資料流**：使用 `PassthroughSubject` 推送即時賠率更新

  ```swift
  let oddsPublisher = PassthroughSubject<Odds, Never>()
  ```

- **UI 資料綁定**：使用 `@Published` 和 `sink` 實現響應式 UI 更新

  ```swift
  viewModel.$oddsDict
      .receive(on: DispatchQueue.main)
      .sink { [weak self] newOddsDict in
          // UI 更新邏輯
      }
  ```

- **批次處理優化**：使用 `.collect(.byTime())` 減少 UI 更新頻率
  ```swift
  .collect(.byTime(DispatchQueue.main, 0.2)) // 批次收集200ms內的更新
  ```

### 如何確保資料存取 Thread-Safe?

#### **@MainActor 確保主線程安全**

```swift
@MainActor
class MatchListViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var oddsDict: [Int: Odds] = [:]

    // 所有方法自動在主線程執行
    func updateData() {
        self.matches = newMatches // 自動在主線程
    }
}
```

#### **DispatchQueue.main 確保 UI 更新**

```swift
// 在背景線程處理資料
let processedData = await Task.detached { ... }.value

// 在主線程更新 UI
DispatchQueue.main.async {
    self.matches = processedData.0
    self.oddsDict = processedData.1
}
```

#### **Combine 的 Thread Safety**

```swift
webSocketService.oddsPublisher
    .receive(on: DispatchQueue.main) // 確保在主線程接收
    .sink { [weak self] odds in
        self?.oddsDict[odds.matchID] = odds // 在主線程更新
    }
```

#### **效能優化策略**

- **批次處理**：使用 `.collect(.byTime())` 減少更新頻率
- **背景處理**：大量資料處理在 background thread
- **記憶體管理**：使用 `[weak self]` 避免循環引用
- **訂閱管理**：使用 `cancellables` 管理訂閱生命週期

### UI 與 ViewModel 資料綁定方式

#### **UIKit + Combine 綁定**

```swift
// ViewModel 中的 @Published 屬性
@Published var matches: [Match] = []
@Published var oddsDict: [Int: Odds] = [:]

// ViewController 中的訂閱
viewModel.$matches
    .receive(on: DispatchQueue.main)
    .sink { [weak self] _ in
        self?.tableView.reloadData()
    }
    .store(in: &cancellables)

viewModel.$oddsDict
    .receive(on: DispatchQueue.main)
    .sink { [weak self] newOddsDict in
        // 檢測變化並更新特定行
        let changedMatchIDs = // 檢測邏輯
        let indexPaths = // 計算需要更新的行
        self?.tableView.reloadRows(at: indexPaths, with: .none)
    }
    .store(in: &cancellables)
```

#### **資料流架構**

```
WebSocket → PassthroughSubject → ViewModel → @Published → ViewController → UI更新
```
