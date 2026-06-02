//
//  StatusFunctions.swift
//  archive_of_downfall
//
//  Created by Student on 6/1/26.
//

import Foundation

struct StatusManager {
    static func getStacks(of type: statusType, on nugget: Nugget) -> Int {
        return nugget.statuses.first(where: {$0.type == type})?.stacks ?? 0
    }
    
    static func addStatus(type: statusType, amount: Int, to nugget: inout Nugget) {
        if let index = nugget.statuses.firstIndex(where: { $0.type == type }) {
            nugget.statuses[index].stacks += amount
        } else {
            let newStatus = Status(type: type, stacks: amount)
            nugget.statuses.append(newStatus)
        }
    }
}
