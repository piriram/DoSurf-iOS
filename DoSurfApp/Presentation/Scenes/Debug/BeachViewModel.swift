//
//  BeachViewModel.swift
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

// MARK: - ViewModel
protocol FirestoreBeachViewModelProtocol {
    var selectedBeachRelay: BehaviorRelay<BeachInfo> { get }
    var dataRelay: BehaviorRelay<BeachDataDump?> { get }
    var isLoadingRelay: BehaviorRelay<Bool> { get }
    var errorRelay: PublishRelay<String> { get }
    
    func fetchBeachData()
    func generateDumpString() -> String
}

class BeachViewModel: FirestoreBeachViewModelProtocol {
    let selectedBeachRelay = BehaviorRelay<BeachInfo>(value: BeachInfo.availableBeaches[0])
    let dataRelay = BehaviorRelay<BeachDataDump?>(value: nil)
    let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    let errorRelay = PublishRelay<String>()
    
    private let beachDataService: BeachDataServiceProtocol
    private let disposeBag = DisposeBag()
    
    init(beachDataService: BeachDataServiceProtocol = BeachDataService(repository: FirestoreBeachRepository())) {
        self.beachDataService = beachDataService
    }
    
    func fetchBeachData() {
        let selectedBeach = selectedBeachRelay.value
        isLoadingRelay.accept(true)
        
        beachDataService.fetchBeachData(beachId: selectedBeach.id) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoadingRelay.accept(false)
                switch result {
                case .success(let data):
                    self.dataRelay.accept(data)
                case .failure(let error):
                    self.errorRelay.accept(error.localizedDescription)
                }
            }
        }
    }
    
    func generateDumpString() -> String {
        guard let data = dataRelay.value else {
            return "No data available"
        }
        dump(data)
        
        var dump = """
        ==========================================
        BEACH DATA DUMP
        ==========================================
        Beach ID: \(data.beachInfo.id)
        Beach Name: \(data.beachInfo.name)
        Expected Region: \(data.beachInfo.region)
        Found In Region: \(data.foundInRegion ?? "Not Found")
        Last Updated: \(data.lastUpdated.asDumpString())
        
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
            Last Updated: \(metadata.lastUpdated.asDumpString())
            
            """
            
            if let earliest = metadata.earliestForecast {
                dump += "Earliest Forecast: \(earliest.asDumpString())\n"
            }
            if let latest = metadata.latestForecast {
                dump += "Latest Forecast: \(latest.asDumpString())\n"
            }
            if let next = metadata.nextForecastTime {
                dump += "Next Forecast: \(next.asDumpString())\n"
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
                Timestamp: \(forecast.timestamp.asDumpString())
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
