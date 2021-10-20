//
//  SFWebFileViewController.swift
//  SFSandbox
//
//  Created by coker on 2021/9/9.
//

import UIKit
import WebKit

class SFWebFileViewController: SFFileViewController {
    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        return webView
    }()

    private var flatViewModel: SFFileViewModel? { self.viewModel as? SFFileViewModel }

    override init(file: SFFileManager.SFFileItem) {
        super.init(file: file)
        self.viewModel = SFFileViewModel(file: file)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = flatViewModel?.fileName
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        loadFile()
    }

    private func loadFile() {
        guard let viewModel = self.flatViewModel else { return }
        guard let path = viewModel.path, !path.isEmpty else {
            viewModel.errorRelay.accept("文件\(viewModel.fileName)为空")
            return
        }
        let url = URL(fileURLWithPath: path)
        switch viewModel.file.suffix {
        case .pdf, .word, .excel:
            webView.load(URLRequest(url: url))
        case .gif:
            do {
                let data = try Data(contentsOf: url)
                webView.load(data, mimeType: "image/gif", characterEncodingName: "", baseURL: url)
            } catch {
                viewModel.errorRelay.accept("文件\(viewModel.fileName)二进制转换失败")
            }
        case .directory, .file, .image, .video, .zip, .json, .txt, .java, .xml, .apk, .ipa, .markdown, .swift, .xib, .html, .code, .javascript:
            break
        }
    }
}
