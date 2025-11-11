//
//  RecordHistoryVC+Presentation.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 11/11/25.
//

import UIKit
import CoreData
import RxSwift
import RxRelay

// MARK: - Presentation Methods
extension RecordHistoryViewController {
    
    func presentLocationSelector() {
        let selectedBeachID = viewModel.selectedBeachIDRelay.value
        let beaches = viewModel.beachesRelay.value
        let selectedBeach = beaches.first { Int($0.id) == selectedBeachID }
        
        let beachSelectViewModel = DIContainer.shared.makeBeachSelectViewModel(
            initialSelectedBeach: selectedBeach
        )
        let beachSelectViewController = BeachSelectViewController(viewModel: beachSelectViewModel)
        beachSelectViewController.hidesBottomBarWhenPushed = true
        beachSelectViewController.showAllButton = true
        
        beachSelectViewController.onBeachSelected = { [weak self] beach in
            guard let beachID = Int(beach.id) else { return }
            self?.locationSelectionSubject.onNext(beachID)
            self?.scrollToTop()
        }
        
        beachSelectViewController.onAllBeachesSelected = { [weak self] in
            self?.locationSelectionSubject.onNext(nil)
            self?.scrollToTop()
        }
        
        navigationController?.pushViewController(beachSelectViewController, animated: true)
    }
    
    func presentSortMenu() {
        let sortOptions: [SortType] = [.latest, .oldest, .highRating, .lowRating]
        
        let actions = sortOptions.map { sortType in
            (title: sortType.title, style: UIAlertAction.Style.default, handler: { [weak self] in
                self?.sortSelectionSubject.onNext(sortType)
                self?.scrollToTop()
            })
        }
        
        showActionSheet(actions: actions)
    }
    
    func presentRatingFilter() {
        var actions: [(title: String, style: UIAlertAction.Style, handler: (() -> Void)?)] = []
        
        for rating in (1...5).reversed() {
            actions.append((
                title: "\(rating)점",
                style: .default,
                handler: {
                    // TODO: ratingFilterSubject 연결
                }
            ))
        }
        
        actions.append((
            title: "전체",
            style: .default,
            handler: {
                // TODO: all filter 연결
            }
        ))
        
        showActionSheet(title: "별점 필터", actions: actions)
    }
    
    func presentDatePresetMenu() {
        let presets: [(String, DatePreset)] = [
            ("오늘", .today),
            ("최근 7일", .last7Days),
            ("이번 달", .thisMonth),
            ("지난 달", .lastMonth)
        ]
        
        var actions = presets.map { title, preset in
            (title: title, style: UIAlertAction.Style.default, handler: { [weak self] in
                // TODO: datePresetSubject 연결
            })
        }
        
        actions.append((
            title: "사용자 지정…",
            style: .default,
            handler: { [weak self] in
                self?.presentDateRangePicker()
            }
        ))
        
        showActionSheet(title: "날짜 프리셋", actions: actions)
    }
    
    func presentDateRangePicker() {
        let pickerViewController = DateRangePickerViewController()
        pickerViewController.initialStart = Date()
        pickerViewController.initialEnd = Date()
        
        pickerViewController.onApply = { [weak self] start, end in
            // TODO: dateRangeSubject 연결
        }
        
        let navigationController = UINavigationController(rootViewController: pickerViewController)
        navigationController.modalPresentationStyle = .popover
        navigationController.preferredContentSize = CGSize(width: 360, height: 420)
        
        if let popoverController = navigationController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: 88, width: 1, height: 1)
            popoverController.permittedArrowDirections = [.up, .down]
            popoverController.delegate = self
        }
        
        present(navigationController, animated: true)
    }
    
    func presentActionSheet(for viewModel: RecordCardViewModel) {
        guard let objectID = viewModel.objectID else { return }
        
        let pinTitle = viewModel.isPin ? "핀 해제" : "핀 고정"
        
        let actions: [(title: String, style: UIAlertAction.Style, handler: (() -> Void)?)] = [
            (title: pinTitle, style: .default, handler: { [weak self] in
                self?.pinRecordSubject.onNext(objectID)
            }),
            (title: "수정", style: .default, handler: { [weak self] in
                self?.presentEditRecord(for: objectID)
            }),
            (title: "삭제", style: .destructive, handler: { [weak self] in
                self?.presentDeleteConfirmation(for: objectID)
            })
        ]
        
        showActionSheet(actions: actions)
    }
    
    func presentDeleteConfirmation(for objectID: NSManagedObjectID) {
        showConfirmationAlert(
            title: "기록 삭제",
            message: "이 기록을 삭제하시겠습니까?",
            confirmTitle: "삭제",
            confirmStyle: .destructive,
            onConfirm: { [weak self] in
                self?.deleteRecordSubject.onNext(objectID)
            }
        )
    }
    
    func presentEditRecord(for objectID: NSManagedObjectID) {
        // TODO: Implement edit record navigation
    }
    
    func handleMemoTap(for viewModel: RecordCardViewModel) {
        let currentMemo = viewModel.memo
        
        if currentMemo?.isEmpty ?? true {
            presentMemoEditor(for: viewModel, initialText: nil)
        } else {
            let actions: [(title: String, style: UIAlertAction.Style, handler: (() -> Void)?)] = [
                (title: "메모 보기", style: .default, handler: { [weak self] in
                    self?.showMemoDetail(for: viewModel)
                }),
                (title: "메모 편집", style: .default, handler: { [weak self] in
                    self?.presentMemoEditor(for: viewModel, initialText: currentMemo)
                })
            ]
            
            showActionSheet(actions: actions)
        }
    }
    
    func presentMemoEditor(for viewModel: RecordCardViewModel, initialText: String?) {
        let editorViewController = CreateMemoViewController()
        editorViewController.initialText = initialText
        
        editorViewController.onSave = { [weak self] text in
            guard let self = self, let objectID = viewModel.objectID else {
                self?.showErrorAlert(message: "선택된 기록을 찾을 수 없습니다.")
                return
            }
            self.updateMemoOnly(objectID: objectID, newMemo: text)
        }
        
        let navigationController = UINavigationController(rootViewController: editorViewController)
        navigationController.modalPresentationStyle = .pageSheet
        
        if let sheetController = navigationController.sheetPresentationController {
            sheetController.detents = [.medium(), .large()]
            sheetController.prefersGrabberVisible = true
        }
        
        present(navigationController, animated: true)
    }
    
    func updateMemoOnly(objectID: NSManagedObjectID, newMemo: String) {
        // TODO: Implement memo update logic
    }
    
    func showMemoDetail(for viewModel: RecordCardViewModel) {
        let memoViewController = MemoDetailViewController(viewModel: viewModel)
        memoViewController.modalPresentationStyle = .pageSheet
        
        if let sheetController = memoViewController.sheetPresentationController {
            sheetController.detents = [.medium(), .large()]
            sheetController.prefersGrabberVisible = true
        }
        
        present(memoViewController, animated: true)
    }
}

