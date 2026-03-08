import UIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - DashboardPageView
final class PagenationView: UIView {
    
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
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.height.equalTo(scrollView.frameLayoutGuide)
        }
    }
    
    private func configureBind() {
        scrollView.rx.observe(CGPoint.self, #keyPath(UIScrollView.contentOffset))
            .compactMap { $0 }
            .filter { [weak self] _ in
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
        
        scrollView.rx.didEndDecelerating
            .subscribe(onNext: { [weak self] in
                self?.updateCurrentPageFromContentOffset()
            })
            .disposed(by: disposeBag)
        
        scrollView.rx.didEndDragging
            .filter { !$0 }
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
            // 기존 superview에서 제거 (중요!)
            page.removeFromSuperview()
            
            let containerView = UIView()
            containerView.tag = index
            
            // containerView를 먼저 stackView에 추가
            contentStackView.addArrangedSubview(containerView)
            
            // containerView에 page 추가 (이 순서가 중요!)
            containerView.addSubview(page)
            
            // containerView의 제약 조건 먼저 설정
            containerView.snp.makeConstraints { make in
                make.width.equalTo(scrollView.frameLayoutGuide)
            }
            
            // page의 제약 조건은 addSubview 후에 설정
            page.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(8)
            }
        }
        
        // 초기 상태 설정
        layoutIfNeeded() // 레이아웃 즉시 적용
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.scrollView.contentOffset = .zero
            self.currentPage.accept(0)
        }
    }
    
    func scrollToPage(_ index: Int, animated: Bool = true) {
        guard index >= 0 && index < pages.count else { return }
        guard index != currentPageIndex else { return }
        
        currentPageIndex = index
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let pageWidth = self.scrollView.bounds.width
            guard pageWidth > 0 else { return }
            
            let targetOffset = CGPoint(x: CGFloat(index) * pageWidth, y: 0)
            self.scrollView.setContentOffset(targetOffset, animated: animated)
            
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
