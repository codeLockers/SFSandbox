//
//  SFUserDefaultsEditViewController.swift
//  SFSandbox
//
//  Created by coker on 2021/9/15.
//

import UIKit
import RxCocoa
import RxSwift

class SFUserDefaultsEditViewController: UIViewController {
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

    private lazy var trueCheckbox: SFCheckbox = {
        let checkbox = SFCheckbox(title: "True")
        return checkbox
    }()

    private lazy var falseCheckBox: SFCheckbox = {
        let checkbox = SFCheckbox(title: "False")
        return checkbox
    }()

    private lazy var inputTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 13)
        textView.textColor = .darkText
        textView.contentInset = UIEdgeInsets(top: 15, left: 20, bottom: 0, right: 20)
        return textView
    }()
    
    private let item: SFUserDefaultsViewModel.Item
    private let disposeBag = DisposeBag()
    private let errorRelay = BehaviorRelay<String?>(value: nil)
    private let successRelay = BehaviorRelay<String?>(value: nil)

    init(item: SFUserDefaultsViewModel.Item) {
        self.item = item
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
        navigationItem.title = item.key
        render()
        handleRxBindings()
    }

    private func handleRxBindings() {
        dismissButton.rx.tap.bind { [weak self] in
            self?.dismiss()
        }.disposed(by: disposeBag)
        saveButton.rx.tap.bind { [weak self] in
            self?.save()
        }.disposed(by: disposeBag)
        Observable.merge(
            errorRelay.compactMap { $0 }.map { .fail($0) },
            successRelay.compactMap { $0 }.map { .success($0) }
        )
        .bind(to: SFToastManager.shared.toast)
        .disposed(by: disposeBag)
        Observable.merge(errorRelay.asObservable(), successRelay.asObservable())
            .bind { [weak self] _ in
                guard let self = self else { return }
                UIApplication.shared
                    .sendAction(#selector(self.resignFirstResponder),
                                to: nil,
                                from: nil,
                                for: nil)
            }.disposed(by: disposeBag)
    }

    private func dismiss() {
        navigationController?.popViewController(animated: true)
    }

    private func render() {
        switch item.type {
        case .bool:
            renderBoolStyle()
        case .number, .url, .string:
            renderInputStyle()
        case .array:
            break
        case .dictionary:
            break
        case .data:
            break
        case .unknow:
            break
        }
    }

    private func renderBoolStyle() {
        view.addSubview(trueCheckbox)
        trueCheckbox.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(20)
            make.height.equalTo(40)
            make.width.equalTo(100)
        }
        view.addSubview(falseCheckBox)
        falseCheckBox.snp.makeConstraints { make in
            make.left.height.width.equalTo(trueCheckbox)
            make.top.equalTo(trueCheckbox.snp.bottom).offset(20)
        }
        trueCheckbox.rx.tap.bind { [weak self] in
            guard
                let self = self,
                !self.trueCheckbox.isSelected
            else { return }
            self.trueCheckbox.isSelected = !self.trueCheckbox.isSelected
            self.falseCheckBox.isSelected = !self.trueCheckbox.isSelected
        }.disposed(by: disposeBag)
        falseCheckBox.rx.tap.bind { [weak self] in
            guard
                let self = self,
                !self.falseCheckBox.isSelected
            else { return }
            self.falseCheckBox.isSelected = !self.falseCheckBox.isSelected
            self.trueCheckbox.isSelected = !self.falseCheckBox.isSelected
        }.disposed(by: disposeBag)
        guard let value = item.value as? Bool else { return }
        trueCheckbox.isSelected = value
        falseCheckBox.isSelected = !value
    }

    private func renderInputStyle() {
        view.addSubview(inputTextView)
        inputTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        switch item.type {
        case .bool, .unknow:
            break
        case .number:
            inputTextView.text = "\(item.value ?? "")"
            inputTextView.isEditable = true
            inputTextView.keyboardType = .decimalPad
        case .array:
            break
        case .dictionary:
            break
        case .string:
            inputTextView.text = item.value as? String
            inputTextView.isEditable = true
            inputTextView.keyboardType = .default
        case .url:
            guard
                let link = UserDefaults.standard.url(forKey: item.key)?.absoluteString,
                !link.isEmpty
            else { return }
            let attributeString = NSMutableAttributedString(string: link, attributes: [.font: UIFont.systemFont(ofSize: 20)])
            attributeString.addAttribute(.link, value: link, range: NSRange(location: 0, length: link.count))
            inputTextView.attributedText = attributeString
            inputTextView.isEditable = true
            inputTextView.keyboardType = .default
        case .data:
            break
        }
    }

    private func save() {
        switch item.type {
        case .bool:
            UserDefaults.standard.set(trueCheckbox.isSelected, forKey: item.key)
            UserDefaults.standard.synchronize()
            successRelay.accept("保存成功")
        case .number:
            guard let value = inputTextView.text, !value.isEmpty else {
                errorRelay.accept("保存失败-数据不能为空")
                return
            }
            if value.isInteger, let data = Int(value) {
                UserDefaults.standard.set(data, forKey: item.key)
            } else if value.isDecimals, let data = Double(value) {
                UserDefaults.standard.set(data, forKey: item.key)
            } else {
                errorRelay.accept("保存失败-数据不是正确的数值")
                return
            }
            UserDefaults.standard.synchronize()
            successRelay.accept("保存成功")
        case .array:
            break
        case .dictionary:
            break
        case .string:
            UserDefaults.standard.set(inputTextView.text, forKey: item.key)
            UserDefaults.standard.synchronize()
            successRelay.accept("保存成功")
        case .data:
            break
        case .url:
            UserDefaults.standard.set(URL(string: inputTextView.text), forKey: item.key)
            UserDefaults.standard.synchronize()
            successRelay.accept("保存成功")
        case .unknow:
            break
        }
        dismiss()
    }
}

class SFCheckbox: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        setTitleColor(.darkText, for: .normal)
        setTitle(title, for: .normal)
        setImage(SFResources.image(.checked), for: .selected)
        setImage(SFResources.image(.unchecked), for: .normal)
        imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        guard let image = currentImage else { return .zero }
        return CGRect(x: 0, y: (contentRect.height - image.size.height) / 2, width: image.size.width, height: image.size.height)
    }

    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let x = (currentImage?.size.width ?? 0) + 10
        return CGRect.init(x: x, y: 0, width: contentRect.width - x, height: contentRect.height)
    }
}
