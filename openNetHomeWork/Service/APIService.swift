//
//  APIService.swift
//  openNetHomeWork
//
//  Created by Roger Tseng on 2025/7/24.
//

import Foundation

protocol MatchAPIServiceProtocol {
    func fetchMatches() async throws -> [Match]
    func fetchOdds() async throws -> [Odds]
}

class MockAPIService: MatchAPIServiceProtocol {
    private let mockFileName = "mock_data"
    private let mockFileExt = "json"

    struct MockData: Codable {
        let matches: [Match]
        let odds: [Odds]
    }

    private func loadMockData() throws -> MockData {
        guard let url = Bundle.main.url(forResource: mockFileName, withExtension: mockFileExt) else {
            throw NSError(domain: "MockAPIService", code: 404, userInfo: [NSLocalizedDescriptionKey: "找不到 mock_data.json"])
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MockData.self, from: data)
    }

    func fetchMatches() async throws -> [Match] {
        let mock = try loadMockData()
        return mock.matches
    }

    func fetchOdds() async throws -> [Odds] {
        let mock = try loadMockData()
        return mock.odds
    }
}

class RealAPIService: MatchAPIServiceProtocol {
    func fetchMatches() async throws -> [Match] {
        // TODO: 實作正式 API 呼叫
        throw NSError(domain: "RealAPIService", code: 501, userInfo: [NSLocalizedDescriptionKey: "尚未實作正式 API"])
    }

    func fetchOdds() async throws -> [Odds] {
        // TODO: 實作正式 API 呼叫
        throw NSError(domain: "RealAPIService", code: 501, userInfo: [NSLocalizedDescriptionKey: "尚未實作正式 API"])
    }
}
