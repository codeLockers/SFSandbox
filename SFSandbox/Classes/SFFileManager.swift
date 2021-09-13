//
//  SFFileManager.swift
//  SFSandbox
//
//  Created by coker on 2021/8/28.
//

import Foundation
import RxSwift
import RxCocoa
import SSZipArchive

extension SFFileManager {
    public enum Path {
        case root
        case document
        case cache
        case library
        case tmp

        public var path: String? {
            switch self {
            case .root:
                return NSHomeDirectory()
            case .document:
                return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
            case .cache:
                return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
            case .library:
                return NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first
            case .tmp:
                return NSTemporaryDirectory()
            }
        }
    }

    public struct SFFileItem {
        let path: String
        let name: String
        let size: Int
        let attributeType: FileAttributeType
        let modificationDate: Date?

        var canZip: Bool {
            switch suffix {
            case .zip:
                return false
            case .directory, .excel, .file, .gif, .image, .json, .pdf, .txt, .video, .word, .java, .xml, .apk, .ipa, .markdown, .swift, .xib, .html, .code, .javascript:
                return true
            }
        }
        var isDirectory: Bool {
            switch suffix {
            case .directory:
                return true
            case .zip, .excel, .file, .gif, .image, .json, .pdf, .txt, .video, .word, .java, .xml, .apk, .ipa, .markdown, .swift, .xib, .html, .code, .javascript:
                return false
            }
        }
        var canShare: Bool { !isDirectory }
        private var suffixName: String? { name.components(separatedBy: ".").last }
        var suffix: SFFileSuffix {
            if attributeType == .typeDirectory { return .directory }
            guard let suffix = suffixName, !suffix.isEmpty else { return .file }
            if suffix == "png" || suffix == "jpg" || suffix == "jpeg" || suffix == "HEIC" {
                return .image
            } else if suffix == "pdf" {
                return .pdf
            } else if suffix == "mp4" || suffix == "mov" {
                return .video
            } else if suffix == "doc" || suffix == "docx" {
                return .word
            } else if suffix == "xls" || suffix == "xlsx" {
                return .excel
            } else if suffix == "zip" {
                return .zip
            } else if suffix == "gif" {
                return .gif
            } else if suffix == "json" {
                return .json
            } else if suffix == "txt" {
                return .txt
            } else if suffix == "java" {
                return .java
            } else if suffix == "xml" {
                return .xml
            } else if suffix == "apk" {
                return .apk
            } else if suffix == "ipa" {
                return .ipa
            } else if suffix == "md" {
                return .markdown
            } else if suffix == "swift" {
                return .swift
            } else if suffix == "xib" {
                return .xib
            } else if suffix == "html" {
                return .html
            } else if suffix == "h" || suffix == "m" || suffix == "c" {
                return .code
            } else if suffix == "js" {
                return .javascript
            } else {
                return .file
            }
        }
    }

    public enum SFFileSuffix {
        case directory
        case file
        case image
        case pdf
        case video
        case word
        case excel
        case zip
        case gif
        case json
        case txt
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

        var localizedName: String {
            switch self {
            case .directory: return "文件夹"
            case .excel: return "Excel文件"
            case .file: return "文件"
            case .gif: return "GIF动图"
            case .image: return "图片"
            case .json: return "JSON文件"
            case .pdf: return "PDF文件"
            case .txt: return "TXT文件"
            case .video: return "视频文件"
            case .word: return "Word文件"
            case .zip: return "压缩包"
            case .java: return "JAVA文件"
            case .xml: return "XML文件"
            case .apk: return "Adroid安装包"
            case .ipa: return "Apple安装包"
            case .markdown: return "Markdown文件"
            case .swift: return "Swift文件"
            case .xib: return "XIB文件"
            case .html: return "HTML文件"
            case .javascript: return "JS文件"
            case .code: return "其他代码文件"
            }
        }
    }

    public enum Operation {
        case create(SFFileSuffix)
        case delete
        case rename(SFFileItem)
        case zip(SFFileItem)
        case unzip(SFFileItem)
    }
}

public class SFFileManager {
    public static let shared = SFFileManager()
    private let fileManager = FileManager.default
    let errorRelay = BehaviorRelay<String?>(value: nil)
    let successRelay = BehaviorRelay<String?>(value: nil)

    private init() {}

