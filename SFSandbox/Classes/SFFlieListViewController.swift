//
//  SFFlieListViewController.swift
//  SFSandbox
//
//  Created by coker on 2021/8/27.
//

import UIKit
import RxSwift
import RxCocoa

class SFNavigationViewController: UINavigationController {}

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

    private lazy var userDefaultsButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 44))
        button.setTitle("UserDefaults", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        return button
    }()

    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchTextField.font = UIFont.systemFont(ofSize: 13)
        searchBar.placeholder = "输入搜索的文件名"
        return searchBar
    }()

    private let disposeBag = DisposeBag()
    private let viewModel: SFFlieListViewModel
    private let dismissStyle: DismissStyle

    init(file: SFFileManager.SFFileItem, dismissStyle: DismissStyle) {
        self.viewModel = SFFlieListViewModel(file: file)
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
        navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: createButton), UIBarButtonItem(customView: userDefaultsButton)]
        navigationItem.title = viewModel.fileName
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
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
                SFToastManager.shared.unregisterToast()
                self.dismiss(animated: true, completion: nil)
            case .pop:
                self.navigationController?.popViewController(animated: true)
            }
        }.disposed(by: disposeBag)
        createButton.rx.tap.bind { [weak self] in
            self?.triggerCreateFileSheet()
        }.disposed(by: disposeBag)
        userDefaultsButton.rx.tap.bind { [weak self] in
            self?.routeToUserDefaults()
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
        searchBar.rx.text.orEmpty
            .skip(1)
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind { [viewModel] text in
                viewModel.search(keyword: text)
            }.disposed(by: disposeBag)
        viewModel.isLoadingRelay.bind { [weak self] isLoading in
            isLoading ? self?.startLoading() : self?.stopLoading()
        }.disposed(by: disposeBag)
    }

    private func route(to file: SFFileManager.SFFileItem) {
        switch file.suffix {
        case .directory:
            routeToDirectory(file)
        case .image:
            routeToImage(file)
        case .pdf, .word, .excel, .gif:
            routeToWeb(file)
        case .video:
            routeToVideo(file)
        case .txt, .json, .java, .file, .xml, .markdown, .swift, .html, .code, .javascript:
            routeToText(file)
        case .zip, .apk, .ipa, .xib:
            break
        }
    }

    private func routeToDirectory(_ directory: SFFileManager.SFFileItem) {
        let fileListVc = SFFlieListViewController(file: directory, dismissStyle: .pop)
        navigationController?.pushViewController(fileListVc, animated: true)
    }

    private func routeToText(_ file: SFFileManager.SFFileItem) {
        let textVc = SFTextFileViewController(file: file)
        navigationController?.pushViewController(textVc, animated: true)
    }

    private func routeToImage(_ image: SFFileManager.SFFileItem) {
        let imageVc = SFImageFileViewController(file: image)
        navigationController?.pushViewController(imageVc, animated: true)
    }

    private func routeToWeb(_ file: SFFileManager.SFFileItem) {
        let webVc = SFWebFileViewController(file: file)
        navigationController?.pushViewController(webVc, animated: true)
    }

    private func routeToVideo(_ video: SFFileManager.SFFileItem) {
        let videoVc = SFVideoFileViewController(file: video)
        navigationController?.pushViewController(videoVc, animated: true)
    }

    private func routeToUserDefaults() {
        let userDetaultsFile = SFFileManager.SFFileItem(path: "",
                                                        name: "UserDefaults",
                                                        size: 0,
                                                        attributeType: .typeUnknown,
                                                        modificationDate: nil)
        let userDefaultsVc = SFUserDefaultsViewController(file: userDetaultsFile)
        navigationController?.pushViewController(userDefaultsVc, animated: true)
    }
}

extension SFFlieListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let file = viewModel.items[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [viewModel] _, _, _ in
            viewModel.deleteFile(file)
        }

        let renameAction = UIContextualAction(style: .normal, title: "重命名") { [weak self] _, _, _ in
            self?.triggerInputNameAlert(operation: .rename(file))
        }
        renameAction.backgroundColor = UIColor(red: 0, green: 122.0 / 255, blue: 1, alpha: 1)

        let zipAction = UIContextualAction(style: .normal, title: file.canZip ? "压缩" : "解压") { [viewModel] _, _, _ in
            file.canZip ? viewModel.zip(file) : viewModel.unzip(file)
        }
        zipAction.backgroundColor = file.canZip ? .orange : .brown

        let shareAction = UIContextualAction(style: .normal, title: "分享") { [weak self] _, _, _ in
            self?.share(file)
        }
        shareAction.backgroundColor = .purple

        return UISwipeActionsConfiguration(actions: file.canShare ? [deleteAction, renameAction, zipAction, shareAction] : [deleteAction, renameAction, zipAction])
    }
}

extension SFFlieListViewController {
    private func triggerCreateFileSheet() {
        let supportFiles: [SFFileManager.SFFileSuffix] = [.directory, .json, .txt, .html, .java, .javascript, .markdown, .swift, .xml]
        let sheetVc = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        sheetVc.addAction(cancelAction)
        let action: ((SFFileManager.SFFileSuffix) -> Void) = { type in
            self.triggerInputNameAlert(operation: .create(type))
        }
        supportFiles.forEach { type in
            let action = UIAlertAction(title: type.localizedName, style: .default) { _ in
                action(type)
            }
            sheetVc.addAction(action)
        }
        present(sheetVc, animated: true, completion: nil)
    }

    private func triggerInputNameAlert(operation: SFFileManager.Operation) {
        var title: String = "输入名称"
        switch operation {
        case .create(let type):
            title = "输入新建\(type.localizedName)的名字"
        case .rename(let file):
            title = "输入\(file.name)的新名字"
        case .delete, .zip, .unzip:
            return
        }
        let alertVc = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alertVc.addTextField { _ in }
        present(alertVc, animated: true, completion: nil)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertVc.addAction(cancelAction)
        let confirmAction = UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let name = alertVc.textFields?.first?.text, !name.isEmpty else { return }
            switch operation {
            case .create(let type):
                self?.viewModel.create(name, type: type)
            case .rename(let file):
                self?.viewModel.rename(file, name: name)
            case .delete, .zip, .unzip:
                break
            }
        }
        alertVc.addAction(confirmAction)
    }

    private func share(_ file: SFFileManager.SFFileItem) {
        let url = URL(fileURLWithPath: file.path)
        let shareVc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        shareVc.completionWithItemsHandler = { [viewModel] type, result, items, error in
            result ? viewModel.successRelay.accept("分享操作成功") : viewModel.errorRelay.accept("分享操作失败")
        }
        self.present(shareVc, animated: true, completion: nil)
    }
}
