//
//  MatchListViewController.swift
//  openNetHomeWork
//
//  Created by Roger Tseng on 2025/7/24.
//

import Combine
import SnapKit
import UIKit

class MatchListViewController: UIViewController {
    // MARK: - properties

    private let viewModel = MatchListViewModel()
    private let tableView = UITableView()
    private var cancellables = Set<AnyCancellable>()
    private var lastOddsDict: [Int: Odds] = [:]

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .white
        label.backgroundColor = .systemGray
        label.text = "連線狀態：-"
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupStatusLabel()
        setupTableView()
        bindViewModel()
        viewModel.fetchInitialData()
    }

    // MARK: - setupUI

    private func setupStatusLabel() {
        view.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(36)
        }
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func bindViewModel() {
        viewModel.$matches
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$oddsDict
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newOddsDict in
                guard let self = self else { return }
                let changedMatchIDs = newOddsDict.compactMap { key, value -> Int? in
                    if let old = self.lastOddsDict[key] {
                        if old.teamAOdds != value.teamAOdds || old.teamBOdds != value.teamBOdds {
                            return key
                        }
                        return nil
                    } else {
                        return key
                    }
                }
                let indexPaths = self.viewModel.matches.enumerated().compactMap { idx, match -> IndexPath? in
                    changedMatchIDs.contains(match.matchID) ? IndexPath(row: idx, section: 0) : nil
                }
                if !indexPaths.isEmpty {
                    self.tableView.reloadRows(at: indexPaths, with: .none)
                    // cell 閃爍動畫
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        for indexPath in indexPaths {
                            if let cell = self.tableView.cellForRow(at: indexPath) {
                                self.animateCellFlash(cell: cell)
                            }
                        }
                    }
                }
                self.lastOddsDict = newOddsDict
            }
            .store(in: &cancellables)

        // 監聽連線狀態
        viewModel.webSocketConnectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateStatusLabel(state: state)
            }
            .store(in: &cancellables)
    }

    private func animateCellFlash(cell: UITableViewCell) {
        let originalColor = cell.contentView.backgroundColor
        UIView.animate(withDuration: 0.15, animations: {
            cell.contentView.backgroundColor = UIColor.yellow.withAlphaComponent(0.5)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                cell.contentView.backgroundColor = originalColor
            }
        }
    }

    private func updateStatusLabel(state: ConnectionState) {
        switch state {
        case .connected:
            statusLabel.text = "連線狀態：已連線"
            statusLabel.backgroundColor = .systemGreen
        case .disconnected:
            statusLabel.text = "連線狀態：已斷線"
            statusLabel.backgroundColor = .systemRed
        case .reconnecting:
            statusLabel.text = "連線狀態：重連中..."
            statusLabel.backgroundColor = .systemOrange
        }
    }
}

extension MatchListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return viewModel.matches.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let match = viewModel.matches[indexPath.row]
        let odds = viewModel.oddsDict[match.matchID]
        let aOdds = odds?.teamAOdds ?? 0
        let bOdds = odds?.teamBOdds ?? 0
        let aStr = String(format: "%.2f", aOdds)
        let bStr = String(format: "%.2f", bOdds)
        cell.textLabel?.text = "\(match.teamA) vs \(match.teamB) | 賠率: A \(aStr) / B \(bStr)"
        return cell
    }
}
