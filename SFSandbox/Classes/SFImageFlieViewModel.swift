//
//  SFImageFlieViewModel.swift
//  SFSandbox
//
//  Created by coker on 2021/9/9.
//

import Foundation

class SFImageFlieViewModel: SFFileViewModel {
    var image: UIImage? {
        guard let path = self.path, !path.isEmpty else {
            errorRelay.accept("图片\(fileName)路径为空")
            return nil
        }
        guard let image = UIImage(contentsOfFile: path) else {
            errorRelay.accept("图片\(fileName)读取失败")
            return nil
        }
        successRelay.accept("图片\(fileName)读取成功")
        return image
    }
}
