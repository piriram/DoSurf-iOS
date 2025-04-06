//
//  CustomTabBar.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/28/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - Custom TabBar
class CustomTabBar: UITabBar {
    private let centerButton = UIButton()
    private let disposeBag = DisposeBag()
    
    // 중앙 버튼 클릭 이벤트
    let centerButtonTapped = PublishRelay<Void>()
    
    // 서핑 상태 추적
    private var isSurfing = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCenterButton()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCenterButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCenterButton()
    }
    
    private func setupCenterButton() {
        // 탭바 스타일링
        backgroundColor = .systemBackground
        tintColor = .systemBlue
        unselectedItemTintColor = .systemGray
        
        // iOS 15+ 대응
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            appearance.shadowColor = .systemGray4
            
            standardAppearance = appearance
            scrollEdgeAppearance = appearance
            isTranslucent = false
        }
        
        // 중앙 버튼 설정
        setupCenterButtonDesign()
        setupCenterButtonConstraints()
        bindCenterButtonEvents()
    }
    
    private func setupCenterButtonDesign() {
        centerButton.layer.cornerRadius = 30
        centerButton.layer.masksToBounds = false
        centerButton.imageView?.contentMode = .scaleAspectFit
        centerButton.tintColor = .white
        
        // 기본 상태와 선택 상태 설정
        setupCenterButtonStates()
        
        // 초기 상태는 비선택
        updateCenterButtonState(isSelected: false)
        
        // 기록하기 텍스트 라벨
        centerButton.setTitle("기록하기", for: .normal)
        centerButton.setTitle("서핑중", for: .selected)
        centerButton.titleLabel?.font = .systemFont(ofSize: 10, weight: .medium)
        
        // 이미지와 텍스트 배치 - 가로 중앙 정렬
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.imagePlacement = .top
            config.imagePadding = 6
            config.titleAlignment = .center
            config.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            centerButton.configuration = config
        } else {
            centerButton.contentHorizontalAlignment = .center
            centerButton.contentVerticalAlignment = .center
            centerButton.titleLabel?.textAlignment = .center
            centerButton.contentEdgeInsets = .zero
            centerButton.imageEdgeInsets = UIEdgeInsets(top: -6, left: 0, bottom: 6, right: 0)
            centerButton.titleEdgeInsets = UIEdgeInsets(top: 24, left: 0, bottom: -4, right: 0)
        }
    }
    
    private func setupCenterButtonStates() {
        let startWaveImage = UIImage(named: "startWave")
        centerButton.setImage(startWaveImage, for: .normal)
        centerButton.setTitleColor(.white, for: .normal)
        
        // 선택 상태에서도 동일 이미지 사용
        centerButton.setImage(startWaveImage, for: .selected)
        centerButton.setTitleColor(.white, for: .selected)
    }
    
    /// 중앙 버튼 상태 업데이트
    func updateCenterButtonState(isSelected: Bool) {
        self.isSurfing = isSelected
        
        UIView.transition(with: centerButton, duration: 0.2, options: .transitionCrossDissolve) {
            self.centerButton.isSelected = isSelected
            
            if isSelected {
                // 선택된 상태: 밝은 파란색
                self.centerButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
                self.centerButton.layer.shadowColor = UIColor.systemBlue.withAlphaComponent(0.6).cgColor
                self.centerButton.layer.shadowOpacity = 0.4
            } else {
                // 기본 상태: 진한 파란색
                self.centerButton.backgroundColor = UIColor.systemBlue
                self.centerButton.layer.shadowColor = UIColor.systemBlue.cgColor
                self.centerButton.layer.shadowOpacity = 0.25
            }
        }
        
        // 그림자 애니메이션
        self.centerButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.centerButton.layer.shadowRadius = 12
    }
    
    /// 서핑 상태 확인
    var surfingState: Bool {
        return isSurfing
    }
    
    private func createWaveIcon(color: UIColor = .white) -> UIImage? {
        // 물결 모양 아이콘 생성 (디자인에 맞게)
        let size = CGSize(width: 24, height: 16)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(2)
            ctx.setLineCap(.round)
            
            // 3개의 물결 그리기
            for i in 0..<3 {
                let y = CGFloat(4 + i * 4)
                ctx.move(to: CGPoint(x: 2, y: y))
                
                for x in stride(from: 2, to: 22, by: 4) {
                    let nextX = CGFloat(x + 2)
                    let offset: CGFloat = (x % 8 == 2) ? -2 : 2
                    let nextY = y + offset
                    ctx.addLine(to: CGPoint(x: nextX, y: nextY))
                }
            }
            ctx.strokePath()
        }
    }
    
    private func setupCenterButtonConstraints() {
        addSubview(centerButton)
        
        centerButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(snp.top).offset(10) // 탭바 위로 올라오게
            make.width.height.equalTo(60)
        }
    }
    
    private func bindCenterButtonEvents() {
        // 버튼 터치 효과
        centerButton.rx.controlEvent(.touchDown)
            .subscribe(onNext: { [weak self] in
                self?.animateButtonPress(pressed: true)
            })
            .disposed(by: disposeBag)
        
        centerButton.rx.controlEvent([.touchUpInside, .touchUpOutside, .touchCancel])
            .subscribe(onNext: { [weak self] in
                self?.animateButtonPress(pressed: false)
            })
            .disposed(by: disposeBag)
        
        // 메인 터치 이벤트
        centerButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .bind(to: centerButtonTapped)
            .disposed(by: disposeBag)
    }
    
    private func animateButtonPress(pressed: Bool) {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .curveEaseInOut]) {
            self.centerButton.transform = pressed ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
            self.centerButton.layer.shadowOpacity = pressed ? 0.1 : (self.isSurfing ? 0.4 : 0.25)
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 탭바가 보이지 않거나 비활성 상태면 터치 무시
        if isHidden || alpha < 0.01 || window == nil {
            return nil
        }
        
        // 탭바가 화면 아래로 내려가 있는(숨겨진) 상태면 터치 무시
        if let superBounds = superview?.bounds, frame.minY >= superBounds.height - 1 {
            return nil
        }
        
        // 중앙 버튼 터치 영역 확장
        let centerButtonFrame = centerButton.frame.insetBy(dx: -10, dy: -10)
        if centerButtonFrame.contains(point) {
            return centerButton
        }
        return super.hitTest(point, with: event)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        arrangeTabBarItems()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var s = super.sizeThatFits(size)
        // 기존 탭바 높이에 중앙 버튼 공간(+20)만 추가
        s.height += 20
        return s
    }
    
    private func arrangeTabBarItems() {
        guard let items = items, items.count >= 2 else { return }
        
        let totalWidth = frame.width
        let buttonWidth = totalWidth / 3 // 3등분 (좌, 중앙공간, 우)
        var buttonIndex = 0
        
        for subview in subviews {
            if String(describing: type(of: subview)) == "UITabBarButton" {
                let newFrame: CGRect
                
                if buttonIndex == 0 {
                    // 첫 번째 버튼 (왼쪽)
                    newFrame = CGRect(x: 0, y: subview.frame.origin.y,
                                     width: buttonWidth, height: subview.frame.height)
                } else {
                    // 두 번째 버튼 (오른쪽)
                    newFrame = CGRect(x: buttonWidth * 2, y: subview.frame.origin.y,
                                     width: buttonWidth, height: subview.frame.height)
                }
                
                subview.frame = newFrame
                buttonIndex += 1
                
                if buttonIndex >= 2 { break } // 2개만 처리
            }
        }
    }
}

