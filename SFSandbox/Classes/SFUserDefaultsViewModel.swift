//
//  SFUserDefaultsViewModel.swift
//  SFSandbox
//
//  Created by coker on 2021/9/15.
//

import UIKit
import RxCocoa
import RxSwift

class SFUserDefaultsViewModel: SFFileViewModel {
    enum ItemType {
        case number
        case bool
        case array
        case dictionary
        case string
        case data
        case url
        case unknow

        var name: String {
            switch self {
            case .number:
                return "Number"
            case .bool:
                return "BOOL"
            case .array:
                return "Array"
            case .dictionary:
                return "Dictionary"
            case .string:
                return "String"
            case .data:
                return "Data"
            case .url:
                return "URL"
            case .unknow:
                return "Unknow"
            }
        }
    }

    struct Item {
        public let key: String
        public let value: Any?
        public let type: ItemType
    }

    private let userDefaults = UserDefaults.standard
    let itemsRelay = BehaviorRelay<[Item]>(value: [])
    var items: [Item] { itemsRelay.value }

    func refreshAllDatas() {
        let dic = userDefaults.dictionaryRepresentation()
        let items = dic.map { key, value -> Item in
            return Item(key: key, value: value, type: dataType(value, for: key))
        }.sorted { $0.key.uppercased() < $1.key.uppercased() }
        itemsRelay.accept(items)
    }

    private func dataType(_ value: Any?, for key: String) -> ItemType {
        guard let data = value else { return .unknow }
        if data is Bool {
            return .bool
        } else if data is NSNumber {
            return .number
        } else if data is Array<Any> {
            return .array
        } else if data is Dictionary<AnyHashable, Any> {
            return .dictionary
        } else if data is String {
            return .string
        } else if data is Data {
            if userDefaults.url(forKey: key) != nil { return .url }
            return .data
        } else if data is URL {
            return .url
        } else {
            return .unknow
        }
    }

    func delete(_ item: Item) {
        userDefaults.removeObject(forKey: item.key)
        userDefaults.synchronize()
        refreshAllDatas()
    }
}
