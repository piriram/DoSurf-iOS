//
//  CustomTabBarController.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/28/25.
//

import UIKit
import RxCocoa
import RxSwift
import SnapKit

// MARK: - Custom TabBarController
class CustomTabBarController: BaseTabBarController {
    private let customTabBar = CustomTabBar()
    private let disposeBag = DisposeBag()
    
    // 기록 화면 표시 여부 추적
    let isRecordingScreenPresented = BehaviorRelay<Bool>(value: false)
    
    // 서핑 종료 오버레이
    private var surfEndOverlay: SurfEndOverlayView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 상태바 스타일 조정
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func configureUI() {
        super.configureUI()
        setupCustomTabBar()
        setupViewControllers()
    }
    
    override func configureBind() {
        super.configureBind()
        bindCenterButton()
        setupTabBarDelegate()
    }
    
    private func setupCustomTabBar() {
        setValue(customTabBar, forKey: "tabBar")
        
        // 탭바 선택 시 애니메이션 효과
        delegate = self
    }
    
    private func setupViewControllers() {
        // 파트차트 ViewController
        let chartVC = createChartViewController()
        let chartNav = UINavigationController(rootViewController: chartVC)
        chartNav.tabBarItem = UITabBarItem(
            title: "파도차트",
            image: UIImage(systemName: "chart.bar"),
            selectedImage: UIImage(systemName: "chart.bar.fill")
        )
        chartNav.tabBarItem.tag = 0
        
        // 더미 ViewController (중앙 버튼 공간)
        let dummyVC = UIViewController()
        dummyVC.tabBarItem = UITabBarItem(title: "", image: nil, tag: 1)
        dummyVC.tabBarItem.isEnabled = false // 선택 불가
        
        // 기록차트 ViewController
        let recordListVC = createRecordListViewController()
        let recordNav = UINavigationController(rootViewController: recordListVC)
        recordNav.tabBarItem = UITabBarItem(
            title: "기록 차트",
            image: UIImage(systemName: "doc.text"),
            selectedImage: UIImage(systemName: "doc.text.fill")
        )
        recordNav.tabBarItem.tag = 2
        
        viewControllers = [chartNav, dummyVC, recordNav]
        selectedIndex = 0
    }
    
    private func createChartViewController() -> UIViewController {
        let vc = DashboardViewController()
        return vc
    }
    
    private func createRecordListViewController() -> UIViewController {
        let vc = StaticsViewController()
        vc.title = "기록 차트"
        // 탭 루트로 사용할 때는 닫기 버튼 제거 (모달이 아님)
        vc.navigationItem.leftBarButtonItem = nil
        return vc
    }
    
    private func setupTabBarDelegate() {
        // 중앙 탭(더미) 선택 방지
        rx.didSelect
            .filter { $0.tabBarItem.tag == 1 }
            .subscribe(onNext: { [weak self] _ in
                // 중앙 탭 선택 시 이전 탭으로 복원
                self?.selectedIndex = self?.selectedIndex == 0 ? 0 : 2
            })
            .disposed(by: disposeBag)
    }
    
    private func bindCenterButton() {
        customTabBar.centerButtonTapped
            .subscribe(onNext: { [weak self] in
                self?.handleCenterButtonTap()
            })
            .disposed(by: disposeBag)
        
        // 기록 화면 상태에 따른 버튼 외형 변경
        isRecordingScreenPresented
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isPresented in
                self?.customTabBar.updateCenterButtonState(isSelected: isPresented)
            })
            .disposed(by: disposeBag)
    }
    
    private func handleCenterButtonTap() {
        // 현재 서핑 상태 확인
        if customTabBar.surfingState {
            // 서핑 중이면 종료 오버레이 표시
            showSurfEndOverlay()
        } else {
            // 서핑 시작
            startSurfing()
        }
    }
    
    private func startSurfing() {
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 상태 추적 - 기록 상태 시작 (탭 전환 없이 상태만 변경)
        isRecordingScreenPresented.accept(true)
    }
    
    private func showSurfEndOverlay() {
        // 이미 오버레이가 표시중이면 무시
        guard surfEndOverlay == nil else { return }
        
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // 오버레이 생성
        surfEndOverlay = SurfEndOverlayView()
        guard let overlay = surfEndOverlay else { return }
        
        // 오버레이 이벤트 바인딩
        overlay.onSurfEnd = { [weak self] in
            self?.endSurfing()
        }
        
        overlay.onCancel = { [weak self] in
            self?.hideSurfEndOverlay()
        }
        
        // 메인 뷰에 추가
        view.addSubview(overlay)
        overlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 탭바 숨기기
        animateTabBarVisibility(hidden: true)
        
        // 오버레이 애니메이션 표시
        overlay.show()
    }
    
    private func hideSurfEndOverlay(completion: (() -> Void)? = nil) {
        // 탭바 보이기 (오버레이가 없더라도 보장)
        if surfEndOverlay == nil {
            animateTabBarVisibility(hidden: false)
            completion?()
            return
        }
        
        guard let overlay = surfEndOverlay else { return }
        
        // 탭바 보이기
        animateTabBarVisibility(hidden: false)
        
        // 오버레이 애니메이션 숨기기
        overlay.hide { [weak self] in
            overlay.removeFromSuperview()
            self?.surfEndOverlay = nil
            completion?()
        }
    }
    
    private func endSurfing() {
        // 서핑 종료 처리
        isRecordingScreenPresented.accept(false)
        
        // 성공 햅틱
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        
        // 오버레이 숨기기 완료 후 기록 작성 화면으로 이동
        hideSurfEndOverlay { [weak self] in
            self?.pushToRecordWrite()
        }
        
        // 기록 저장 로직 등 추가 처리
        // TODO: 실제 서핑 데이터 저장
    }
    
    private func pushToRecordWrite() {
        let recordVC = SurfRecordViewController()
        recordVC.title = "기록 작성"
        recordVC.hidesBottomBarWhenPushed = true
        
        if let nav = self.selectedViewController as? UINavigationController {
            nav.pushViewController(recordVC, animated: true)
        } else if let nav = self.navigationController {
            nav.pushViewController(recordVC, animated: true)
        } 
    }
    
    private func animateTabBarVisibility(hidden: Bool) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.tabBar.alpha = hidden ? 0 : 1
            self.tabBar.transform = hidden ?
            CGAffineTransform(translationX: 0, y: self.tabBar.frame.height) : .identity
        }
    }
}
