import UIKit

final class DateRangePickerViewController: UIViewController {
    var initialStart: Date?
    var initialEnd: Date?
    var onApply: ((Date, Date) -> Void)?

    private let startPicker = UIDatePicker()
    private let endPicker = UIDatePicker()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "기간 선택"

        setupPickers()
        setupLayout()
        setupNavBar()
    }

    private func setupPickers() {
        startPicker.datePickerMode = .date
        endPicker.datePickerMode = .date
        if #available(iOS 14.0, *) {
            startPicker.preferredDatePickerStyle = .inline
            endPicker.preferredDatePickerStyle = .inline
        }
        startPicker.timeZone = TimeZone(identifier: "Asia/Seoul")
        endPicker.timeZone = TimeZone(identifier: "Asia/Seoul")

        let now = Date()
        startPicker.date = initialStart ?? now
        endPicker.date = initialEnd ?? now
        endPicker.minimumDate = startPicker.date
        startPicker.addTarget(self, action: #selector(startChanged), for: .valueChanged)
        endPicker.addTarget(self, action: #selector(endChanged), for: .valueChanged)
    }

    private func setupLayout() {
        let startLabel = UILabel()
        startLabel.text = "시작 날짜"
        startLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        let endLabel = UILabel()
        endLabel.text = "종료 날짜"
        endLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        let stack = UIStackView(arrangedSubviews: [startLabel, startPicker, endLabel, endPicker])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func setupNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "적용", style: .done, target: self, action: #selector(applyTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "취소", style: .plain, target: self, action: #selector(cancelTapped))
    }

    @objc private func startChanged() {
        if endPicker.date < startPicker.date {
            endPicker.date = startPicker.date
        }
        endPicker.minimumDate = startPicker.date
    }

    @objc private func endChanged() {
        if endPicker.date < startPicker.date {
            endPicker.date = startPicker.date
        }
    }

    @objc private func applyTapped() {
        let cal = Calendar.current
        let start = cal.startOfDay(for: startPicker.date)
        let end = cal.startOfDay(for: endPicker.date)
        onApply?(start, end)
        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}
