import Foundation

// MARK: - Repository Errors
enum RepositoryError: Error {
    case unknown
    case entityNotFound(String)
    case saveError(Error)
    case fetchError(Error)
    case deleteError(Error)
    case updateError(Error)
    case invalidObjectID
    
    var localizedDescription: String {
        switch self {
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        case .entityNotFound(let entityName):
            return "\(entityName) 엔티티를 찾을 수 없습니다."
        case .saveError(let error):
            return "저장 중 오류가 발생했습니다: \(error.localizedDescription)"
        case .fetchError(let error):
            return "데이터를 가져오는 중 오류가 발생했습니다: \(error.localizedDescription)"
        case .deleteError(let error):
            return "삭제 중 오류가 발생했습니다: \(error.localizedDescription)"
        case .updateError(let error):
            return "업데이트 중 오류가 발생했습니다: \(error.localizedDescription)"
        case .invalidObjectID:
            return "유효하지 않은 객체 ID입니다."
        }
    }
}
