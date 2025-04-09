import UIKit

final class CreateMemoViewController: UIViewController {
    var onSave: ((String) -> Void)?
    var initialText: String?

    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let countLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "메모 작성"
        setupNavBar()
        setupTextView()
        setupCountLabel()
        setupKeyboardHandling()
        applyInitialTextIfNeeded()
    }

    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "취소", style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "저장", style: .done, target: self, action: #selector(saveTapped))
    }

    private func setupTextView() {
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.delegate = self

        placeholderLabel.text = "메모를 입력하세요..."
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.font = .systemFont(ofSize: 16)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])

        textView.addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 12),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 16)
        ])

        // 키보드 툴바
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [flex, done]
        textView.inputAccessoryView = toolbar
    }

    private func setupCountLabel() {
        countLabel.text = "0자"
        countLabel.textColor = .secondaryLabel
        countLabel.font = .systemFont(ofSize: 13)
        view.addSubview(countLabel)
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 8),
            countLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor)
        ])
    }

    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc private func keyboardWillChange(_ note: Notification) {
        guard let userInfo = note.userInfo,
              let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        let curve = UIView.AnimationOptions(rawValue: curveRaw << 16)

        let converted = view.convert(endFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - converted.origin.y)

        UIView.animate(withDuration: duration, delay: 0, options: curve) {
            self.additionalSafeAreaInsets.bottom = overlap
            self.view.layoutIfNeeded()
        }
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func cancelTapped() { dismiss(animated: true) }

    @objc private func saveTapped() {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            let alert = UIAlertController(title: "메모 없음", message: "내용을 입력해 주세요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }
        onSave?(text)
        dismiss(animated: true)
    }

    private func applyInitialTextIfNeeded() {
        guard let text = initialText, !text.isEmpty else { return }
        textView.text = text
        placeholderLabel.isHidden = true
        countLabel.text = "\(text.count)자"
        // Optionally update title for edit mode
        if self.title == nil || self.title?.isEmpty == true {
            self.title = "메모 편집"
        }
    }
}

extension CreateMemoViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        countLabel.text = "\(textView.text.count)자"
    }
}
