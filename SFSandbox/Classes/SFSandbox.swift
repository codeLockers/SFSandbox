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
    private let disposeBag = DisposeBag()
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)

    private let entranceButton = EntranceButton()
    private lazy var rootViewController: SFNavigationViewController = {
        let fileListVc = SFFlieListViewController(path: SFFileManager.Path.root.path, dismissStyle: .close)
        let navigation = SFNavigationViewController(rootViewController: fileListVc)
        navigation.modalPresentationStyle = .overFullScreen
        return navigation
    }()

    public init() {}

    private let toastRelay = BehaviorRelay<SFToastManager.Toast?>(value: nil)

    public func start() {
        setup()
        handleRxBindings()
    }

    private func handleRxBindings() {
        entranceButton.rx.tap.bind { [weak self] in
            self?.enter()
        }.disposed(by: disposeBag)
        Observable.merge(
            SFFileManager.shared.errorRelay.compactMap { $0 }.map { .fail($0) },
            SFFileManager.shared.successRelay.compactMap { $0 }.map { .success($0) }
        )
        .bind(to: SFToastManager.shared.toast)
        .disposed(by: disposeBag)
    }
}

extension SFSandbox {
    private func setup() {
        guard let window = UIApplication.shared.windows.last else { return }
        window.addSubview(entranceButton)
        window.bringSubview(toFront: entranceButton)
        entranceButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(30)
            make.bottom.equalTo(window.safeAreaLayoutGuide.snp.bottom).inset(30)
            make.size.equalTo(50)
        }
    }

    private func enter() {
        guard let window = UIApplication.shared.windows.last else { return }
        window.rootViewController?.present(rootViewController, animated: true, completion: {
            SFToastManager.shared.registerToast(on: window)
        })


    }
}

extension SFSandbox {
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
        if rootViewController?.presentedViewController is SFNavigationViewController { return }
        guard let button = subviews.first(where: { $0 is SFSandbox.EntranceButton }) else { return }
        bringSubview(toFront: button)
    }
}
