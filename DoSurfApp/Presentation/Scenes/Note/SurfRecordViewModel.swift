//
//  SurfRecordViewModel.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/29/25.
//

import RxSwift
import RxCocoa

final class SurfRecordViewModel {
    struct Input {
        let saveTap: Driver<Void>
        let ratingChanged: Driver<Int>
        let memoText: Driver<String>
    }
    struct Output {
        let saved: Driver<Void>
    }
    
    private let disposeBag = DisposeBag()
    
    func transform(_ input: Input) -> Output {
        // 여기서 실제 저장 로직/DI 주입 가능
        let savedRelay = PublishRelay<Void>()
        input.saveTap
            .drive(onNext: { savedRelay.accept(()) })
            .disposed(by: disposeBag)
        
        return Output(saved: savedRelay.asDriver(onErrorDriveWith: .empty()))
    }
}
