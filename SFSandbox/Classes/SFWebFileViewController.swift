//
//  SFWebFileViewController.swift
//  SFSandbox
//
//  Created by coker on 2021/9/9.
//

import UIKit
import WebKit

class SFWebFileViewController: SFViewController {
    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        return webView
    }()
    
    override init(file: SFFileManager.SFFileItem) {
        super.init(file: file)
        self.viewModel = SFViewModel(file: file)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        loadFile()
    }

    private func loadFile() {
        guard let path = viewModel?.path, !path.isEmpty else {
            viewModel?.errorRelay.accept("文件\(viewModel?.fileName ?? "")为空")
            return
        }
        let url = URL(fileURLWithPath: path)
        webView.load(URLRequest(url: url))
    }
}
