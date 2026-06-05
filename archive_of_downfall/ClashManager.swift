//
//  ClashManager.swift
//  archive_of_downfall
//
//  Created by Student on 6/5/26.
//

import Foundation

struct ClashAction {
    let player: String
    let target: String
    let playerCard: Card
    let enemyCard: Card
}

class ClashQueueManager {
    static let shared = ClashQueueManager()
    
    var queue: [ClashAction] = []
    
    func addToQueue(clash: ClashAction) {
        queue.append(clash)
    }
}
