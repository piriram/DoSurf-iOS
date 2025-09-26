import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Firebase
import FirebaseFirestore

// MARK: - Beach ID Model
struct BeachInfo {
    let id: String
    let name: String
    let region: String
    
    static let availableBeaches: [BeachInfo] = [
        BeachInfo(id: "1001", name: "정동진", region: "gangreung"),
        BeachInfo(id: "2001", name: "월포", region: "pohang"),
        BeachInfo(id: "3001", name: "중문", region: "jeju"),
        BeachInfo(id: "4001", name: "해운대", region: "busan")
    ]
}

// MARK: - DTOs
struct BeachDataDump {
    let beachInfo: BeachInfo
    let metadata: BeachMetadata?
    let forecasts: [ForecastData]
    let lastUpdated: Date
    var foundInRegion: String?
}

struct BeachMetadata {
    let beachId: Int
    let region: String
    let beach: String
    let lastUpdated: Date
    let totalForecasts: Int
    let status: String
    let earliestForecast: Date?
    let latestForecast: Date?
    let nextForecastTime: Date?
}

struct ForecastData {
    let documentId: String
    let beachId: Int
    let region: String
    let beach: String
    let datetime: String
    let timestamp: Date
    let windSpeed: Double?
    let windDirection: Double?
    let waveHeight: Double?
    let airTemperature: Double?
    let precipitationProbability: Double?
    let precipitationType: Int?
    let skyCondition: Int?
    let humidity: Double?
    let precipitation: Double?
    let snow: Double?
    let omWaveHeight: Double?
    let omWaveDirection: Double?
    let omSeaSurfaceTemperature: Double?
}

// MARK: - Service
protocol BeachDataServiceProtocol {
    func fetchBeachData(beachId: String) -> Single<BeachDataDump>
    func searchBeachInAllRegions(beachId: String) -> Single<String?>
}

class BeachDataService: BeachDataServiceProtocol {
    private let db = Firestore.firestore()
    private let knownRegions = ["gangreung", "pohang", "jeju", "busan"]
    
