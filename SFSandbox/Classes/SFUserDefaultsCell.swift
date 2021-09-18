//
//  SFUserDefaultsCell.swift
//  SFSandbox
//
//  Created by coker on 2021/9/15.
//

import UIKit

class SFUserDefaultsCell: UITableViewCell {
    static let reuseIdentifier: String = String(describing: SFFileCell.self)

    private lazy var keyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .darkText
        return label
    }()

    private lazy var typeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = .darkGray
        return label
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        accessoryType = .disclosureIndicator
        contentView.addSubview(keyLabel)
        keyLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.bottom.equalTo(contentView.snp.centerY)
        }
        contentView.addSubview(typeLabel)
        typeLabel.snp.makeConstraints { make in
            make.left.equalTo(keyLabel)
            make.bottom.equalToSuperview().inset(10)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(_ item: SFUserDefaultsViewModel.Item) {
        keyLabel.text = item.key
        typeLabel.text = item.type.name
    }
}
