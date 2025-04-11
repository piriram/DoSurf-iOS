import UIKit
import SnapKit

final class CreateMemoViewController: UIViewController {
    
    // MARK: - Properties
    
    var onSave: ((String) -> Void)?
    var initialText: String?
    
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let bottomBar = UIView()
    private let countLabel = UILabel()
    
    private let maxCharacterCount = 1000
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupLayout()
        setupKeyboardHandling()
        applyInitialTextIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .backgroundWhite
        
        setupHeaderView()
        setupTextView()
        setupBottomBar()
        setupSheetPresentation()
    }
    
    private func setupSheetPresentation() {
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
            sheet.largestUndimmedDetentIdentifier = .medium
        }
    }
    
    private func setupHeaderView() {
        headerView.backgroundColor = .backgroundHeader
        view.addSubview(headerView)
        
        titleLabel.text = "메모 작성"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .lableBlack
        titleLabel.textAlignment = .center
        headerView.addSubview(titleLabel)
        
        closeButton.setTitle("취소", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        closeButton.setTitleColor(.secondaryLabel, for: .normal)
        closeButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        headerView.addSubview(closeButton)
        
        saveButton.setTitle("저장", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        saveButton.setTitleColor(.surfBlue, for: .normal)
        saveButton.setTitleColor(.surfBlue.withAlphaComponent(0.5), for: .disabled)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.isEnabled = false
        headerView.addSubview(saveButton)
    }
    
    private func setupTextView() {
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .lableBlack
        textView.backgroundColor = .white
        textView.layer.cornerRadius = 16
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.backgroundGray.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.delegate = self
        textView.showsVerticalScrollIndicator = false
        view.addSubview(textView)
        
        placeholderLabel.text = "메모를 입력하세요..."
        placeholderLabel.textColor = .tertiaryLabel
        placeholderLabel.font = .systemFont(ofSize: 16)
        textView.addSubview(placeholderLabel)
    }
    
    private func setupBottomBar() {
        bottomBar.backgroundColor = .clear
        view.addSubview(bottomBar)
        
        countLabel.text = "0 / \(maxCharacterCount)"
        countLabel.textColor = .secondaryLabel
        countLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        countLabel.textAlignment = .right
        bottomBar.addSubview(countLabel)
    }
    
    private func setupLayout() {
        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(56)
        }
        
        closeButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        saveButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
        
        textView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(bottomBar.snp.top).offset(-12)
        }
        
        placeholderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.equalToSuperview().inset(21)
        }
        
        bottomBar.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top).offset(-12)
            $0.height.equalTo(20)
        }
        
        countLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - Actions
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        onSave?(text)
        dismiss(animated: true)
    }
    
    private func applyInitialTextIfNeeded() {
        guard let text = initialText, !text.isEmpty else { return }
        textView.text = text
        updateUI()
        titleLabel.text = "메모 편집"
    }
    
    private func updateUI() {
        let text = textView.text ?? ""
        let count = text.count
        
        placeholderLabel.isHidden = !text.isEmpty
        saveButton.isEnabled = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if count > maxCharacterCount {
            countLabel.textColor = .systemRed
            countLabel.text = "\(count) / \(maxCharacterCount)"
        } else {
            countLabel.textColor = .secondaryLabel
            countLabel.text = "\(count) / \(maxCharacterCount)"
        }
    }
}

// MARK: - UITextViewDelegate

extension CreateMemoViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateUI()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        return updatedText.count <= maxCharacterCount
    }
}
