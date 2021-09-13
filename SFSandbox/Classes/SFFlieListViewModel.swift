//
//  SFFlieListViewModel.swift
//  SFSandbox
//
//  Created by coker on 2021/8/30.
//

import Foundation
import RxSwift
import RxCocoa

class SFFlieListViewModel: SFViewModel {
    let itemsRelay = BehaviorRelay<[SFFileManager.SFFileItem]>(value: [])
    var items: [SFFileManager.SFFileItem] { itemsRelay.value }
    private var searchKeyword: String = ""

    func refresh() {
        let items = SFFileManager.shared.listItems(at: path)?.filter { searchKeyword.isEmpty || $0.name.contains(searchKeyword) } ?? []
        itemsRelay.accept(items)
    }

    func createDirectory(_ name: String) {
        guard let path = self.path, !path.isEmpty else { return }
        if SFFileManager.shared.createDirectory(at: path.addPathComponent(name)) {
            refresh()
        }
    }

    func create(_ name: String, type: SFFileManager.SFFileSuffix) {
        guard let path = self.path, !path.isEmpty else { return }
        var suffix = ""
        switch type {
        case .directory:
            createDirectory(name)
            return
        case .json:
            suffix = "json"
        case .txt:
            suffix = "txt"
        case .java:
            suffix = "java"
        case .xml:
            suffix = "xml"
        case .markdown:
            suffix = "md"
        case .swift:
            suffix = "swift"
        case .html:
            suffix = "html"
        case .javascript:
            suffix = "js"
        case .excel, .file, .gif, .image, .pdf, .video, .word, .zip, .apk, .ipa, .xib, .code:
            return
        }
        if SFFileManager.shared.createFile(at: path.addPathComponent(name).addSuffix(suffix)) {
            refresh()
        }
    }

    func deleteFile(_ file: SFFileManager.SFFileItem) {
        let result = SFFileManager.shared.delete(file)
        if !result { return }
        var items = items
        items.removeAll(where: { $0.path == file.path })
        itemsRelay.accept(items)
    }

    func rename(_ file: SFFileManager.SFFileItem, name: String) {
        if SFFileManager.shared.rename(file, name: name) {
            refresh()
        }
    }

    func zip(_ file: SFFileManager.SFFileItem) {
        if SFFileManager.shared.zip(file) {
            refresh()
            successRelay.accept("压缩文件\(file.name)成功")
        } else {
            errorRelay.accept("压缩文件\(file.name)失败")
        }
    }

    func unzip(_ file: SFFileManager.SFFileItem) {
        if SFFileManager.shared.unzip(file) {
            refresh()
            successRelay.accept("解压文件\(file.name)成功")
        } else {
            errorRelay.accept("解压文件\(file.name)失败")
        }
    }

    func search(keyword: String) {
        self.searchKeyword = keyword
        refresh()
    }
}
