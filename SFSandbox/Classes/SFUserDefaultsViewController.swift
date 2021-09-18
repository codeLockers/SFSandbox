//
//  SFUserDefaultsViewController.swift
//  SFSandbox
//
//  Created by coker on 2021/9/15.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class SFUserDefaultsViewController: SFViewController, UIScrollViewDelegate {
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(SFUserDefaultsCell.self, forCellReuseIdentifier: SFUserDefaultsCell.reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 60
        return tableView
    }()

    private var flatViewModel: SFUserDefaultsViewModel? { self.viewModel as? SFUserDefaultsViewModel }

    override init(file: SFFileManager.SFFileItem) {
        super.init(file: file)
        self.viewModel = SFUserDefaultsViewModel(file: file)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        handleRxBindings()
        flatViewModel?.refreshAllDatas()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        flatViewModel?.refreshAllDatas()
    }

    private func handleRxBindings() {
        flatViewModel?.itemsRelay.bind(to: tableView.rx.items) { (tableView, _, element) in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SFUserDefaultsCell.reuseIdentifier) as? SFUserDefaultsCell
            else {
                return SFUserDefaultsCell(style: .default, reuseIdentifier: SFUserDefaultsCell.reuseIdentifier)
            }
            cell.render(element)
            return cell
        }.disposed(by: disposeBag)
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        tableView.rx.itemSelected.bind { [weak self] indexPath in
            guard let item = self?.flatViewModel?.items[indexPath.row] else { return }
            let editVc = SFUserDefaultsEditViewController(item: item)
            self?.navigationController?.pushViewController(editVc, animated: true)
        }.disposed(by: disposeBag)
    }
}

extension SFUserDefaultsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = flatViewModel?.items[indexPath.row] else { return nil }
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [viewModel] _, _, _ in
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
