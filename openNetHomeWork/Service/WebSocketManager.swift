//
//  WebSocketManager.swift
//  openNetHomeWork
//
//  Created by Roger Tseng on 2025/7/24.
//

import Combine
import Foundation

enum ConnectionState {
    case connected
    case disconnected
    case reconnecting
}

protocol OddsWebSocketServiceProtocol {
    var oddsPublisher: PassthroughSubject<Odds, Never> { get }
    var connectionStatePublisher: PassthroughSubject<ConnectionState, Never> { get }
    func start()
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

    private func simulateDisconnect() {
        stop()
        connectionStatePublisher.send(.reconnecting)
        DispatchQueue.main.asyncAfter(deadline: .now() + reconnectDelay) { [weak self] in
            self?.start()
        }
    }
}
