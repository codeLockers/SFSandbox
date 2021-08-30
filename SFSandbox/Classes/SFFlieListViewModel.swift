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

    init(path: String?) {
        self.path = path
    }

    func fetchSandboxItems() {
        let items = SFFileManager.shared.listItems(at: path) ?? []
        itemsRelay.accept(items)
    }
}
