//
//  SFSandbox.swift
//  SFSandbox
//
//  Created by coker on 2021/8/27.
//

import Foundation
import SnapKit
import RxSwift
import RxCocoa

public class SFSandbox {
    private let disposebag = DisposeBag()
    private let errorRelay = BehaviorRelay<Error?>(value: nil)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)

    private let entranceButton = EntranceButton()
    private lazy var closeButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        button.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: 20, bottom: 0, right: 0)
        button.setImage(SFResources.image(.close), for: .normal)
        return button
    }()
    private lazy var rootViewController: SFSandboxNavigationViewController = {
        let fileListVc = SFFlieListViewController()
        fileListVc.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)
        let navigation = SFSandboxNavigationViewController(rootViewController: fileListVc)
        navigation.modalPresentationStyle = .overFullScreen
        return navigation
    }()

    public init() {}

    public func start() {
        setup()
        handleRxBindings()
    }

    private func handleRxBindings() {
        entranceButton.rx.tap.bind { [weak self] in
            self?.enter()
        }.disposed(by: disposebag)
        closeButton.rx.tap.bind { [weak self] in
            self?.dismiss()
        }.disposed(by: disposebag)
    }
}

extension SFSandbox {
    private func setup() {
        guard let window = UIApplication.shared.windows.last else {
            errorRelay.accept(.noWindow)
            return
        }
        window.addSubview(entranceButton)
        window.bringSubview(toFront: entranceButton)
        entranceButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(30)
            make.bottom.equalTo(window.safeAreaLayoutGuide.snp.bottom).inset(30)
            make.size.equalTo(50)
        }
    }

    private func enter() {
        UIApplication.shared.windows.last?.rootViewController?.present(rootViewController, animated: true, completion: nil)
    }

    private func dismiss() {
        rootViewController.dismiss(animated: true)
    }
}

extension SFSandbox {
    public enum Error {
        case noWindow
    }

    fileprivate class EntranceButton: UIButton {
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setImage(SFResources.image(.entrance), for: .normal)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension UIWindow {
    open override func layoutSubviews() {
        super.layoutSubviews()
        if rootViewController?.presentedViewController is SFSandboxNavigationViewController { return }
        guard let button = subviews.first(where: { $0 is SFSandbox.EntranceButton }) else { return }
        bringSubview(toFront: button)
    }
}
