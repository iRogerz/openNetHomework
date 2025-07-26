//
//  Match.swift
//  openNetHomeWork
//
//  Created by Roger Tseng on 2025/7/24.
//

import Foundation

struct Match: Codable, Identifiable {
    let matchID: Int
    let teamA: String
    let teamB: String
    let startTime: Date

    var id: Int { matchID }
}
