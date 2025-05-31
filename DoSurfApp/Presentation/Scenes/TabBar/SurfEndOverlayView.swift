import UIKit
import RxSwift
import RxCocoa

// MARK: - Surf End Overlay View
final class SurfEndOverlayView: BaseOverlayView {
    
    // MARK: - Callbacks
    var onSurfEnd: (() -> Void)?
    var onCancelSurfing: (() -> Void)?
    var onCancel: (() -> Void)?
    
    // MARK: - Initialization
    override init(containerSize: CGFloat = 400) {
        super.init(containerSize: containerSize)
        setupUI()
        bindActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        bindActions()
    }
    
    // MARK: - Setup
    private func setupUI() {
        setupButtons(
            main: .primary(title: "서핑 종료"),
            secondary: .capsuled(title: "서핑 취소하기", tintColor: .textRed),
            cancel: .icon(image: UIImage(systemName: "xmark"), tintColor: .surfBlue)
        )
    }
    
    private func bindActions() {
        // 서핑 종료 버튼
        mainButton?.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.onSurfEnd?()
            })
            .disposed(by: disposeBag)
        
        // 서핑 취소하기 버튼
        secondaryButton?.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.onCancelSurfing?()
            })
            .disposed(by: disposeBag)
        
        // 취소 버튼
        cancelButton?.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.onCancel?()
            })
            .disposed(by: disposeBag)
    }
}
