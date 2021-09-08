//
//  SFFlieListViewModel.swift
//  SFSandbox
//
//  Created by coker on 2021/8/30.
//

import Foundation
import RxSwift
import RxCocoa

class SFFlieListViewModel {
    private let file: SFFileManager.SFFileItem
    let itemsRelay = BehaviorRelay<[SFFileManager.SFFileItem]>(value: [])
    var items: [SFFileManager.SFFileItem] { itemsRelay.value }
    private var path: String? { file.path }
    var fileName: String { file.name }
    
    init(file: SFFileManager.SFFileItem) {
        self.file = file
    }

    func refresh() {
        let items = SFFileManager.shared.listItems(at: path) ?? []
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
        case .excel, .file, .gif, .image, .pdf, .video, .word, .zip:
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
}
