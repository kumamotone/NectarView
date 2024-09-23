//
//  Item.swift
//  NectarView
//
//  Created by 熊本和正 on 2024/09/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
