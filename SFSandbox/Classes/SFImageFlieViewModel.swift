//
//  SFImageFlieViewModel.swift
//  SFSandbox
//
//  Created by coker on 2021/9/9.
//

import Foundation

class SFImageFlieViewModel: SFViewModel {
    var image: UIImage? {
        guard let path = self.path, !path.isEmpty else {
            errorRelay.accept("图片路径为空")
            return nil
        }
        guard let image = UIImage(contentsOfFile: path) else {
            errorRelay.accept("图片读取失败")
            return nil
        }
        successRelay.accept("图片读取成功")
        return image
    }
}
