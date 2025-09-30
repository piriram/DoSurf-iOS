//
//  DashboardViewController.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/29/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class DashboardViewController: BaseViewController {
    
    // MARK: - Properties
    private let viewModel: DashboardViewModel
    private let disposeBag = DisposeBag()
    
    private var currentBeachData: BeachDataDump?
    private let viewDidLoadSubject = PublishSubject<Void>()
    private let beachSelectedSubject = PublishSubject<String>()
    
    // MARK: - UI Components (기존 코드 그대로 유지)
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "backgroundMain")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var beachSelectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("해변 선택", for: .normal)
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        return button
    }()
    
    private lazy var locationHeaderView: UIView = {
        let view = UIView()
        view.addSubview(beachSelectButton)
        beachSelectButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        return view
    }()
    
    private lazy var statisticsHeaderView: UIView = {
        let view = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = "선호하는 차트 통계"
        titleLabel.font = .systemFont(ofSize: 21, weight: .bold)
        titleLabel.textColor = .white
        
        let infoButton = UIButton(type: .system)
        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoButton.tintColor = .white
        
        view.addSubview(titleLabel)
        view.addSubview(infoButton)
        view.backgroundColor = .clear
        
        titleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        infoButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        return view
    }()
    
    private lazy var cardCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(DashboardCardCell.self, forCellWithReuseIdentifier: DashboardCardCell.identifier)
        return collectionView
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = 3
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .white.withAlphaComponent(0.4)
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.hidesForSinglePage = true
        return pageControl
    }()
    
    private lazy var chartContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private let chartListView = BeachChartListView()
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Initialization
    init(viewModel: DashboardViewModel = DIContainer.shared.makeDashboardViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides from BaseViewController
    override func configureNavigationBar() {
        super.configureNavigationBar()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func configureUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(backgroundImageView)
        view.addSubview(locationHeaderView)
        view.addSubview(statisticsHeaderView)
        view.addSubview(cardCollectionView)
        view.addSubview(pageControl)
        
        view.addSubview(chartContainerView)
        chartContainerView.addSubview(chartListView)
        chartListView.attachRefreshControl(refreshControl)
    }

    override func configureLayout() {
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        locationHeaderView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        
        statisticsHeaderView.snp.makeConstraints { make in
            make.top.equalTo(locationHeaderView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(24)
        }
        
        cardCollectionView.snp.makeConstraints { make in
            make.top.equalTo(statisticsHeaderView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(120)
        }
        
        pageControl.snp.makeConstraints { make in
            make.top.equalTo(cardCollectionView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.height.equalTo(20)
        }
        
        chartContainerView.snp.makeConstraints { make in
            make.top.equalTo(pageControl.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        chartListView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func configureAction() {
        beachSelectButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .bind(onNext: { [weak self] in
                self?.pushBeachChoose()
            })
            .disposed(by: disposeBag)
    }

    override func configureBind() {
        cardCollectionView.rx.setDelegate(self).disposed(by: disposeBag)
        
        // ViewModel Input 설정
        let input = DashboardViewModel.Input(
            viewDidLoad: viewDidLoadSubject.asObservable(),
            beachSelected: beachSelectedSubject.asObservable(),
            refreshTriggered: refreshControl.rx.controlEvent(.valueChanged).asObservable()
        )
        
        // ViewModel Output 바인딩
        let output = viewModel.transform(input: input)
        
        // 해변 데이터 바인딩
        output.beachData
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] beachData in
                self?.currentBeachData = beachData
                self?.beachSelectButton.setTitle(beachData.beachInfo.name, for: .normal)
            })
            .disposed(by: disposeBag)
        
        // 대시보드 카드 바인딩
        output.dashboardCards
            .observe(on: MainScheduler.instance)
            .do(onNext: { [weak self] cards in
                let cardsPerPage = 2
                self?.pageControl.numberOfPages = Int(ceil(Double(cards.count) / Double(cardsPerPage)))
            })
            .bind(to: cardCollectionView.rx.items(
                cellIdentifier: DashboardCardCell.identifier,
                cellType: DashboardCardCell.self
            )) { index, data, cell in
                cell.configure(with: data)
            }
            .disposed(by: disposeBag)
        
        // 그룹화된 차트 바인딩
        output.groupedCharts
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] groupedCharts in
                self?.chartListView.update(groupedCharts: groupedCharts)
            })
            .disposed(by: disposeBag)
        
        // 로딩 상태 바인딩
        output.isLoading
            .observe(on: MainScheduler.instance)
            .bind(to: refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
        
        // 에러 처리
        output.error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
                self?.showErrorAlert(error: error)
            })
            .disposed(by: disposeBag)
        
        // viewDidLoad 트리거
        viewDidLoadSubject.onNext(())
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupPageControlBinding()
    }

    // MARK: - Private Methods
    private func setupPageControlBinding() {
        cardCollectionView.rx.contentOffset
            .observe(on: MainScheduler.instance)
            .map { [weak self] offset -> Int in
                guard let self = self else { return 0 }
                let pageWidth = self.cardCollectionView.bounds.width
                guard pageWidth > 0 else { return 0 }
                let rawPage = (offset.x + pageWidth / 2) / pageWidth
                let page = Int(rawPage.rounded(.down))
                return max(0, min(page, self.pageControl.numberOfPages - 1))
            }
            .distinctUntilChanged()
            .bind(to: pageControl.rx.currentPage)
            .disposed(by: disposeBag)

        pageControl.rx.controlEvent(.valueChanged)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                let page = self.pageControl.currentPage
                let pageWidth = self.cardCollectionView.bounds.width
                guard pageWidth > 0 else { return }
                let targetOffset = CGPoint(x: CGFloat(page) * pageWidth, y: 0)
                self.cardCollectionView.setContentOffset(targetOffset, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func pushBeachChoose() {
        let viewModel = BeachSelectViewModel(
            fetchBeachDataUseCase: DIContainer.shared.makeFetchBeachDataUseCase()
        )
        let vc = BeachSelectViewController(viewModel: viewModel)
        vc.hidesBottomBarWhenPushed = true
        
        // 해변 선택 결과 받기
        vc.onBeachSelected = { [weak self] beachId in
            self?.beachSelectedSubject.onNext(beachId)
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showErrorAlert(error: Error) {
        let alert = UIAlertController(
            title: "데이터 로드 실패",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension DashboardViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 16
        let insets: CGFloat = 40
        let width = (collectionView.frame.width - insets - spacing) / 2
        return CGSize(width: width, height: 120)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView == cardCollectionView else { return }
        
        let pageWidth = scrollView.frame.width
        guard pageWidth > 0 else { return }
        
        let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
        let targetPage: Int
        
        if velocity.x > 0.5 {
            targetPage = currentPage + 1
        } else if velocity.x < -0.5 {
            targetPage = currentPage - 1
        } else {
            targetPage = currentPage
        }
        
        let clampedPage = max(0, min(targetPage, pageControl.numberOfPages - 1))
        targetContentOffset.pointee.x = CGFloat(clampedPage) * pageWidth
        pageControl.currentPage = clampedPage
    }
}

extension DIContainer {
    func makeDashboardViewModel() -> DashboardViewModel {
        return DashboardViewModel(
            fetchBeachDataUseCase: makeFetchBeachDataUseCase()
        )
    }
}