    public func attributes(at path: String) -> [FileAttributeKey: Any]? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            successRelay.accept("读取文件\(path.lastComponentToastName)属性成功")
            return attributes
        } catch {
            errorRelay.accept("读取文件\(path.lastComponentToastName)属性失败")
            return nil
        }
    }

    public func type(at path: String) -> FileAttributeType {
        return attributes(at: path)?[FileAttributeKey.type] as? FileAttributeType ?? .typeUnknown
    }

    public func size(at path: String, intialSize: inout Int) {
        switch type(at: path) {
        case .typeDirectory:
            do {
                let subPaths = try fileManager.contentsOfDirectory(atPath: path)
                subPaths.forEach { subPath in
                    size(at: path.addPathComponent(subPath), intialSize: &intialSize)
                }
                successRelay.accept("计算文件size-读取文件\(path.lastComponentToastName)的子文件成功")
            } catch {
                errorRelay.accept("计算文件size-读取文件\(path.lastComponentToastName)的子文件失败")
            }
        default:
            let size = (attributes(at: path)?[FileAttributeKey.size] as? NSNumber) ?? NSNumber(value: 0)
            intialSize += size.intValue
        }
    }

    public func modificationDate(at path: String) -> Date? {
        return (attributes(at: path)?[FileAttributeKey.modificationDate] as? Date)
    }

    public func isDirectoryExist(at path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let isExist = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return isExist && isDirectory.boolValue
    }

    public func isFileExist(at path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }

    public func listItems(at path: String?) -> [SFFileItem]? {
        guard let path = path, !path.isEmpty else { return nil }
        do {
            let itemPaths = try fileManager.contentsOfDirectory(atPath: path)
            successRelay.accept("读取文件\(path.lastComponentToastName)的子文件成功")
            return itemPaths
                .map { itemPath in
                    let filePath = path.addPathComponent(itemPath)
                    var fileSize: Int = 0
                    size(at: filePath, intialSize: &fileSize)
                    return SFFileItem(path: filePath,
                               name: itemPath,
                               size: fileSize,
                               attributeType: type(at: filePath),
                               modificationDate: modificationDate(at: filePath))
                }.sorted(by: { $0.modificationDate ?? Date() > $1.modificationDate ?? Date() })
        } catch {
            errorRelay.accept("读取文件\(path.lastComponentToastName)的子文件失败")
            return nil
        }
    }

    @discardableResult
    public func createDirectory(at path: String) -> Bool {
        if isDirectoryExist(at: path) {
            errorRelay.accept("创建文件夹\(path.lastComponentToastName)失败-文件夹已经存在")
            return false
        }
        do {
            try fileManager.createDirectory(at: URL(fileURLWithPath: path), withIntermediateDirectories: true, attributes: nil)
            successRelay.accept("创建文件夹\(path.lastComponentToastName)成功")
            return true
        } catch {
            errorRelay.accept("创建文件夹\(path.lastComponentToastName)失败")
            return false
        }
    }

    @discardableResult
    public func createFile(at path: String) -> Bool {
        if isFileExist(at: path) {
            errorRelay.accept("创建文件\(path.lastComponentToastName)失败-文件已经存在")
            return false
        }
        let result = fileManager.createFile(atPath: path, contents: nil, attributes: nil)
        result ? successRelay.accept("创建文件\(path.lastComponentToastName)成功") : errorRelay.accept("创建文件\(path.lastComponentToastName)失败")
        return result
    }

    @discardableResult
    public func delete(_ file: SFFileItem) -> Bool {
        do {
            try fileManager.removeItem(atPath: file.path)
            successRelay.accept("删除文件\(file.name)成功")
            return true
        } catch {
            errorRelay.accept("删除文件\(file.name)失败")
            return false
        }
    }

    @discardableResult
    public func move(_ file: SFFileItem, to target: String) -> Bool {
        do {
            if file.isDirectory {
                let subFileItems = listItems(at: file.path)
                subFileItems?.forEach({ file in
                    let path = target.addPathComponent(file.name)
                    if file.suffix == .directory {
                        createDirectory(at: path)
                    }
                    move(file, to: path)
                })
            } else {
                try fileManager.moveItem(atPath: file.path, toPath: target)
            }
            successRelay.accept("移动文件\(file.name)成功")
            return true
        } catch {
            errorRelay.accept("移动文件\(file.name)失败")
            return false
        }
    }

    @discardableResult
    public func rename(_ file: SFFileItem, name: String) -> Bool {
        let suffix = file.path.suffix ?? ""
        var components = file.path.components(separatedBy: "/")
        components.removeLast()
        let path = components.joined(separator: "/").addPathComponent(name).addSuffix(suffix)
        if file.isDirectory {
            if !createDirectory(at: path) {
                errorRelay.accept("重命名文件夹-创建\(name)失败")
                return false
            }
            let moveResult = move(file, to: path)
            //delete original
            let deleteResult = delete(file)
            moveResult ? successRelay.accept("重命名文件夹-移动\(file.name)成功") : errorRelay.accept("重命名文件夹-移动\(file.name)失败")
            deleteResult ? successRelay.accept("重命名文件夹-删除原\(file.name)成功") : errorRelay.accept("重命名文件夹-删除原\(file.name)失败")
            return moveResult && deleteResult
        } else {
            if isFileExist(at: path) {
                errorRelay.accept("重命名文件-文件\(name)已经存在")
                return false
            }
            let result = move(file, to: path)
            result ? successRelay.accept("重命名文件-移动文件\(file.name)成功") : errorRelay.accept("重命名文件-移动文件\(file.name)失败")
            return result
        }
    }

    @discardableResult
    public func copy(_ file: SFFileItem, to path: String) -> Bool {
        do {
            try fileManager.copyItem(atPath: file.path, toPath: path)
            successRelay.accept("复制文件-文件\(file.name)成功")
            return true
        } catch {
            errorRelay.accept("复制文件-文件\(file.name)失败")
            return false
        }
    }

    @discardableResult
    public func zip(_ file: SFFileItem) -> Bool {
        let newPath = file.path.removeSuffix().addSuffix("zip")
        if isFileExist(at: newPath) {
            errorRelay.accept("压缩文件-压缩文件\(file.name)已经存在")
            return false
        }
        if !file.canZip {
            errorRelay.accept("压缩文件-压缩文件\(file.name)不能被压缩")
            return false
        }
        if file.isDirectory {
            return SSZipArchive.createZipFile(atPath: newPath, withContentsOfDirectory: file.path)
        } else {
            return SSZipArchive.createZipFile(atPath: newPath, withFilesAtPaths: [file.path])
        }
    }

    @discardableResult
    public func unzip(_ file: SFFileItem) -> Bool {
        if file.canZip {
            errorRelay.accept("解压文件-文件\(file.name)不是压缩文件")
            return false
        }
        let path = file.path.removeSuffix()
        guard !path.isEmpty else {
            errorRelay.accept("解压文件-文件\(file.name)解压路径为空")
            return false
        }
        if isDirectoryExist(at: path) {
            errorRelay.accept("解压文件-文件\(file.name)解压目标路径已存在")
            return false
        }
        return SSZipArchive.unzipFile(atPath: file.path, toDestination: path)
    }
}

