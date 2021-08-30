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
        case back
        case directory
        case file
        case image
        case video
        case word
        case excel
        case zip

        var filename: String {
            switch self {
            case .entrance:
                return "sf_sandbox_entrance"
            case .close:
                return "sf_sandbox_close"
            case .back:
                return "sf_sandbox_back"
            case .directory:
                return "sf_sandbox_directory"
            case .file:
                return "sf_sandbox_file"
            case .image:
                return "sf_sandbox_picture"
            case .video:
                return "sf_sandbox_video"
            case .word:
                return "sf_sandbox_word"
            case .excel:
                return "sf_sandbox_excel"
            case .zip:
                return "sf_sandbox_zip"
            }
        }
    }

    static func image(_ image: Image, type: String = "png") -> UIImage? {
        guard let path = bundle.path(forResource: image.filename + "@3x", ofType: type) else { return nil }
        return UIImage(contentsOfFile: path)
    }
}

