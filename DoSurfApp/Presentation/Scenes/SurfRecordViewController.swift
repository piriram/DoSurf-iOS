//
//  SurfRecordViewController.swift
//  DoSurfApp
//
//  Created by Assistant on 9/29/25.
//
import UIKit
import RxSwift
import RxCocoa
import SnapKit

class SurfRecordViewController: BaseViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var surfRecord: SurfRecord?
    private var charts: [Chart] = []
    private var isCommentExpanded = false
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header Section
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private let surfingDateLabel: UILabel = {
        let label = UILabel()
        label.text = "서핑 한 날"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let dateValueLabel: UILabel = {
        let label = UILabel()
        label.text = "June 2024"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .systemBlue
        return label
    }()
    
    private let startTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "시작 시간"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let startTimeValueLabel: UILabel = {
        let label = UILabel()
        label.text = "13:00"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .systemBlue
        return label
    }()
    
    private let endTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "종료 시간"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let endTimeValueLabel: UILabel = {
        let label = UILabel()
        label.text = "15:00"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .systemBlue
        return label
    }()
    
    // Chart Section
    private lazy var chartContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private let chartDateLabel: UILabel = {
        let label = UILabel()
        label.text = "7월 25일 목요일"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private lazy var chartTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: ChartTableViewCell.identifier)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 56
        tableView.isScrollEnabled = false
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
    
    // Wave Rating Section
    private lazy var waveRatingView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private let waveRatingTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 파도 평가"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private lazy var ratingStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = 20
        return stackView
    }()
    
    // Comment Section
    private lazy var commentView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private let commentTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "파도 코멘트"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private lazy var addCommentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("메모 추가", for: .normal)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        button.setTitleColor(.systemBlue, for: .normal)
        button.tintColor = .systemBlue
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        return button
    }()
    
    private lazy var commentTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .systemGray6
        textView.layer.cornerRadius = 12
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .label
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.text = "서핑 경험이나 파도 상태에 대한 메모를 작성해보세요..."
        textView.textColor = .placeholderText
        textView.isHidden = true
        return textView
    }()
    
    // Save Button
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("기록 저장", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 12
        return button
    }()
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMockData()
    }
    
    // MARK: - Overrides from BaseViewController
    override func configureNavigationBar() {
        super.configureNavigationBar()
        title = "서핑 기록"
        
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: nil,
            action: nil
        )
        navigationItem.leftBarButtonItem = closeButton
    }

    override func configureUI() {
        view.backgroundColor = .systemGroupedBackground
        
        // 초기에는 스크롤 비활성화
        scrollView.isScrollEnabled = false
        
        setupRatingView()
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add all subviews
        contentView.addSubview(headerView)
        contentView.addSubview(chartContainerView)
        contentView.addSubview(waveRatingView)
        contentView.addSubview(commentView)
        contentView.addSubview(saveButton)
        
        // Header components
        headerView.addSubview(surfingDateLabel)
        headerView.addSubview(dateValueLabel)
        headerView.addSubview(startTimeLabel)
        headerView.addSubview(startTimeValueLabel)
        headerView.addSubview(endTimeLabel)
        headerView.addSubview(endTimeValueLabel)
        
        // Chart components
        chartContainerView.addSubview(chartDateLabel)
        chartContainerView.addSubview(chartTableView)
        
        // Wave rating components
        waveRatingView.addSubview(waveRatingTitleLabel)
        waveRatingView.addSubview(ratingStackView)
        
        // Comment components
        commentView.addSubview(commentTitleLabel)
        commentView.addSubview(addCommentButton)
        commentView.addSubview(commentTextView)
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        // Header layout
        headerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        surfingDateLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(20)
        }
        
        dateValueLabel.snp.makeConstraints { make in
            make.top.equalTo(surfingDateLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(20)
        }
        
        startTimeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20)
            make.centerX.equalToSuperview()
        }
        
        startTimeValueLabel.snp.makeConstraints { make in
            make.top.equalTo(startTimeLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
        
        endTimeLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(20)
        }
        
        endTimeValueLabel.snp.makeConstraints { make in
            make.top.equalTo(endTimeLabel.snp.bottom).offset(4)
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(20)
        }
        
        // Chart layout
        chartContainerView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        chartDateLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20)
            make.centerX.equalToSuperview()
        }
        
        chartTableView.snp.makeConstraints { make in
            make.top.equalTo(chartDateLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(200) // 3-4개 행 정도
        }
        
        // Wave rating layout
        waveRatingView.snp.makeConstraints { make in
            make.top.equalTo(chartContainerView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        waveRatingTitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(20)
        }
        
        ratingStackView.snp.makeConstraints { make in
            make.top.equalTo(waveRatingTitleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(20)
            make.height.equalTo(80)
        }
        
        // Comment layout
        commentView.snp.makeConstraints { make in
            make.top.equalTo(waveRatingView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        commentTitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(20)
        }
        
        addCommentButton.snp.makeConstraints { make in
            make.top.equalTo(commentTitleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().inset(20)
        }
        
        commentTextView.snp.makeConstraints { make in
            make.top.equalTo(addCommentButton.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(120)
            make.bottom.equalToSuperview().inset(20)
        }
        
        // Save button layout
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(commentView.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(56)
            make.bottom.equalToSuperview().inset(40)
        }
    }

    override func configureAction() {
        // Navigation close button
        navigationItem.leftBarButtonItem?.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        // Add comment button
        addCommentButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.toggleCommentSection()
            })
            .disposed(by: disposeBag)
        
        // Save button
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.saveRecord()
            })
            .disposed(by: disposeBag)
    }

    override func configureBind() {
        // Chart table view binding
        Observable.just(charts)
            .bind(to: chartTableView.rx.items(cellIdentifier: ChartTableViewCell.identifier, cellType: ChartTableViewCell.self)) { index, chart, cell in
                cell.configure(with: chart)
            }
            .disposed(by: disposeBag)
        
        // Comment text view placeholder handling
        commentTextView.rx.didBeginEditing
            .subscribe(onNext: { [weak self] in
                self?.handleTextViewBeginEditing()
            })
            .disposed(by: disposeBag)
        
        commentTextView.rx.didEndEditing
            .subscribe(onNext: { [weak self] in
                self?.handleTextViewEndEditing()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    private func setupRatingView() {
        let ratings = ["1점\n별로예요", "2점\n그저그래요", "3점\n괜찮아요", "4점\n만족해요", "5점\n최고예요"]
        
        for (index, rating) in ratings.enumerated() {
            let ratingButton = createRatingButton(title: rating, rating: index + 1)
            ratingStackView.addArrangedSubview(ratingButton)
        }
    }
    
    private func createRatingButton(title: String, rating: Int) -> UIButton {
        let button = UIButton(type: .system)
        
        let lines = title.components(separatedBy: "\n")
        let attributedTitle = NSMutableAttributedString()
        
        // 첫 번째 줄 (점수)
        let scoreText = NSAttributedString(
            string: lines[0] + "\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
        )
        attributedTitle.append(scoreText)
        
        // 두 번째 줄 (설명)
        let descText = NSAttributedString(
            string: lines[1],
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
        attributedTitle.append(descText)
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        
        // 별 아이콘 추가
        let starImage = UIImage(systemName: "star.fill")
        button.setImage(starImage, for: .normal)
        button.tintColor = .systemGray4
        
        button.contentVerticalAlignment = .center
        button.imageEdgeInsets = UIEdgeInsets(top: -30, left: 0, bottom: 0, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: 20, left: -20, bottom: 0, right: 0)
        
        // Rating button action
        button.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.selectRating(rating)
            })
            .disposed(by: disposeBag)
        
        return button
    }
    
    private func selectRating(_ rating: Int) {
        // 모든 버튼 초기화
        for (index, view) in ratingStackView.arrangedSubviews.enumerated() {
            if let button = view as? UIButton {
                let isSelected = index < rating
                button.tintColor = isSelected ? .systemYellow : .systemGray4
            }
        }
        
        // 햅틱 피드백
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
    }
    
    private func toggleCommentSection() {
        isCommentExpanded.toggle()
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            if self.isCommentExpanded {
                // 텍스트뷰 표시 및 스크롤 활성화
                self.commentTextView.isHidden = false
                self.addCommentButton.setTitle("메모 숨기기", for: .normal)
                self.addCommentButton.setImage(UIImage(systemName: "minus"), for: .normal)
                self.scrollView.isScrollEnabled = true
                
                // 댓글 섹션 하단 제약 조건 업데이트
                self.commentView.snp.updateConstraints { make in
                    // 기존 bottom constraint 업데이트는 자동으로 처리됨
                }
                
            } else {
                // 텍스트뷰 숨기기 및 스크롤 비활성화
                self.commentTextView.isHidden = true
                self.addCommentButton.setTitle("메모 추가", for: .normal)
                self.addCommentButton.setImage(UIImage(systemName: "plus"), for: .normal)
                self.scrollView.isScrollEnabled = false
                self.scrollView.setContentOffset(.zero, animated: true)
            }
            
            self.view.layoutIfNeeded()
        } completion: { _ in
            if self.isCommentExpanded {
                // 텍스트뷰가 보이도록 스크롤
                self.scrollView.scrollRectToVisible(self.commentTextView.frame, animated: true)
                self.commentTextView.becomeFirstResponder()
            }
        }
    }
    
    private func handleTextViewBeginEditing() {
        if commentTextView.textColor == .placeholderText {
            commentTextView.text = ""
            commentTextView.textColor = .label
        }
    }
    
    private func handleTextViewEndEditing() {
        if commentTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            commentTextView.text = "서핑 경험이나 파도 상태에 대한 메모를 작성해보세요..."
            commentTextView.textColor = .placeholderText
        }
    }
    
    private func saveRecord() {
        // 햅틱 피드백
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        
        // 실제 저장 로직 구현
        // TODO: ViewModel을 통한 데이터 저장
        
        // 저장 완료 후 화면 닫기
        dismiss(animated: true)
    }
    
    private func setupMockData() {
        charts = [
            Chart(
                beachID: 1001,
                time: Date(),
                windDirection: 0.0,
                windSpeed: 3.3,
                waveDirection: 0.0,
                waveHeight: 0.2,
                wavePeriod: 3.3,
                waterTemperature: 28,
                weather: .clear,
                airTemperature: 28
            ),
            Chart(
                beachID: 1001,
                time: Date().addingTimeInterval(3600),
                windDirection: 0.0,
                windSpeed: 3.3,
                waveDirection: 0.0,
                waveHeight: 0.2,
                wavePeriod: 3.3,
                waterTemperature: 28,
                weather: .clear,
                airTemperature: 28
            ),
            Chart(
                beachID: 1001,
                time: Date().addingTimeInterval(7200),
                windDirection: 0.0,
                windSpeed: 3.3,
                waveDirection: 0.0,
                waveHeight: 0.2,
                wavePeriod: 3.3,
                waterTemperature: 28,
                weather: .clear,
                airTemperature: 28
            )
        ]
    }
}

// MARK: - Supporting Models
struct SurfRecord {
    let id: String
    let date: Date
    let startTime: Date
    let endTime: Date
    let location: String
    let rating: Int?
    let comment: String?
    let charts: [Chart]
}
