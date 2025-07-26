# 即時賽事賠率監控系統

## 專案概述

這是一個 iOS 應用程式，用於即時監控賽事賠率變化。系統採用 WebSocket 連接來接收即時數據，並使用 MVVM 架構模式來管理狀態和 UI 更新。

## 專案架構

```
openNetHomeWork/
├── AppDelegate.swift              # 應用程式入口點
├── SceneDelegate.swift            # 場景委託，管理 UI 生命週期
├── Model/                        # 數據模型層
│   ├── Match.swift               # 賽事模型
│   └── Odds.swift                # 賠率模型
├── View/                         # 視圖層
│   └── MatchListViewController.swift  # 賽事列表視圖控制器
├── ViewModel/                    # 視圖模型層
│   └── MatchListViewModel.swift  # 賽事列表視圖模型
├── Service/                      # 服務層
│   ├── APIService.swift          # API 服務
│   └── WebSocketManager.swift    # WebSocket 連接管理
└── Resource/                     # 資源文件
    └── mock_data.json           # 模擬數據
```
