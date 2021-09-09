//
//  SFImageFileViewController.swift
//  SFSandbox
//
//  Created by coker on 2021/9/9.
//

import UIKit

class SFImageFileViewController: SFViewController {
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private var flatViewModel: SFImageFlieViewModel? { self.viewModel as? SFImageFlieViewModel }

    override init(file: SFFileManager.SFFileItem) {
        super.init(file: file)
        self.viewModel = SFImageFlieViewModel(file: file)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        imageView.image = flatViewModel?.image
    }
}
