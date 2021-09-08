//
//  SFTextFileViewController.swift
//  SFSandbox
//
//  Created by coker on 2021/9/8.
//

import UIKit
import RxSwift
import RxCocoa

class SFTextFileViewController: UIViewController {
    private lazy var dismissButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 30)
        button.setImage(SFResources.image(.back), for: .normal)
        return button
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        button.setTitle("保存", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        return button
    }()

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.textColor = .black
        textView.font = .systemFont(ofSize: 15)
        textView.contentInset = UIEdgeInsets(top: 15, left: 20, bottom: 0, right: 20)
        return textView
    }()

    private let disposeBag = DisposeBag()
    private let viewModel: SFTextFlieViewModel

    init(file: SFFileManager.SFFileItem) {
        self.viewModel = SFTextFlieViewModel(file: file)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: dismissButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)
        navigationItem.title = viewModel.fileName
        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        handleRxBindings()
    }

    private func handleRxBindings() {
        Observable.merge(
            viewModel.errorRelay.compactMap { $0 }.map { .fail($0) },
            viewModel.successRelay.compactMap { $0 }.map { .success($0) }
        )
        .bind(to: SFToastManager.shared.toast)
        .disposed(by: disposeBag)
        dismissButton.rx.tap.bind { [navigationController] in
            navigationController?.popViewController(animated: true)
        }.disposed(by: disposeBag)
        saveButton.rx.tap.bind { [viewModel, textView] in
            viewModel.save(textView.text)
        }.disposed(by: disposeBag)
        viewModel.contentRelay.compactMap { $0 }
            .bind(to: textView.rx.text)
            .disposed(by: disposeBag)
        viewModel.writeSuccessRelay
            .compactMap { $0 }
            .filter { $0 }
            .bind { [navigationController] _ in
                navigationController?.popViewController(animated: true)
            }.disposed(by: disposeBag)
    }
}
