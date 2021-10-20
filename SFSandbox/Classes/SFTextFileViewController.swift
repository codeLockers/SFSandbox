//
//  SFTextFileViewController.swift
//  SFSandbox
//
//  Created by coker on 2021/9/8.
//

import UIKit
import RxSwift
import RxCocoa

class SFTextFileViewController: SFFileViewController {
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

    private var flatViewModel: SFTextFlieViewModel? { self.viewModel as? SFTextFlieViewModel }

    override init(file: SFFileManager.SFFileItem) {
        super.init(file: file)
        self.viewModel = SFTextFlieViewModel(file: file)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)
        navigationItem.title = flatViewModel?.fileName
        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        handleRxBindings()
    }

    private func handleRxBindings() {
        saveButton.rx.tap.bind { [flatViewModel, textView] in
            flatViewModel?.save(textView.text)
        }.disposed(by: disposeBag)
        flatViewModel?.contentRelay.compactMap { $0 }
            .bind(to: textView.rx.text)
            .disposed(by: disposeBag)
        flatViewModel?.writeSuccessRelay
            .compactMap { $0 }
            .filter { $0 }
            .bind { [navigationController] _ in
                navigationController?.popViewController(animated: true)
            }.disposed(by: disposeBag)
    }
}