    func fetchBeachData(beachId: String) -> Single<BeachDataDump> {
        return searchBeachInAllRegions(beachId: beachId)
            .flatMap { [weak self] foundRegion -> Single<BeachDataDump> in
                guard let self = self,
                      let region = foundRegion else {
                    return Single.error(NSError(domain: "BeachDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Beach ID \(beachId) not found in any region"]))
                }
                
                return self.fetchBeachDataFromRegion(beachId: beachId, region: region)
                    .map { data in
                        var updatedData = data
                        updatedData.foundInRegion = region
                        return updatedData
                    }
            }
    }
    
    func searchBeachInAllRegions(beachId: String) -> Single<String?> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NSError(domain: "BeachDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])))
                return Disposables.create()
            }
            
            let group = DispatchGroup()
            var foundRegion: String?
            
            for region in self.knownRegions {
                group.enter()
                
                // 해당 region에 beachId 컬렉션이 존재하는지 확인
                self.db.collection("regions")
                    .document(region)
                    .collection(beachId)
                    .document("_metadata")
                    .getDocument { document, error in
                        if document?.exists == true {
                            foundRegion = region
                        }
                        group.leave()
                    }
            }
            
            group.notify(queue: .main) {
                observer(.success(foundRegion))
            }
            
            return Disposables.create()
        }
    }
    
    private func fetchBeachDataFromRegion(beachId: String, region: String) -> Single<BeachDataDump> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NSError(domain: "BeachDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])))
                return Disposables.create()
            }
            
            let group = DispatchGroup()
            var metadata: BeachMetadata?
            var forecasts: [ForecastData] = []
            let beachInfo = BeachInfo.availableBeaches.first { $0.id == beachId } ?? BeachInfo(id: beachId, name: "Unknown", region: region)
            
            // 메타데이터 가져오기
            group.enter()
            self.db.collection("regions")
                .document(region)
                .collection(beachId)
                .document("_metadata")
                .getDocument { document, error in
                    if let document = document, document.exists,
                       let data = document.data() {
                        metadata = BeachMetadata(
                            beachId: data["beach_id"] as? Int ?? Int(beachId) ?? 0,
                            region: data["region"] as? String ?? region,
                            beach: data["beach"] as? String ?? "",
                            lastUpdated: (data["last_updated"] as? Timestamp)?.dateValue() ?? Date(),
                            totalForecasts: data["total_forecasts"] as? Int ?? 0,
                            status: data["status"] as? String ?? "",
                            earliestForecast: (data["earliest_forecast"] as? Timestamp)?.dateValue(),
                            latestForecast: (data["latest_forecast"] as? Timestamp)?.dateValue(),
                            nextForecastTime: (data["next_forecast_time"] as? Timestamp)?.dateValue()
                        )
                    }
                    group.leave()
                }
            
            // 예보 데이터 가져오기 (최근 20개)
            group.enter()
            self.db.collection("regions")
                .document(region)
                .collection(beachId)
                .whereField("timestamp", isGreaterThan: Timestamp(date: Date().addingTimeInterval(-48*60*60))) // 48시간 이내
                .order(by: "timestamp", descending: false)
                .limit(to: 20)
                .getDocuments { snapshot, error in
                    if let documents = snapshot?.documents {
                        for document in documents {
                            // _metadata 문서는 제외
                            if document.documentID == "_metadata" { continue }
                            
                            let data = document.data()
                            let forecast = ForecastData(
                                documentId: document.documentID,
                                beachId: data["beach_id"] as? Int ?? Int(beachId) ?? 0,
                                region: data["region"] as? String ?? region,
                                beach: data["beach"] as? String ?? "",
                                datetime: data["datetime"] as? String ?? "",
                                timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                                windSpeed: data["wind_speed"] as? Double,
                                windDirection: data["wind_direction"] as? Double,
                                waveHeight: data["wave_height"] as? Double,
                                airTemperature: data["air_temperature"] as? Double,
                                precipitationProbability: data["precipitation_probability"] as? Double,
                                precipitationType: data["precipitation_type"] as? Int,
                                skyCondition: data["sky_condition"] as? Int,
                                humidity: data["humidity"] as? Double,
                                precipitation: data["precipitation"] as? Double,
                                snow: data["snow"] as? Double,
                                omWaveHeight: data["om_wave_height"] as? Double,
                                omWaveDirection: data["om_wave_direction"] as? Double,
                                omSeaSurfaceTemperature: data["om_sea_surface_temperature"] as? Double
                            )
                            forecasts.append(forecast)
                        }
                        
                        // 시간 순으로 정렬
                        forecasts.sort { $0.timestamp < $1.timestamp }
                    }
                    group.leave()
                }
            
            group.notify(queue: .main) {
                let beachData = BeachDataDump(
                    beachInfo: beachInfo,
                    metadata: metadata,
                    forecasts: forecasts,
                    lastUpdated: Date(),
                    foundInRegion: region
                )
                observer(.success(beachData))
            }
            
            return Disposables.create()
        }
    }
}

// MARK: - ViewModel
protocol BeachViewModelProtocol {
    var selectedBeachRelay: BehaviorRelay<BeachInfo> { get }
    var dataRelay: BehaviorRelay<BeachDataDump?> { get }
    var isLoadingRelay: BehaviorRelay<Bool> { get }
    var errorRelay: PublishRelay<String> { get }
    
    func fetchBeachData()
    func generateDumpString() -> String
}

class BeachViewModel: BeachViewModelProtocol {
    let selectedBeachRelay = BehaviorRelay<BeachInfo>(value: BeachInfo.availableBeaches[0])
    let dataRelay = BehaviorRelay<BeachDataDump?>(value: nil)
    let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    let errorRelay = PublishRelay<String>()
    
