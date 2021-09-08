//
//  SFFileManager.swift
//  SFSandbox
//
//  Created by coker on 2021/8/28.
//

import Foundation
import RxSwift
import RxCocoa

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
            }
        }
    }

    public enum Operation {
        case create(SFFileSuffix)
        case delete
        case move
        case rename(SFFileItem)
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
            switch file.suffix {
            case .directory:
                let subFileItems = listItems(at: file.path)
                subFileItems?.forEach({ file in
                    let path = target.addPathComponent(file.name)
                    if file.suffix == .directory {
                        createDirectory(at: path)
                    }
                    move(file, to: path)
                })
            case .excel, .file, .gif, .image, .json, .pdf, .txt, .video, .word, .zip:
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
        switch file.suffix {
        case .directory:
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
        case .excel, .file, .gif, .image, .json, .pdf, .txt, .video, .word, .zip:
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