extension String {
    public func addPathComponent(_ path: String?) -> String {
        guard let path = path, !path.isEmpty else { return self }
        return self + "/" + path
    }

    public func addSuffix(_ suffix: String) -> String {
        if suffix.isEmpty { return self }
        return self + "." + suffix
    }

    public func removeSuffix() -> String {
        if !self.contains(".") { return self }
        var components = self.components(separatedBy: ".")
        components.removeLast()
        return components.joined(separator: ".")
    }

    public var suffix: String? {
        if !self.contains(".") { return nil }
        return self.components(separatedBy: ".").last
    }

    public var lastComponent: String? {
        return self.components(separatedBy: "/").last
    }

    public var lastComponentToastName: String {
        return lastComponent ?? "未知"
    }
}

extension Int {
    public func fileSizeFormatter() -> String {
        if self < 1024 {
            return "\(self) bytes"
        } else if self < 1024 * 1024 {
            let size = Float(self) / Float(1024)
            return "\(String(format:"%.2f",size)) KB"
        } else if self <= 1024 * 1024 * 1024 {
            let size = Float(self) / Float(1024 * 1024)
            return "\(String(format:"%.2f",size)) MB"
        } else {
            let size = Float(self) / Float(1024 * 1024 * 1024)
            return "\(String(format:"%.2f",size)) GB"
        }
    }
}

extension Date {
    public func formatString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: self)
    }
}
