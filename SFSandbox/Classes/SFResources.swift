//
//  SFResources.swift
//  SFSandbox
//
//  Created by coker on 2021/8/27.
//

import Foundation



struct SFResources {
    static let bundleUrl: URL = Bundle(for: SFSandbox.self).url(forResource: "SFSandbox", withExtension: "bundle") ?? URL(fileURLWithPath: "")
    static let bundle = Bundle(url: bundleUrl)

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
        case gif
        case json
        case txt
        case pdf
        case play
        case pause
        case slider
        case java
        case xml
        case apk
        case ipa
        case markdown
        case swift
        case xib
        case html
        case code
        case javascript

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
            case .gif:
                return "sf_sandbox_gif"
            case .json:
                return "sf_sandbox_json"
            case .txt:
                return "sf_sandbox_txt"
            case .pdf:
                return "sf_sandbox_pdf"
            case .play:
                return "sf_sandbox_play"
            case .pause:
                return "sf_sandbox_pause"
            case .slider:
                return "sf_sandbox_slider"
            case .java:
                return "sf_sandbox_java"
            case .xml:
                return "sf_sandbox_xml"
            case .apk:
                return "sf_sandbox_apk"
            case .ipa:
                return "sf_sandbox_store"
            case .markdown:
                return "sf_sandbox_markdown"
            case .swift:
                return "sf_sandbox_swift"
            case .xib:
                return "sf_sandbox_xcode"
            case .html:
                return "sf_sandbox_html"
            case .code:
                return "sf_sandbox_code"
            case .javascript:
                return "sf_sandbox_js"
            }
        }
    }

    static func image(_ image: Image, type: String = "png") -> UIImage? {
        guard let path = bundle?.path(forResource: image.filename + "@3x", ofType: type) else { return nil }
        return UIImage(contentsOfFile: path)
    }
}

