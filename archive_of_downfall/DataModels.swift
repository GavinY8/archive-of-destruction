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
    
    init(name: String, hp: Int, stagger: Int, light: Int, maxLight: Int, dice: [SpeedDice], slash: Double, pierce: Double, blunt: Double, staggerSlash: Double, staggerPierce: Double, staggerBlunt: Double, deck: [Card], statuses: [Status] = []) {
           self.name = name
           self.hp = hp
           self.stagger = stagger
           self.light = light
           self.maxLight = maxLight
           self.dice = dice
           self.slash = slash
           self.pierce = pierce
           self.blunt = blunt
           self.staggerSlash = staggerSlash
           self.staggerPierce = staggerPierce
           self.staggerBlunt = staggerBlunt
           self.deck = deck
           self.statuses = statuses
   }
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
    var atkType: atktype? = nil
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
