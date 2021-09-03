//
//  SFFileManager.swift
//  SFSandbox
//
//  Created by coker on 2021/8/28.
//

import Foundation

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
    }
}

public class SFFileManager {
    public static let shared = SFFileManager()
    private let fileManager = FileManager.default
    private init() {}

    public func attributes(at path: String) -> [FileAttributeKey: Any]? {
        return try? fileManager.attributesOfItem(atPath: path)
    }

    public func type(at path: String) -> FileAttributeType {
        return attributes(at: path)?[FileAttributeKey.type] as? FileAttributeType ?? .typeUnknown
    }

    public func size(at path: String, intialSize: inout Int) {
        switch type(at: path) {
        case .typeDirectory:
            let subPaths = try? fileManager.contentsOfDirectory(atPath: path)
            subPaths?.forEach { subPath in
                size(at: path.addPathComponent(subPath), intialSize: &intialSize)
            }
        default:
            let size = (attributes(at: path)?[FileAttributeKey.size] as? NSNumber) ?? NSNumber(value: 0)
            intialSize += size.intValue
        }
    }

    public func modificationDate(at path: String) -> Date? {
        return (attributes(at: path)?[FileAttributeKey.modificationDate] as? Date)
    }


    public func listItems(at path: String?) -> [SFFileItem]? {
        guard let path = path, !path.isEmpty else { return nil }
        let itemPaths = try? fileManager.contentsOfDirectory(atPath: path)
        return itemPaths?
            .map { itemPath in
                let filePath = path.addPathComponent(itemPath)
                var fileSize: Int = 0
                size(at: filePath, intialSize: &fileSize)
                return SFFileItem(path: filePath,
                           name: itemPath,
                           size: fileSize,
                           attributeType: type(at: filePath),
                           modificationDate: modificationDate(at: filePath))
            }
    }

    @discardableResult
    public func createDirectory(at path: String) -> Bool {
        do {
            try fileManager.createDirectory(at: URL(fileURLWithPath: path), withIntermediateDirectories: true, attributes: nil)
            return true
        } catch { return false }
    }

    @discardableResult
    public func createFile(at path: String) -> Bool {
        return fileManager.createFile(atPath: path, contents: nil, attributes: nil)
    }

    @discardableResult
    public func delete(at path: String) -> Bool {
        do {
            try fileManager.removeItem(atPath: path)
            return true
        } catch { return false }
    }
}

extension String {
    public func addPathComponent(_ path: String?) -> String {
        guard let path = path, !path.isEmpty else { return self }
        return self + "/" + path
    }

    public func addSuffix(_ suffix: String) -> String {
        return self + "." + suffix
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
