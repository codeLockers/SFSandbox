//
//  SFToast.swift
//  SFSandbox
//
//  Created by coker on 2021/9/7.
//

import UIKit
import RxSwift
import RxCocoa

class SFToastManager {
    enum Toast: Equatable {
        case success(String)
        case fail(String)

        var isSuccess: Bool {
            switch self {
            case .success: return true
            case .fail: return false
            }
        }
    }

    static let shared = SFToastManager()
    private let toastQueue = DispatchQueue(label: "com.sandbox.toast.queue", attributes: .concurrent)
    private var pendingToasts = [Toast]()
    private var toastView: SFToast?
    private var window: UIWindow?

    private init() {}

    var toast: Binder<Toast> {
        return Binder(self) { manager, toast in
            manager.pushToast(toast)
        }
    }

    func registerToast(on window: UIWindow) {
        self.window = window
        self.toastView = SFToast()
        guard let toastView = self.toastView else { return }
        window.addSubview(toastView)
        toastView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(window.snp.bottom)
            make.height.equalTo(120)
        }
    }

    func unregisterToast() {
        toastView?.removeFromSuperview()
        toastView = nil
    }

    private func pushToast(_ toast: Toast) {
        toastQueue.async(flags: .barrier) { [weak self] in
            self?.pendingToasts.append(toast)
            if self?.pendingToasts.count == 1 {
                self?.popToast()
            }
        }
    }

    private func popToast() {
        toastQueue.async(flags: .barrier) { [weak self] in
            if self?.pendingToasts.isEmpty ?? true {
                self?.hideToastView()
                return
            }
            guard let toast = self?.pendingToasts.first else { return }
            self?.display(toast)
            switch toast {
            case .success:
                self?.toastQueue.asyncAfter(deadline: .now() + 0.35) {
                    self?.pendingToasts.removeFirst()
                    self?.popToast()
                }
            case .fail:
                self?.toastQueue.asyncAfter(deadline: .now() + 3) {
                    self?.pendingToasts.removeFirst()
                    self?.popToast()
                }
            }
        }
    }

    private func display(_ toast: Toast) {
        DispatchQueue.main.async {
            guard let toastView = self.toastView, let window = self.window else { return }
            if toastView.frame.origin.y >= window.frame.height { self.showToastView() }
            let successStats =  self.pendingToasts.filter { $0.isSuccess }.count
            toastView.render(toast,
                             successStats: successStats,
                             errorStats: self.pendingToasts.count - successStats)
        }
    }

    private func showToastView() {
        guard let window = self.window else { return }
        window.layoutIfNeeded()
        UIView.animate(withDuration: 0.35) {
            self.toastView?.snp.updateConstraints { make in
                make.top.equalTo(window.snp.bottom).offset(-120)
            }
            window.layoutIfNeeded()
        }
    }

    private func hideToastView() {
        guard let window = self.window else { return }
        DispatchQueue.main.async {
            window.layoutIfNeeded()
            UIView.animate(withDuration: 0.35) {
                self.toastView?.snp.updateConstraints { make in
                    make.top.equalTo(window.snp.bottom)
                }
                window.layoutIfNeeded()
            }
        }
    }
}

class SFToast: UIView {
    private lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 13)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var successStatsLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 13)
        label.textAlignment = .center
        return label
    }()

    private lazy var errorStatsLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 13)
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(successStatsLabel)
        successStatsLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(30)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }
        addSubview(errorStatsLabel)
        errorStatsLabel.snp.makeConstraints { make in
            make.centerY.equalTo(successStatsLabel)
            make.right.equalTo(successStatsLabel.snp.left).offset(-20)
        }
        addSubview(label)
        label.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.bottom.lessThanOrEqualTo(successStatsLabel.snp.top)
            make.top.equalToSuperview().inset(15)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(_ toast: SFToastManager.Toast, successStats: Int, errorStats: Int) {
        switch toast {
        case .success(let message):
            label.text = message
            backgroundColor = UIColor(red: 60.0 / 255, green: 194.0 / 255, blue: 0, alpha: 1)
        case .fail(let message):
            label.text = message
            backgroundColor = UIColor(red: 244.0 / 255, green: 81.0 / 255, blue: 81.0 / 255, alpha: 1)
        }
        successStatsLabel.text = "成功：\(successStats)"
        errorStatsLabel.text = "失败：\(errorStats)"
    }
}
