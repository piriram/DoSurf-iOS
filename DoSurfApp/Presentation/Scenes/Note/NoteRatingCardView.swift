import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class NoteRatingCardView: UIView {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let numberOfSteps = 5
    private var circleViews: [UIImageView] = []
    private var circlePositions: [CGFloat] = []
    
    // MARK: - Observables
    let selectedRating = BehaviorRelay<Int>(value: 3)
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 파도 평가"
        label.font = .systemFont(ofSize: FontSize.subheading, weight: FontSize.bold)
        label.textColor = .surfBlue
        return label
    }()
    
    private let trackContainerView = UIView()
    
    private let trackLineView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: AssetImage.line)
        view.contentMode = .scaleToFill
        return view
    }()
    
    private let starImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: AssetImage.ratingStarFill)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let labelsContainerView = UIView()
    private var labelContainers: [UIView] = []
    private var labelCenterXConstraints: [Constraint] = []
    
    private let ratingDescriptions = [
        "별로에요",
        "아쉬워요",
        "보통이에요",
        "만족해요",
        "최고에요"
    ]
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        bind()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        bind()
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        
        addSubview(titleLabel)
        addSubview(trackContainerView)
        addSubview(labelsContainerView)
        
        trackContainerView.addSubview(trackLineView)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().offset(16)
        }
        
        trackContainerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(40)
            $0.height.equalTo(40)
        }
        
        trackLineView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.height.equalTo(4)
        }
        
        labelsContainerView.snp.makeConstraints {
            $0.top.equalTo(trackContainerView.snp.bottom).offset(8)
            $0.leading.trailing.equalTo(trackContainerView)
            $0.bottom.equalToSuperview().offset(-20)
        }
        
        setupCircles()
        setupStar()
        setupLabels()
        
        // 팬 제스처 추가
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        trackContainerView.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        trackContainerView.addGestureRecognizer(tapGesture)
    }
    
    private func setupCircles() {
        for i in 0..<numberOfSteps {
            let circleView = UIImageView()
            circleView.image = UIImage(named: AssetImage.ellipse)
            circleView.contentMode = .scaleAspectFit
            circleView.tag = i + 1
            
            trackContainerView.addSubview(circleView)
            circleViews.append(circleView)
            
            circleView.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.width.height.equalTo(16)
            }
        }
    }
    
    private func setupStar() {
        trackContainerView.addSubview(starImageView)
        
        starImageView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(26)
        }
    }
    
    private func setupLabels() {
        for (index, description) in ratingDescriptions.enumerated() {
            let containerView = UIView()
            
            containerView.backgroundColor = .clear
            containerView.layer.cornerRadius = 0
            containerView.clipsToBounds = false
            
            let pointLabel = UILabel()
            pointLabel.text = "\(index + 1)점"
            pointLabel.font = .systemFont(ofSize: FontSize.body2Size, weight: FontSize.bold)
            pointLabel.textColor = .surfBlue
            pointLabel.textAlignment = .center
            
            let pointRow = UIStackView(arrangedSubviews: [pointLabel])
            pointRow.axis = .horizontal
            pointRow.alignment = .center
            pointRow.spacing = 4
            
            let descLabel = UILabel()
            descLabel.text = description
            descLabel.font = .systemFont(ofSize: FontSize.twelve,weight: FontSize.medium)
            descLabel.textColor = .surfBlue
            descLabel.textAlignment = .center
            
            containerView.addSubview(pointRow)
            containerView.addSubview(descLabel)
            
            pointRow.snp.makeConstraints {
                $0.top.equalToSuperview().offset(6)
                $0.leading.trailing.equalToSuperview().inset(10)
            }
            
            descLabel.snp.makeConstraints {
                $0.top.equalTo(pointRow.snp.bottom).offset(2)
                $0.leading.trailing.equalToSuperview().inset(10)
                $0.bottom.equalToSuperview().offset(-6)
            }
            
            labelsContainerView.addSubview(containerView)
            
            containerView.snp.makeConstraints {
                $0.top.bottom.equalToSuperview()
                let c = $0.centerX.equalTo(labelsContainerView.snp.leading).offset(0).constraint
                labelCenterXConstraints.append(c)
            }
            
            containerView.setContentHuggingPriority(.required, for: .horizontal)
            containerView.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            labelContainers.append(containerView)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCirclePositions()
        updateLabelPositions()
        updateStarPosition(for: selectedRating.value, animated: false)
    }
    
    private func updateCirclePositions() {
        guard !circleViews.isEmpty else { return }
        
        let trackWidth = trackContainerView.bounds.width
        let spacing = trackWidth / CGFloat(numberOfSteps - 1)
        
        circlePositions.removeAll()
        
        for (index, circleView) in circleViews.enumerated() {
            let xPosition = CGFloat(index) * spacing
            circlePositions.append(xPosition)
            
            circleView.snp.remakeConstraints {
                $0.centerY.equalToSuperview()
                $0.leading.equalToSuperview().offset(xPosition - 8)
                $0.width.height.equalTo(16)
            }
        }
        
        layoutIfNeeded()
    }
    
    private func updateLabelPositions() {
        guard circlePositions.count == numberOfSteps, labelCenterXConstraints.count == numberOfSteps else { return }
        for (index, constraint) in labelCenterXConstraints.enumerated() {
            let x = circlePositions[index]
            constraint.update(offset: x)
        }
        layoutIfNeeded()
    }
    
    // MARK: - Gesture Handlers
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: trackContainerView)
        updateRatingFromLocation(location.x)
    }
    
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: trackContainerView)
        updateRatingFromLocation(location.x)
    }
    
    private func updateRatingFromLocation(_ x: CGFloat) {
        guard !circlePositions.isEmpty else { return }
        
        let clampedX = max(0, min(x, trackContainerView.bounds.width))
        
        // 가장 가까운 원 찾기
        var closestIndex = 0
        var minDistance = CGFloat.greatestFiniteMagnitude
        
        for (index, position) in circlePositions.enumerated() {
            let distance = abs(position - clampedX)
            if distance < minDistance {
                minDistance = distance
                closestIndex = index
            }
        }
        
        let newRating = closestIndex + 1
        if newRating != selectedRating.value {
            selectedRating.accept(newRating)
        }
    }
    
    // MARK: - Binding
    private func bind() {
        selectedRating
            .asDriver()
            .drive(onNext: { [weak self] rating in
                self?.updateStarPosition(for: rating, animated: true)
                self?.updateCircleColors(for: rating)
            })
            .disposed(by: disposeBag)
    }
    
    private func updateStarPosition(for rating: Int, animated: Bool) {
        guard rating > 0, rating <= circlePositions.count else { return }
        
        let xPosition = circlePositions[rating - 1]
        
        starImageView.snp.remakeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(xPosition - 16)
            $0.width.height.equalTo(26)
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }
    }
    
    private func updateCircleColors(for rating: Int) {
        circleViews.enumerated().forEach { index, imageView in
            let isActive = index < rating
            let templateImage = UIImage(named: AssetImage.ellipse)
            imageView.image = templateImage
            
        }
    }
}

