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

    private var cancellables = Set<AnyCancellable>()
    private let apiService: MatchAPIServiceProtocol
    private let webSocketService: OddsWebSocketServiceProtocol
    let webSocketConnectionStatePublisher = PassthroughSubject<ConnectionState, Never>()

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

    func fetchInitialData() {
        Task {
            do {
                let matches = try await apiService.fetchMatches()
                let odds = try await apiService.fetchOdds()
                DispatchQueue.main.async {
                    self.matches = matches.sorted { $0.startTime > $1.startTime }
                    self.oddsDict = Dictionary(uniqueKeysWithValues: odds.map { ($0.matchID, $0) })
                }
            } catch {
                print("Fetch error: \(error)")
            }
        }
    }

    func subscribeWebSocket() {
        webSocketService.oddsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] odds in
                self?.oddsDict[odds.matchID] = odds
            }
            .store(in: &cancellables)
    }

    private func subscribeConnectionState() {
        webSocketService.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.webSocketConnectionStatePublisher.send(state)
            }
            .store(in: &cancellables)
    }
}
