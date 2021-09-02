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

    private lazy var createButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        button.setTitle("新建", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: createButton)
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
        createButton.rx.tap.bind { [weak self] in
            self?.triggerCreateFileSheet()
        }.disposed(by: disposeBag)
        viewModel.itemsRelay.bind(to: tableView.rx.items) { (tableView, _, element) in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SFFileCell.reuseIdentifier) as? SFFileCell
            else {
                return SFFileCell(style: .default, reuseIdentifier: SFFileCell.reuseIdentifier)
            }
            cell.render(element)
            return cell
        }.disposed(by: disposeBag)
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
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

extension SFFlieListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [viewModel] _, _, _ in
            viewModel.deleteFile(viewModel.items[indexPath.row])
        }
        let renameAction = UIContextualAction(style: .normal, title: "重命名") { _, _, _ in

        }
        renameAction.backgroundColor = .blue
        return UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
    }
}

extension SFFlieListViewController {
    private func triggerCreateFileSheet() {
        let supportFiles: [SFFileManager.SFFileSuffix] = [.directory, .json, .txt]
        let sheetVc = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        sheetVc.addAction(cancelAction)
        let fileName: ((SFFileManager.SFFileSuffix) -> String) = { type in
            switch type {
            case .directory:
                return "文件夹"
            case .json:
                return "json"
            case .txt:
                return "txt"
            case .excel, .file, .gif, .image, .pdf, .video, .word, .zip:
                return ""
            }
        }
        let action: ((SFFileManager.SFFileSuffix) -> Void) = { type in
            self.triggerInputNameAlert(type, name: fileName(type))
        }
        supportFiles.forEach { type in
            let action = UIAlertAction(title: fileName(type), style: .default) { _ in
                action(type)
            }
            sheetVc.addAction(action)
        }
        present(sheetVc, animated: true, completion: nil)
    }

    private func triggerInputNameAlert(_ type: SFFileManager.SFFileSuffix, name: String) {
        let alertVc = UIAlertController(title: "输入\(name)名称", message: nil, preferredStyle: .alert)
        alertVc.addTextField { _ in }
        present(alertVc, animated: true, completion: nil)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertVc.addAction(cancelAction)
        let confirmAction = UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let name = alertVc.textFields?.first?.text, !name.isEmpty else { return }
            switch type {
            case .directory:
                self?.viewModel.createDirectory(name)
            case .txt:
                self?.viewModel.createFile(name, suffix: "txt")
            case .json:
                self?.viewModel.createFile(name, suffix: "json")
            case .excel, .file, .gif, .image, .pdf, .video, .word, .zip:
                break
            }
        }
        alertVc.addAction(confirmAction)
    }
}
