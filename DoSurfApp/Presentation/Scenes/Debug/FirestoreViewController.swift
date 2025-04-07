//
//  FirestoreViewController.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/26/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Firebase
import FirebaseFirestore

// MARK: - ViewController
class FirestoreViewController: UIViewController {
    private let viewModel: FirestoreBeachViewModelProtocol
    private let disposeBag = DisposeBag()
    
    // UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let pickerContainerView = UIView()
    private let pickerLabel = UILabel()
    private let beachPicker = UIPickerView()
    private let fetchButton = UIButton(type: .system)
    private let copyButton = UIButton(type: .system)
    private let textView = UITextView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let statsLabel = UILabel()
    
    private let availableBeaches = BeachInfo.availableBeaches
    
    init(viewModel: FirestoreBeachViewModelProtocol = BeachViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
        setupPickerView()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Beach Data Dump"
        
        // Title
        titleLabel.text = "Beach Forecast Data"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        
        // Picker Container
        pickerContainerView.backgroundColor = .systemGray6
        pickerContainerView.layer.cornerRadius = 8
        
        // Picker Label
        pickerLabel.text = "Select Beach ID:"
        pickerLabel.font = .systemFont(ofSize: 16, weight: .medium)
        
        // Beach Picker
        beachPicker.backgroundColor = .clear
        
        // Fetch Button
        fetchButton.setTitle("Fetch Data", for: .normal)
        fetchButton.backgroundColor = .surfBlue
        fetchButton.setTitleColor(.white, for: .normal)
        fetchButton.layer.cornerRadius = 8
        fetchButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        
        // Copy Button
        copyButton.setTitle("Copy to Clipboard", for: .normal)
        copyButton.backgroundColor = .systemGreen
        copyButton.setTitleColor(.white, for: .normal)
        copyButton.layer.cornerRadius = 8
        copyButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        copyButton.isEnabled = false
        
        // Stats Label
        statsLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statsLabel.textColor = .systemGray
        statsLabel.textAlignment = .center
        statsLabel.numberOfLines = 0
        
        // Text View
        textView.font = .systemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .systemGray6
        textView.layer.cornerRadius = 8
        textView.isEditable = false
        textView.text = "Select a beach ID and press 'Fetch Data' to load forecast data..."
        
        // Loading Indicator
        loadingIndicator.hidesWhenStopped = true
        
        // Add to view hierarchy
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        pickerContainerView.addSubview(pickerLabel)
        pickerContainerView.addSubview(beachPicker)
        
        [titleLabel, pickerContainerView, fetchButton, copyButton, statsLabel, textView, loadingIndicator].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        pickerContainerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(140)
        }
        
        pickerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        beachPicker.snp.makeConstraints { make in
            make.top.equalTo(pickerLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(8)
        }
        
        fetchButton.snp.makeConstraints { make in
            make.top.equalTo(pickerContainerView.snp.bottom).offset(20)
            make.leading.equalToSuperview().inset(20)
            make.height.equalTo(44)
            make.width.equalTo(120)
        }
        
        copyButton.snp.makeConstraints { make in
            make.top.equalTo(pickerContainerView.snp.bottom).offset(20)
            make.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
            make.width.equalTo(150)
        }
        
        statsLabel.snp.makeConstraints { make in
            make.top.equalTo(fetchButton.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        textView.snp.makeConstraints { make in
            make.top.equalTo(statsLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.greaterThanOrEqualTo(400)
            make.bottom.equalToSuperview().inset(20)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(textView)
        }
    }
    
    private func setupPickerView() {
        beachPicker.dataSource = self
        beachPicker.delegate = self
        
        // 초기 선택값 설정
        viewModel.selectedBeachRelay.accept(availableBeaches[0])
    }
    
    private func setupBindings() {
        // Fetch Button Tap
        fetchButton.rx.tap
            .bind { [weak self] in
                self?.viewModel.fetchBeachData()
            }
            .disposed(by: disposeBag)
        
        // Copy Button Tap
        copyButton.rx.tap
            .bind { [weak self] in
                let dumpString = self?.viewModel.generateDumpString() ?? ""
                UIPasteboard.general.string = dumpString
                self?.showAlert(title: "Copied", message: "Data copied to clipboard!")
            }
            .disposed(by: disposeBag)
        
        // Loading State
        viewModel.isLoadingRelay
            .bind { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                    self?.fetchButton.isEnabled = false
                    self?.textView.text = "Loading..."
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.fetchButton.isEnabled = true
                }
            }
            .disposed(by: disposeBag)
        
        // Data Updates
        viewModel.dataRelay
            .compactMap { $0 }
            .bind { [weak self] data in
                guard let self = self else { return }
                
                let dumpString = self.viewModel.generateDumpString()
                self.textView.text = dumpString
                self.copyButton.isEnabled = true
                
                let forecastCount = data.forecasts.count
                let metadataStatus = data.metadata != nil ? "Available" : "Not Found"
                
                self.statsLabel.text = """
                Beach: \(data.beachInfo.name) (ID: \(data.beachInfo.id))
                Region: \(data.foundInRegion ?? "Not Found")
                Metadata: \(metadataStatus) | Forecasts: \(forecastCount)
                """
            }
            .disposed(by: disposeBag)
        
        // Error Handling
        viewModel.errorRelay
            .bind { [weak self] errorMessage in
                self?.showAlert(title: "Error", message: errorMessage)
            }
            .disposed(by: disposeBag)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate
extension FirestoreViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return availableBeaches.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let beach = availableBeaches[row]
        return "\(beach.id) - \(beach.name) (\(beach.region))"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedBeach = availableBeaches[row]
        viewModel.selectedBeachRelay.accept(selectedBeach)
        
        // 선택이 변경되면 기존 데이터 클리어
        viewModel.dataRelay.accept(nil)
        copyButton.isEnabled = false
        textView.text = "Beach ID \(selectedBeach.id) selected. Press 'Fetch Data' to load forecast data..."
        statsLabel.text = ""
    }
}
