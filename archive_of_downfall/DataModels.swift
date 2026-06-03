//
//  Player.swift
//  archive_of_downfall
//
//  Created by Student on 5/26/26.
//
import Foundation

struct Nugget {
    var name: String
    
    var hp: Int
    var maxhp: Int
    var stagger: Int
    var maxStagger: Int
    var light: Int
    var maxLight: Int
    var speedDice: [SpeedDice]
    
    var slash: Double
    var pierce: Double
    var blunt: Double
    
    var staggerSlash: Double
    var staggerPierce: Double
    var staggerBlunt: Double
    
    var deck: [Card]
    var hand: [Card]
    var discard: [Card]
    
    var statuses: [Status]
    
    var isStaggered: Bool = false
}

struct SpeedDice {
    var min: Int
    var max: Int
    var assignedCard: Card?
}

struct Card {
    var name: String
    var cost: Int
    var dice: [Dice]
}

struct Dice {
    var minRoll: Int
    var maxRoll: Int
    var type: DiceType
    var atkType: AtkType? = nil
}

enum AtkType {
    case slash, blunt, pierce
}

enum DiceType {
    case atk, evade, block
}

enum StatusType {
    case bleed, paralysis, burn, protection, staggerProtection, fragile, strength, feeble, endurance, disarm, haste, bind
}

struct Status {
    var type: StatusType
    var stacks: Int
}

struct Deck {
    private var drawPile: [Card] = []
    
    mutating func drawCard(from originalDeck: [Card]) -> Card {
        if drawPile.isEmpty {
            drawPile = originalDeck.shuffled()
        }
        return drawPile.removeFirst()
    }
}
