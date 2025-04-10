//
//  DashboardPageView.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/2/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - DashboardPageView
final class DashboardPageView: UIView {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    
    private var pages: [UIView] = []
    private var currentPageIndex = 0
    
    // MARK: - Outputs
    let currentPage = BehaviorRelay<Int>(value: 0)
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        configureLayout()
        configureBind()
        
        // 디버깅용 로그
        print("🔄 DashboardPageView initialized")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    private func configureUI() {
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = true
        scrollView.backgroundColor = .clear
        
        contentStackView.axis = .horizontal
        contentStackView.spacing = 0
        contentStackView.distribution = .fillEqually
        
        addSubview(scrollView)
        scrollView.addSubview(contentStackView)
    }
    
    private func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(scrollView.snp.height)
        }
    }
    
    private func configureBind() {
        // 스크롤이 끝날 때만 페이지 변경 감지 (드래그 중에는 감지하지 않음)
        scrollView.rx.observe(CGPoint.self, #keyPath(UIScrollView.contentOffset))
            .compactMap { $0 }
            .filter { [weak self] _ in
                // 스크롤이 진행 중이 아닐 때만 페이지 변경 감지
                guard let self = self else { return false }
                return !self.scrollView.isDragging && !self.scrollView.isDecelerating
            }
            .map { [weak self] offset -> Int in
                guard let self = self else { return 0 }
                let pageWidth = self.scrollView.bounds.width
                guard pageWidth > 0, !self.pages.isEmpty else { return 0 }
                let rawPage = offset.x / pageWidth
                let calculatedPage = max(0, min(Int(rawPage.rounded()), self.pages.count - 1))
                return calculatedPage
            }
            .distinctUntilChanged()
            .bind(to: currentPage)
            .disposed(by: disposeBag)
        
        // 스크롤 끝남 감지를 위한 추가 바인딩
        scrollView.rx.didEndDecelerating
            .subscribe(onNext: { [weak self] in
                self?.updateCurrentPageFromContentOffset()
            })
            .disposed(by: disposeBag)
        
        scrollView.rx.didEndDragging
            .filter { !$0 } // willDecelerate가 false인 경우 (바로 멈춤)
            .subscribe(onNext: { [weak self] _ in
                self?.updateCurrentPageFromContentOffset()
            })
            .disposed(by: disposeBag)
    }
    
    private func updateCurrentPageFromContentOffset() {
        let pageWidth = scrollView.bounds.width
        guard pageWidth > 0, !pages.isEmpty else { return }
        let rawPage = scrollView.contentOffset.x / pageWidth
        let calculatedPage = max(0, min(Int(rawPage.rounded()), pages.count - 1))
        
        // 페이지가 실제로 변경된 경우에만 업데이트
        if calculatedPage != currentPageIndex {
            print("📄 Page changed: \(currentPageIndex) → \(calculatedPage)")
            currentPageIndex = calculatedPage
            currentPage.accept(calculatedPage)
        }
    }
    
    // MARK: - Public Methods
    func configure(pages: [UIView]) {
        // 기존 페이지 제거
        contentStackView.arrangedSubviews.forEach { view in
            contentStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        self.pages = pages
        currentPageIndex = 0
        
        // 새 페이지 추가
        pages.enumerated().forEach { index, page in
            let containerView = UIView()
            containerView.tag = index // 디버깅용 태그
            containerView.addSubview(page)
            
            page.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(8)
            }
            
            contentStackView.addArrangedSubview(containerView)
            
            containerView.snp.makeConstraints { make in
                make.width.equalTo(scrollView.snp.width)
            }
        }
        
        // 초기 상태 설정
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.scrollView.contentOffset = .zero
            self.currentPage.accept(0)
        }
    }
    
    func scrollToPage(_ index: Int, animated: Bool = true) {
        guard index >= 0 && index < pages.count else { return }
        guard index != currentPageIndex else { return } // 이미 같은 페이지면 리턴
        
        currentPageIndex = index
        
        // 레이아웃이 완료된 후 스크롤
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let pageWidth = self.scrollView.bounds.width
            guard pageWidth > 0 else { return }
            
            let targetOffset = CGPoint(x: CGFloat(index) * pageWidth, y: 0)
            self.scrollView.setContentOffset(targetOffset, animated: animated)
            
            // 애니메이션이 없는 경우 즉시 페이지 업데이트
            if !animated {
                self.currentPage.accept(index)
            }
        }
    }
    
    func getPage(at index: Int) -> UIView? {
        guard index >= 0 && index < pages.count else { return nil }
        return pages[index]
    }
}











