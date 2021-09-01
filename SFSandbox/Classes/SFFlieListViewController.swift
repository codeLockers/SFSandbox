//
//  SFFlieListViewController.swift
//  SFSandbox
//
//  Created by coker on 2021/8/27.
//

import UIKit
import RxSwift
import RxCocoa

class SFSandboxNavigationViewController: UINavigationController { }

class SFFlieListViewController: UIViewController {
    enum DismissStyle {
        case close
        case pop

        var image: UIImage? {
            switch self {
            case .close:
                return SFResources.image(.close)
            case .pop:
                return SFResources.image(.back)
            }
        }

        var imageEdgeInsets: UIEdgeInsets {
            switch self {
            case .close:
                return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)
            case .pop:
                return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 30)
            }
        }
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(SFFileCell.self, forCellReuseIdentifier: SFFileCell.reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 60
        return tableView
    }()

    private lazy var dismissButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        button.imageEdgeInsets = dismissStyle.imageEdgeInsets
        button.setImage(dismissStyle.image, for: .normal)
        return button
    }()

    private let disposeBag = DisposeBag()
    private let viewModel: SFFlieListViewModel
    private let dismissStyle: DismissStyle

    init(path: String?, dismissStyle: DismissStyle) {
        self.viewModel = SFFlieListViewModel(path: path)
        self.dismissStyle = dismissStyle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: dismissButton)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        handleRxBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refresh()
    }

    private func handleRxBindings() {
        dismissButton.rx.tap.bind { [weak self] in
            guard let self = self else { return }
            switch self.dismissStyle {
            case .close:
                self.dismiss(animated: true, completion: nil)
            case .pop:
                self.navigationController?.popViewController(animated: true)
            }
        }.disposed(by: disposeBag)
        viewModel.itemsRelay.bind(to: tableView.rx.items) { (tableView, _, element) in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SFFileCell.reuseIdentifier) as? SFFileCell
            else {
                return SFFileCell(style: .default, reuseIdentifier: SFFileCell.reuseIdentifier)
            }
            cell.render(element)
            return cell
        }.disposed(by: disposeBag)
        tableView.rx.itemSelected.bind { [weak self] indexPath in
            guard let fileItem = self?.viewModel.itemsRelay.value[indexPath.row] else { return }
            self?.route(to: fileItem)
        }.disposed(by: disposeBag)
    }

    private func route(to file: SFFileManager.SFFileItem) {
        switch file.suffix {
        case .directory:
            routeToDirectory(file)
        default:
            break
        }
    }

    private func routeToDirectory(_ directory: SFFileManager.SFFileItem) {
        let fileListVc = SFFlieListViewController(path: directory.path, dismissStyle: .pop)
        navigationController?.pushViewController(fileListVc, animated: true)
    }
}
