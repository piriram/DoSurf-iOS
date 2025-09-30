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
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let containerView = UIView()
    private let surfEndButton = UIButton()
    private let cancelButton = UIButton()
    private let disposeBag = DisposeBag()
    
    // 콜백
    var onSurfEnd: (() -> Void)?
    var onCancel: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        bindActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        bindActions()
    }
    
    private func setupUI() {
        // 블러 백그라운드
        blurEffectView.alpha = 0
        addSubview(blurEffectView)
        
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 컨테이너 뷰
        containerView.alpha = 0
        addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(200)
        }
        
        setupSurfEndButton()
        setupCancelButton()
    }
    
    private func setupSurfEndButton() {
        //TODO: 기록하기 버튼 추가
        // 서핑 종료 버튼 (큰 파란색 원형)
        surfEndButton.backgroundColor = .surfBlue
        surfEndButton.setTitle("서핑 종료", for: .normal)
        surfEndButton.setTitleColor(.white, for: .normal)
        surfEndButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        surfEndButton.layer.cornerRadius = 60
        
        // 그림자 효과
        surfEndButton.layer.shadowColor = UIColor.surfBlue.cgColor
        surfEndButton.layer.shadowOffset = CGSize(width: 0, height: 8)
        surfEndButton.layer.shadowRadius = 16
        surfEndButton.layer.shadowOpacity = 0.3
        
        containerView.addSubview(surfEndButton)
        
        surfEndButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
            make.width.height.equalTo(120)
        }
    }
    
    private func setupCancelButton() {
        // 취소 버튼 (작은 X 버튼)
        cancelButton.backgroundColor = .systemBackground
        cancelButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        cancelButton.tintColor = .surfBlue
        cancelButton.layer.cornerRadius = 20
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor.surfBlue.cgColor
        
        // 그림자 효과
        cancelButton.layer.shadowColor = UIColor.black.cgColor
        cancelButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        cancelButton.layer.shadowRadius = 4
        cancelButton.layer.shadowOpacity = 0.1
        
        containerView.addSubview(cancelButton)
        
        cancelButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(surfEndButton.snp.bottom).offset(30)
            make.width.height.equalTo(40)
        }
    }
    
    private func bindActions() {
        // 서핑 종료 버튼 터치 효과
        surfEndButton.rx.controlEvent(.touchDown)
            .subscribe(onNext: { [weak self] in
                self?.animateButtonPress(button: self?.surfEndButton, pressed: true)
            })
            .disposed(by: disposeBag)
        
        surfEndButton.rx.controlEvent([.touchUpInside, .touchUpOutside, .touchCancel])
            .subscribe(onNext: { [weak self] in
                self?.animateButtonPress(button: self?.surfEndButton, pressed: false)
            })
            .disposed(by: disposeBag)
        
        // 취소 버튼 터치 효과
        cancelButton.rx.controlEvent(.touchDown)
            .subscribe(onNext: { [weak self] in
                self?.animateButtonPress(button: self?.cancelButton, pressed: true)
            })
            .disposed(by: disposeBag)
        
        cancelButton.rx.controlEvent([.touchUpInside, .touchUpOutside, .touchCancel])
            .subscribe(onNext: { [weak self] in
                self?.animateButtonPress(button: self?.cancelButton, pressed: false)
            })
            .disposed(by: disposeBag)
        
        // 버튼 액션
        surfEndButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.onSurfEnd?()
            })
            .disposed(by: disposeBag)
        
        cancelButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.onCancel?()
            })
            .disposed(by: disposeBag)
    }
    
    private func animateButtonPress(button: UIButton?, pressed: Bool) {
        guard let button = button else { return }
        
        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .curveEaseInOut]) {
            button.transform = pressed ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
        }
    }
    
    /// 오버레이 표시
    func show() {
        // 초기 상태 설정
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
            // 블러 효과 나타내기
            self.blurEffectView.alpha = 1
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
            self.blurEffectView.alpha = 0
        } completion: { _ in
            completion()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 백그라운드 터치시 아무것도 하지 않음 (터치 무시)
        // 실수로 닫히지 않도록 방지
    }
}
extension CustomTabBarController: UITabBarControllerDelegate, UIAdaptivePresentationControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // 중앙 더미 탭 선택 방지
        guard let index = viewControllers?.firstIndex(of: viewController) else { return true }
        return index != 1
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // 탭 선택시 애니메이션 효과 (선택사항)
        guard let selectedIndex = viewControllers?.firstIndex(of: viewController),
              selectedIndex != 1 else { return }
        
        // 선택된 탭 아이콘 애니메이션
        animateTabSelection(at: selectedIndex)
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // 스와이프로 모달이 닫혔을 때
        isRecordingScreenPresented.accept(false)
    }
    
    private func animateTabSelection(at index: Int) {
        guard let tabBarItems = tabBar.items,
              index < tabBarItems.count,
              let tabBarButtons = tabBar.subviews.filter({
                  String(describing: type(of: $0)) == "UITabBarButton"
              }) as? [UIView],
              index < tabBarButtons.count else { return }
        
        let selectedButton = tabBarButtons[index == 0 ? 0 : 1] // 중앙 더미 제외
        
        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction]) {
            selectedButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                selectedButton.transform = .identity
            }
        }
    }
}


