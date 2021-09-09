//
//  SFViewController.swift
//  SFSandbox
//
//  Created by coker on 2021/9/9.
//

import UIKit
import RxSwift
import RxCocoa

class SFViewController: UIViewController {
    private lazy var dismissButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 30)
        button.setImage(SFResources.image(.back), for: .normal)
        return button
    }()

    let disposeBag = DisposeBag()
    var viewModel: SFViewModelProtocol?

    init(file: SFFileManager.SFFileItem) {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: dismissButton)
        navigationItem.title = viewModel?.fileName
        dismissButton.rx.tap.bind { [navigationController] in
            navigationController?.popViewController(animated: true)
        }.disposed(by: disposeBag)
        guard let viewModel = self.viewModel else { return }
        Observable.merge(
            viewModel.errorRelay.compactMap { $0 }.map { .fail($0) },
            viewModel.successRelay.compactMap { $0 }.map { .success($0) }
        )
        .bind(to: SFToastManager.shared.toast)
        .disposed(by: disposeBag)
    }
}
