//
//  FetchBeachDataUseCase.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/30/25.
//
import UIKit
import RxSwift

protocol FetchBeachDataUseCase {
    func execute(beachId: String) -> Single<BeachData>
}

final class DefaultFetchBeachDataUseCase: FetchBeachDataUseCase {
    private let repository: RxBeachRepository
    private let knownRegions: [String]
    
    init(
        repository: RxBeachRepository,
        knownRegions: [String] = BeachRegion.allCases.map { $0.rawValue }
    ) {
        self.repository = repository
        self.knownRegions = knownRegions
    }
    
    func execute(beachId: String) -> Single<BeachData> {
        return repository.findRegion(for: beachId, among: knownRegions)
            .flatMap { [weak self] foundRegion -> Single<BeachData> in
                guard let self = self, let region = foundRegion else {
                    return .error(FirebaseAPIError.beachNotFoundInAnyRegion(beachId: beachId))
                }
                
                let since = Date().addingTimeInterval(-48*60*60)
                
                return Single.zip(
                    self.repository.fetchMetadata(beachId: beachId, region: region),
                    self.repository.fetchForecasts(beachId: beachId, region: region, since: since, limit: 20)
                )
                .map { metadataDTO, forecastDTOs in
                    guard let metadataDTO = metadataDTO else {
                        throw FirebaseAPIError.notFound
                    }
                    
                    // DTO → Domain 변환
                    let metadata = metadataDTO.toDomain()
                    let charts = forecastDTOs
                        .map { $0.toDomain() }
                        .sorted { $0.time < $1.time }
                    
                    return BeachData(
                        metadata: metadata,
                        charts: charts,
                        lastUpdated: Date()
                    )
                }
            }
            .catch { error in
                .error(FirebaseAPIError.map(error))
            }
    }
}

import FirebaseFirestore
// MARK: - Error
enum FirebaseAPIError: Error, LocalizedError, Equatable {
    case notFound
    case permissionDenied
    case unauthenticated
    case unavailable
    case deadlineExceeded
    case cancelled
    case alreadyExists
    case failedPrecondition
    case resourceExhausted
    case internalError
    case invalidArgument(message: String?)
    case decodingFailed(message: String?)
    case invalidPath(message: String?)
    case beachNotFoundInAnyRegion(beachId: String)
    case unknown(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .notFound: return "요청한 리소스를 찾을 수 없습니다."
        case .permissionDenied: return "접근 권한이 없습니다."
        case .unauthenticated: return "인증이 필요합니다."
        case .unavailable: return "서비스가 일시적으로 불가합니다. 잠시 후 다시 시도해주세요."
        case .deadlineExceeded: return "요청 시간이 초과되었습니다."
        case .cancelled: return "요청이 취소되었습니다."
        case .alreadyExists: return "이미 존재하는 리소스입니다."
        case .failedPrecondition: return "요청 전제 조건이 충족되지 않았습니다."
        case .resourceExhausted: return "요청 한도를 초과했습니다."
        case .internalError: return "내부 오류가 발생했습니다."
        case .invalidArgument(let msg): return msg ?? "요청 인자가 올바르지 않습니다."
        case .decodingFailed(let msg): return msg ?? "데이터 해석에 실패했습니다."
        case .invalidPath(let msg): return msg ?? "잘못된 경로입니다."
        case .beachNotFoundInAnyRegion(let id): return "어느 지역에서도 비치 ID (\(id))를 찾지 못했습니다."
        case .unknown(let err): return err.localizedDescription
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .unavailable, .deadlineExceeded, .resourceExhausted, .internalError:
            return true
        default:
            return false
        }
    }
    
    static func map(_ error: Error) -> FirebaseAPIError {
        let ns = error as NSError
        let code = FirestoreErrorCode.Code(rawValue: ns.code) ?? .unknown
        switch code {
        case .notFound: return .notFound
        case .permissionDenied: return .permissionDenied
        case .unauthenticated: return .unauthenticated
        case .unavailable: return .unavailable
        case .deadlineExceeded: return .deadlineExceeded
        case .cancelled: return .cancelled
        case .alreadyExists: return .alreadyExists
        case .failedPrecondition: return .failedPrecondition
        case .resourceExhausted: return .resourceExhausted
        case .internal: return .internalError
        case .invalidArgument: return .invalidArgument(message: ns.localizedDescription)
        default: return .unknown(underlying: error)
        }
    }
}

extension FirebaseAPIError {
    static func == (lhs: FirebaseAPIError, rhs: FirebaseAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.notFound, .notFound),
            (.permissionDenied, .permissionDenied),
            (.unauthenticated, .unauthenticated),
            (.unavailable, .unavailable),
            (.deadlineExceeded, .deadlineExceeded),
            (.cancelled, .cancelled),
            (.alreadyExists, .alreadyExists),
            (.failedPrecondition, .failedPrecondition),
            (.resourceExhausted, .resourceExhausted),
            (.internalError, .internalError):
            return true
        case let (.invalidArgument(l), .invalidArgument(r)):
            return l == r
        case let (.decodingFailed(l), .decodingFailed(r)):
            return l == r
        case let (.invalidPath(l), .invalidPath(r)):
            return l == r
        case let (.beachNotFoundInAnyRegion(id1), .beachNotFoundInAnyRegion(id2)):
            return id1 == id2
        case let (.unknown(u1), .unknown(u2)):
            let n1 = u1 as NSError
            let n2 = u2 as NSError
            return n1.domain == n2.domain && n1.code == n2.code
        default:
            return false
        }
    }
}

