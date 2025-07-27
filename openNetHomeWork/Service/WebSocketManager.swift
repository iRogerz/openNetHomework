//
//  WebSocketManager.swift
//  openNetHomeWork
//
//  Created by Roger Tseng on 2025/7/24.
//

import Combine
import Foundation

enum ConnectionState {
    /// 已連接狀態
    case connected
    /// 已斷開狀態
    case disconnected
    /// 重新連接中狀態
    case reconnecting
}

protocol OddsWebSocketServiceProtocol {
    
    /// 賠率資料發布者，用於推送最新的賠率資訊
    var oddsPublisher: PassthroughSubject<Odds, Never> { get }
    
    /// 連接狀態發布者，用於推送連接狀態變化
    var connectionStatePublisher: PassthroughSubject<ConnectionState, Never> { get }
    
    /// 啟動WebSocket連接
    func start()
    
    /// 停止WebSocket連接
    func stop()
}

class MockOddsWebSocketService: OddsWebSocketServiceProtocol {
    let oddsPublisher = PassthroughSubject<Odds, Never>()
    let connectionStatePublisher = PassthroughSubject<ConnectionState, Never>()
    private var timer: Timer?
    private var matchIDs: [Int] = Array(1001 ... 1100)
    private var isConnected = false
    private var reconnectDelay: TimeInterval = 2.0

    func start() {
        guard !isConnected else { return }
        isConnected = true
        connectionStatePublisher.send(.connected)
        scheduleTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if isConnected {
            isConnected = false
            connectionStatePublisher.send(.disconnected)
        }
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // 模擬隨機斷線
            if Int.random(in: 0 ..< 30) == 0 {
                self.simulateDisconnect()
                return
            }
            
            // 隨機選擇10個比賽ID並生成模擬賠率
            let shuffled = self.matchIDs.shuffled()
            let selected = shuffled.prefix(10)
            for matchID in selected {
                let odds = Odds(
                    matchID: matchID,
                    teamAOdds: Double.random(in: 1.7 ... 2.2),
                    teamBOdds: Double.random(in: 1.7 ... 2.2)
                )
                self.oddsPublisher.send(odds)
            }
        }
    }

    /// 模擬斷線和重連
    private func simulateDisconnect() {
        stop()
        connectionStatePublisher.send(.reconnecting)
        DispatchQueue.main.asyncAfter(deadline: .now() + reconnectDelay) { [weak self] in
            self?.start()
        }
    }
}
