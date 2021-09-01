//
//  SFFileCell.swift
//  SFSandbox
//
//  Created by coker on 2021/8/30.
//

import UIKit

class SFFileCell: UITableViewCell {
    static let reuseIdentifier: String = String(describing: SFFileCell.self)

    private lazy var fileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .darkText
        return label
    }()

    private lazy var sizeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = .darkGray
        return label
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        accessoryType = .disclosureIndicator
        contentView.addSubview(fileImageView)
        fileImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.size.equalTo(35)
        }
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(fileImageView.snp.right).offset(10)
            make.right.equalToSuperview().inset(20)
            make.bottom.equalTo(fileImageView.snp.centerY).offset(-3)
        }
        contentView.addSubview(sizeLabel)
        sizeLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.top.equalTo(fileImageView.snp.centerY).offset(3)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(_ file: SFFileManager.SFFileItem) {
        switch file.suffix {
            case .directory:
                fileImageView.image = SFResources.image(.directory)
            case .file:
                fileImageView.image = SFResources.image(.file)
            case .image:
                fileImageView.image = SFResources.image(.image)
            case .pdf:
                fileImageView.image = SFResources.image(.image)
            case .video:
                fileImageView.image = SFResources.image(.video)
            case .word:
                fileImageView.image = SFResources.image(.word)
            case .excel:
                fileImageView.image = SFResources.image(.excel)
            case .zip:
                fileImageView.image = SFResources.image(.zip)
            case .gif:
                fileImageView.image = SFResources.image(.gif)
            case .json:
                fileImageView.image = SFResources.image(.json)
            case .txt:
                fileImageView.image = SFResources.image(.txt)
        }
        nameLabel.text = file.name
        sizeLabel.text = file.size.fileSizeFormatter()
    }
}