    private let beachDataService: BeachDataServiceProtocol
    private let disposeBag = DisposeBag()
    
    init(beachDataService: BeachDataServiceProtocol = BeachDataService()) {
        self.beachDataService = beachDataService
    }
    
    func fetchBeachData() {
        let selectedBeach = selectedBeachRelay.value
        isLoadingRelay.accept(true)
        
        beachDataService.fetchBeachData(beachId: selectedBeach.id)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] data in
                    self?.isLoadingRelay.accept(false)
                    self?.dataRelay.accept(data)
                },
                onFailure: { [weak self] error in
                    self?.isLoadingRelay.accept(false)
                    self?.errorRelay.accept(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }
    
    func generateDumpString() -> String {
        guard let data = dataRelay.value else {
            return "No data available"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        var dump = """
        ==========================================
        BEACH DATA DUMP
        ==========================================
        Beach ID: \(data.beachInfo.id)
        Beach Name: \(data.beachInfo.name)
        Expected Region: \(data.beachInfo.region)
        Found In Region: \(data.foundInRegion ?? "Not Found")
        Last Updated: \(dateFormatter.string(from: data.lastUpdated))
        
        """
        
        if let metadata = data.metadata {
            dump += """
            METADATA
            ==========================================
            Beach ID: \(metadata.beachId)
            Region: \(metadata.region)
            Beach Name: \(metadata.beach)
            Status: \(metadata.status)
            Total Forecasts: \(metadata.totalForecasts)
            Last Updated: \(dateFormatter.string(from: metadata.lastUpdated))
            
            """
            
            if let earliest = metadata.earliestForecast {
                dump += "Earliest Forecast: \(dateFormatter.string(from: earliest))\n"
            }
            if let latest = metadata.latestForecast {
                dump += "Latest Forecast: \(dateFormatter.string(from: latest))\n"
            }
            if let next = metadata.nextForecastTime {
                dump += "Next Forecast: \(dateFormatter.string(from: next))\n"
            }
        } else {
            dump += """
            METADATA
            ==========================================
            No metadata found
            
            """
        }
        
        dump += """
        
        FORECAST DATA
        ==========================================
        Total Records: \(data.forecasts.count)
        
        """
        
        if data.forecasts.isEmpty {
            dump += "No forecast data available\n"
        } else {
            for (index, forecast) in data.forecasts.enumerated() {
                dump += """
                
                [\(index + 1)] Document ID: \(forecast.documentId)
                ------------------------------------------
                Timestamp: \(dateFormatter.string(from: forecast.timestamp))
                Datetime: \(forecast.datetime)
                
                Weather Data:
                  - Air Temperature: \(forecast.airTemperature?.description ?? "N/A")°C
                  - Wind Speed: \(forecast.windSpeed?.description ?? "N/A") m/s
                  - Wind Direction: \(forecast.windDirection?.description ?? "N/A")°
                  - Wave Height: \(forecast.waveHeight?.description ?? "N/A") m
                  - Humidity: \(forecast.humidity?.description ?? "N/A")%
                  - Precipitation: \(forecast.precipitation?.description ?? "N/A") mm
                  - Precipitation Prob: \(forecast.precipitationProbability?.description ?? "N/A")%
                  - Sky Condition: \(forecast.skyCondition?.description ?? "N/A")
                
                Open-Meteo Data:
                  - OM Wave Height: \(forecast.omWaveHeight?.description ?? "N/A") m
                  - OM Wave Direction: \(forecast.omWaveDirection?.description ?? "N/A")°
                  - OM Sea Surface Temp: \(forecast.omSeaSurfaceTemperature?.description ?? "N/A")°C
                
                """
            }
        }
        
        return dump
    }
}

// MARK: - ViewController
class FirestoreViewController: UIViewController {
    private let viewModel: BeachViewModelProtocol
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
    
    init(viewModel: BeachViewModelProtocol = BeachViewModel()) {
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
        fetchButton.backgroundColor = .systemBlue
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
