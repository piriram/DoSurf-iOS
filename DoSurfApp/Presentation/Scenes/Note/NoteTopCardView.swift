//
//  SurfRecordTopCard.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/6/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - SurfRecordTopCard
/// 상단 카드: 날짜/시간 피커 + 차트 테이블
final class NoteTopCardView: UIView {
    
    // MARK: - UI Components
    private let containerStack = UIStackView()
    
    // Header (날짜/시간 피커)
    private let headerCard = UIView()
    let datePicker = UIDatePicker()
    let startTimePicker = UIDatePicker()
    let endTimePicker = UIDatePicker()
    
    // Table (차트)
    private let tableCard = UIView()
    private let tableContainer = UIStackView()
    let chartDateLabel = UILabel()
    let tableView = UITableView(frame: .zero, style: .plain)
    
    private let emptyChartLabel: UILabel = {
        let label = UILabel()
        label.text = "차트 데이터가 없습니다."
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    // MARK: - Properties
    private let tableFixedHeight: CGFloat = 260
    private var tableCardHeightConstraint: Constraint?
    
    var charts: [Chart] = [] {
        didSet {
            tableView.reloadData()
            emptyChartLabel.isHidden = !charts.isEmpty
        }
    }
    
    // MARK: - Rx
    let dateChanged = PublishRelay<Date>()
    let startTimeChanged = PublishRelay<Date>()
    let endTimeChanged = PublishRelay<Date>()
    
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
            make.edges.equalToSuperview().inset(12)
        }
        
        // Configure header
        configureHeaderCard()
        containerStack.addArrangedSubview(headerCard)
        
        // Configure table
        configureTableCard()
        containerStack.addArrangedSubview(tableCard)
    }
    
    private func configureHeaderCard() {
        headerCard.backgroundColor = .clear
        
        // Configure pickers
        configureDatePickers()
        
        // Create picker rows
        let dateRow = makePickerRow(title: "서핑 한 날짜", picker: datePicker)
        let startRow = makePickerRow(title: "시작 시간", picker: startTimePicker)
        let endRow = makePickerRow(title: "종료 시간", picker: endTimePicker)
        
        let headerStack = UIStackView(arrangedSubviews: [dateRow, startRow, endRow])
        headerStack.axis = .vertical
        headerStack.spacing = 0
        
        headerCard.addSubview(headerStack)
        headerStack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    private func configureDatePickers() {
        datePicker.datePickerMode = .date
        startTimePicker.datePickerMode = .time
        endTimePicker.datePickerMode = .time
        
        // 타임존을 명시적으로 KST로 지정
        datePicker.timeZone = TimeZone(identifier: "Asia/Seoul")
        startTimePicker.timeZone = TimeZone(identifier: "Asia/Seoul")
        endTimePicker.timeZone = TimeZone(identifier: "Asia/Seoul")
        
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .compact
            startTimePicker.preferredDatePickerStyle = .compact
            endTimePicker.preferredDatePickerStyle = .compact
        }
    }
    
    private func configureTableCard() {
        tableCard.backgroundColor = .clear
        tableCard.layer.masksToBounds = true
        
        tableCard.snp.makeConstraints { make in
            tableCardHeightConstraint = make.height.equalTo(tableFixedHeight).constraint
        }
        
        // Container stack
        tableContainer.axis = .vertical
        tableContainer.spacing = 0
        tableCard.addSubview(tableContainer)
        tableContainer.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        // Date header
        let dateHeaderView = makeDateHeader()
        tableContainer.addArrangedSubview(dateHeaderView)
        
        // Column header
        let columnHeader = makeColumnHeader()
        tableContainer.addArrangedSubview(columnHeader)
        
        // TableView
        configureTableView()
        tableContainer.addArrangedSubview(tableView)
    }
    
    private func makeDateHeader() -> UIView {
        let headerView = UIView()
        chartDateLabel.font = .systemFont(ofSize: 18, weight: .bold)
        chartDateLabel.textColor = .surfBlue
        chartDateLabel.textAlignment = .center
        
        headerView.addSubview(chartDateLabel)
        chartDateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(12)
        }
        
        return headerView
    }
    
    private func makeColumnHeader() -> UIView {
        let header = ChartHeaderView()
        header.snp.makeConstraints { make in
            make.height.equalTo(36)
        }
        return header
    }
    
    private func configureTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 56
        tableView.isScrollEnabled = true
        tableView.showsVerticalScrollIndicator = true
        tableView.tableFooterView = UIView()
        tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: ChartTableViewCell.identifier)
        
        tableView.backgroundView = emptyChartLabel
        emptyChartLabel.isHidden = true
    }
    
    private func makePickerRow(title: String, picker: UIDatePicker) -> UIView {
        let row = UIView()
        let left = UILabel()
        left.text = title
        left.font = .systemFont(ofSize: 14, weight: .regular)
        
        row.addSubview(left)
        row.addSubview(picker)
        
        left.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        picker.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(8)
            make.centerY.equalTo(left)
        }
        
        row.snp.makeConstraints { $0.height.equalTo(44) }
        
        let separator = UIView()
        separator.backgroundColor = .separator
        row.addSubview(separator)
        separator.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
        
        return row
    }
    
    // MARK: - Bind
    private func bind() {
        datePicker.rx.controlEvent(.valueChanged)
            .map { [weak self] in self?.datePicker.date ?? Date() }
            .bind(to: dateChanged)
            .disposed(by: disposeBag)
        
        startTimePicker.rx.controlEvent(.valueChanged)
            .map { [weak self] in self?.startTimePicker.date ?? Date() }
            .bind(to: startTimeChanged)
            .disposed(by: disposeBag)
        
        endTimePicker.rx.controlEvent(.valueChanged)
            .map { [weak self] in self?.endTimePicker.date ?? Date() }
            .bind(to: endTimeChanged)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Public Methods
    func updateChartDateLabel() {
        chartDateLabel.text = datePicker.date.koreanMonthDayWeekday
    }
    
    func setupPickers(date: Date, startTime: Date, endTime: Date) {
        datePicker.date = date
        startTimePicker.date = startTime
        endTimePicker.date = endTime
        updateChartDateLabel()
    }
    
    func updatePickerBounds(dayStart: Date, dayEnd: Date, startTime: Date) {
        startTimePicker.minimumDate = dayStart
        startTimePicker.maximumDate = dayEnd
        
        endTimePicker.minimumDate = startTime
        endTimePicker.maximumDate = dayEnd
    }
}
