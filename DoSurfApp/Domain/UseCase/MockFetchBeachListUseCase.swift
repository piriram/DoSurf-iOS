import Foundation
import RxSwift

final class MockFetchBeachListUseCase: FetchBeachListUseCase {
    private let beaches: [BeachDTO] = [
        BeachDTO(id: "1001", region: .init(slug: "gangreung", displayName: "강릉", order: 1), regionName: "강릉", place: "죽도"),
        BeachDTO(id: "1002", region: .init(slug: "gangreung", displayName: "강릉", order: 1), regionName: "강릉", place: "강촌"),
        BeachDTO(id: "1003", region: .init(slug: "gangreung", displayName: "강릉", order: 1), regionName: "강릉", place: "안현"),
        BeachDTO(id: "1004", region: .init(slug: "gangreung", displayName: "강릉", order: 1), regionName: "강릉", place: "도항"),
        BeachDTO(id: "2001", region: .init(slug: "pohang", displayName: "포항", order: 2), regionName: "포항", place: "간절곶"),
        BeachDTO(id: "2002", region: .init(slug: "pohang", displayName: "포항", order: 2), regionName: "포항", place: "청해"),
        BeachDTO(id: "3001", region: .init(slug: "jeju", displayName: "제주", order: 3), regionName: "제주", place: "협재"),
        BeachDTO(id: "3002", region: .init(slug: "jeju", displayName: "제주", order: 3), regionName: "제주", place: "중문"),
        BeachDTO(id: "3003", region: .init(slug: "jeju", displayName: "제주", order: 3), regionName: "제주", place: "함덕"),
        BeachDTO(id: "4001", region: .init(slug: "busan", displayName: "부산", order: 4), regionName: "부산", place: "송도")
    ]

    func execute(region: String) -> Single<[BeachDTO]> {
        .just(beaches.filter { $0.region.slug == region })
    }

    func executeAll() -> Single<[BeachDTO]> {
        .just(beaches)
    }
}
