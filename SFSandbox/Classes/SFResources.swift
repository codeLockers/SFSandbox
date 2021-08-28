//
//  SFResources.swift
//  SFSandbox
//
//  Created by coker on 2021/8/27.
//

import Foundation

struct SFResources {
    static let bundle = Bundle(for: SFSandbox.self)

    enum Image {
        case entrance
        case close

        var filename: String {
            switch self {
            case .entrance:
                return "sf_sandbox_entrance"
            case .close:
                return "sf_close"
            }
        }
    }

    static func image(_ image: Image, type: String = "png") -> UIImage? {
        guard let path = bundle.path(forResource: image.filename + "@3x", ofType: type) else { return nil }
        return UIImage(contentsOfFile: path)
    }
}

