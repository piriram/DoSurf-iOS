import UIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - SurfRecordBottomCard
/// 하단 카드: 별점 평가 + 메모
final class NoteBottomCardView: UIView {
    
    // MARK: - UI Components
    private let containerStack = UIStackView()
    
    // Rating
    let ratingCardView = NoteRatingCardView()
    
    // Comment
    private let commentCard = UIView()
    private let commentTitle = UILabel()
    let addMemoButton = UIButton(type: .system)
    let memoTextView = UITextView()
    
    // MARK: - Properties
    private(set) var isMemoOpened = false
    
    // MARK: - Rx
    let memoButtonTapped = PublishRelay<Void>()
    let requestScrollToMemo = PublishRelay<Void>()
    
    var ratingChanged: Observable<Int> {
        return ratingCardView.selectedRating.asObservable()
    }
    
    var memoChanged: Observable<String?> {
        return memoTextView.rx.text.asObservable()
    }
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        bind()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureUI()
        bind()
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        // Container style
        layer.cornerRadius = 12
        layer.masksToBounds = true
        backgroundColor = .white
        
        // Container stack
        containerStack.axis = .vertical
        containerStack.spacing = 12
        addSubview(containerStack)
        containerStack.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(16)
        }
        
        // Rating
        configureRatingCard()
        containerStack.addArrangedSubview(ratingCardView)
        
        // Comment
        configureCommentCard()
        containerStack.addArrangedSubview(commentCard)
    }
    
    private func configureRatingCard() {
        ratingCardView.backgroundColor = .clear
        // 기본 별점 3점
        ratingCardView.selectedRating.accept(3)
    }
    
    private func configureCommentCard() {
        commentCard.backgroundColor = .clear
        
        // Title
        commentTitle.text = "파도 코멘트"
        commentTitle.font = .systemFont(ofSize: FontSize.subheading, weight: FontSize.bold)
        commentTitle.textColor = .surfBlue
        
        // Add memo button
        addMemoButton.setTitle("메모 추가  ", for: .normal)
        addMemoButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addMemoButton.tintColor = .surfBlue
        addMemoButton.titleLabel?.font = .systemFont(ofSize: FontSize.body1, weight: FontSize.semibold)
        addMemoButton.semanticContentAttribute = .forceRightToLeft
        addMemoButton.backgroundColor = .white
        addMemoButton.layer.cornerRadius = 20
        addMemoButton.layer.borderWidth = 1
        addMemoButton.layer.borderColor = UIColor.surfBlue.cgColor
        addMemoButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 10)
        
        // Memo text view
        memoTextView.isHidden = true
        memoTextView.font = .systemFont(ofSize: 15)
        memoTextView.backgroundColor = UIColor.secondarySystemBackground
        memoTextView.layer.cornerRadius = 10
        memoTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        memoTextView.snp.makeConstraints { $0.height.greaterThanOrEqualTo(100) }
        
        // Stack
        let commentStack = UIStackView(arrangedSubviews: [commentTitle, addMemoButton, memoTextView])
        commentStack.axis = .vertical
        commentStack.spacing = 12
        
        commentCard.addSubview(commentStack)
        commentStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        commentTitle.snp.makeConstraints { make in
            make.leading.equalTo(commentStack.snp.leading).inset(16)
        }
        
        addMemoButton.snp.makeConstraints { make in
            make.leading.equalTo(commentStack.snp.leading).inset(16)
            make.trailing.equalTo(commentStack.snp.trailing).inset(16)
        }
        
        memoTextView.snp.makeConstraints { make in
            make.leading.equalTo(commentStack.snp.leading).inset(16)
            make.trailing.equalTo(commentStack.snp.trailing).inset(16)
        }
    }
    
    // MARK: - Bind
    private func bind() {
        // Forward add memo button taps
        addMemoButton.rx.tap
            .bind(to: memoButtonTapped)
            .disposed(by: disposeBag)
        
        // When memo text view begins editing, request parent to scroll to it
        memoTextView.rx.didBeginEditing
            .map { }
            .bind(to: requestScrollToMemo)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Public Methods
    func showMemoTextView() {
        guard !isMemoOpened else { return }
        isMemoOpened = true
        memoTextView.isHidden = false
        // Ask parent to scroll to the memo area
        requestScrollToMemo.accept(())
    }
    
    func setupRating(_ rating: Int) {
        let validRating = max(1, min(5, rating))
        ratingCardView.selectedRating.accept(validRating)
    }
    
    func setupMemo(_ memo: String?) {
        guard let memo = memo, !memo.isEmpty else { return }
        memoTextView.text = memo
        memoTextView.isHidden = false
        isMemoOpened = true
        // Ensure visibility when a memo is preset
        requestScrollToMemo.accept(())
    }
    
    func getRating() -> Int {
        ratingCardView.selectedRating.value
    }
    
    func getMemo() -> String? {
        guard !memoTextView.isHidden, !memoTextView.text.isEmpty else {
            return nil
        }
        return memoTextView.text
    }
}

