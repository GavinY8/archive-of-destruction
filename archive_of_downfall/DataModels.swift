//
//  Player.swift
//  archive_of_downfall
//
//  Created by Student on 5/26/26.
//
import Foundation

struct Nugget {
    var name: String
    
    var numSpeedDice: Int
    var hp: Int
    var stagger: Int
    var light: Int
    var maxLight: Int
    var dice: [SpeedDice]
    
    var slash: Double
    var pierce: Double
    var blunt: Double
    
    var staggerSlash: Double
    var staggerPierce: Double
    var staggerBlunt: Double
    
    var deck: [Card]
    var statuses: [Status]
}

struct SpeedDice {
    var min: Int
    var max: Int
}

struct Card {
    var name: String
    var cost: Int
    var dice: [Dice]
}

struct Dice {
    var minRoll: Int
    var maxRoll: Int
    var type: dicetype
}

enum atktype {
    case slash, blunt, pierce
}

enum dicetype {
    case atk, evade, block
}

struct Status {
    var bleed: Int = 0
    var paralyze: Int = 0
    var burn: Int = 0
    var protection: Int = 0
    var staggerProtection: Int = 0
    var fragile: Int = 0
    var strength: Int = 0
    var feeble: Int = 0
    var haste: Int = 0
    var bind: Int = 0
    var charge: Int = 0
    var endurance: Int = 0
    var disarm: Int = 0
}
