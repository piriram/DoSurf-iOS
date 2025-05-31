import UIKit
import WatchConnectivity

class SurfDataReceiverViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let statusIndicator = UIView()
    private let statusLabel = UILabel()
    
    // 데이터 표시 레이블들
    private let distanceLabel = UILabel()
    private let durationLabel = UILabel()
    private let startTimeLabel = UILabel()
    private let endTimeLabel = UILabel()
    private let lastReceivedLabel = UILabel()
    
    // 버튼들
    private let refreshButton = UIButton(type: .system)
    private let clearButton = UIButton(type: .system)
    
    // MARK: - Properties
    private var watchConnectivity: iPhoneWatchConnectivity!
    private var receivedData: SurfSessionData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWatchConnectivity()
        updateUI()
        
        // 자동 새로고침 타이머 (5초마다)
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.updateConnectionStatus()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Surf Data from Watch"
        
        // 스크롤뷰 설정
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // 메인 스택뷰 생성
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.spacing = 20
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 제목
        titleLabel.text = "🏄‍♂️ Surf Session Data"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        
        // 연결 상태
        let statusStackView = UIStackView()
        statusStackView.axis = .horizontal
        statusStackView.spacing = 8
        statusStackView.alignment = .center
        statusStackView.translatesAutoresizingMaskIntoConstraints = false
        
        statusIndicator.layer.cornerRadius = 8
        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        statusIndicator.widthAnchor.constraint(equalToConstant: 16).isActive = true
        statusIndicator.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        
        statusStackView.addArrangedSubview(statusIndicator)
        statusStackView.addArrangedSubview(statusLabel)
        
        // 데이터 섹션
        let dataSection = createDataSection()
        
        // 버튼 섹션
        let buttonSection = createButtonSection()
        
        // 메인 스택뷰에 추가
        mainStackView.addArrangedSubview(titleLabel)
        mainStackView.addArrangedSubview(statusStackView)
        mainStackView.addArrangedSubview(dataSection)
        mainStackView.addArrangedSubview(buttonSection)
        
        contentView.addSubview(mainStackView)
        
        // 제약조건 설정
        NSLayoutConstraint.activate([
            // 스크롤뷰
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 컨텐츠뷰
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // 메인 스택뷰
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createDataSection() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 12
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 데이터 레이블들 설정
        [distanceLabel, durationLabel, startTimeLabel, endTimeLabel, lastReceivedLabel].forEach { label in
            label.font = .systemFont(ofSize: 16)
            label.textColor = .label
            stackView.addArrangedSubview(label)
        }
        
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        
        return containerView
    }
    
    private func createButtonSection() -> UIView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        
        // 새로고침 버튼
        refreshButton.setTitle("Refresh", for: .normal)
        refreshButton.backgroundColor = .systemBlue
        refreshButton.setTitleColor(.white, for: .normal)
        refreshButton.layer.cornerRadius = 8
        refreshButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        refreshButton.addTarget(self, action: #selector(refreshData), for: .touchUpInside)
        
        // 지우기 버튼
        clearButton.setTitle("Clear", for: .normal)
        clearButton.backgroundColor = .systemRed
        clearButton.setTitleColor(.white, for: .normal)
        clearButton.layer.cornerRadius = 8
        clearButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        clearButton.addTarget(self, action: #selector(clearData), for: .touchUpInside)
        
        stackView.addArrangedSubview(refreshButton)
        stackView.addArrangedSubview(clearButton)
        
        // 버튼 높이 설정
        refreshButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        clearButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        return stackView
    }
    
    // MARK: - WatchConnectivity Setup
    private func setupWatchConnectivity() {
        watchConnectivity = iPhoneWatchConnectivity()
        watchConnectivity.delegate = self
        watchConnectivity.activate()
    }
    
    // MARK: - UI Updates
    private func updateUI() {
        updateConnectionStatus()
        updateDataLabels()
    }
    
    private func updateConnectionStatus() {
        DispatchQueue.main.async {
            let isConnected = WCSession.default.isReachable
            self.statusIndicator.backgroundColor = isConnected ? .systemGreen : .systemRed
            self.statusLabel.text = isConnected ? "Apple Watch Connected" : "Apple Watch Disconnected"
            self.statusLabel.textColor = isConnected ? .systemGreen : .systemRed
        }
    }
    
    private func updateDataLabels() {
        DispatchQueue.main.async {
            if let data = self.receivedData {
                self.distanceLabel.text = "📏 Distance: \(Int(data.distance)) meters"
                self.durationLabel.text = "⏱️ Duration: \(self.formatDuration(data.duration))"
                self.startTimeLabel.text = "🚀 Start: \(self.formatDate(data.startTime))"
                self.endTimeLabel.text = "🏁 End: \(self.formatDate(data.endTime))"
                
                let lastReceived = UserDefaults.standard.object(forKey: "lastReceivedTime") as? Date ?? Date()
                self.lastReceivedLabel.text = "📅 Received: \(self.formatDate(lastReceived))"
            } else {
                self.distanceLabel.text = "📏 Distance: No data"
                self.durationLabel.text = "⏱️ Duration: No data"
                self.startTimeLabel.text = "🚀 Start: No data"
                self.endTimeLabel.text = "🏁 End: No data"
                self.lastReceivedLabel.text = "📅 Received: Never"
            }
        }
    }
    
    // MARK: - Helper Methods
    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - Actions
    @objc private func refreshData() {
        updateUI()
        
        // 새로고침 효과
        refreshButton.backgroundColor = .systemGray
        UIView.animate(withDuration: 0.2) {
            self.refreshButton.backgroundColor = .systemBlue
        }
    }
    
    @objc private func clearData() {
        let alert = UIAlertController(title: "Clear Data", message: "Are you sure you want to clear all received data?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            self.receivedData = nil
            UserDefaults.standard.removeObject(forKey: "lastReceivedTime")
            self.updateDataLabels()
        })
        
        present(alert, animated: true)
    }
}

// MARK: - WatchConnectivity Delegate
extension SurfDataReceiverViewController: iPhoneWatchConnectivityDelegate {
    func didReceiveSurfData(_ data: SurfSessionData) {
        receivedData = data
        UserDefaults.standard.set(Date(), forKey: "lastReceivedTime")
        updateDataLabels()
        
        // 성공 알림
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "✅ Data Received", message: "New surf session data received from Apple Watch!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func watchConnectivityDidChangeReachability(_ isReachable: Bool) {
        updateConnectionStatus()
    }
}
