//
//  MatchListViewModel.swift
//  openNetHomeWork
//
//  Created by Roger Tseng on 2025/7/24.
//

import Combine
import Foundation


class MatchListViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var oddsDict: [Int: Odds] = [:]

    /// 用於管理 Combine 訂閱的集合
    private var cancellables = Set<AnyCancellable>()
    
    private let apiService: MatchAPIServiceProtocol
    private let webSocketService: OddsWebSocketServiceProtocol
    
    let webSocketConnectionStatePublisher = PassthroughSubject<ConnectionState, Never>()

    /// 使用Dependency Injection 的方式初始化服務
    init(
        apiService: MatchAPIServiceProtocol = MockAPIService(),
        webSocketService: OddsWebSocketServiceProtocol = MockOddsWebSocketService()
    ) {
        self.apiService = apiService
        self.webSocketService = webSocketService
        
        subscribeWebSocket()
        subscribeConnectionState()
        webSocketService.start()
    }

    /// 獲取初始資料
    func fetchInitialData() {
        Task {
            do {
                // 並行獲取比賽和賠率資料
                let matches = try await apiService.fetchMatches()
                let odds = try await apiService.fetchOdds()
                
                DispatchQueue.main.async {
                    // 按開始時間降序排列比賽
                    self.matches = matches.sorted { $0.startTime > $1.startTime }
                    // 將賠率資料轉換為字典格式，方便快速查找
                    self.oddsDict = Dictionary(uniqueKeysWithValues: odds.map { ($0.matchID, $0) })
                }
            } catch {
                print("Fetch error: \(error)")
            }
        }
    }

    /// 訂閱WebSocket賠率更新
    func subscribeWebSocket() {
        webSocketService.oddsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] odds in
                // 更新對應比賽的賠率資料
                self?.oddsDict[odds.matchID] = odds
            }
            .store(in: &cancellables) // 將訂閱存儲到集合中，避免記憶體洩漏
    }

    /// 訂閱WebSocket連接狀態變化
    private func subscribeConnectionState() {
        webSocketService.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                // 將連接狀態轉發給UI
                self?.webSocketConnectionStatePublisher.send(state)
            }
            .store(in: &cancellables) // 將訂閱存儲到集合中，避免記憶體洩漏
    }
}
