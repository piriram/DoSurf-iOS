//
//  WeatherRepository.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/25/25.
//

import Foundation
import RxSwift

protocol WhetherRepositoryProtocol{
    func fetchMarineData(for beachID: String) //-> Observable<[Chart]>
    func fetchLatestMarineData(for beachID: String) //-> Observable<Chart>
}
