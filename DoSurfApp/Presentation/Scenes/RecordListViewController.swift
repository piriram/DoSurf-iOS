//
//  RecordListViewController.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/28/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - Record List ViewController
class RecordListViewController: UIViewController {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    
    // Placeholder data source
    private var items: [String] = (1...20).map { "기록 \($0)" }
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = 54
        return tableView
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "아직 기록이 없어요"
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindTable()
        reloadEmptyState()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "기록 차트"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "필터",
            style: .plain,
            target: self,
            action: #selector(filterTapped)
        )
        
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
    }
    
    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func bindTable() {
        // Simple non-Rx binding for placeholder
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func reloadEmptyState() {
        let isEmpty = items.isEmpty
        tableView.isHidden = isEmpty
        emptyLabel.isHidden = !isEmpty
    }
    
    // MARK: - Actions
    @objc private func filterTapped() {
        let alert = UIAlertController(title: "필터", message: "필터 기능은 추후 제공됩니다.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "확인", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension RecordListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = items[indexPath.row]
        config.secondaryText = "상세 보기"
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detail = UIViewController()
        detail.view.backgroundColor = .systemBackground
        detail.title = items[indexPath.row]
        navigationController?.pushViewController(detail, animated: true)
    }
}
