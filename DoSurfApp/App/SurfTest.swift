//
//  SurfTest.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/9/25.
//

import UIKit

final class SurfSessionsTestViewController: UITableViewController {
    
    private var rows: [String] = ["Waiting for watch data..."]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Surf Sessions (Test)"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "subtitleCell")
        tableView.tableFooterView = UIView()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(refreshTapped))
        // TODO: Integrate with repository and notification listeners when available
    }
    
    @objc private func refreshTapped() {
        // No-op refresh to prove UI works
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "subtitleCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)

        cell.textLabel?.text = rows[indexPath.row]
        cell.detailTextLabel?.text = nil

        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    // MARK: - Public interface
    
    public func updateWithMock(distance: Double, duration: Double, waveCount: Int) {
        let formatted = String(format: "Distance: %.2f km, Duration: %.1f min, Waves: %d", distance, duration, waveCount)
        rows.append(formatted)
        tableView.reloadData()
    }
    // TODO: Replace this mock update method with real data handling from repository
}
