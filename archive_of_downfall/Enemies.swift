//
//  Enemies.swift
//  archive_of_downfall
//
//  Created by Student on 5/26/26.
//

import Foundation
//chat put enemies here
struct Enemies {
    
    static var basic = Nugget( name: "basic", page: Page(30, 15, [SpeedDice(min: 1, max: 4), SpeedDice(min: 2, max: 5)], 1.0, 1.5, 2.0, 1.0, 1.5, 2.0), hp: 30, stagger: 15, light: 3, maxLight: 3, deck: CardDatabase.starterDeck, hand: [], discard: [], statuses: [])
    
}
