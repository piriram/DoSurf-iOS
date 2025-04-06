import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class SurfRatingCardView: UIView {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let numberOfSteps = 5
    private var circleViews: [UIImageView] = []
    private var circlePositions: [CGFloat] = []
    
    // MARK: - Observables
    let selectedRating = BehaviorRelay<Int>(value: 1)
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 파도 평가"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        return label
    }()
    
    private let trackContainerView = UIView()
    
    private let trackLineView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "line")
        view.contentMode = .scaleToFill
        return view
    }()
    
    private let starImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "ratingStar")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let labelsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        return stackView
    }()
    
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
        addSubview(labelsStackView)
        
        trackContainerView.addSubview(trackLineView)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(20)
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
        
        labelsStackView.snp.makeConstraints {
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
            circleView.image = UIImage(named: "elipse")
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
            $0.width.height.equalTo(32)
        }
    }
    
    private func setupLabels() {
        for (index, description) in ratingDescriptions.enumerated() {
            let containerView = UIView()
            
            let pointLabel = UILabel()
            pointLabel.text = "\(index + 1)점"
            pointLabel.font = .systemFont(ofSize: 11, weight: .medium)
            pointLabel.textColor = .systemGray
            pointLabel.textAlignment = .center
            
            let descLabel = UILabel()
            descLabel.text = description
            descLabel.font = .systemFont(ofSize: 10)
            descLabel.textColor = .systemGray2
            descLabel.textAlignment = .center
            
            containerView.addSubview(pointLabel)
            containerView.addSubview(descLabel)
            
            pointLabel.snp.makeConstraints {
                $0.top.leading.trailing.equalToSuperview()
            }
            
            descLabel.snp.makeConstraints {
                $0.top.equalTo(pointLabel.snp.bottom).offset(2)
                $0.leading.trailing.bottom.equalToSuperview()
            }
            
            labelsStackView.addArrangedSubview(containerView)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCirclePositions()
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
            $0.width.height.equalTo(32)
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
            let templateImage = UIImage(named: "eclipse")?.withRenderingMode(.alwaysTemplate)
            imageView.image = templateImage
            imageView.tintColor = isActive ? .systemBlue : .systemGray4
        }
    }
}

// MARK: - Preview
#if DEBUG
import SwiftUI

struct SurfRatingCardViewPreview: PreviewProvider {
    static var previews: some View {
        UIViewPreviewWrapper {
            let view = SurfRatingCardView()
            view.backgroundColor = .systemGray6
            return view
        }
        .frame(height: 160)
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

struct UIViewPreviewWrapper<T: UIView>: UIViewRepresentable {
    let viewBuilder: () -> T
    
    func makeUIView(context: Context) -> T {
        viewBuilder()
    }
    
    func updateUIView(_ uiView: T, context: Context) {}
}
#endif
