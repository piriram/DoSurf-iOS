//
//  SurfEndOverlayView.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/29/25.
//

import UIKit
import RxSwift
import SnapKit
import RxCocoa

// MARK: - Surf End Overlay View
class SurfEndOverlayView: UIView {
    private let gradientBlurView = GradientBlurView(
        blurStyle: .systemThickMaterial,
        dimAlpha: 0.2,
        gradientStartLocation: 0.0,
        gradientEndLocation: 1.0
    )
    private let containerView = UIView()
    private let surfEndButton: CustomButton
    private let cancelSurfingButton: CustomButton
    private let cancelButton: CustomButton
    private let disposeBag = DisposeBag()
    
    // 블러 높이 설정 (bottom부터 이 높이만큼 블러 처리)
    private let blurHeight: CGFloat = 800
    
    // 콜백
    var onSurfEnd: (() -> Void)?
    var onCancelSurfing: (() -> Void)?
    var onCancel: (() -> Void)?
    
    override init(frame: CGRect) {
        self.surfEndButton = CustomButton(style: .primary(title: "서핑 종료"))
        self.cancelSurfingButton = CustomButton(style: .outlined(title: "서핑 취소하기", tintColor: .systemRed))
        self.cancelButton = CustomButton(style: .icon(image: UIImage(systemName: "xmark"), tintColor: .surfBlue))
        super.init(frame: frame)
        setupUI()
        bindActions()
    }
    
    required init?(coder: NSCoder) {
        self.surfEndButton = CustomButton(style: .primary(title: "서핑 종료"))
        self.cancelSurfingButton = CustomButton(style: .outlined(title: "서핑 취소하기", tintColor: .systemRed))
        self.cancelButton = CustomButton(style: .icon(image: UIImage(systemName: "xmark"), tintColor: .surfBlue))
        super.init(coder: coder)
        setupUI()
        bindActions()
    }
    
    private func setupUI() {
        // 그라데이션 블러 백그라운드
        gradientBlurView.alpha = 0
        addSubview(gradientBlurView)
        
        gradientBlurView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(blurHeight)
        }
        
        // 컨테이너 뷰
        containerView.alpha = 0
        addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.height.equalTo(400)
        }
        
        setupSurfEndButton()
        setupCancelSurfingButton()
        setupCancelButton()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    private func setupSurfEndButton() {
        containerView.addSubview(surfEndButton)
        
        surfEndButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(154)
        }
    }
    
    private func setupCancelSurfingButton() {
        containerView.addSubview(cancelSurfingButton)
        
        cancelSurfingButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(surfEndButton.snp.bottom).offset(24)
            make.height.equalTo(48)
            make.width.equalTo(160)
        }
    }
    
    private func setupCancelButton() {
        containerView.addSubview(cancelButton)
        
        cancelButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(28)
            make.width.height.equalTo(68)
        }
    }
    
    private func bindActions() {
        // 서핑 종료 버튼 액션
        surfEndButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.onSurfEnd?()
            })
            .disposed(by: disposeBag)
        
        // 서핑 취소하기 버튼 액션
        cancelSurfingButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.onCancelSurfing?()
            })
            .disposed(by: disposeBag)
        
        // 취소 버튼 액션
        cancelButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.onCancel?()
            })
            .disposed(by: disposeBag)
    }
    
    /// 오버레이 표시
    func show() {
        // 초기 상태 설정
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
            // 블러 효과 나타내기
            self.gradientBlurView.alpha = 1
        }
        
        UIView.animate(withDuration: 0.4, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: [.allowUserInteraction]) {
            // 컨테이너 스케일 애니메이션
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    /// 오버레이 숨기기
    func hide(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn]) {
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
        
        UIView.animate(withDuration: 0.3, delay: 0.1, options: [.curveEaseIn]) {
            self.gradientBlurView.alpha = 0
        } completion: { _ in
            completion()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 백그라운드 터치시 아무것도 하지 않음 (터치 무시)
        // 실수로 닫히지 않도록 방지
    }
}
