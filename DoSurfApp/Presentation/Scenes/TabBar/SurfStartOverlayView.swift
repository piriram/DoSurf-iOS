//
//  SurfStartOverlayView.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 11/4/25.
//

import UIKit
import RxSwift
import RxCocoa

// MARK: - Surf Start Overlay View
final class SurfStartOverlayView: BaseOverlayView {
    
    // MARK: - Callbacks
    var onSurfStart: (() -> Void)?
    var onRecordDirectly: (() -> Void)?
    var onCancel: (() -> Void)?
    
    // MARK: - Initialization
    override init(containerSize: CGFloat = 400) {
        super.init(containerSize: containerSize)
        setupUI()
        bindActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        bindActions()
    }
    
    // MARK: - Setup
    private func setupUI() {
        setupButtons(
            main: .primary(title: "서핑 시작"),
            secondary: .outlined(title: "기록 바로하기", tintColor: .surfBlue),
            cancel: .icon(image: UIImage(systemName: "xmark"), tintColor: .surfBlue)
        )
    }
    
    private func bindActions() {
        // 서핑 시작 버튼
        mainButton?.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.onSurfStart?()
            })
            .disposed(by: disposeBag)
        
        // 기록 바로하기 버튼
        secondaryButton?.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.onRecordDirectly?()
            })
            .disposed(by: disposeBag)
        
        // 취소 버튼
        cancelButton?.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.onCancel?()
            })
            .disposed(by: disposeBag)
    }
}
