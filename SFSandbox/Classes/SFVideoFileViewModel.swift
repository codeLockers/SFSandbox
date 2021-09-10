//
//  SFVideoFileViewModel.swift
//  SFSandbox
//
//  Created by coker on 2021/9/9.
//

import UIKit
import AVFoundation

class SFVideoFileViewModel: SFViewModel {
    var videoUrl: URL? {
        guard let path = self.path, !path.isEmpty else {
            errorRelay.accept("视频\(fileName)文件地址为空")
            return nil
        }
        return URL(fileURLWithPath: path)
    }
}
