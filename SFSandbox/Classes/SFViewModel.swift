//
//  SFViewModel.swift
//  SFSandbox
//
//  Created by coker on 2021/9/9.
//

import Foundation
import RxCocoa
import RxSwift

class SFViewModel: SFViewModelProtocol {
    let file: SFFileManager.SFFileItem
    let errorRelay = BehaviorRelay<String?>(value: nil)
    let successRelay = BehaviorRelay<String?>(value: nil)

    var path: String? { file.path }
    var fileName: String { file.name }

    init(file: SFFileManager.SFFileItem) {
        self.file = file
    }
}

protocol SFViewModelProtocol {
    var file: SFFileManager.SFFileItem { get }
    var path: String? { get }
    var fileName: String { get }
    var errorRelay: BehaviorRelay<String?> { get }
    var successRelay: BehaviorRelay<String?> { get }
}
