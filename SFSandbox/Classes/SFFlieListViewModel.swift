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
    private let path: String?
    let itemsRelay = BehaviorRelay<[SFFileManager.SFFileItem]>(value: [])
    var items: [SFFileManager.SFFileItem] { itemsRelay.value }
    
    init(path: String?) {
        self.path = path
    }

    func refresh() {
        let items = SFFileManager.shared.listItems(at: path) ?? []
        itemsRelay.accept(items)
    }

    func createDirectory(_ name: String) {
        guard let path = self.path, !path.isEmpty else { return }
        SFFileManager.shared.createDirectory(at: path.addPathComponent(name))
        refresh()
    }

    func createFile(_ name: String, suffix: String) {
        guard let path = self.path, !path.isEmpty else { return }
        SFFileManager.shared.createFile(at: path.addPathComponent(name).addSuffix(suffix))
        refresh()
    }

    func deleteFile(_ file: SFFileManager.SFFileItem) {
        let result = SFFileManager.shared.delete(at: file.path)
        if !result { return }
        var items = items
        items.removeAll(where: { $0.path == file.path })
        itemsRelay.accept(items)
    }
}
