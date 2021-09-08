//
//  SFTextFlieViewModel.swift
//  SFSandbox
//
//  Created by coker on 2021/9/8.
//

import Foundation
import RxSwift
import RxCocoa

class SFTextFlieViewModel {
    private let file: SFFileManager.SFFileItem
    private var path: String? { file.path }
    var fileName: String { file.name }

    let contentRelay = BehaviorRelay<String?>(value: nil)
    let errorRelay = BehaviorRelay<String?>(value: nil)
    let successRelay = BehaviorRelay<String?>(value: nil)
    let writeSuccessRelay = BehaviorRelay<Bool?>(value: nil)

    init(file: SFFileManager.SFFileItem) {
        self.file = file
        readFile()
    }

    private func readFile() {
        guard let path = self.path, !path.isEmpty else {
            errorRelay.accept("读取文件\(file.name)不存在")
            return
        }
        do {
            let content = try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
            contentRelay.accept(content)
            successRelay.accept("读取文件\(file.name)成功")
        } catch {
            errorRelay.accept("读取文件\(file.name)失败")
        }
    }

    func save(_ content: String) {
        guard
            let path = self.path,
            !path.isEmpty,
            let handle = FileHandle(forWritingAtPath: path)
        else {
            errorRelay.accept("写入目标文件\(file.name)不存在")
            return
        }
        guard let data = content.data(using: .utf8) else {
            errorRelay.accept("写入内容编码失败")
            return
        }
        do {
            try handle.truncate(atOffset: 0)
            successRelay.accept("文件\(file.name)清空成功")
        } catch {
            errorRelay.accept("文件\(file.name)清空失败")
            return
        }
        handle.write(data)
        successRelay.accept("文件\(file.name)写入成功")
        do {
            try handle.close()
            successRelay.accept("文件\(file.name)关闭成功")
        } catch {
            errorRelay.accept("文件\(file.name)关闭失败")
        }
        writeSuccessRelay.accept(true)

    }
}
